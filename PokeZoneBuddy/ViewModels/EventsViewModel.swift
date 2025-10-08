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
            // Fetch from API (with cache fallback)
            let apiEvents = try await apiService.fetchEvents()
            
            // OFFLINE: Save to SwiftData for offline access
            await saveEventsToLocalStorage(apiEvents)
            
            lastSyncDate = Date()
            
        } catch {
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
            errorMessage = "No internet connection"
            showError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let apiEvents = try await apiService.fetchEvents(forceRefresh: true)
            await saveEventsToLocalStorage(apiEvents)
            lastSyncDate = Date()
            isOffline = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
            AppLogger.viewModel.error("Force refresh error: \(error)")
        }
    }
    
    /// Aktualisiert die Event-Liste (convenience method)
    func refreshEvents() async {
        await syncEvents()
    }
    
    // MARK: - Private Methods
    
    /// OFFLINE: Save API events to SwiftData
    private func saveEventsToLocalStorage(_ apiEvents: [Event]) async {
        // Use background context for heavy operation
        let container = modelContext.container
        
        await Task.detached {
            let context = ModelContext(container)
            
            // Delete all existing events first
            let descriptor = FetchDescriptor<Event>()
            if let existingEvents = try? context.fetch(descriptor) {
                for event in existingEvents {
                    context.delete(event)
                }
            }
            
            // Insert new events (@Attribute(.unique) handles upsert automatically!)
            for apiEvent in apiEvents {
                context.insert(apiEvent)
            }
            
            try? context.save()
            
            AppLogger.viewModel.info("Saved \(apiEvents.count) events to local storage")
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

    /// Events gruppiert nach Typ
    var eventsByType: [String: [Event]] {
        Dictionary(grouping: events, by: { $0.eventType })
    }
}

// MARK: - Formatting Helpers

extension EventsViewModel {
    /// Formatiert die letzte Update-Zeit für die Anzeige
    var lastUpdateText: String? {
        guard let updateTime = lastSyncDate else { return nil }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.unitsStyle = .full
        
        return String(format: String(localized: "events.last_updated"), formatter.localizedString(for: updateTime, relativeTo: Date()))
    }
}
