//
//  ReminderPreferences.swift
//  PokéZoneBuddy
//
//  Created by Claude Code on 2025-10-12.
//

import Foundation
import SwiftData

/// Represents a time offset for event reminders
enum ReminderOffset: String, Codable, CaseIterable {
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case threeHours
    case oneDay

    var timeInterval: TimeInterval {
        switch self {
        case .fifteenMinutes: return 15 * 60
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .threeHours: return 3 * 60 * 60
        case .oneDay: return 24 * 60 * 60
        }
    }

    var displayName: String {
        switch self {
        case .fifteenMinutes: return "15 minutes before"
        case .thirtyMinutes: return "30 minutes before"
        case .oneHour: return "1 hour before"
        case .threeHours: return "3 hours before"
        case .oneDay: return "1 day before"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .fifteenMinutes: return "15 min"
        case .thirtyMinutes: return "30 min"
        case .oneHour: return "1 hour"
        case .threeHours: return "3 hours"
        case .oneDay: return "1 day"
        }
    }
}

/// SwiftData model for storing user's notification preferences per event
@Model
final class ReminderPreferences {
    // Note: No @Attribute(.unique) — incompatible with CloudKit sync.
    // Deduplication is enforced in PreferencesRepository.upsertReminder instead.
    var eventID: String = ""
    // Default values required for CloudKit compatibility.
    var enabledOffsets: [ReminderOffset] = [ReminderOffset.thirtyMinutes]
    var isEnabled: Bool = false
    var lastScheduledDate: Date?

    init(eventID: String, enabledOffsets: [ReminderOffset] = [.thirtyMinutes], isEnabled: Bool = true) {
        self.eventID = eventID
        self.enabledOffsets = enabledOffsets
        self.isEnabled = isEnabled
        self.lastScheduledDate = nil
    }
}
