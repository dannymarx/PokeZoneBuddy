//
//  MacOSSidebarView.swift
//  PokeZoneBuddy
//
//  Sidebar for macOS main window
//

#if os(macOS)
import SwiftUI
import SwiftData

struct MacOSSidebarView: View {

    // MARK: - Properties

    @Binding var selectedItem: SidebarItem
    let citiesViewModel: CitiesViewModel
    let eventsViewModel: EventsViewModel
    @Binding var selectedEvent: Event?
    let onAddCity: () -> Void
    let onShowSettings: () -> Void
    let onCitySelected: (FavoriteCity, CitySpot?) -> Void

    // MARK: - Query

    @Query(sort: \FavoriteEvent.addedDate, order: .reverse) private var favoriteEventModels: [FavoriteEvent]

    // MARK: - Computed Properties

    private var favoriteEvents: [Event] {
        let favoriteIDs = Set(favoriteEventModels.map { $0.eventID })
        return eventsViewModel.events
            .filter { event in
                guard favoriteIDs.contains(event.id) else { return false }
                return event.isUpcoming || event.isCurrentlyActive
            }
            .sorted { $0.startTime < $1.startTime }
    }

    // MARK: - Body

    var body: some View {
        List(selection: $selectedItem) {
            Section(String(localized: "sidebar.navigation")) {
                ForEach(SidebarItem.allCases) { item in
                    NavigationLink(value: item) {
                        Label(item.title, systemImage: item.icon)
                    }
                }

                Button {
                    onShowSettings()
                } label: {
                    Label(String(localized: "settings.title"), systemImage: "gearshape")
                }
                .buttonStyle(.plain)
            }

            if !favoriteEvents.isEmpty {
                Section(String(localized: "sidebar.favorite_events")) {
                    ForEach(favoriteEvents.prefix(5)) { event in
                        Button {
                            selectedItem = .events
                            selectedEvent = event
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.displayName)
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                                Text(event.displayHeading)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("PokeZoneBuddy")
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FavoriteCity.self,
        Event.self,
        configurations: config
    )

    let context = container.mainContext
    let citiesVM = CitiesViewModel(modelContext: context)
    let eventsVM = EventsViewModel(modelContext: context, networkMonitor: NetworkMonitor())

    @State var selectedItem: SidebarItem = .events
    @State var selectedEvent: Event? = nil

    MacOSSidebarView(
        selectedItem: $selectedItem,
        citiesViewModel: citiesVM,
        eventsViewModel: eventsVM,
        selectedEvent: $selectedEvent,
        onAddCity: {},
        onShowSettings: {},
        onCitySelected: { _, _ in }
    )
    .modelContainer(container)
}
#endif
