//
//  FavoriteEventCard.swift
//  PokeZoneBuddy
//
//  Created by Claude on 06.10.2025.
//  Compact event card for sidebar favorite events display
//

import SwiftUI

/// Compact event card for sidebar favorite events display
struct FavoriteEventCard: View {
    let event: Event

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
                // Event Thumbnail
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
                }

                // Event Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(formatEventDate(event.startTime))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.gray.opacity(0.15))
        )
        .help(String(localized: "favorite_event.tap_to_view"))
    }
}
