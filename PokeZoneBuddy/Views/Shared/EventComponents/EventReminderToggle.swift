//
//  EventReminderToggle.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-12.
//

import SwiftUI
import UserNotifications
import SwiftData

/// A simple, streamlined reminder toggle for event detail views
struct EventReminderDetailView: View {

    enum LayoutStyle {
        case standalone
        case embedded
    }

    // MARK: - Properties

    let event: Event
    let layout: LayoutStyle
    private let notificationManager = NotificationManager.shared

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var isEnabled = false
    @State private var selectedOffset: ReminderOffset = .thirtyMinutes
    @State private var showTimeOptions = false

    // MARK: - Init

    init(event: Event, layout: LayoutStyle = .standalone) {
        self.event = event
        self.layout = layout
    }

    // MARK: - Body

    var body: some View {
        contentView
        .id(event.id)
        .task(id: event.id) {
            await loadNotifications()
        }
        .onDisappear {
            // Reset state when view disappears
            showTimeOptions = false
        }
        .onChange(of: notificationManager.authorizationStatus) { oldValue, newValue in
            Task {
                await loadNotifications()
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch layout {
        case .standalone:
            VStack(spacing: 16) {
                headerView
                cardContainer
            }
        case .embedded:
            cardContainer
        }
    }

    private var headerView: some View {
        HStack {
            Text("settings.reminders.title")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            Spacer()
        }
    }

    @ViewBuilder
    private var cardContainer: some View {
        if layout == .standalone {
            cardBody
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.25),
                                    .systemBlue.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        } else {
            cardBody
        }
    }

    private var cardBody: some View {
        VStack(spacing: 0) {
            toggleSection

            if isEnabled {
                Divider()
                timeSelectorButton

                if showTimeOptions {
                    Divider()
                    timeOptionsMenu
                }
            }

            if !notificationManager.isAuthorized {
                Divider()
                permissionWarning
            }
        }
    }

    private var contentPadding: CGFloat {
        layout == .standalone ? 16 : 12
    }

    private var toggleSection: some View {
        Toggle(isOn: $isEnabled) {
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.systemBlue)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.systemBlue.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("notifications.notify_before_event")
                        .font(.system(size: 14, weight: .medium))

                    Text(isEnabled ? selectedOffset.displayName : "No reminders set")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toggleStyle(.switch)
        .disabled(!notificationManager.isAuthorized)
        .onChange(of: isEnabled) { oldValue, newValue in
            handleToggle(newValue)
        }
        .padding(contentPadding)
    }

    private var timeSelectorButton: some View {
        Button {
            showTimeOptions.toggle()
        } label: {
            HStack {
                Text("notifications.time.label")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                Text(selectedOffset.shortDisplayName)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.systemBlue)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(showTimeOptions ? 90 : 0))
                    .animation(.spring(response: 0.3), value: showTimeOptions)
            }
            .padding(contentPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var timeOptionsMenu: some View {
        VStack(spacing: 0) {
            ForEach(ReminderOffset.allCases, id: \.self) { offset in
                timeOptionButton(for: offset)

                if offset != ReminderOffset.allCases.last {
                    Divider()
                        .padding(.leading, contentPadding)
                }
            }
        }
    }

    private func timeOptionButton(for offset: ReminderOffset) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedOffset = offset
                showTimeOptions = false
            }
            updateReminder()
        } label: {
            HStack {
                Text(offset.displayName)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)

                Spacer()

                if offset == selectedOffset {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.systemBlue)
                }
            }
            .padding(.horizontal, contentPadding)
            .padding(.vertical, 12)
            .background(offset == selectedOffset ? Color.systemBlue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var permissionWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.systemOrange)

            Text("notifications.enable.instruction")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            Button("action.open_settings") {
                openSettings()
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.systemBlue)
        }
        .padding(contentPadding)
    }

    // MARK: - Actions

    private func loadNotifications() async {
        let preferencesManager = ReminderPreferencesManager(modelContext: modelContext)
        if let preferences = preferencesManager.getPreferences(for: event.id) {
            isEnabled = preferences.isEnabled
            selectedOffset = preferences.enabledOffsets.first ?? .thirtyMinutes
        } else {
            isEnabled = false
            selectedOffset = .thirtyMinutes
        }
    }

    private func handleToggle(_ enabled: Bool) {
        Task {
            let preferencesManager = ReminderPreferencesManager(modelContext: modelContext)

            if enabled {
                // Save preferences and schedule notification
                preferencesManager.updatePreferences(for: event.id, offsets: [selectedOffset], isEnabled: true)
                await notificationManager.scheduleNotifications(for: event, offsets: [selectedOffset])
            } else {
                // Save preferences and cancel notification
                preferencesManager.updatePreferences(for: event.id, offsets: [selectedOffset], isEnabled: false)
                await notificationManager.cancelNotifications(for: event.id)
            }
        }
    }

    private func updateReminder() {
        guard isEnabled else { return }

        Task {
            let preferencesManager = ReminderPreferencesManager(modelContext: modelContext)

            // Update preferences with new offset
            preferencesManager.updatePreferences(for: event.id, offsets: [selectedOffset], isEnabled: true)

            // Reschedule notifications
            await notificationManager.cancelNotifications(for: event.id)
            await notificationManager.scheduleNotifications(for: event, offsets: [selectedOffset])
        }
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
    let event = Event(
        id: "test-event",
        name: "Community Day",
        eventType: "community-day",
        heading: "Community Day",
        startTime: Date().addingTimeInterval(3600),
        endTime: Date().addingTimeInterval(7200),
        isGlobalTime: false
    )

    return VStack {
        EventReminderDetailView(event: event)
    }
    .padding()
}
