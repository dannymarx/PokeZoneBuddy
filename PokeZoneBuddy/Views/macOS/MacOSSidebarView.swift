//
//  MacOSSidebarView.swift
//  PokeZoneBuddy
//
//  Sidebar for macOS main window with Liquid Glass design
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
    let onCitySelected: (FavoriteCity, CitySpot?) -> Void

    // MARK: - Query

    @Query(sort: \FavoriteEvent.addedDate, order: .reverse) private var favoriteEventModels: [FavoriteEvent]

    // MARK: - State

    @State private var hoveredItem: SidebarItem?

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
        ZStack {
            // Liquid Glass background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        // Navigation section
                        navigationSection

                        // Favorite events section
                        if !favoriteEvents.isEmpty {
                            Divider()
                                .padding(.vertical, 8)

                            favoriteEventsSection
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                }

                Spacer()

                Divider()
                    .padding(.horizontal, 12)

                creditsFooter
            }
        }
    }

    // MARK: - Navigation Section

    private var navigationSection: some View {
        VStack(spacing: 8) {
            ForEach(SidebarItem.allCases) { item in
                NavigationItemView(
                    item: item,
                    isSelected: selectedItem == item,
                    isHovered: hoveredItem == item,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedItem = item
                        }
                    },
                    onHover: { isHovering in
                        hoveredItem = isHovering ? item : nil
                    }
                )
            }
        }
    }

    // MARK: - Favorite Events Section

    private var favoriteEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "sidebar.favorite_events"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 12)
                .padding(.top, 4)

            VStack(spacing: 6) {
                ForEach(favoriteEvents.prefix(15)) { event in
                    SidebarFavoriteEventRow(
                        event: event,
                        onTap: {
                            selectedItem = .events
                            selectedEvent = event
                        }
                    )
                }
            }
        }
    }

    // MARK: - Navigation Item View

    private struct NavigationItemView: View {
        let item: SidebarItem
        let isSelected: Bool
        let isHovered: Bool
        let onTap: () -> Void
        let onHover: (Bool) -> Void

        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    // Icon with Liquid Glass effect
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(item.accentColor.gradient)
                                .frame(width: 34, height: 34)
                        } else {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(
                                            isHovered ? item.accentColor.opacity(0.4) : .white.opacity(0.15),
                                            lineWidth: isHovered ? 1.5 : 1
                                        )
                                )
                        }

                        Image(systemName: item.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : item.accentColor)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .shadow(
                        color: isSelected ? item.accentColor.opacity(0.3) : .clear,
                        radius: 6,
                        x: 0,
                        y: 2
                    )

                    // Label
                    Text(item.title)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? .primary : .secondary)

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isHovered && !isSelected ? Color.primary.opacity(0.05) : .clear)
                )
            }
            .buttonStyle(.plain)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
            .onHover { hovering in
                onHover(hovering)
            }
        }
    }

    // MARK: - Favorite Event Row

    /// Full-bleed image card with blur overlay and event title
    private struct SidebarFavoriteEventRow: View {
        let event: Event
        let onTap: () -> Void
        @State private var isHovered = false

        var body: some View {
            ZStack {
                // Background: Full image
                Group {
                    if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure, .empty:
                                // Fallback gradient
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(.quaternary)
                            }
                        }
                    } else {
                        // Fallback gradient
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.6), .cyan.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Blur layer over the image
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Event title on top
                Text(event.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 12)
            }
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        .white.opacity(isHovered ? 0.4 : 0.2),
                        lineWidth: isHovered ? 2 : 1
                    )
            )
            .shadow(
                color: .black.opacity(isHovered ? 0.25 : 0.15),
                radius: isHovered ? 10 : 6,
                x: 0,
                y: isHovered ? 5 : 3
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                onTap()
            }
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
        onCitySelected: { _, _ in }
    )
    .modelContainer(container)
}
#endif
