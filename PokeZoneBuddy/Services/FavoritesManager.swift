//
//  FavoritesManager.swift
//  PokeZoneBuddy
//
//  Created by Claude on 03.10.2025.
//  Version 0.3 - Favorites Manager
//

import Foundation
import SwiftData
import Observation

/// Manager for handling event favorites using SwiftData
/// Uses @Observable for modern SwiftUI state management
@Observable
class FavoritesManager {
    
    // MARK: - Properties
    
    private var modelContext: ModelContext
    
    // MARK: - Initializer
    
    /// Creates a new favorites manager
    /// - Parameter modelContext: The SwiftData model context for persistence
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// Toggles the favorite status of an event
    /// If the event is favorited, it will be unfavorited and vice versa
    /// - Parameter eventID: The unique ID of the event
    func toggleFavorite(eventID: String) {
        if let existing = fetchFavorite(eventID: eventID) {
            // Event is favorited - remove it
            modelContext.delete(existing)

            // Cancel notifications and delete preferences
            Task { @MainActor in
                await NotificationManager.shared.cancelNotifications(for: eventID)
                let preferencesManager = ReminderPreferencesManager(modelContext: modelContext)
                preferencesManager.deletePreferences(for: eventID)
            }
        } else {
            // Event is not favorited - add it
            let favorite = FavoriteEvent(eventID: eventID)
            modelContext.insert(favorite)

            // Schedule notifications using custom preferences
            Task { @MainActor in
                if let event = fetchEvent(eventID: eventID) {
                    let preferencesManager = ReminderPreferencesManager(modelContext: modelContext)
                    let offsets = preferencesManager.getEnabledOffsets(for: eventID)
                    await NotificationManager.shared.scheduleNotifications(for: event, offsets: offsets)
                }
            }
        }

        // Save changes
        try? modelContext.save()
    }
    
    /// Checks if an event is favorited
    /// - Parameter eventID: The unique ID of the event
    /// - Returns: True if the event is in favorites, false otherwise
    func isFavorite(eventID: String) -> Bool {
        return fetchFavorite(eventID: eventID) != nil
    }
    
    /// Gets all favorited event IDs
    /// - Returns: Array of event IDs that are favorited
    func getAllFavoriteEventIDs() -> [String] {
        let descriptor = FetchDescriptor<FavoriteEvent>(
            sortBy: [SortDescriptor(\.addedDate, order: .reverse)]
        )
        
        guard let favorites = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        return favorites.map { $0.eventID }
    }
    
    // MARK: - Private Methods

    /// Fetches a favorite event by ID
    /// - Parameter eventID: The unique ID of the event
    /// - Returns: The FavoriteEvent if found, nil otherwise
    private func fetchFavorite(eventID: String) -> FavoriteEvent? {
        let descriptor = FetchDescriptor<FavoriteEvent>(
            predicate: #Predicate { $0.eventID == eventID }
        )

        return try? modelContext.fetch(descriptor).first
    }

    /// Fetches an event by ID
    /// - Parameter eventID: The unique ID of the event
    /// - Returns: The Event if found, nil otherwise
    private func fetchEvent(eventID: String) -> Event? {
        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate { $0.id == eventID }
        )

        return try? modelContext.fetch(descriptor).first
    }
}
