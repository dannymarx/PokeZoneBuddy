//
//  ReminderPreferencesManager.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-12.
//

import Foundation
import SwiftData

/// Manager for handling reminder preferences using SwiftData
class ReminderPreferencesManager {

    private var modelContext: ModelContext

    // MARK: - Initializer

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// Get reminder preferences for an event
    /// - Parameter eventID: The unique ID of the event
    /// - Returns: ReminderPreferences if found, nil otherwise
    func getPreferences(for eventID: String) -> ReminderPreferences? {
        let descriptor = FetchDescriptor<ReminderPreferences>(
            predicate: #Predicate { $0.eventID == eventID }
        )

        return try? modelContext.fetch(descriptor).first
    }

    /// Get or create reminder preferences for an event with default values
    /// - Parameter eventID: The unique ID of the event
    /// - Returns: Existing or newly created ReminderPreferences
    func getOrCreatePreferences(for eventID: String) -> ReminderPreferences {
        if let existing = getPreferences(for: eventID) {
            return existing
        }

        // Create new preferences with default
        let preferences = ReminderPreferences(
            eventID: eventID,
            enabledOffsets: [.thirtyMinutes],
            isEnabled: true
        )
        modelContext.insert(preferences)
        try? modelContext.save()

        return preferences
    }

    /// Update reminder preferences for an event
    /// - Parameters:
    ///   - eventID: The unique ID of the event
    ///   - offsets: Array of reminder offsets to enable
    ///   - isEnabled: Whether reminders are enabled for this event
    func updatePreferences(for eventID: String, offsets: [ReminderOffset], isEnabled: Bool) {
        let preferences = getOrCreatePreferences(for: eventID)
        preferences.enabledOffsets = offsets
        preferences.isEnabled = isEnabled
        preferences.lastScheduledDate = Date()

        try? modelContext.save()

        AppLogger.notifications.info("Updated preferences for event \(eventID): \(offsets.count) offsets, enabled: \(isEnabled)")
    }

    /// Delete preferences for an event
    /// - Parameter eventID: The unique ID of the event
    func deletePreferences(for eventID: String) {
        if let preferences = getPreferences(for: eventID) {
            modelContext.delete(preferences)
            try? modelContext.save()
            AppLogger.notifications.info("Deleted preferences for event \(eventID)")
        }
    }

    /// Get all events with reminder preferences
    /// - Returns: Array of ReminderPreferences
    func getAllPreferences() -> [ReminderPreferences] {
        let descriptor = FetchDescriptor<ReminderPreferences>(
            sortBy: [SortDescriptor(\.lastScheduledDate, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Get enabled reminder offsets for an event
    /// - Parameter eventID: The unique ID of the event
    /// - Returns: Array of enabled ReminderOffset, or default [.thirtyMinutes] if no preferences exist
    func getEnabledOffsets(for eventID: String) -> [ReminderOffset] {
        guard let preferences = getPreferences(for: eventID),
              preferences.isEnabled else {
            return [.thirtyMinutes] // Default
        }

        return preferences.enabledOffsets
    }

    /// Check if reminders are enabled for an event
    /// - Parameter eventID: The unique ID of the event
    /// - Returns: True if reminders are enabled, false otherwise
    func isEnabled(for eventID: String) -> Bool {
        return getPreferences(for: eventID)?.isEnabled ?? true
    }
}
