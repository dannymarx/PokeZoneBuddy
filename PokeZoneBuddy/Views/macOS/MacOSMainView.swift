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
    @Bindable var citiesViewModel: CitiesViewModel

    @State private var selectedSidebarItem: SidebarItem = .events
    @State private var selectedEvent: Event?
    @State private var showAddCity = false
    @State private var showCityPickerForSpot = false
    @State private var cityForNewSpot: FavoriteCity?
    @State private var selectedCity: FavoriteCity?
    @State private var selectedSpot: CitySpot?
    @State private var editingSpot: CitySpot?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showNotificationSettings = false

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
                onCitySelected: { city, spot in
                    selectedCity = city
                    selectedSpot = spot
                }
            )
            .navigationSplitViewColumnWidth(ideal: 240)

        } content: {
            // Content (middle column)
            contentColumn
                .navigationSplitViewColumnWidth(ideal: 450)

        } detail: {
            // Detail (right column)
            detailColumn
                .navigationSplitViewColumnWidth(ideal: 400)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showAddCity) {
            AddCitySheet(viewModel: citiesViewModel)
                .presentationSizing(.fitted)
        }
        .sheet(item: $cityForNewSpot, onDismiss: {
            // Cleanup handled by binding
        }) { city in
            AddSpotSheet(city: city, viewModel: citiesViewModel)
                .presentationSizing(.fitted)
        }
        .sheet(isPresented: $showCityPickerForSpot) {
            CityPickerSheet(cities: citiesViewModel.favoriteCities) { city in
                cityForNewSpot = city
            }
            .presentationSizing(.fitted)
        }
        .sheet(item: $editingSpot) { spot in
            EditSpotSheet(spot: spot, viewModel: citiesViewModel)
                .presentationSizing(.fitted)
        }
        .onChange(of: selectedSidebarItem) { oldValue, newValue in
            if newValue == .settings {
                columnVisibility = .all
            }
            // Clear notification settings when leaving settings
            if oldValue == .settings && newValue != .settings {
                showNotificationSettings = false
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
                showCacheManagement: settingsSelectionBinding
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
                },
                onAddSpot: { showCityPickerForSpot = true }
            )

        case .settings:
            SettingsView(
                displayMode: .primaryOnly,
                showsDismissButton: false,
                citiesViewModel: citiesViewModel,
                showNotificationSettings: $showNotificationSettings
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
                EmptyStateView(
                    icon: "building.2",
                    title: String(localized: "placeholder.no_city_selected.title"),
                    subtitle: String(localized: "placeholder.no_city_selected.subtitle")
                )
            }

        case .allSpots:
            if let spot = selectedSpot {
                SpotDetailView(spot: spot, viewModel: citiesViewModel) { editSpot in
                    editingSpot = editSpot
                }
            } else {
                EmptyStateView(
                    icon: "mappin.and.ellipse",
                    title: String(localized: "placeholder.no_spot_selected.title"),
                    subtitle: String(localized: "placeholder.no_spot_selected.subtitle")
                )
            }

        case .settings:
            if showNotificationSettings {
                NotificationSettingsView()
            } else {
                SettingsSupplementaryPane()
            }
        }
    }

    // MARK: - Helper Views

    private var settingsSelectionBinding: Binding<Bool> {
        Binding(
            get: { selectedSidebarItem == .settings },
            set: { isPresented in
                if isPresented {
                    selectedSidebarItem = .settings
                } else if selectedSidebarItem == .settings {
                    selectedSidebarItem = .events
                }
            }
        )
    }
}

// MARK: - Sidebar Item

enum SidebarItem: String, CaseIterable, Identifiable {
    case events
    case cities
    case allSpots
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .events:
            return String(localized: "events.title")
        case .cities:
            return String(localized: "sidebar.your_cities")
        case .allSpots:
            return String(localized: "spots.section.title")
        case .settings:
            return String(localized: "settings.title")
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
        case .settings:
            return "gearshape"
        }
    }

    var accentColor: Color {
        switch self {
        case .events:
            return .systemBlue
        case .cities:
            return .systemPurple
        case .allSpots:
            return .systemGreen
        case .settings:
            return .systemGray
        }
    }
}

// MARK: - Preview

#Preview {
    MacOSMainView()
        .modelContainer(for: [Event.self, FavoriteCity.self, CitySpot.self], inMemory: true)
}
#endif
