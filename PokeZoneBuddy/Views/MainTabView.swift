//
//  MainTabView.swift
//  PokeZoneBuddy
//
//  iOS 26 TabView with Search Integration
//

import SwiftUI
import SwiftData

struct MainTabView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(NetworkMonitor.self) private var networkMonitor

    // MARK: - State

    @State private var eventsViewModel: EventsViewModel?
    @State private var citiesViewModel: CitiesViewModel?
    @State private var searchText = ""

    // MARK: - Body

    var body: some View {
        Group {
            if let eventsVM = eventsViewModel, let citiesVM = citiesViewModel {
                mainTabView(eventsVM: eventsVM, citiesVM: citiesVM)
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

    // MARK: - Main Tab View

    private func mainTabView(eventsVM: EventsViewModel, citiesVM: CitiesViewModel) -> some View {
        TabView {
            Tab(String(localized: "events.title"), systemImage: "calendar") {
                EventsListView()
            }

            Tab(String(localized: "sidebar.your_cities"), systemImage: "building.2") {
                CitiesManagementView(viewModel: citiesVM)
            }

            Tab(String(localized: "spots.section.title"), systemImage: "mappin.and.ellipse") {
                AllSpotsView(citiesViewModel: citiesVM)
            }

            Tab(String(localized: "search.title"), systemImage: "magnifyingglass", role: .search) {
                NavigationStack {
                    SearchView(
                        eventsViewModel: eventsVM,
                        citiesViewModel: citiesVM,
                        searchText: $searchText
                    )
                    .searchable(text: $searchText)
                }
            }

            Tab(String(localized: "settings.title"), systemImage: "gearshape") {
                SettingsView()
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

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [Event.self, FavoriteCity.self], inMemory: true)
}
