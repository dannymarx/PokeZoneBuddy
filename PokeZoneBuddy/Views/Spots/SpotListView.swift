//
//  SpotListView.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 06.10.2025.
//

import SwiftUI
import SwiftData

/// Liste aller Spots einer Stadt
struct SpotListView: View {

    // MARK: - Properties

    let spots: [CitySpot]
    let viewModel: CitiesViewModel

    // MARK: - State

    @State private var selectedSpot: CitySpot?

    // MARK: - Body

    var body: some View {
        Group {
            if spots.isEmpty {
                emptyStateView
            } else {
                spotsList
            }
        }
        .sheet(item: $selectedSpot) { spot in
            VStack(spacing: 0) {
                // Overview
                SpotDetailView(spot: spot, viewModel: viewModel)
                Divider()
                // Edit
                EditSpotSheet(spot: spot, viewModel: viewModel)
            }
        }
    }

    // MARK: - View Components

    /// Empty State wenn keine Spots vorhanden
    @ViewBuilder
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label(String(localized: "spots.section.empty"), systemImage: "mappin.slash")
        } description: {
            Text(String(localized: "spots.section.empty.description"))
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "spots.section.empty") + ". " + String(localized: "spots.section.empty.description"))
    }

    /// Liste aller Spots
    @ViewBuilder
    private var spotsList: some View {
        List {
            ForEach(spots) { spot in
                Button {
                    selectedSpot = spot
                } label: {
                    SpotRowView(
                        spot: spot,
                        onEdit: {
                            selectedSpot = spot
                        },
                        onDelete: {
                            deleteSpot(spot)
                        }
                    )
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    deleteButton(for: spot)
                    favoriteButton(for: spot)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("\(spot.name), \(spot.category.localizedName)")
            }
        }
        .listStyle(.inset)
    }

    /// Delete Button für Swipe Actions
    @ViewBuilder
    private func deleteButton(for spot: CitySpot) -> some View {
        Button(role: .destructive) {
            deleteSpot(spot)
        } label: {
            Label(String(localized: "spots.action.delete"), systemImage: "trash")
        }
        .tint(.red)
    }

    /// Favorite Toggle Button für Swipe Actions
    @ViewBuilder
    private func favoriteButton(for spot: CitySpot) -> some View {
        Button {
            toggleFavorite(spot)
        } label: {
            if spot.isFavorite {
                Label(String(localized: "favorites.remove"), systemImage: "star.slash")
            } else {
                Label(String(localized: "favorites.add"), systemImage: "star")
            }
        }
        .tint(.yellow)
    }

    // MARK: - Methods

    /// Löscht einen Spot
    private func deleteSpot(_ spot: CitySpot) {
        viewModel.deleteSpot(spot)
    }

    /// Toggelt den Favoriten-Status
    private func toggleFavorite(_ spot: CitySpot) {
        viewModel.toggleSpotFavorite(spot)
    }
}

// MARK: - Preview

#Preview("Spot List - With Spots") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FavoriteCity.self,
        CitySpot.self,
        configurations: config
    )

    let context = container.mainContext

    let mockCity = FavoriteCity(
        name: "Tokyo",
        timeZoneIdentifier: "Asia/Tokyo",
        fullName: "Tokyo, Japan"
    )

    let mockSpots = [
        CitySpot(
            name: "Shibuya Crossing",
            notes: "Famous intersection with many PokéStops",
            latitude: 35.661852,
            longitude: 139.700514,
            category: .pokestop,
            isFavorite: true
        ),
        CitySpot(
            name: "Tokyo Tower Gym",
            notes: "Iconic landmark, great for raids",
            latitude: 35.658517,
            longitude: 139.745438,
            category: .gym,
            isFavorite: false
        ),
        CitySpot(
            name: "Yoyogi Park Meeting",
            notes: "Community Day meetup spot",
            latitude: 35.671598,
            longitude: 139.696930,
            category: .meetingPoint,
            isFavorite: true
        ),
    ]

    let viewModel = CitiesViewModel(modelContext: context)

    NavigationStack {
        SpotListView(spots: mockSpots, viewModel: viewModel)
            .navigationTitle(String(localized: "spots.section.title"))
    }
    .modelContainer(container)
}

#Preview("Spot List - Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FavoriteCity.self,
        CitySpot.self,
        configurations: config
    )

    let context = container.mainContext
    let viewModel = CitiesViewModel(modelContext: context)

    NavigationStack {
        SpotListView(spots: [], viewModel: viewModel)
            .navigationTitle(String(localized: "spots.section.title"))
    }
    .modelContainer(container)
}
