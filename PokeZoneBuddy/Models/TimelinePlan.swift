//
//  TimelinePlan.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-20.
//  Version 1.6.0 - Multi-City Timeline Plans & Templates
//

import Foundation
import SwiftData

/// Model for storing event-specific timeline plans
/// Each plan saves city selections for a specific event instance
@Model
final class TimelinePlan {

    // MARK: - Properties

    /// Unique identifier
    var id: UUID

    /// User-defined plan name
    var name: String

    /// Links to Event.id (e.g., "community-day-march-2025")
    var eventID: String

    /// Event display name for historical reference
    var eventName: String

    /// Event type for filtering/grouping
    var eventType: String

    /// TimeZone identifiers (e.g., ["Asia/Tokyo", "America/New_York"])
    var cityIdentifiers: [String]

    /// Creation timestamp
    var dateCreated: Date

    /// Last modification timestamp
    var dateModified: Date

    // MARK: - Initializer

    /// Creates a new timeline plan
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: User-defined plan name
    ///   - eventID: The unique ID of the event
    ///   - eventName: Event display name
    ///   - eventType: Event type for filtering
    ///   - cityIdentifiers: Array of timezone identifiers
    init(
        id: UUID = UUID(),
        name: String,
        eventID: String,
        eventName: String,
        eventType: String,
        cityIdentifiers: [String]
    ) {
        self.id = id
        self.name = name
        self.eventID = eventID
        self.eventName = eventName
        self.eventType = eventType
        self.cityIdentifiers = cityIdentifiers
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}
