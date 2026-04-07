//
//  FavoriteEvent.swift
//  PokéZoneBuddy
//
//  Created by Claude on 03.10.2025.
//  Version 0.3 - Favorites System
//

import Foundation
import SwiftData

/// Model for storing favorite events locally with SwiftData
/// Each favorite is identified by the unique event ID
@Model
final class FavoriteEvent {
    
    // MARK: - Properties
    
    /// Unique event ID (matches Event.id)
    /// Note: No @Attribute(.unique) — CloudKit sync is incompatible with unique constraints.
    /// Deduplication is enforced in PreferencesRepository.addFavorite instead.
    // Default "" required for CloudKit compatibility (all properties must have a default).
    var eventID: String = ""

    /// Timestamp when this event was favorited
    var addedDate: Date = Date()
    
    // MARK: - Initializer
    
    /// Creates a new favorite event
    /// - Parameter eventID: The unique ID of the event to favorite
    init(eventID: String) {
        self.eventID = eventID
        self.addedDate = Date()
    }
}
