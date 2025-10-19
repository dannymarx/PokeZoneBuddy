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
import OSLog

#if os(macOS)

/// Service for managing calendar integration using EventKit
/// Uses write-only access to add events to the user's calendar
/// macOS 26+ only
@MainActor
@Observable
class CalendarService {
    
    // MARK: - Properties
    
    private let eventStore = EKEventStore()
    private let timezoneService = TimezoneService.shared
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

        // Determine event timing in user's local timezone
        let userTimezone = timezoneService.userTimezone
        let startDate: Date
        let endDate: Date

        if event.isGlobalTime {
            // Location-specific events already represent an absolute point in time (UTC)
            startDate = event.startTime
            endDate = event.endTime
        } else if let cityTimezone = city.timeZone {
            // Global events need to be converted from the city's wall-clock time
            startDate = timezoneService.convertLocalEventTime(
                event.startTime,
                from: cityTimezone,
                to: userTimezone
            )
            endDate = timezoneService.convertLocalEventTime(
                event.endTime,
                from: cityTimezone,
                to: userTimezone
            )
        } else {
            // Fallback: treat as global if city timezone is unavailable
            AppLogger.calendar.warn("Falling back to global time for city \(city.name)")
            startDate = event.startTime
            endDate = event.endTime
        }

        // Create calendar event
        let ekEvent = EKEvent(eventStore: eventStore)

        // Set timezone and dates
        ekEvent.timeZone = userTimezone
        ekEvent.startDate = startDate
        ekEvent.endDate = endDate

        // Set event details
        ekEvent.title = "\(event.displayName) - \(city.name)"
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

    /// Adds a multi-city event to the user's calendar with all cities' time information
    /// - Parameters:
    ///   - event: The Pokemon GO event to add
    ///   - cities: The list of cities to include in the event
    /// - Throws: CalendarError if the event cannot be saved
    func addMultiCityEventToCalendar(event: Event, cities: [FavoriteCity]) async throws {
        // Check permission first
        if authorizationStatus != .writeOnly && authorizationStatus != .fullAccess {
            try await requestAccess()
        }

        guard !cities.isEmpty else {
            throw CalendarError.noCitiesProvided
        }

        // Determine overall event timing (earliest start to latest end across all cities)
        let userTimezone = timezoneService.userTimezone
        var allStartDates: [Date] = []
        var allEndDates: [Date] = []

        for city in cities {
            let (start, end) = calculateEventTimes(event: event, city: city, userTimezone: userTimezone)
            allStartDates.append(start)
            allEndDates.append(end)
        }

        guard let earliestStart = allStartDates.min(),
              let latestEnd = allEndDates.max() else {
            throw CalendarError.invalidTimeRange
        }

        // Create calendar event
        let ekEvent = EKEvent(eventStore: eventStore)

        // Set timezone and dates (span from earliest to latest)
        ekEvent.timeZone = userTimezone
        ekEvent.startDate = earliestStart
        ekEvent.endDate = latestEnd

        // Set event details
        let cityNames = cities.map { $0.name }.joined(separator: ", ")
        ekEvent.title = "\(event.displayName) - Multi-City"
        ekEvent.location = cityNames
        ekEvent.notes = buildMultiCityEventNotes(event: event, cities: cities)

        // Use default calendar
        ekEvent.calendar = eventStore.defaultCalendarForNewEvents

        // Save to calendar
        do {
            try eventStore.save(ekEvent, span: .thisEvent)
        } catch {
            AppLogger.calendar.error("Failed to save multi-city EKEvent: \(String(describing: error))")
            throw CalendarError.saveFailed
        }
    }

    // MARK: - Private Helper Methods

