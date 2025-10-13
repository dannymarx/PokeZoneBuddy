//
//  AllSpotsView.swift
//  PokeZoneBuddy
//
//  Shows all City Spots across all cities
//

import SwiftUI
import SwiftData

struct AllSpotsView: View {

    // MARK: - Properties

    @Bindable var citiesViewModel: CitiesViewModel
    @State private var selectedSpot: CitySpot?
    @State private var showCityPicker = false
    @State private var showAddSpot = false
    @State private var cityForNewSpot: FavoriteCity?
    @State private var editingSpot: CitySpot?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if citiesViewModel.favoriteCities.isEmpty {
                    emptyStateView
                } else if allSpots.isEmpty {
                    noSpotsView
                } else {
                    spotsList
                }
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: "spots.section.title"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(String(localized: "spots.add.title")) {
                        showCityPicker = true
                    }
                }

                if !allSpots.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }
            }
#endif
            .sheet(item: $selectedSpot) { spot in
                SpotDetailView(spot: spot, viewModel: citiesViewModel) { spot in
                    editingSpot = spot
                }
#if os(iOS)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
#elseif os(macOS)
                .presentationSizing(.fitted)
#endif
            }
            .sheet(item: $editingSpot) { spot in
                EditSpotSheet(spot: spot, viewModel: citiesViewModel)
#if os(iOS)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
#elseif os(macOS)
                .presentationSizing(.fitted)
#endif
            }
            .sheet(isPresented: $showCityPicker, onDismiss: {
                // Show AddSpotSheet after CityPickerSheet dismisses
                if cityForNewSpot != nil {
                    showAddSpot = true
                }
            }) {
                CityPickerSheet(cities: citiesViewModel.favoriteCities) { city in
                    cityForNewSpot = city
                }
#if os(iOS)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
#endif
            }
            .sheet(isPresented: $showAddSpot, onDismiss: {
                // Clear selected city after AddSpotSheet closes
                cityForNewSpot = nil
            }) {
                if let city = cityForNewSpot {
                    AddSpotSheet(city: city, viewModel: citiesViewModel)
#if os(iOS)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
#endif
                }
            }
            .onChange(of: showAddSpot) { _, newValue in
                if !newValue {
                    cityForNewSpot = nil
                }
            }
        }
    }

    // MARK: - Spots List

    private var spotsList: some View {
        List {
            ForEach(citiesViewModel.favoriteCities, id: \.persistentModelID) { city in
                let spots = citiesViewModel.getSpots(for: city)
                if !spots.isEmpty {
                    Section {
                        ForEach(spots, id: \.persistentModelID) { spot in
                            Button {
                                selectedSpot = spot
                            } label: {
                                SpotRowContent(spot: spot)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            citiesViewModel.deleteSpots(at: offsets, from: city)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.blue)
                            Text(city.name)
                        }
                    }
                }
            }
        }
#if os(macOS)
        .listStyle(.inset)
#else
        .listStyle(.insetGrouped)
#endif
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "map.circle",
            title: String(localized: "placeholder.no_cities.title"),
            subtitle: String(localized: "placeholder.no_cities.subtitle")
        )
    }

    private var noSpotsView: some View {
        EmptyStateView(
            icon: "mappin.slash",
            title: String(localized: "spots.section.empty"),
            subtitle: String(localized: "spots.section.empty.description")
        )
    }

    // MARK: - Computed Properties

    private var allSpots: [CitySpot] {
        citiesViewModel.favoriteCities.flatMap { city in
            citiesViewModel.getSpots(for: city)
        }
    }
}

// MARK: - Spot Row Content

private struct SpotRowContent: View {
    let spot: CitySpot

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon with liquid glass styling
            Circle()
                .fill(categoryColor.gradient)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                )
                .shadow(color: categoryColor.opacity(0.25), radius: 3, x: 0, y: 1.5)

            // Spot Info - Compact layout with inline badge
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(spot.name)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)

                    // Inline category badge
                    HStack(spacing: 3) {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 9))
                        Text(spot.category.localizedName)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(categoryColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(categoryColor.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: categoryColor.opacity(0.1), radius: 1, x: 0, y: 0.5)
                }

                if !spot.notes.isEmpty {
                    Text(spot.notes)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            // Favorite Indicator
            if spot.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow)
                    .symbolRenderingMode(.hierarchical)
                    .shadow(color: .yellow.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    private var categoryIcon: String {
        switch spot.category {
        case .pokestop: return "mappin.circle.fill"
        case .gym: return "dumbbell.fill"
        case .meetingPoint: return "person.2.fill"
        case .other: return "mappin.and.ellipse"
        }
    }

    private var categoryColor: Color {
        switch spot.category {
        case .pokestop: return .blue
        case .gym: return .red
        case .meetingPoint: return .purple
        case .other: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
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

    let mockSpot = CitySpot(
        name: "Shibuya Crossing",
        notes: "Famous intersection",
        latitude: 35.661852,
        longitude: 139.700514,
        category: .pokestop,
        isFavorite: true,
        city: mockCity
    )

    context.insert(mockCity)
    context.insert(mockSpot)
    try? context.save()

    let viewModel = CitiesViewModel(modelContext: context)
    viewModel.loadFavoriteCitiesFromDatabase()

    return AllSpotsView(citiesViewModel: viewModel)
        .modelContainer(container)
}
