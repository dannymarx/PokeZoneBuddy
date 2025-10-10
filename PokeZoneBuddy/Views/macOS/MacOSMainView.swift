//
//  MacOSMainView.swift
//  PokeZoneBuddy
//
//  Main macOS window with 3-column NavigationSplitView
//  Follows macOS 26 design patterns
//

#if os(macOS)
import SwiftUI
import SwiftData

struct MacOSMainView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(NetworkMonitor.self) private var networkMonitor

    // MARK: - State

    @State private var eventsViewModel: EventsViewModel?
    @State private var citiesViewModel: CitiesViewModel?

    // MARK: - Body

    var body: some View {
        Group {
            if let eventsVM = eventsViewModel, let citiesVM = citiesViewModel {
                MacOSContentView(
                    eventsViewModel: eventsVM,
                    citiesViewModel: citiesVM
                )
            } else {
                loadingView
            }
        }
        .onAppear {
            if eventsViewModel == nil {
                initializeViewModels()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
            Text(String(localized: "loading.generic"))
                .secondaryStyle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }

    // MARK: - Initialize ViewModels

    private func initializeViewModels() {
        eventsViewModel = EventsViewModel(modelContext: modelContext, networkMonitor: networkMonitor)
        citiesViewModel = CitiesViewModel(modelContext: modelContext)

        if let eventsVM = eventsViewModel, eventsVM.events.isEmpty {
            Task { await eventsVM.syncEvents() }
        }
    }
}

// MARK: - macOS Content View

private struct MacOSContentView: View {

    let eventsViewModel: EventsViewModel
    let citiesViewModel: CitiesViewModel

    @State private var selectedSidebarItem: SidebarItem = .events
    @State private var selectedEvent: Event?
    @State private var showAddCity = false
    @State private var showSettings = false
    @State private var selectedCity: FavoriteCity?
    @State private var selectedSpot: CitySpot?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    // MARK: - Body

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar (left column)
            MacOSSidebarView(
                selectedItem: $selectedSidebarItem,
                citiesViewModel: citiesViewModel,
                eventsViewModel: eventsViewModel,
                selectedEvent: $selectedEvent,
                onAddCity: { showAddCity = true },
                onShowSettings: { showSettings = true },
                onCitySelected: { city, spot in
                    selectedCity = city
                    selectedSpot = spot
                }
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)

        } content: {
            // Content (middle column)
            contentColumn
                .navigationSplitViewColumnWidth(min: 420, ideal: 480, max: 600)

        } detail: {
            // Detail (right column)
            detailColumn
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showAddCity) {
            AddCitySheet(viewModel: citiesViewModel)
                .presentationSizing(.fitted)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationSizing(.fitted)
        }
        .sheet(item: $selectedCity) { city in
            SpotListView(
                viewModel: citiesViewModel,
                city: city,
                initialSpot: selectedSpot
            )
            .presentationSizing(.fitted)
        }
        .onChange(of: selectedCity) { _, newValue in
            if newValue == nil {
                selectedSpot = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshEvents)) { _ in
            Task { await eventsViewModel.refreshEvents() }
        }
        .alert(String(localized: "alert.error.title"), isPresented: Binding(
            get: { eventsViewModel.showError },
            set: { eventsViewModel.showError = $0 }
        )) {
            Button(String(localized: "common.ok")) {
                eventsViewModel.showError = false
            }
        } message: {
            Text(eventsViewModel.errorMessage ?? String(localized: "alert.error.unknown"))
        }
    }

    // MARK: - Content Column

    @ViewBuilder
    private var contentColumn: some View {
        switch selectedSidebarItem {
        case .events:
            EventsContentView(
                viewModel: eventsViewModel,
                selectedEvent: $selectedEvent,
                layout: .split,
                onEventSelected: { event in
                    selectedEvent = event
                },
                showCacheManagement: $showSettings
            )

        case .cities:
            CitiesContentView(
                viewModel: citiesViewModel,
                onCitySelected: { city in
                    selectedCity = city
                    selectedSpot = citiesViewModel.getSpots(for: city).first
                },
                onAddCity: { showAddCity = true }
            )

        case .allSpots:
            AllSpotsContentView(
                viewModel: citiesViewModel,
                onSpotSelected: { city, spot in
                    selectedCity = city
                    selectedSpot = spot
                }
            )
        }
    }

    // MARK: - Detail Column

    @ViewBuilder
    private var detailColumn: some View {
        switch selectedSidebarItem {
        case .events:
            EventDetailContainerView(
                event: selectedEvent,
                cities: citiesViewModel.favoriteCities
            )

        case .cities:
            if let city = selectedCity {
                CityDetailView(city: city, viewModel: citiesViewModel)
            } else {
                placeholderView(
                    icon: "building.2",
                    title: String(localized: "placeholder.no_city_selected.title"),
                    subtitle: String(localized: "placeholder.no_city_selected.subtitle")
                )
            }

        case .allSpots:
            if let spot = selectedSpot {
                SpotDetailView(spot: spot, viewModel: citiesViewModel) { editSpot in
                    // Handle edit
                }
            } else {
                placeholderView(
                    icon: "mappin.and.ellipse",
                    title: String(localized: "placeholder.no_spot_selected.title"),
                    subtitle: String(localized: "placeholder.no_spot_selected.subtitle")
                )
            }
        }
    }

    // MARK: - Helper Views

    private func placeholderView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.quaternary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

// MARK: - Sidebar Item

enum SidebarItem: String, CaseIterable, Identifiable {
    case events
    case cities
    case allSpots

    var id: String { rawValue }

    var title: String {
        switch self {
        case .events:
            return String(localized: "events.title")
        case .cities:
            return String(localized: "sidebar.your_cities")
        case .allSpots:
            return String(localized: "spots.section.title")
        }
    }

    var icon: String {
        switch self {
        case .events:
            return "calendar"
        case .cities:
            return "building.2"
        case .allSpots:
            return "mappin.and.ellipse"
        }
    }
}

// MARK: - Preview

#Preview {
    MacOSMainView()
        .modelContainer(for: [Event.self, FavoriteCity.self, CitySpot.self], inMemory: true)
}
#endif
