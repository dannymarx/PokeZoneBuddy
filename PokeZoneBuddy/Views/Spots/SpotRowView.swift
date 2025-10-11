//
//  SpotRowView.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 06.10.2025.
//

import SwiftUI

/// Einzelne Row-Ansicht für einen CitySpot in einer Liste
struct SpotRowView: View {

    // MARK: - Properties

    let spot: CitySpot
    let onEdit: () -> Void
    let onDelete: () -> Void

    // MARK: - State

    @State private var showCopiedFeedback: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            categoryIcon

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(spot.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Notes (truncated to 2 lines)
                if !spot.notes.isEmpty {
                    Text(spot.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }

                // Category Badge with Liquid Glass
                HStack(spacing: 4) {
                    Image(systemName: spot.category.icon)
                        .font(.caption2)
                    Text(spot.category.localizedName)
                        .font(.caption2)
                }
                .foregroundStyle(categoryColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(categoryColor.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: categoryColor.opacity(0.15), radius: 2, x: 0, y: 1)
            }

            Spacer()

            // Favorite Star
            if spot.isFavorite {
                Image(systemName: "star.fill")
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Favorite spot")
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            contextMenuItems
        }
        .overlay(alignment: .top) {
            if showCopiedFeedback {
                copiedFeedbackView
            }
        }
    }

    // MARK: - View Components

    /// Category Icon mit passendem SF Symbol and Liquid Glass styling
    @ViewBuilder
    private var categoryIcon: some View {
        Image(systemName: spot.category.icon)
            .font(.title2)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        categoryColor,
                        categoryColor.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .symbolRenderingMode(.hierarchical)
            .frame(width: 32, height: 32)
            .accessibilityLabel("\(spot.category.localizedName) icon")
    }

    /// Context Menu Items
    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            copyToClipboard()
        } label: {
            Label("Copy Coordinates", systemImage: "doc.on.doc")
        }

        Button {
            onEdit()
        } label: {
            Label("Edit", systemImage: "pencil")
        }

        Divider()

        Button(role: .destructive) {
            onDelete()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    /// Feedback-View wenn Koordinaten kopiert wurden with Liquid Glass
    @ViewBuilder
    private var copiedFeedbackView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .symbolRenderingMode(.hierarchical)
            Text("Copied!")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .green.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 2)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Computed Properties

    /// Farbe basierend auf Kategorie
    private var categoryColor: Color {
        switch spot.category {
        case .gym:
            return .blue
        case .pokestop:
            return .cyan
        case .meetingPoint:
            return .purple
        case .other:
            return .gray
        }
    }

    // MARK: - Methods

    /// Kopiert Koordinaten in die Zwischenablage
    private func copyToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(spot.formattedCoordinates, forType: .string)
        #else
        UIPasteboard.general.string = spot.formattedCoordinates
        #endif

        // Feedback anzeigen
        withAnimation(.spring(response: 0.3)) {
            showCopiedFeedback = true
        }

        // Feedback nach 1.5 Sekunden ausblenden
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.spring(response: 0.3)) {
                showCopiedFeedback = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Spot Row - Gym") {
    let mockSpot = CitySpot(
        name: "Central Park Gym",
        notes: "Great raid location with 5 gyms nearby. Always active community.",
        latitude: 40.785091,
        longitude: -73.968285,
        category: .gym,
        isFavorite: true
    )

    List {
        SpotRowView(spot: mockSpot, onEdit: {}, onDelete: {})
    }
}

#Preview("Spot Row - PokéStop") {
    let mockSpot = CitySpot(
        name: "Times Square Stop",
        notes: "High-traffic area",
        latitude: 40.758896,
        longitude: -73.985130,
        category: .pokestop,
        isFavorite: false
    )

    List {
        SpotRowView(spot: mockSpot, onEdit: {}, onDelete: {})
    }
}
