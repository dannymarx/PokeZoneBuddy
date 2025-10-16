//
//  PreferencesRepository.swift
//  PokeZoneBuddy
//
//  Created by Claude on 10/16/25.
//

import Foundation
import SwiftData

// MARK: - Repository Protocol

protocol PreferencesRepositoryProtocol {
    func isFavorite(eventID: String) -> Bool
    func getAllFavoriteEventIDs() -> Set<String>
    func addFavorite(eventID: String) async throws
    func removeFavorite(eventID: String) async throws

    func getReminders(for eventID: String) -> [ReminderOffset]
    func saveReminders(eventID: String, offsets: [ReminderOffset]) async throws
    func removeReminders(for eventID: String) async throws
}

// MARK: - Repository Implementation

@MainActor
final class PreferencesRepository: PreferencesRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Favorites

    func isFavorite(eventID: String) -> Bool {
        let descriptor = FetchDescriptor<FavoriteEvent>(
            predicate: #Predicate { $0.eventID == eventID }
        )
        let favorites = (try? modelContext.fetch(descriptor)) ?? []
        return !favorites.isEmpty
    }

    func getAllFavoriteEventIDs() -> Set<String> {
        let descriptor = FetchDescriptor<FavoriteEvent>()
        let favorites = (try? modelContext.fetch(descriptor)) ?? []
        return Set(favorites.map { $0.eventID })
    }

    func addFavorite(eventID: String) async throws {
        // Check if already exists
        guard !isFavorite(eventID: eventID) else { return }

        let favorite = FavoriteEvent(eventID: eventID)
        modelContext.insert(favorite)
        try modelContext.save()
    }

    func removeFavorite(eventID: String) async throws {
        let descriptor = FetchDescriptor<FavoriteEvent>(
            predicate: #Predicate { $0.eventID == eventID }
        )
        let favorites = try modelContext.fetch(descriptor)

        for favorite in favorites {
            modelContext.delete(favorite)
        }

        try modelContext.save()
    }

    // MARK: - Reminders

    func getReminders(for eventID: String) -> [ReminderOffset] {
        let descriptor = FetchDescriptor<ReminderPreferences>(
            predicate: #Predicate { $0.eventID == eventID }
        )
        guard let preferences = try? modelContext.fetch(descriptor).first else {
            return []
        }
        return preferences.enabledOffsets
    }

    func saveReminders(eventID: String, offsets: [ReminderOffset]) async throws {
        // Remove existing
        let descriptor = FetchDescriptor<ReminderPreferences>(
            predicate: #Predicate { $0.eventID == eventID }
        )
        let existing = try modelContext.fetch(descriptor)
        for pref in existing {
            modelContext.delete(pref)
        }

        // Add new
        if !offsets.isEmpty {
            let preferences = ReminderPreferences(eventID: eventID, enabledOffsets: offsets)
            modelContext.insert(preferences)
        }

        try modelContext.save()
    }

    func removeReminders(for eventID: String) async throws {
        let descriptor = FetchDescriptor<ReminderPreferences>(
            predicate: #Predicate { $0.eventID == eventID }
        )
        let preferences = try modelContext.fetch(descriptor)

        for pref in preferences {
            modelContext.delete(pref)
        }

        try modelContext.save()
    }
}
