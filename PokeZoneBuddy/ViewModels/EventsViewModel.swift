//
//  EventsViewModel.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.2025.
//  Version 0.4 - Performance & Offline Optimizations
//

import Foundation
import SwiftData
import Observation

/// ViewModel für Event-Management mit @Observable Pattern (macOS 26)
/// Lädt Events von der API und verwaltet sie in SwiftData
/// PERFORMANCE & OFFLINE: Optimized queries, offline-first approach
@Observable
final class EventsViewModel {
    
    // MARK: - Properties
    
    /// Liste aller geladenen Events
    private(set) var events: [Event] = []
    
    /// Gibt an ob gerade Daten geladen werden
    private(set) var isLoading = false
    
    /// Fehlermeldung falls beim Laden etwas schief geht
    private(set) var errorMessage: String?
    
    /// Zeigt ob ein Fehler aufgetreten ist
    var showError = false
    
    /// Timestamp des letzten erfolgreichen Updates
    private(set) var lastSyncDate: Date?
    
    /// OFFLINE: Indicates if app is in offline mode
    private(set) var isOffline = false

    /// Refresh button state for UI feedback
    private(set) var refreshState: RefreshState = .idle

    /// Count of events from last successful refresh
    private(set) var lastRefreshEventCount: Int = 0

    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let networkMonitor: NetworkMonitor
    private let apiService: APIService
    
    // MARK: - Initialization
    
    /// Initialisiert das ViewModel mit den benötigten Dependencies
    /// - Parameters:
    ///   - modelContext: SwiftData ModelContext für Persistierung
    ///   - networkMonitor: Network connectivity monitor
    init(modelContext: ModelContext, networkMonitor: NetworkMonitor) {
        self.modelContext = modelContext
        self.networkMonitor = networkMonitor
        self.apiService = APIService.shared
        
        // OFFLINE: Load from local storage first
        loadFromLocalStorage()
    }
    
    // MARK: - Public Methods
    
    /// OFFLINE: Load cached events from SwiftData
    func loadFromLocalStorage() {
        let descriptor = FetchDescriptor<Event>(
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            events = try modelContext.fetch(descriptor)
            AppLogger.viewModel.info("Loaded \(events.count) events from local storage")
        } catch {
            self.errorMessage = "Failed to load saved events"
            self.showError = true
            AppLogger.viewModel.error("Local fetch error: \(error)")
        }
    }
    
