//
//  CalendarService.swift
//  PokeZoneBuddy
//
//  Created by Claude on 03.10.2025.
//  Version 0.3 - Calendar Integration (macOS only)
//

import Foundation
import EventKit
import Observation

#if os(macOS)

/// Service for managing calendar integration using EventKit
/// Uses write-only access to add events to the user's calendar
/// macOS 26+ only
@MainActor
@Observable
class CalendarService {
    
    // MARK: - Properties
    
    private let eventStore = EKEventStore()
    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    // MARK: - Initializer
    
    init() {
        updateAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    /// Updates the current authorization status
    func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    /// Requests write-only access to the user's calendar
    /// - Throws: CalendarError if access is denied
    func requestAccess() async throws {
        let granted = try await eventStore.requestWriteOnlyAccessToEvents()
        guard granted else {
            throw CalendarError.accessDenied
        }
        updateAuthorizationStatus()
    }
    
    /// Adds an event to the user's calendar
    /// - Parameters:
    ///   - event: The Pokemon GO event to add
    ///   - city: The city for timezone context
    /// - Throws: CalendarError if the event cannot be saved
    func addEventToCalendar(event: Event, city: FavoriteCity) async throws {
        // Check permission first
        if authorizationStatus != .writeOnly && authorizationStatus != .fullAccess {
            try await requestAccess()
        }
        
        // Create calendar event
        let ekEvent = EKEvent(eventStore: eventStore)
        
        // Set timezone based on city
        let timeZone = TimeZone(identifier: city.timeZoneIdentifier) ?? .current
        ekEvent.timeZone = timeZone
        
        // Set dates (convert from global time if needed)
        if event.isGlobalTime {
            // Event has global UTC time - convert to city's timezone
            ekEvent.startDate = event.startTime
            ekEvent.endDate = event.endTime
        } else {
            // Event has local time - use directly
            ekEvent.startDate = event.startTime
            ekEvent.endDate = event.endTime
        }
        
        // Set event details
        ekEvent.title = "\(event.name) - \(city.name)"
        ekEvent.location = city.name
        ekEvent.notes = buildEventNotes(event: event)
        
        // Use default calendar
        ekEvent.calendar = eventStore.defaultCalendarForNewEvents
        
        // Save to calendar
        do {
            try eventStore.save(ekEvent, span: .thisEvent)
        } catch {
            AppLogger.calendar.error("Failed to save EKEvent: \(String(describing: error))")
            throw CalendarError.saveFailed
        }
    }
    
    // MARK: - Private Methods
    
    /// Builds detailed notes for the calendar event
    private func buildEventNotes(event: Event) -> String {
        var notes = [String]()
        
        // Event heading
        notes.append(event.heading)
        
        // Event type
        notes.append("Type: \(event.eventType)")
        
        // Features
        if event.hasSpawns {
            notes.append("✓ Spawns")
        }
        if event.hasFieldResearchTasks {
            notes.append("✓ Field Research")
        }
        
        // Link
        if let link = event.link {
            notes.append("")
            notes.append("More info: \(link)")
        }
        
        // App credit
        notes.append("")
        notes.append("Added via PokeZoneBuddy")
        
        return notes.joined(separator: "\n")
    }
}

// MARK: - Calendar Error

enum CalendarError: LocalizedError {
    case accessDenied
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access was denied"
        case .saveFailed:
            return "Event could not be saved to calendar"
        }
    }
}

#endif

