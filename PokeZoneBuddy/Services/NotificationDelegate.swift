//
//  NotificationDelegate.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-12.
//

import Foundation
import UserNotifications

/// Delegate for handling notification-related callbacks
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    // MARK: - Foreground Notifications

    /// Called when a notification is about to be presented while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        AppLogger.notifications.info("Notification will be presented in foreground")

        // Show notification even when app is open
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - Notification Response

    /// Called when the user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        AppLogger.notifications.info("Notification tapped with action: \(response.actionIdentifier)")

        // Handle default action (tapping the notification)
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            if let eventID = userInfo["eventID"] as? String {
                AppLogger.notifications.info("Navigating to event: \(eventID)")

                // Post notification to navigate to event
                NotificationCenter.default.post(
                    name: .navigateToEvent,
                    object: nil,
                    userInfo: ["eventID": eventID]
                )
            }
        }

        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when user taps a notification to navigate to an event
    static let navigateToEvent = Notification.Name("navigateToEvent")
}
