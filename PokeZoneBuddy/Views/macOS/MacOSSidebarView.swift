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

    // MARK: - Navigation Item View

    private struct NavigationItemView: View {
        let item: SidebarItem
        let isSelected: Bool
        let isHovered: Bool
        let onTap: () -> Void
        let onHover: (Bool) -> Void

        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // Icon with Liquid Glass effect
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(item.accentColor.gradient)
                                .frame(width: 44, height: 44)
                        } else {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(
                                            isHovered ? item.accentColor.opacity(0.4) : .white.opacity(0.15),
                                            lineWidth: isHovered ? 1.5 : 1
                                        )
                                )
                        }

                        Image(systemName: item.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : item.accentColor)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .shadow(
                        color: isSelected ? item.accentColor.opacity(0.3) : .clear,
                        radius: 8,
                        x: 0,
                        y: 2
                    )

                    // Label
                    Text(item.title)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? .primary : .secondary)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
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

    /// Modern Liquid Glass card style for sidebar favorite events
    private struct SidebarFavoriteEventRow: View {
        let event: Event
        @State private var isHovered = false

        var body: some View {
            HStack(spacing: 12) {
                // Circular thumbnail with glow
                ZStack {
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
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1.5)
                        )
                    } else {
                        Circle()
                            .fill(.blue.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "calendar")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.blue)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(.blue.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                }
                .shadow(color: .blue.opacity(0.2), radius: isHovered ? 6 : 4, x: 0, y: 2)

                // Event info
                VStack(alignment: .leading, spacing: 3) {
                    Text(event.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(event.displayHeading)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isHovered ? Color.blue.opacity(0.3) : .white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: .black.opacity(isHovered ? 0.08 : 0.04),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 4 : 2
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
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
