//
//  FavoriteEventsSidebarSection.swift
//  PokeZoneBuddy
//
//  Created by Claude on 06.10.2025.
//  Favorite Events Sidebar Section - Displays favorited events in compact card form
//

import SwiftUI
import SwiftData

/// Sidebar section displaying favorited events in compact card format
/// Filters to show only upcoming/active events (no past events)
struct FavoriteEventsSidebarSection: View {

    // MARK: - Properties

    /// The events view model containing all events
    let eventsViewModel: EventsViewModel

    /// Callback when an event is selected
    let onEventSelected: (Event) -> Void

    // MARK: - Computed Properties

    /// Filtered favorite events (only upcoming/active, no past events)
    /// Uses EventsViewModel.favoriteEvents for consistent filtering
    private var favoriteEvents: [Event] {
        eventsViewModel.favoriteEvents
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(String(localized: "sidebar.favorite_events"))
                    .titleStyle()
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            // Events List
            ScrollView(.vertical, showsIndicators: false) {
                if favoriteEvents.isEmpty {
                    placeholderView
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(favoriteEvents) { event in
                            FavoriteEventCard(event: event)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onEventSelected(event)
                                }
                        }
                    }
                    .padding(16)
                }
            }
            .scrollIndicators(.hidden, axes: .vertical)
            .hideScrollIndicatorsCompat()
        }
        .hideScrollIndicatorsCompat()
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text(String(localized: "placeholder.no_favorites.title"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(String(localized: "placeholder.no_favorites.subtitle"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("With Favorites") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Event.self, FavoriteEvent.self, configurations: config)
    let context = container.mainContext

    // Create sample events
    let event1 = Event(
        id: "community-day-2025",
        name: "Community Day: Bulbasaur",
        eventType: "community-day",
        heading: "Community Day",
        startTime: Date().addingTimeInterval(86400),
        endTime: Date().addingTimeInterval(90000),
        isGlobalTime: false,
        imageURL: "https://via.placeholder.com/150"
    )
    let event2 = Event(
        id: "raid-hour-2025",
        name: "Raid Hour: Legendary",
        eventType: "raid-hour",
        heading: "Raid Hour",
        startTime: Date().addingTimeInterval(172800),
        endTime: Date().addingTimeInterval(176400),
        isGlobalTime: true,
        imageURL: "https://via.placeholder.com/150"
    )

    context.insert(event1)
    context.insert(event2)

    // Create favorites
    let fav1 = FavoriteEvent(eventID: "community-day-2025")
    let fav2 = FavoriteEvent(eventID: "raid-hour-2025")
    context.insert(fav1)
    context.insert(fav2)

    let viewModel = EventsViewModel(
        modelContext: context,
        networkMonitor: NetworkMonitor()
    )

    return FavoriteEventsSidebarSection(
        eventsViewModel: viewModel,
        onEventSelected: { _ in }
    )
    .modelContainer(container)
    .frame(width: 260, height: 400)
}

#Preview("Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Event.self, FavoriteEvent.self, configurations: config)
    let context = container.mainContext

    let viewModel = EventsViewModel(
        modelContext: context,
        networkMonitor: NetworkMonitor()
    )

    return FavoriteEventsSidebarSection(
        eventsViewModel: viewModel,
        onEventSelected: { _ in }
    )
    .modelContainer(container)
    .frame(width: 260, height: 400)
}
