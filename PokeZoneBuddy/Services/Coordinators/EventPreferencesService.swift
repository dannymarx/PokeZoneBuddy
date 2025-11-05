//
//  EventPreferencesService.swift
//  PokeZoneBuddy
//
//  Created by Claude on 10/16/25.
//
//  Central service for managing favourites and reminder preferences.
//

import Foundation
import Observation

// MARK: - Service Protocol

protocol EventPreferencesServiceProtocol {
    func toggleFavorite(eventID: String) async throws
    func isFavorite(eventID: String) -> Bool
    func getAllFavoriteEventIDs() -> Set<String>

    func reminderState(for eventID: String) -> ReminderPreferenceState
    func remindersEnabled(for eventID: String) -> Bool
    func updateReminders(
        for event: Event,
        offsets: [ReminderOffset],
        isEnabled: Bool,
        cityIdentifier: String?
    ) async throws
    func disableReminders(for eventID: String) async throws
}

// MARK: - Service Implementation

@MainActor
@Observable
final class EventPreferencesService: EventPreferencesServiceProtocol {
    private let preferencesRepository: PreferencesRepositoryProtocol
    private let eventRepository: EventRepositoryProtocol
    private let notificationManager: NotificationManagerProtocol

    init(
        preferencesRepository: PreferencesRepositoryProtocol,
        eventRepository: EventRepositoryProtocol,
        notificationManager: NotificationManagerProtocol
    ) {
        self.preferencesRepository = preferencesRepository
        self.eventRepository = eventRepository
        self.notificationManager = notificationManager
    }

    // MARK: - Favorites

    func toggleFavorite(eventID: String) async throws {
        if preferencesRepository.isFavorite(eventID: eventID) {
            try await preferencesRepository.removeFavorite(eventID: eventID)
            try await preferencesRepository.deleteReminder(eventID: eventID)
            await notificationManager.cancelNotifications(for: eventID)
            AppLogger.notifications.info("Removed favorite and cleared reminders for event \(eventID)")
            return
        }

        try await preferencesRepository.addFavorite(eventID: eventID)
        AppLogger.notifications.info("Added favorite for event \(eventID)")

        // Restore reminders if user previously enabled them
        let state = preferencesRepository.getReminderState(for: eventID)
        guard state.isEnabled, !state.offsets.isEmpty else {
            return
        }

        guard let event = try await eventRepository.fetchEvent(id: eventID) else {
            AppLogger.notifications.warn("Favorite added but event not found for reminder restore: \(eventID)")
            return
        }

        await notificationManager.scheduleNotifications(
            for: event,
            city: nil,
            offsets: state.offsets
        )

        try await preferencesRepository.upsertReminder(
            eventID: eventID,
            offsets: state.offsets,
            isEnabled: true,
            lastScheduledDate: Date()
        )
    }

    func reminderState(for eventID: String) -> ReminderPreferenceState {
        preferencesRepository.getReminderState(for: eventID)
    }

    func isFavorite(eventID: String) -> Bool {
        preferencesRepository.isFavorite(eventID: eventID)
    }

    func getAllFavoriteEventIDs() -> Set<String> {
        preferencesRepository.getAllFavoriteEventIDs()
    }

    func remindersEnabled(for eventID: String) -> Bool {
        reminderState(for: eventID).isEnabled
    }

    // MARK: - Reminders

    func updateReminders(
        for event: Event,
        offsets: [ReminderOffset],
        isEnabled: Bool,
        cityIdentifier: String?
    ) async throws {
        let normalizedOffsets = offsets.isEmpty ? [.thirtyMinutes] : offsets

        await notificationManager.cancelNotifications(for: event.id)

        var lastScheduledDate: Date? = nil
        if isEnabled {
            await notificationManager.scheduleNotifications(
                for: event,
                city: cityIdentifier,
                offsets: normalizedOffsets
            )
            lastScheduledDate = Date()
        }

        try await preferencesRepository.upsertReminder(
            eventID: event.id,
            offsets: normalizedOffsets,
            isEnabled: isEnabled,
            lastScheduledDate: lastScheduledDate
        )
    }

    func disableReminders(for eventID: String) async throws {
        let state = preferencesRepository.getReminderState(for: eventID)
        await notificationManager.cancelNotifications(for: eventID)
        try await preferencesRepository.upsertReminder(
            eventID: eventID,
            offsets: state.offsets,
            isEnabled: false,
            lastScheduledDate: nil
        )
    }
}
