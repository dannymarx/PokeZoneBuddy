//
//  EventsViewModel.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.2025.
//

import Foundation
import SwiftData
import Combine

/// ViewModel für Event-Management
/// Lädt Events von der API und verwaltet sie in SwiftData
@MainActor
final class EventsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Liste aller geladenen Events
    @Published var events: [Event] = []
    
    /// Gibt an ob gerade Daten geladen werden
    @Published var isLoading = false
    
    /// Fehlermeldung falls beim Laden etwas schief geht
    @Published var errorMessage: String?
    
    /// Zeigt ob ein Fehler aufgetreten ist
    @Published var showError = false
    
    /// Timestamp des letzten erfolgreichen Updates
    @Published var lastUpdateTime: Date?
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let apiService: APIService
    
    // MARK: - Initialization
    
    /// Initialisiert das ViewModel mit den benötigten Dependencies
    /// - Parameter modelContext: SwiftData ModelContext für Persistierung
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.apiService = APIService.shared
        
        // Beim Start vorhandene Events aus der Datenbank laden
        loadEventsFromDatabase()
    }
    
    // MARK: - Public Methods
    
    /// Lädt Events aus der lokalen Datenbank
    func loadEventsFromDatabase() {
        do {
            let descriptor = FetchDescriptor<Event>(
                sortBy: [SortDescriptor(\.startTime, order: .forward)]
            )
            events = try modelContext.fetch(descriptor)
        } catch {
            print("❌ Fehler beim Laden aus Datenbank: \(error)")
            errorMessage = "Failed to load saved events"
            showError = true
        }
    }
    
    /// Lädt neue Events von der API und speichert sie
    func fetchEvents() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            // Events von API laden
            let fetchedEvents = try await apiService.fetchEvents()
            
            // Alte Events löschen
            try deleteAllEvents()
            
            // Neue Events in Datenbank speichern
            for event in fetchedEvents {
                modelContext.insert(event)
            }
            
            try modelContext.save()
            
            // Events neu aus DB laden um konsistent zu sein
            loadEventsFromDatabase()
            
            // Update-Zeit speichern
            lastUpdateTime = Date()
            
            print("✅ \(fetchedEvents.count) Events erfolgreich geladen")
            
        } catch let error as APIError {
            print("❌ API Fehler: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            print("❌ Unbekannter Fehler: \(error)")
            errorMessage = String(localized: "alert.error.unknown")
            showError = true
        }
        
        isLoading = false
    }
    
    /// Aktualisiert die Event-Liste (convenience method)
    func refreshEvents() async {
        await fetchEvents()
    }
    
    // MARK: - Filtered Events
    
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
    
    /// Events gruppiert nach Typ
    var eventsByType: [String: [Event]] {
        Dictionary(grouping: events, by: { $0.eventType })
    }
    
    // MARK: - Private Methods
    
    /// Löscht alle Events aus der Datenbank
    private func deleteAllEvents() throws {
        let descriptor = FetchDescriptor<Event>()
        let existingEvents = try modelContext.fetch(descriptor)
        
        for event in existingEvents {
            modelContext.delete(event)
        }
    }
}

// MARK: - Formatting Helpers

extension EventsViewModel {
    /// Formatiert die letzte Update-Zeit für die Anzeige
    var lastUpdateText: String? {
        guard let updateTime = lastUpdateTime else { return nil }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.unitsStyle = .full
        
        return String(format: String(localized: "events.last_updated"), formatter.localizedString(for: updateTime, relativeTo: Date()))
    }
}
