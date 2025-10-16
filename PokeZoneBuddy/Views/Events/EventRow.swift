//
//  EventRow.swift
//  PokeZoneBuddy
//
//  Extracted from EventsListView for better modularity
//

import SwiftUI

/// A row view displaying a single event with thumbnail, details, and badges
struct EventRow: View {
    let event: Event
    let isSelected: Bool
    var isPast: Bool = false
    var isActive: Bool = false

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        // Show UTC time components without timezone conversion
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale.current
        return formatter
    }()

    private func formatEventDate(_ date: Date) -> String {
        return Self.dateFormatter.string(from: date)
    }

    var body: some View {
        HStack(spacing: 12) {
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
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                // Event Name & Countdown
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isPast ? .secondary : .primary)
                            .lineLimit(2)

                        Text(event.displayHeading)
                            .captionStyle()
                    }

                    Spacer()

                    CompactCountdownBadge(event: event)

                    FavoriteButton(eventID: event.id)
                        .padding(.leading, 4)
                }

                // Badges with Liquid Glass effect
                HStack(spacing: 6) {
                    ModernBadge(event.displayHeading, icon: "tag.fill", color: eventTypeColor)
                        .liquidGlassBadge(color: eventTypeColor)

                    if event.hasSpawns {
                        ModernBadge(String(localized: "badge.spawns"), icon: "location.fill", color: .green)
                            .liquidGlassBadge(color: .green)
                    }
                }

                // Date
                Text(formatEventDate(event.startTime))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(14)
        .liquidGlassEventCard(
            isSelected: isSelected,
            isActive: isActive,
            accentColor: .accentColor
        )
        .padding(.horizontal, 20)
        .opacity(isPast ? 0.6 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isSelected)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isActive)
    }

    private var eventTypeColor: Color {
        switch event.eventType {
        case "community-day":
            return .green
        case "raid-hour", "raid-day", "raid-battles", "raid-weekend":
            return .red
        case "pokemon-spotlight-hour":
            return .yellow
        case "go-battle-league":
            return .purple
        case "research", "ticketed-event":
            return .blue
        default:
            return .gray
        }
    }
}
