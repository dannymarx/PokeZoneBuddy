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
        VStack(spacing: 0) {
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
                                SidebarFavoriteEventRow(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            creditsFooter
        }
        .navigationTitle("PokeZoneBuddy")
    }

    // MARK: - Favorite Event Row

    /// Compact circular thumbnail style for sidebar favorite events
    /// Optimized for sidebars 220-280pt width with proper text wrapping
    private struct SidebarFavoriteEventRow: View {
        let event: Event

        var body: some View {
            HStack(spacing: 10) {
                // Circular thumbnail
                if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                            Circle()
                                .fill(.quaternary)
                                .overlay(
                                    ProgressView()
                                        .controlSize(.mini)
                                )
                        @unknown default:
                            Circle()
                                .fill(.quaternary)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    // Fallback icon
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundStyle(.blue)
                        )
                }

                // Event info with wrapping text
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.85)

                    Text(event.displayHeading)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Credits Footer

    private var creditsFooter: some View {
        VStack(spacing: 6) {
            Text(Constants.Legal.footerText)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.8)

            Text(Constants.Credits.fullCredit)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
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
