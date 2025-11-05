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

    func getReminderState(for eventID: String) -> ReminderPreferenceState
    func upsertReminder(
        eventID: String,
        offsets: [ReminderOffset],
        isEnabled: Bool,
        lastScheduledDate: Date?
    ) async throws
    func deleteReminder(eventID: String) async throws
}

// MARK: - Reminder Preference Snapshot

struct ReminderPreferenceState {
    let offsets: [ReminderOffset]
    let isEnabled: Bool
    let lastScheduledDate: Date?

    static let disabled = ReminderPreferenceState(
        offsets: [.thirtyMinutes],
        isEnabled: false,
        lastScheduledDate: nil
    )
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

    func getReminderState(for eventID: String) -> ReminderPreferenceState {
        guard let preferences = fetchReminderPreferences(for: eventID) else {
            return .disabled
        }

        let offsets = preferences.enabledOffsets.isEmpty ? [.thirtyMinutes] : preferences.enabledOffsets
        return ReminderPreferenceState(
            offsets: offsets,
            isEnabled: preferences.isEnabled && !offsets.isEmpty,
            lastScheduledDate: preferences.lastScheduledDate
        )
    }

    func upsertReminder(
        eventID: String,
        offsets: [ReminderOffset],
        isEnabled: Bool,
        lastScheduledDate: Date?
    ) async throws {
        let preferences: ReminderPreferences

        if let existing = fetchReminderPreferences(for: eventID) {
            preferences = existing
        } else {
            let newPreferences = ReminderPreferences(eventID: eventID)
            modelContext.insert(newPreferences)
            preferences = newPreferences
        }

        preferences.enabledOffsets = offsets.isEmpty ? [.thirtyMinutes] : offsets
        preferences.isEnabled = isEnabled
        preferences.lastScheduledDate = lastScheduledDate

        try modelContext.save()
    }

    func deleteReminder(eventID: String) async throws {
        guard let preferences = fetchReminderPreferences(for: eventID) else {
            return
        }

        modelContext.delete(preferences)
        try modelContext.save()
    }

    // MARK: - Helpers

    private func fetchReminderPreferences(for eventID: String) -> ReminderPreferences? {
        let descriptor = FetchDescriptor<ReminderPreferences>(
            predicate: #Predicate { $0.eventID == eventID }
        )
        return try? modelContext.fetch(descriptor).first
    }
}
