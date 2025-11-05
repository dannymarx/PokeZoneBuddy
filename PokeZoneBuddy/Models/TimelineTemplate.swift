//
//  TimelineTemplate.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-20.
//  Version 1.6.0 - Multi-City Timeline Plans & Templates
//

import Foundation
import SwiftData

/// Model for storing reusable city configurations for event types
/// Templates can be applied to any event of the matching type
@Model
final class TimelineTemplate {

    // MARK: - Properties

    /// Unique identifier
    var id: UUID

    /// Template name (e.g., "Community Day Default")
    var name: String

    /// Target event type ("community-day", "raid-hour", "all")
    var eventType: String

    /// Default cities for this event type (timezone identifiers)
    var cityIdentifiers: [String]

    /// Auto-apply when viewing matching event type
    var isDefault: Bool

    /// Creation timestamp
    var dateCreated: Date

    /// Last modification timestamp
    var dateModified: Date

    // MARK: - Initializer

    /// Creates a new timeline template
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Template name
    ///   - eventType: Target event type
    ///   - cityIdentifiers: Array of timezone identifiers
    ///   - isDefault: Whether to auto-apply this template
    init(
        id: UUID = UUID(),
        name: String,
        eventType: String,
        cityIdentifiers: [String],
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.eventType = eventType
        self.cityIdentifiers = cityIdentifiers
        self.isDefault = isDefault
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}
