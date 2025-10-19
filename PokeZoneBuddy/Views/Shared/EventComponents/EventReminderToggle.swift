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
        toggleSection
    }

    private var contentPadding: CGFloat {
        layout == .standalone ? 16 : 12
    }

    private var toggleSection: some View {
        VStack(alignment: .leading, spacing: layout == .embedded ? 4 : 8) {
            HStack(spacing: 12) {
                Toggle(isOn: $isEnabled) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(isEnabled ? Color.systemBlue : .secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.primary.opacity(0.08))
                        )
                }
                .toggleStyle(.switch)
                .disabled(!notificationManager.isAuthorized)
                .onChange(of: isEnabled) { _, newValue in
                    handleToggle(newValue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "notifications.notify_before_event"))
                        .font(.system(size: 13, weight: .medium))

                    Text(isEnabled ? selectedOffset.displayName : String(localized: "notifications.none_set"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                if layout == .standalone {
                    Menu {
                        ForEach(ReminderOffset.allCases, id: \.self) { offset in
                            Button {
                                selectedOffset = offset
                                updateReminder()
                            } label: {
                                HStack {
                                    Text(offset.displayName)
                                    if selectedOffset == offset {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedOffset.shortDisplayName)
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                    }
                    .disabled(!isEnabled)
                }
            }

            if !notificationManager.isAuthorized {
                if layout == .embedded {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)

                        Text(String(localized: "notifications.enable.instruction"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Spacer(minLength: 4)

                        Button(String(localized: "action.open_settings")) {
                            openSettings()
                        }
                        .buttonStyle(.borderless)
                        .font(.system(size: 11, weight: .semibold))
                    }
                } else {
                    permissionWarning
                }
            }
        }
        .padding(.vertical, layout == .standalone ? 12 : 6)
        .padding(.horizontal, contentPadding)
    }

    private var permissionWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.systemOrange)

            Text(String(localized: "notifications.enable.instruction"))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            Button(String(localized: "action.open_settings")) {
                openSettings()
            }
            .buttonStyle(.borderless)
            .font(.system(size: 12, weight: .medium))
        }
        .padding(.top, 6)
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
                preferencesManager.updatePreferences(for: event.id, offsets: [selectedOffset], isEnabled: true)
                await notificationManager.scheduleNotifications(for: event, offsets: [selectedOffset])
            } else {
                preferencesManager.updatePreferences(for: event.id, offsets: [selectedOffset], isEnabled: false)
                await notificationManager.cancelNotifications(for: event.id)
            }
        }
    }
    
    private func updateReminder() {
        guard isEnabled else { return }
        Task {
            let preferencesManager = ReminderPreferencesManager(modelContext: modelContext)
            preferencesManager.updatePreferences(for: event.id, offsets: [selectedOffset], isEnabled: true)
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
        EventReminderDetailView(event: event, layout: .embedded)
    }
    .padding()
}
