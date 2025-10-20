//
//  NotificationCoordinator.swift
//  PokeZoneBuddy
//
//  Created by Claude on 10/16/25.
//
//  This coordinator orchestrates notification scheduling across multiple services,
//  eliminating circular dependencies between NotificationManager, FavoritesManager,
//  and ReminderPreferencesManager.
//

import Foundation
import UserNotifications

// MARK: - Coordinator Protocol

protocol NotificationCoordinatorProtocol {
    func scheduleNotifications(for eventID: String, offsets: [ReminderOffset]) async
    func cancelNotifications(for eventID: String) async
    func updateNotifications(for eventID: String) async
    func rescheduleAllNotifications() async
}

// MARK: - Coordinator Implementation

@MainActor
final class NotificationCoordinator: NotificationCoordinatorProtocol {
    private let notificationManager: NotificationManagerProtocol
    private let eventRepository: EventRepositoryProtocol

    init(
        notificationManager: NotificationManagerProtocol,
        eventRepository: EventRepositoryProtocol
    ) {
        self.notificationManager = notificationManager
        self.eventRepository = eventRepository
    }

    // MARK: - Public Methods

    func scheduleNotifications(for eventID: String, offsets: [ReminderOffset]) async {
        guard let event = try? await eventRepository.fetchEvent(id: eventID) else {
            return
        }

        for offset in offsets {
            guard let triggerDate = calculateTriggerDate(
                from: event.startTime,
                offset: offset
            ) else {
                continue
            }

            // Create notification content
            let content = createNotificationContent(
                for: event,
                offset: offset
            )

            // Schedule notification
            await notificationManager.scheduleNotification(
                identifier: "\(eventID)_\(offset.rawValue)",
                content: content,
                triggerDate: triggerDate
            )
        }
    }

    func cancelNotifications(for eventID: String) async {
        // Cancel all notifications with this event ID prefix
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()

        let identifiersToCancel = pending
            .filter { $0.identifier.hasPrefix(eventID) }
            .map { $0.identifier }

        center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
    }

    func updateNotifications(for eventID: String) async {
        // Cancel existing notifications
        await cancelNotifications(for: eventID)

        // Re-schedule with current preferences
        // Note: This would need PreferencesRepository to get current offsets
        // For now, this is a placeholder
    }

    func rescheduleAllNotifications() async {
        // Cancel all pending notifications
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        // Re-schedule all active reminders
        // Note: This would need PreferencesRepository to get all preferences
        // For now, this is a placeholder
    }

    // MARK: - Private Helpers

    private func calculateTriggerDate(
        from eventDate: Date,
        offset: ReminderOffset
    ) -> Date? {
        let secondsBeforeEvent = offset.timeInterval
        let triggerDate = eventDate.addingTimeInterval(-secondsBeforeEvent)

        // Don't schedule notifications in the past
        guard triggerDate > Date() else {
            return nil
        }

        return triggerDate
    }

    private func createNotificationContent(
        for event: Event,
        offset: ReminderOffset
    ) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = event.name
        content.body = "Event starts in \(offset.displayName)"
        content.sound = .default
        content.userInfo = ["eventID": event.id]

        return content
    }
}

// MARK: - NotificationManager Protocol

protocol NotificationManagerProtocol {
    func scheduleNotification(
        identifier: String,
        content: UNNotificationContent,
        triggerDate: Date
    ) async
    func cancelNotification(identifier: String) async
}
