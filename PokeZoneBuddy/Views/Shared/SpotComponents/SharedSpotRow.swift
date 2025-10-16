//
//  SharedSpotRow.swift
//  PokeZoneBuddy
//
//  Unified spot row component used across different views
//  Consolidates SpotRowView functionality with additional flexibility
//

import SwiftUI

/// Shared spot row content component displaying spot information
/// Used in AllSpotsView, SpotListView, and other spot listing views
struct SharedSpotRow: View {
    // MARK: - Properties

    let spot: CitySpot
    var showFavorite: Bool = true
    var compact: Bool = false
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var showContextMenu: Bool = true

    // MARK: - State

    @State private var showCopiedFeedback: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // Title and Badge Row
            HStack(spacing: 12) {
                // Name - Left aligned
                Text(spot.name)
                    .font(.system(size: compact ? 14 : 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                // Favorite Indicator
                if showFavorite && spot.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: compact ? 11 : 12))
                        .foregroundStyle(Color.systemYellow)
                        .symbolRenderingMode(.hierarchical)
                        .shadow(color: Color.systemYellow.opacity(0.3), radius: 2, x: 0, y: 1)
                        .accessibilityLabel("Favorite spot")
                }

                // Category badge - Right aligned
                HStack(spacing: 4) {
                    Image(systemName: spot.category.icon)
                        .font(.system(size: 11, weight: .semibold))
                    Text(spot.category.localizedName)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(spot.category.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(spot.category.color.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(spot.category.color.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: spot.category.color.opacity(0.2), radius: 2, x: 0, y: 1)
            }

            // Notes
            if !spot.notes.isEmpty {
                HStack {
                    Text(spot.notes)
                        .font(.system(size: compact ? 11 : 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, compact ? 6 : 8)
        .padding(.horizontal, compact ? 4 : 8)
        .contextMenu {
            if showContextMenu {
                contextMenuItems
            }
        }
        .overlay(alignment: .top) {
            if showCopiedFeedback {
                copiedFeedbackView
            }
        }
    }

    // MARK: - View Components

    /// Context Menu Items
    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            copyToClipboard()
        } label: {
            Label("Copy Coordinates", systemImage: "doc.on.doc")
        }

        if let onEdit = onEdit {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }

        if onEdit != nil || onDelete != nil {
            Divider()
        }

        if let onDelete = onDelete {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    /// Feedback view when coordinates are copied with Liquid Glass
    @ViewBuilder
    private var copiedFeedbackView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.systemGreen)
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
                            .systemGreen.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.systemGreen.opacity(0.2), radius: 8, x: 0, y: 2)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Methods

    /// Copies coordinates to clipboard
    private func copyToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(spot.formattedCoordinates, forType: .string)
        #else
        UIPasteboard.general.string = spot.formattedCoordinates
        #endif

        // Show feedback
        withAnimation(.spring(response: 0.3)) {
            showCopiedFeedback = true
        }

        // Hide feedback after 1.5 seconds
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.spring(response: 0.3)) {
                showCopiedFeedback = false
            }
        }
    }
}

#Preview("Standard") {
    List {
        SharedSpotRow(
            spot: CitySpot(
                name: "Central Park Gym",
                notes: "Great raid location",
                latitude: 40.785091,
                longitude: -73.968285,
                category: .gym,
                isFavorite: true
            )
        )
        SharedSpotRow(
            spot: CitySpot(
                name: "Times Square Stop",
                notes: "High-traffic area",
                latitude: 40.758896,
                longitude: -73.985130,
                category: .pokestop,
                isFavorite: false
            )
        )
    }
}

#Preview("Compact") {
    List {
        SharedSpotRow(
            spot: CitySpot(
                name: "Shibuya Crossing",
                notes: "Famous intersection",
                latitude: 35.661852,
                longitude: 139.700514,
                category: .meetingPoint,
                isFavorite: true
            ),
            compact: true
        )
    }
}
