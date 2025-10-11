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
    @State private var selectedCity: FavoriteCity?
    @State private var selectedSpot: CitySpot?
    @State private var showCityPicker = false
    @State private var showAddSpot = false
    @State private var cityForNewSpot: FavoriteCity?

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
            .sheet(item: $selectedCity) { city in
                SpotListView(
                    viewModel: citiesViewModel,
                    city: city,
                    initialSpot: selectedSpot
                )
#if os(iOS)
                .presentationDetents([.fraction(0.9), .large])
                .presentationDragIndicator(.visible)
#elseif os(macOS)
                .presentationSizing(.fitted)
#endif
            }
            .sheet(isPresented: $showCityPicker) {
                CityPickerSheet(cities: citiesViewModel.favoriteCities) { city in
                    cityForNewSpot = city
                    showAddSpot = true
                }
#if os(iOS)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
#elseif os(macOS)
                .presentationSizing(.fitted)
#endif
            }
            .sheet(isPresented: $showAddSpot) {
                if let city = cityForNewSpot {
                    AddSpotSheet(city: city, viewModel: citiesViewModel)
#if os(iOS)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
#elseif os(macOS)
                        .presentationSizing(.fitted)
#endif
                }
            }
            .onChange(of: selectedCity) { newValue in
                if case .none = newValue {
                    selectedSpot = nil
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
                                selectedCity = city
                            } label: {
                                SpotRowContent(spot: spot)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            citiesViewModel.deleteSpots(at: offsets, from: city)
                        }
                        .onMove { source, destination in
                            citiesViewModel.moveSpots(from: source, to: destination, in: city)
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
            // Category Icon
            Circle()
                .fill(categoryColor.gradient)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                )

            // Spot Info
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                if !spot.notes.isEmpty {
                    Text(spot.notes)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Favorite Indicator
            if spot.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 4)
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
