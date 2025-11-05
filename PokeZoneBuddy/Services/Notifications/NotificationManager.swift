//
//  NotificationManager.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-12.
//

import Foundation
import UserNotifications
import SwiftData
import Combine

/// Central service for managing all notification operations
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // Throttling for timezone changes
    private var lastRescheduleTime: Date?
    private let rescheduleThrottleInterval: TimeInterval = 60 // 1 minute

    private init() {
        // Add observer for timezone changes
        NotificationCenter.default.addObserver(
            forName: .NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleTimezoneChange()
            }
        }
    }

    /// Handle timezone change with throttling
    private func handleTimezoneChange() async {
        // Throttle rapid timezone changes
        if let lastTime = lastRescheduleTime,
           Date().timeIntervalSince(lastTime) < rescheduleThrottleInterval {
            AppLogger.notifications.debug("Ignoring timezone change (throttled)")
            return
        }

        lastRescheduleTime = Date()
        AppLogger.notifications.info("Timezone changed, will reschedule notifications when ModelContext is available")
        // Note: Actual rescheduling must be triggered by the app with ModelContext
        // Post notification for app to handle
        NotificationCenter.default.post(name: .timezoneDidChange, object: nil)
    }

    // MARK: - Authorization

    /// Request notification authorization from the user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await updateAuthorizationStatus()

            if granted {
                AppLogger.notifications.info("Notification authorization granted")
            } else {
                AppLogger.notifications.info("Notification authorization denied")
            }

            return granted
        } catch {
            AppLogger.notifications.error("Failed to request authorization: \(error.localizedDescription)")
            return false
        }
    }

    /// Check current authorization status
    func updateAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Check if notifications are authorized
    var isAuthorized: Bool {
        return authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    // MARK: - Scheduling Notifications

    /// Schedule a notification for an event
    func scheduleNotification(for event: Event, city: String? = nil, offset: ReminderOffset) async {
        // Check authorization
        await updateAuthorizationStatus()
        guard isAuthorized else {
            AppLogger.notifications.debug("Cannot schedule notification: not authorized")
            return
        }

        // Calculate trigger date
        let triggerDate = event.actualStartTime.addingTimeInterval(-offset.timeInterval)

        // Don't schedule if notification time is in the past
        guard triggerDate > Date() else {
            AppLogger.notifications.debug("Skipping notification for \(event.id): trigger time in past")
            return
        }

        // Don't schedule for past events
        guard event.isUpcoming else {
            AppLogger.notifications.debug("Skipping notification for \(event.id): event is not upcoming")
            return
        }

        // Build notification content (with image support)
        let content = await NotificationContentBuilder.buildContent(for: event, city: city, offset: offset)

        // Create trigger
        let trigger = createTrigger(for: triggerDate)

        // Create request with unique identifier
        let identifier = notificationIdentifier(eventID: event.id, offset: offset)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Schedule notification
        do {
            try await center.add(request)
            AppLogger.notifications.info("Scheduled notification for \(event.displayName) at \(triggerDate)")
        } catch {
            AppLogger.notifications.error("Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    /// Schedule notifications for multiple offsets
    func scheduleNotifications(for event: Event, city: String? = nil, offsets: [ReminderOffset]) async {
        for offset in offsets {
            await scheduleNotification(for: event, city: city, offset: offset)
        }
    }

    // MARK: - Canceling Notifications

    /// Cancel all notifications for a specific event
    func cancelNotifications(for eventID: String) async {
        let identifiers = ReminderOffset.allCases.map { notificationIdentifier(eventID: eventID, offset: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        AppLogger.notifications.info("Canceled notifications for event: \(eventID)")
    }

    /// Cancel all pending notifications
    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        AppLogger.notifications.info("Canceled all pending notifications")
    }

    // MARK: - Rescheduling

    /// Reschedule all notifications for favorited events
    /// This should be called after timezone changes or when the app needs to refresh all notifications
    /// - Parameter modelContext: The SwiftData ModelContext to access favorites and events
    func rescheduleAllNotifications(modelContext: ModelContext) async {
        AppLogger.notifications.info("Rescheduling all notifications due to timezone change")

        // Get all favorited events
        let favoritesManager = FavoritesManager(modelContext: modelContext)
        let favoriteEventIDs = favoritesManager.getAllFavoriteEventIDs()

        AppLogger.notifications.debug("Found \(favoriteEventIDs.count) favorited event(s) to reschedule")

        // Cancel all existing notifications first
        await cancelAllNotifications()

        // Reschedule only for upcoming events
        var rescheduledCount = 0
        var skippedCount = 0

        for eventID in favoriteEventIDs {
            guard let event = fetchEvent(eventID: eventID, modelContext: modelContext) else {
                AppLogger.notifications.warn("Could not find event \(eventID) for rescheduling")
                continue
            }

            // CRITICAL: Only reschedule if event is still upcoming
            guard event.isUpcoming else {
                AppLogger.notifications.debug("Skipping rescheduling for past event: \(eventID)")
                skippedCount += 1
                continue
            }

            // Get user's preferred reminder offsets for this event
            let preferencesManager = ReminderPreferencesManager(modelContext: modelContext)
            let offsets = preferencesManager.getEnabledOffsets(for: eventID)

            // Schedule notifications for each offset
            await scheduleNotifications(for: event, offsets: offsets)
            rescheduledCount += 1
        }

        AppLogger.notifications.info("Rescheduled \(rescheduledCount) event(s), skipped \(skippedCount) past event(s)")
    }

    // MARK: - Cleanup

    /// Remove notifications for expired events
    func cleanupExpiredNotifications() async {
        let pending = await getPendingNotifications()
        let now = Date()

        let expiredIDs = pending.filter { request in
            guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                  let nextDate = trigger.nextTriggerDate() else {
                return false
            }
            return nextDate < now
        }.map { $0.identifier }

        if !expiredIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: expiredIDs)
            AppLogger.notifications.info("Cleaned up \(expiredIDs.count) expired notifications")
        }
    }

    /// Remove orphaned notifications (for events no longer favorited)
    func cleanupOrphanedNotifications(validEventIDs: Set<String>) async {
        let pending = await getPendingNotifications()

        let orphanedIDs = pending.filter { request in
            guard let eventID = extractEventID(from: request.identifier) else { return false }
            return !validEventIDs.contains(eventID)
        }.map { $0.identifier }

        if !orphanedIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: orphanedIDs)
            AppLogger.notifications.info("Cleaned up \(orphanedIDs.count) orphaned notifications")
        }
    }

    // MARK: - Query Notifications

    /// Get all pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }

    /// Get pending notifications for a specific event
    func getPendingNotifications(for eventID: String) async -> [UNNotificationRequest] {
        let all = await getPendingNotifications()
        return all.filter { request in
            guard let requestEventID = extractEventID(from: request.identifier) else { return false }
            return requestEventID == eventID
        }
    }

    /// Get count of pending notifications
    func getPendingNotificationCount() async -> Int {
        let pending = await getPendingNotifications()
        return pending.count
    }

    // MARK: - Testing

    /// Schedule a test notification (fires in 5 seconds)
    func scheduleTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from PokeZoneBuddy"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)

        do {
            try await center.add(request)
            AppLogger.notifications.info("Scheduled test notification")
        } catch {
            AppLogger.notifications.error("Failed to schedule test notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    /// Create a unique notification identifier
    private func notificationIdentifier(eventID: String, offset: ReminderOffset) -> String {
        return "event::\(eventID)::\(offset.rawValue)"
    }

    /// Extract event ID from notification identifier
    private func extractEventID(from identifier: String) -> String? {
        let components = identifier.split(separator: "::")
        guard components.count == 3, components[0] == "event" else { return nil }
        return String(components[1])
    }

    /// Create a calendar trigger for a specific date
    private func createTrigger(for date: Date) -> UNNotificationTrigger {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }

    /// Fetch an event by ID from the database
    /// - Parameters:
    ///   - eventID: The unique ID of the event
    ///   - modelContext: The SwiftData ModelContext to query
    /// - Returns: The Event if found, nil otherwise
    private func fetchEvent(eventID: String, modelContext: ModelContext) -> Event? {
        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate { $0.id == eventID }
        )
        return try? modelContext.fetch(descriptor).first
    }
}

// MARK: - Notification Content Builder

/// Utility for building notification content
struct NotificationContentBuilder {
    static func buildContent(for event: Event, city: String?, offset: ReminderOffset) async -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        // Build title based on event type
        content.title = buildTitle(for: event)

        // Build body with city context
        content.body = buildBody(for: event, city: city, offset: offset)

        // Add metadata
        content.sound = .default
        content.categoryIdentifier = "EVENT_REMINDER"
        content.threadIdentifier = event.eventType // Groups notifications by event type
        content.userInfo = [
            "eventID": event.id,
            "eventType": event.eventType,
            "startTime": event.startTime.timeIntervalSince1970,
            "isGlobalTime": event.isGlobalTime
        ]

        // Add rich image attachment
        if let imageURL = NotificationImageService.shared.getBestImageURL(for: event),
           let attachment = await NotificationImageService.shared.createAttachment(from: imageURL) {
            content.attachments = [attachment]
            AppLogger.notifications.debug("Added image attachment to notification for \(event.id)")
        }

        return content
    }

    private static func buildTitle(for event: Event) -> String {
        switch event.eventType {
        case "community-day":
            return "Community Day Starting Soon!"
        case "raid-hour":
            return "Raid Hour Starting Soon!"
        case "raid-day":
            return "Raid Day Starting Soon!"
        case "pokemon-spotlight-hour":
            return "Spotlight Hour Starting Soon!"
        case "go-battle-league":
            return "GO Battle League Starting Soon!"
        default:
            return "\(event.displayHeading) Starting Soon!"
        }
    }

    private static func buildBody(for event: Event, city: String?, offset: ReminderOffset) -> String {
        let timeRemaining = offset.shortDisplayName

        if let city = city {
            return "\(event.displayName) starts in \(city) in \(timeRemaining)"
        } else if event.isGlobalTime {
            return "\(event.displayName) starts in \(timeRemaining)"
        } else {
            return "\(event.displayName) starts globally in \(timeRemaining)"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Notification posted when timezone changes (throttled)
    static let timezoneDidChange = Notification.Name("timezoneDidChange")
}
