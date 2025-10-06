//
//  CityDetailView.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 06.10.2025.
//

import SwiftUI
import SwiftData

/// Detail-Ansicht für eine Stadt mit Spots und Events
struct CityDetailView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    let city: FavoriteCity
    let viewModel: CitiesViewModel

    // MARK: - State

    @State private var showingAddSpotSheet = false
    @State private var editingSpot: CitySpot? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                cityInfoSection
                spotsSection
            }
            .listStyle(.inset)
            .navigationTitle(city.displayName)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingAddSpotSheet) {
                AddSpotSheet(city: city, viewModel: viewModel)
            }
            .sheet(item: $editingSpot) { spot in
                EditSpotSheet(spot: spot, viewModel: viewModel)
            }
        }
    }

    // MARK: - View Components

    /// City Information Section
    @ViewBuilder
    private var cityInfoSection: some View {
        Section {
            LabeledContent(String(localized: "city.info.fullName")) {
                Text(city.fullName)
                    .foregroundStyle(.secondary)
            }

            LabeledContent(String(localized: "city.info.timeZone")) {
                Text(city.abbreviatedTimeZone)
                    .foregroundStyle(.secondary)
            }

            LabeledContent(String(localized: "city.info.utcOffset")) {
                Text(city.formattedUTCOffset)
                    .foregroundStyle(.blue)
            }

            LabeledContent(String(localized: "city.info.added")) {
                Text(city.addedDate, style: .date)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(String(localized: "city.info.section"))
        }
    }

    /// Spots Section mit Empty State oder Liste
    @ViewBuilder
    private var spotsSection: some View {
        Section {
            if city.spots.isEmpty {
                ContentUnavailableView(
                    String(localized: "spots.section.empty"),
                    systemImage: "mappin.slash",
                    description: Text(String(localized: "spots.section.empty.description"))
                )
                .listRowBackground(Color.clear)
            } else {
                // Zeige erste 3 Spots
                ForEach(sortedSpots.prefix(3)) { spot in
                    NavigationLink {
                        SpotDetailView(spot: spot, viewModel: viewModel)
                    } label: {
                        SpotRowView(
                            spot: spot,
                            onEdit: {
                                editingSpot = spot
                            },
                            onDelete: {
                                viewModel.deleteSpot(spot)
                            }
                        )
                    }
                }

                // "Alle anzeigen" Link wenn mehr als 3 Spots
                if city.spots.count > 3 {
                    NavigationLink {
                        SpotListView(
                            spots: sortedSpots,
                            viewModel: viewModel
                        )
                    } label: {
                        HStack {
                            Text(String(format: String(localized: "spots.action.showAll"), city.spots.count))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text(String(localized: "spots.section.title"))
                Spacer()
                Button {
                    showingAddSpotSheet = true
                } label: {
                    Label(String(localized: "spots.add.title"), systemImage: "plus.circle.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "spots.add.title"))
            }
        }
    }

    /// Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(String(localized: "common.done")) {
                dismiss()
            }
        }
    }

    // MARK: - Computed Properties

    /// Sortierte Spots (neueste zuerst)
    private var sortedSpots: [CitySpot] {
        return viewModel.getSpots(for: city)
    }
}

// MARK: - Preview

#Preview("City Detail - With Spots") {
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

    // Mock Spots
    let spot1 = CitySpot(
        name: "Shibuya Crossing",
        notes: "Famous intersection",
        latitude: 35.661852,
        longitude: 139.700514,
        category: .pokestop,
        isFavorite: true,
        city: mockCity
    )

    let spot2 = CitySpot(
        name: "Tokyo Tower",
        notes: "Iconic landmark",
        latitude: 35.658517,
        longitude: 139.745438,
        category: .gym,
        city: mockCity
    )

    let spot3 = CitySpot(
        name: "Yoyogi Park",
        notes: "Community Day spot",
        latitude: 35.671598,
        longitude: 139.696930,
        category: .meetingPoint,
        city: mockCity
    )

    let spot4 = CitySpot(
        name: "Akihabara Station",
        notes: "Tech district",
        latitude: 35.698353,
        longitude: 139.773114,
        category: .other,
        city: mockCity
    )

    context.insert(mockCity)
    context.insert(spot1)
    context.insert(spot2)
    context.insert(spot3)
    context.insert(spot4)

    let viewModel = CitiesViewModel(modelContext: context)

    return CityDetailView(city: mockCity, viewModel: viewModel)
        .modelContainer(container)
}

#Preview("City Detail - Empty Spots") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FavoriteCity.self,
        CitySpot.self,
        configurations: config
    )

    let context = container.mainContext

    let mockCity = FavoriteCity(
        name: "Berlin",
        timeZoneIdentifier: "Europe/Berlin",
        fullName: "Berlin, Germany"
    )

    context.insert(mockCity)

    let viewModel = CitiesViewModel(modelContext: context)

    return CityDetailView(city: mockCity, viewModel: viewModel)
        .modelContainer(container)
}

