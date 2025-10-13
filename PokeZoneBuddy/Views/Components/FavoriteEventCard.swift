//
//  FavoriteEventCard.swift
//  PokeZoneBuddy
//
//  Created by Claude on 06.10.2025.
//  Compact event card for sidebar favorite events display
//

import SwiftUI
import SwiftData

/// Compact event card for sidebar favorite events display
struct FavoriteEventCard: View {
    let event: Event
    @State private var isHovered = false
    @State private var hasReminders = false

    @Environment(\.modelContext) private var modelContext

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale.current
        return formatter
    }()

    private func formatEventDate(_ date: Date) -> String {
        return Self.dateFormatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                // Event Thumbnail with Liquid Glass frame
                if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                            Rectangle()
                                .fill(.quaternary)
                                .overlay(
                                    ProgressView()
                                        .controlSize(.small)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(.quaternary)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                }

                // Event Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(formatEventDate(event.startTime))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()

                        if hasReminders {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(isHovered ? 0.35 : 0.2),
                            .accentColor.opacity(isHovered ? 0.25 : 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: .black.opacity(isHovered ? 0.1 : 0.06),
            radius: isHovered ? 8 : 4,
            x: 0,
            y: isHovered ? 3 : 2
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .help(String(localized: "favorite_event.tap_to_view"))
        .onHover { hovering in
            isHovered = hovering
        }
        .task {
            checkReminders()
        }
    }

    private func checkReminders() {
        let preferencesManager = ReminderPreferencesManager(modelContext: modelContext)
        hasReminders = preferencesManager.isEnabled(for: event.id)
    }
}
