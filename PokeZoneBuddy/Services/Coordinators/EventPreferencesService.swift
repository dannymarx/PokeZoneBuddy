//
//  EventPreferencesService.swift
//  PokeZoneBuddy
//
//  Created by Claude on 10/16/25.
//
//  This service consolidates FavoritesManager and ReminderPreferencesManager
//  into a single, cohesive service for managing event preferences.
//

import Foundation

// MARK: - Service Protocol

protocol EventPreferencesServiceProtocol {
    func toggleFavorite(eventID: String) async throws
    func isFavorite(eventID: String) -> Bool
    func getAllFavoriteEventIDs() -> Set<String>

    func setReminders(eventID: String, offsets: [ReminderOffset]) async throws
    func getReminders(for eventID: String) -> [ReminderOffset]
    func removeReminders(for eventID: String) async throws
}

// MARK: - Service Implementation

@MainActor
final class EventPreferencesService: EventPreferencesServiceProtocol {
    private let preferencesRepository: PreferencesRepositoryProtocol
    private let notificationCoordinator: NotificationCoordinatorProtocol

    init(
        preferencesRepository: PreferencesRepositoryProtocol,
        notificationCoordinator: NotificationCoordinatorProtocol
    ) {
        self.preferencesRepository = preferencesRepository
        self.notificationCoordinator = notificationCoordinator
    }

    // MARK: - Favorites

    func toggleFavorite(eventID: String) async throws {
        let isFavorite = preferencesRepository.isFavorite(eventID: eventID)

        if isFavorite {
            // Remove favorite and cancel notifications
            try await preferencesRepository.removeFavorite(eventID: eventID)
            await notificationCoordinator.cancelNotifications(for: eventID)
        } else {
            // Add favorite
            try await preferencesRepository.addFavorite(eventID: eventID)
        }
    }

    func isFavorite(eventID: String) -> Bool {
        preferencesRepository.isFavorite(eventID: eventID)
    }

    func getAllFavoriteEventIDs() -> Set<String> {
        preferencesRepository.getAllFavoriteEventIDs()
    }

    // MARK: - Reminders

    func setReminders(eventID: String, offsets: [ReminderOffset]) async throws {
        // Save reminder preferences
        try await preferencesRepository.saveReminders(eventID: eventID, offsets: offsets)

        // Schedule notifications
        await notificationCoordinator.scheduleNotifications(for: eventID, offsets: offsets)
    }

    func getReminders(for eventID: String) -> [ReminderOffset] {
        preferencesRepository.getReminders(for: eventID)
    }

    func removeReminders(for eventID: String) async throws {
        try await preferencesRepository.removeReminders(for: eventID)
        await notificationCoordinator.cancelNotifications(for: eventID)
    }
}
