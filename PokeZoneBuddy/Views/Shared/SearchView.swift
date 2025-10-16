//
//  SearchView.swift
//  PokeZoneBuddy
//
//  Unified search view for Events and City Spots
//

import SwiftUI
import SwiftData

struct SearchView: View {

    // MARK: - Properties

    let eventsViewModel: EventsViewModel
    let citiesViewModel: CitiesViewModel
    @Binding var searchText: String

    // MARK: - State

    @State private var selectedEvent: Event?
    @State private var selectedCity: FavoriteCity?
    @State private var selectedSpot: CitySpot?
    @State private var navigationPath: [String] = []

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if searchText.isEmpty {
                emptySearchView
            } else {
                searchResultsView
            }
        }
        .background(Color.appBackground)
        .navigationTitle(String(localized: "search.title"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .navigationDestination(for: String.self) { eventID in
            if let event = eventsViewModel.events.first(where: { $0.id == eventID }) {
                EventDetailView(event: event, favoriteCities: citiesViewModel.favoriteCities)
            }
        }
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
        .onChange(of: selectedCity) { oldValue, newValue in
            if case .none = newValue {
                selectedSpot = nil
            }
        }
    }

    // MARK: - Empty Search View

    private var emptySearchView: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 72))
                .foregroundStyle(.quaternary)

            VStack(spacing: 8) {
                Text(String(localized: "search.empty.title"))
                    .font(.system(size: 20, weight: .semibold))

                Text(String(localized: "search.empty.subtitle"))
                    .secondaryStyle()
                    .multilineTextAlignment(.center)
            }
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Search Results View

    private var searchResultsView: some View {
        List {
            // Events Section
            if !filteredEvents.isEmpty {
                Section {
                    ForEach(filteredEvents) { event in
                        Button {
                            navigationPath.append(event.id)
                        } label: {
                            EventSearchRow(event: event)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.systemBlue)
                        Text(String(localized: "events.title"))
                    }
                }
            }

            // City Spots Section
            if !filteredSpots.isEmpty {
                Section {
                    ForEach(filteredSpots) { spot in
                        Button {
                            if let city = citiesViewModel.favoriteCities.first(where: { city in
                                citiesViewModel.getSpots(for: city).contains(where: { $0.id == spot.id })
                            }) {
                                selectedSpot = spot
                                selectedCity = city
                            }
                        } label: {
                            SpotSearchRow(spot: spot, citiesViewModel: citiesViewModel)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.systemGreen)
                        Text(String(localized: "spots.section.title"))
                    }
                }
            }

            // No Results
            if filteredEvents.isEmpty && filteredSpots.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)

                        Text(String(localized: "search.no_results"))
                            .secondaryStyle()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                .listRowBackground(Color.clear)
            }
        }
#if os(macOS)
        .listStyle(.inset)
#else
        .listStyle(.insetGrouped)
#endif
    }

    // MARK: - Filtered Results

    private var filteredEvents: [Event] {
        guard !searchText.isEmpty else { return [] }
        let lowercasedSearch = searchText.lowercased()
        return eventsViewModel.events.filter { event in
            event.displayName.lowercased().contains(lowercasedSearch) ||
            event.displayHeading.lowercased().contains(lowercasedSearch)
        }
    }

    private var filteredSpots: [CitySpot] {
        guard !searchText.isEmpty else { return [] }
        let lowercasedSearch = searchText.lowercased()
        return citiesViewModel.favoriteCities.flatMap { city in
            citiesViewModel.getSpots(for: city).filter { spot in
                spot.name.lowercased().contains(lowercasedSearch) ||
                spot.notes.lowercased().contains(lowercasedSearch)
            }
        }
    }
}

// MARK: - Event Search Row

private struct EventSearchRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
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
                    @unknown default:
                        Rectangle()
                            .fill(.quaternary)
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                Text(event.displayHeading)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Spot Search Row

private struct SpotSearchRow: View {
    let spot: CitySpot
    let citiesViewModel: CitiesViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Spot Icon
            Circle()
                .fill(spot.category.color.gradient)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                if let cityName = cityName {
                    Text(cityName)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if spot.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.systemYellow)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
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

    private var cityName: String? {
        citiesViewModel.favoriteCities.first { city in
            citiesViewModel.getSpots(for: city).contains(where: { $0.id == spot.id })
        }?.name
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Event.self,
        FavoriteCity.self,
        CitySpot.self,
        configurations: config
    )

    let context = container.mainContext
    let networkMonitor = NetworkMonitor()

    let eventsVM = EventsViewModel(modelContext: context, networkMonitor: networkMonitor)
    let citiesVM = CitiesViewModel(modelContext: context)

    return NavigationStack {
        SearchView(
            eventsViewModel: eventsVM,
            citiesViewModel: citiesVM,
            searchText: .constant("test")
        )
    }
    .modelContainer(container)
}