    /// OFFLINE: Sync with network if available
    func syncEvents() async {
        guard networkMonitor.shouldSync else {
            AppLogger.viewModel.warn("Skipping sync: network unavailable or constrained")
            isOffline = true
            return
        }

        isLoading = true
        isOffline = false
        errorMessage = nil
        showError = false

        defer { isLoading = false }

        do {
            // Fetch from API (with cache fallback) - returns DTOs
            let eventDTOs = try await apiService.fetchEvents()

            // OFFLINE: Save to SwiftData for offline access
            await saveEventsToLocalStorage(eventDTOs)

            lastSyncDate = Date()

        } catch {
            // Don't show cancellation errors to the user
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                AppLogger.viewModel.debug("Sync was cancelled (likely due to concurrent request)")
                // OFFLINE: We still have local data, so it's okay
                isOffline = true
                return
            }

            self.errorMessage = error.localizedDescription
            self.showError = true
            AppLogger.viewModel.error("Sync error: \(error)")

            // OFFLINE: We still have local data, so it's okay
            isOffline = true
        }
    }
    
    /// OFFLINE: Force refresh from network
    func forceRefresh() async {
        guard networkMonitor.isConnected else {
            AppLogger.viewModel.warn("Cannot refresh: no network connection")
            refreshState = .error
            self.errorMessage = String(localized: "toast.no_connection.title", defaultValue: "No internet connection")
            return
        }

        isLoading = true
        refreshState = .loading
        defer {
            isLoading = false
        }

        do {
            let eventDTOs = try await apiService.fetchEvents(forceRefresh: true)
            let eventCount = eventDTOs.count  // Capture count before async boundary
            await saveEventsToLocalStorage(eventDTOs)
            lastSyncDate = Date()
            isOffline = false
            lastRefreshEventCount = eventCount

            // Success state
            refreshState = .success
            AppLogger.viewModel.info("Successfully refreshed \(eventCount) events")

            // Auto-reset to idle after 2.5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                if refreshState == .success {
                    refreshState = .idle
                }
            }

        } catch {
            // Don't show cancellation errors to the user
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                AppLogger.viewModel.debug("Force refresh was cancelled (likely due to concurrent request)")
                refreshState = .idle
                return
            }

            // Error state
            self.errorMessage = error.localizedDescription
            refreshState = .error
            AppLogger.viewModel.error("Force refresh error: \(error)")

            // Auto-reset to idle after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if refreshState == .error {
                    refreshState = .idle
                }
            }
        }
    }
    
    /// Aktualisiert die Event-Liste (convenience method)
    /// This is called by toolbar buttons and Cmd+R, should use forceRefresh for user feedback
    func refreshEvents() async {
        await forceRefresh()
    }
    
    // MARK: - Private Methods
    
    /// OFFLINE: Save API events to SwiftData
    /// Uses @Attribute(.unique) on Event.id for automatic upsert behavior
    private func saveEventsToLocalStorage(_ eventDTOs: [EventDTO]) async {
        // Use background context for heavy operation
        let container = modelContext.container

        await Task.detached {
            let context = ModelContext(container)

            // Convert DTOs to Event models and insert
            // @Attribute(.unique) on Event.id handles upserts automatically
            // SwiftData will update existing events or insert new ones based on the unique ID
            for eventDTO in eventDTOs {
                let event = eventDTO.toEvent()
                context.insert(event)
            }

            // Clean up old events that are no longer in the API response
            // This is more efficient than delete-all-then-insert
            let apiEventIDs = Set(eventDTOs.map { $0.id })
            let descriptor = FetchDescriptor<Event>()

            guard let existingEvents = try? context.fetch(descriptor) else {
                await AppLogger.viewModel.error("Failed to fetch existing events for cleanup")
                // Still try to save new events
                do {
                    try context.save()
                    await AppLogger.viewModel.info("Saved \(eventDTOs.count) events to local storage")
                } catch {
                    await AppLogger.viewModel.error("Failed to save events: \(error)")
                }
                return
            }

            // Validate: Don't delete everything if API returns suspiciously few events
            if eventDTOs.count < 5 && existingEvents.count > 10 {
                await AppLogger.viewModel.warn("API returned only \(eventDTOs.count) events but we have \(existingEvents.count) cached. Skipping cleanup to prevent data loss.")
                // Still save new events, but don't delete old ones
                do {
                    try context.save()
                    await AppLogger.viewModel.info("Saved \(eventDTOs.count) events to local storage (cleanup skipped)")
                } catch {
                    await AppLogger.viewModel.error("Failed to save events: \(error)")
                }
                return
            }

            // Safe deletion with logging
            let eventsToDelete = existingEvents.filter { !apiEventIDs.contains($0.id) }
            let deletedCount = eventsToDelete.count

            for event in eventsToDelete {
                context.delete(event)
            }

            // Save with proper error handling
            do {
                try context.save()
                if deletedCount > 0 {
                    await AppLogger.viewModel.info("Saved \(eventDTOs.count) events and cleaned up \(deletedCount) old events")
                } else {
                    await AppLogger.viewModel.info("Saved \(eventDTOs.count) events to local storage")
                }
            } catch {
                await AppLogger.viewModel.error("Failed to save events: \(error)")
                // Don't throw - we want to keep using cached events
            }
        }.value

        // Reload from storage
        loadFromLocalStorage()
    }
    
    // MARK: - Filtered Events
    
    /// PERFORMANCE: Get filtered events (filtering in Swift, not in Predicate)
    func getFilteredEvents(config: FilterConfiguration) -> [Event] {
        return events.filter { event in
            // Type filter
            if !config.selectedTypes.isEmpty {
                if !config.selectedTypes.contains(event.eventType) {
                    return false
                }
            }
            
            // Search text filter
            if !config.searchText.isEmpty {
                let searchLower = config.searchText.lowercased()
                let matchesName = event.name.lowercased().contains(searchLower)
                let matchesHeading = event.heading.lowercased().contains(searchLower)
                let matchesType = event.eventType.lowercased().contains(searchLower)
                
                if !matchesName && !matchesHeading && !matchesType {
                    return false
                }
            }
            
            return true
        }
    }
    
    /// Nur zukünftige Events
    var upcomingEvents: [Event] {
        events.filter { $0.isUpcoming }
    }
    
    /// Nur aktuell laufende Events
    var activeEvents: [Event] {
        events.filter { $0.isCurrentlyActive }
    }
    
    /// Nur vergangene Events
    var pastEvents: [Event] {
        events.filter { $0.isPast }
    }

    /// Favorisierte Events (nur zukünftige/aktive, sortiert nach StartTime)
    /// PERFORMANCE: Uses Set for O(1) ID lookup
    var favoriteEvents: [Event] {
        let favoritesManager = FavoritesManager(modelContext: modelContext)
        let favoriteIDs = Set(favoritesManager.getAllFavoriteEventIDs())

        return events
            .filter { event in
                // Must be favorited
                guard favoriteIDs.contains(event.id) else { return false }
                // Must be upcoming or active (not past)
                return event.isUpcoming || event.isCurrentlyActive
            }
            .sorted { $0.startTime < $1.startTime }
    }
}