    /// Calculates event start and end times for a specific city
    private func calculateEventTimes(event: Event, city: FavoriteCity, userTimezone: TimeZone) -> (start: Date, end: Date) {
        let startDate: Date
        let endDate: Date

        if event.isGlobalTime {
            // Location-specific events already represent an absolute point in time (UTC)
            startDate = event.startTime
            endDate = event.endTime
        } else if let cityTimezone = city.timeZone {
            // Global events need to be converted from the city's wall-clock time
            startDate = timezoneService.convertLocalEventTime(
                event.startTime,
                from: cityTimezone,
                to: userTimezone
            )
            endDate = timezoneService.convertLocalEventTime(
                event.endTime,
                from: cityTimezone,
                to: userTimezone
            )
        } else {
            // Fallback: treat as global if city timezone is unavailable
            startDate = event.startTime
            endDate = event.endTime
        }

        return (startDate, endDate)
    }
    
    // MARK: - Private Methods

    /// Builds detailed notes for the calendar event
    private func buildEventNotes(event: Event) -> String {
        var notes = [String]()

        // Event heading
        notes.append(event.displayHeading)

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

    /// Builds detailed notes for a multi-city calendar event
    private func buildMultiCityEventNotes(event: Event, cities: [FavoriteCity]) -> String {
        var notes = [String]()
        let userTimezone = timezoneService.userTimezone

        // Event heading
        notes.append(event.displayHeading)
        notes.append("Type: \(event.eventType)")
        notes.append("")

        // Multi-city schedule header
        notes.append("━━━━━━━━━━━━━━━━━━━━━━")
        notes.append("MULTI-CITY SCHEDULE")
        notes.append("━━━━━━━━━━━━━━━━━━━━━━")
        notes.append("")

        // Sort cities by start time
        let sortedCities = cities.sorted { city1, city2 in
            let (start1, _) = calculateEventTimes(event: event, city: city1, userTimezone: userTimezone)
            let (start2, _) = calculateEventTimes(event: event, city: city2, userTimezone: userTimezone)
            return start1 < start2
        }

        // Add each city's timing
        for (index, city) in sortedCities.enumerated() {
            let (startDate, endDate) = calculateEventTimes(event: event, city: city, userTimezone: userTimezone)

            // City name
            notes.append("\(index + 1). \(city.displayName)")

            // Formatted time range
            let timeFormatter = DateFormatter()
            timeFormatter.dateStyle = .none
            timeFormatter.timeStyle = .short
            timeFormatter.timeZone = userTimezone
            timeFormatter.locale = Locale.autoupdatingCurrent

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateFormatter.timeZone = userTimezone
            dateFormatter.locale = Locale.autoupdatingCurrent

            let startTime = timeFormatter.string(from: startDate)
            let endTime = timeFormatter.string(from: endDate)
            let date = dateFormatter.string(from: startDate)
            let tzAbbr = userTimezone.abbreviation(for: startDate) ?? userTimezone.identifier

            notes.append("   \(date)")
            notes.append("   \(startTime) - \(endTime) \(tzAbbr)")

            // Time difference if available
            if let cityTimezone = city.timeZone {
                let timeDiff = timezoneService.timeDifferenceDescription(
                    from: userTimezone,
                    to: cityTimezone,
                    at: startDate
                )
                notes.append("   \(timeDiff)")
            }

            // Add spacing between cities
            if index < sortedCities.count - 1 {
                notes.append("")
            }
        }

        notes.append("")
        notes.append("━━━━━━━━━━━━━━━━━━━━━━")
        notes.append("")

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
        notes.append("Multi-City Planning Feature")

        return notes.joined(separator: "\n")
    }
}

// MARK: - Calendar Error

enum CalendarError: LocalizedError {
    case accessDenied
    case saveFailed
    case noCitiesProvided
    case invalidTimeRange

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access was denied"
        case .saveFailed:
            return "Event could not be saved to calendar"
        case .noCitiesProvided:
            return "No cities provided for multi-city event"
        case .invalidTimeRange:
            return "Invalid time range for multi-city event"
        }
    }
}

#endif
