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
    @Environment(\.modelContext) private var modelContext
    @State private var isFavorite = false
    
    // MARK: - Body
    
    var body: some View {
        Button {
            toggleFavorite()
        } label: {
            Label("Favorite", systemImage: isFavorite ? "star.fill" : "star")
                .labelStyle(.iconOnly)
                .foregroundStyle(isFavorite ? .yellow : .secondary)
        }
        .buttonStyle(.borderless) // Critical for buttons in List rows!
        .symbolEffect(.bounce, value: isFavorite)
        .onAppear {
            checkFavoriteStatus()
        }
        .help(isFavorite ? "Remove from favorites" : "Add to favorites")
    }
    
    // MARK: - Private Methods
    
    private func toggleFavorite() {
        let manager = FavoritesManager(modelContext: modelContext)
        manager.toggleFavorite(eventID: eventID)
        isFavorite.toggle()
    }
    
    private func checkFavoriteStatus() {
        let manager = FavoritesManager(modelContext: modelContext)
        isFavorite = manager.isFavorite(eventID: eventID)
    }
}

// MARK: - Preview

#Preview {
    FavoriteButton(eventID: "test-event-id")
        .modelContainer(for: [FavoriteEvent.self], inMemory: true)
        .padding()
}
