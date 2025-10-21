//
//  NotificationSettingsView.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-12.
//

import SwiftUI
import UserNotifications
import SwiftData

struct NotificationSettingsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    private let notificationManager = NotificationManager.shared
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var pendingCount = 0
    @State private var isLoaded = false

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Permission status
                permissionCard

                // Quick stats
                if authorizationStatus == .authorized {
                    statsCard
                }

                // Testing section
                testingSection
            }
            .padding(24)
        }
        .scrollIndicators(.hidden, axes: .vertical)
        .hideScrollIndicatorsCompat()
        .background(Color.appBackground)
        .navigationTitle("settings.notifications.title")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .onAppear {
            Task {
                await updateStatus()
            }
        }
        .onDisappear {
            // Reset state when leaving
            isLoaded = false
        }
        .refreshable {
            await updateStatus()
        }
    }

    // MARK: - Permission Card

    private var permissionCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: permissionIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(permissionColor)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(permissionColor.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(permissionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(permissionSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if authorizationStatus == .notDetermined {
                Button {
                    Task {
                        let granted = await notificationManager.requestAuthorization()
                        if granted {
                            await updateStatus()
                        }
                    }
                } label: {
                    Text("notifications.enable.title")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.systemBlue)
                        )
                }
                .buttonStyle(.plain)
            } else if authorizationStatus == .denied {
                Button {
                    openSettings()
                } label: {
                    HStack {
                        Text("action.open_system_settings")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Color.systemBlue)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.systemBlue.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    permissionColor.opacity(0.2),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("reminders.active_title")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Text("\(pendingCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.systemBlue)
                }

                Spacer()

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.systemBlue.opacity(0.3))
            }

            Divider()

            Text("reminders.help.message")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    Color.systemBlue.opacity(0.2),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Testing Section

    private var testingSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("settings.testing.title")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }

            Button {
                Task {
                    await notificationManager.scheduleTestNotification()
                }
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("notifications.action.send_test")
                            .font(.system(size: 14, weight: .medium))

                        Text("countdown.arrives_in_seconds")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .foregroundStyle(.primary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.quaternary.opacity(0.3))
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var permissionIcon: String {
        switch authorizationStatus {
        case .authorized, .provisional:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "bell.badge.fill"
        case .ephemeral:
            return "bell.fill"
        @unknown default:
            return "bell.fill"
        }
    }

    private var permissionColor: Color {
        switch authorizationStatus {
        case .authorized, .provisional:
            return .systemGreen
        case .denied:
            return .systemRed
        case .notDetermined:
            return .systemBlue
        case .ephemeral:
            return .systemBlue
        @unknown default:
            return .systemGray
        }
    }

    private var permissionTitle: String {
        switch authorizationStatus {
        case .authorized:
            return "Notifications Enabled"
        case .provisional:
            return "Notifications Enabled"
        case .denied:
            return "Notifications Disabled"
        case .notDetermined:
            return "Get Notified"
        case .ephemeral:
            return "Temporary Access"
        @unknown default:
            return "Unknown Status"
        }
    }

    private var permissionSubtitle: String {
        switch authorizationStatus {
        case .authorized:
            return "You'll receive event reminders"
        case .provisional:
            return "Quiet notifications enabled"
        case .denied:
            return "Enable in Settings to get reminders"
        case .notDetermined:
            return "Never miss an event"
        case .ephemeral:
            return "Limited notification access"
        @unknown default:
            return "Check notification settings"
        }
    }

    private func updateStatus() async {
        await notificationManager.updateAuthorizationStatus()
        authorizationStatus = notificationManager.authorizationStatus
        pendingCount = await notificationManager.getPendingNotificationCount()
    }

    private func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #else
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
