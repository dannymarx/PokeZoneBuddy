//
//  FavoriteButton.swift
//  PokeZoneBuddy
//
//  Created by Claude on 03.10.2025.
//  Version 0.3 - Favorite Button Component
//

import SwiftUI
import SwiftData

/// A button that toggles the favorite status of an event
/// Displays a filled star when favorited, an empty star when not
struct FavoriteButton: View {

    // MARK: - Properties

    let eventID: String
    @Environment(EventPreferencesService.self) private var eventPreferencesService

    // Query all favorites - this automatically updates when favorites change!
    @Query private var allFavorites: [FavoriteEvent]

    // Computed property to check if this specific event is favorited
    private var isFavorite: Bool {
        allFavorites.contains(where: { $0.eventID == eventID })
    }

    // MARK: - Body

    var body: some View {
        Button {
            toggleFavorite()
        } label: {
            Label("favorites.action.add", systemImage: isFavorite ? "star.fill" : "star")
                .labelStyle(.iconOnly)
                .foregroundStyle(isFavorite ? Color.systemYellow : .secondary)
        }
        .buttonStyle(.borderless) // Critical for buttons in List rows!
        .symbolEffect(.bounce, value: isFavorite)
        .help(isFavorite ? "favorites.action.remove" : "favorites.action.add")
    }

    // MARK: - Private Methods

    private func toggleFavorite() {
        Task {
            do {
                try await eventPreferencesService.toggleFavorite(eventID: eventID)
            } catch {
                AppLogger.notifications.error("Failed to toggle favorite for \(eventID): \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FavoriteButton(eventID: "test-event-id")
        .modelContainer(for: [FavoriteEvent.self], inMemory: true)
        .padding()
}
