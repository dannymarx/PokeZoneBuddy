//
//  EventsListView.swift
//  PokeZoneBuddy
//
//  Moderne macOS 26 Haupt-View
//  Version 0.4 - Updated for @Observable Pattern
//

import SwiftUI
import SwiftData

struct EventsListView: View {
    
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
                mainContent(eventsVM: eventsVM, citiesVM: citiesVM)
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
    
    // MARK: - Main Content
    
    private func mainContent(eventsVM: EventsViewModel, citiesVM: CitiesViewModel) -> some View {
        AdaptiveEventsView(
            eventsViewModel: eventsVM,
            citiesViewModel: citiesVM
        )
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

// MARK: - Adaptive Layout Container

private struct AdaptiveEventsView: View {
    let eventsViewModel: EventsViewModel
    let citiesViewModel: CitiesViewModel
    
    @State private var selectedEvent: Event?
    @State private var showCitiesManagement = false
    @State private var showCacheManagement = false
    @State private var activeCityForSpots: FavoriteCity?
    @State private var activeSpotForSpots: CitySpot?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var navigationPath: [String] = []
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var shouldUseSplitLayout: Bool {
#if os(iOS)
        if dynamicTypeSize.isAccessibilitySize {
            return false
        }
        if let horizontalSizeClass, let verticalSizeClass {
            return horizontalSizeClass == .regular && verticalSizeClass == .regular
        }
        return false
#else
        return true
#endif
    }
    
    var body: some View {
        adaptiveLayout
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
    
    private var adaptiveLayout: some View {
        Group {
            if shouldUseSplitLayout {
                splitLayout
            } else {
                compactLayout
            }
        }
        .sheet(item: $activeCityForSpots) { city in
            SpotListView(
                viewModel: citiesViewModel,
                city: city,
                initialSpot: activeSpotForSpots
            )
#if os(iOS)
            .presentationDetents([.fraction(0.9), .large])
            .presentationDragIndicator(.visible)
#elseif os(macOS)
            .presentationSizing(.fitted)
#endif
        }
        .onChange(of: activeCityForSpots) { oldValue, newValue in
            if case .none = newValue {
                activeSpotForSpots = nil
            }
        }
        .sheet(isPresented: $showCitiesManagement) {
            CitiesManagementView(viewModel: citiesViewModel)
        }
#if os(iOS)
        .sheet(isPresented: $showCacheManagement) {
            SettingsView()
        }
#endif
    }
    
    private var splitLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            CitiesSidebarView(
                viewModel: citiesViewModel,
                eventsViewModel: eventsViewModel,
                showManagement: $showCitiesManagement,
                showCacheManagement: $showCacheManagement,
                selectedEvent: $selectedEvent,
                onCitySelected: { city, spot in
                    activeSpotForSpots = spot
                    activeCityForSpots = city
                }
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
            
        } content: {
            EventsContentView(
                viewModel: eventsViewModel,
                selectedEvent: $selectedEvent,
                layout: .split,
                onEventSelected: { event in
                    selectedEvent = event
                },
                showCacheManagement: $showCacheManagement
            )
            .navigationSplitViewColumnWidth(min: 420, ideal: 460, max: 540)
            
        } detail: {
            EventDetailContainerView(
                event: selectedEvent,
                cities: citiesViewModel.favoriteCities
            )
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    private var compactLayout: some View {
        NavigationStack(path: $navigationPath) {
            EventsContentView(
                viewModel: eventsViewModel,
                selectedEvent: $selectedEvent,
                layout: .compact,
                onEventSelected: handleCompactSelection,
                showCacheManagement: $showCacheManagement
            )
            .navigationDestination(for: String.self) { eventID in
                if let event = eventsViewModel.events.first(where: { $0.id == eventID }) {
                    EventDetailView(event: event, favoriteCities: citiesViewModel.favoriteCities)
                } else {
                    MissingEventView()
                }
            }
        }
    }

    private func handleCompactSelection(_ event: Event) {
        selectedEvent = event
        if navigationPath.last != event.id {
            navigationPath.append(event.id)
        }
    }
    
    private struct MissingEventView: View {
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(.tertiary)
                
                Text(String(localized: "alert.error.unknown"))
                    .secondaryStyle()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
        }
    }
}

// MARK: - Cities Sidebar View

private struct CitiesSidebarView: View {
    // With @Observable, no property wrapper needed for read-only access!
    let viewModel: CitiesViewModel
    let eventsViewModel: EventsViewModel
    @Binding var showManagement: Bool
    @Binding var showCacheManagement: Bool
    @Binding var selectedEvent: Event?
    let onCitySelected: (FavoriteCity, CitySpot?) -> Void

    // SwiftData Query to observe favorite changes in real-time
    @Query(sort: \FavoriteEvent.addedDate, order: .reverse) private var favoriteEventModels: [FavoriteEvent]

    // Computed property for favorite events (reactive to SwiftData changes)
    private var favoriteEvents: [Event] {
        let favoriteIDs = Set(favoriteEventModels.map { $0.eventID })
        return eventsViewModel.events
            .filter { event in
                guard favoriteIDs.contains(event.id) else { return false }
                return event.isUpcoming || event.isCurrentlyActive
            }
            .sorted { $0.startTime < $1.startTime }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
            citiesList
            
            if !favoriteEvents.isEmpty {
                Divider()
                favoriteEventsSection
            }

            Divider()

            settingsButton
        }
        .background(Color.appBackground)
        .hideScrollIndicatorsCompat()
        .animation(.default, value: favoriteEvents.isEmpty)
    }
    
    private var header: some View {
        HStack {
            Text(String(localized: "sidebar.your_cities"))
                .titleStyle()
            Spacer()
            Button {
                showManagement = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(String(localized: "sidebar.add_city"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var citiesList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if viewModel.favoriteCities.isEmpty {
                noCitiesPlaceholder
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.favoriteCities) { city in
                        CityCard(city: city) {
                            let initialSpot = viewModel.getSpots(for: city).first
                            onCitySelected(city, initialSpot)
                        }
                    }
                }
                .padding(16)
            }
        }
        .scrollIndicators(.hidden, axes: .vertical)
        .hideScrollIndicatorsCompat()
    }
    
    private var favoriteEventsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text(String(localized: "sidebar.favorite_events"))
                    .titleStyle()
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(favoriteEvents) { event in
                        FavoriteEventCard(event: event)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEvent = event
                            }
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden, axes: .vertical)
            .hideScrollIndicatorsCompat()
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var settingsButton: some View {
        Button {
            showCacheManagement = true
        } label: {
            HStack {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                Text(String(localized: "settings.title"))
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .background(Color.clear)
    }
    
    private var noCitiesPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 4) {
                Text(String(localized: "placeholder.no_cities.title"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(String(localized: "placeholder.no_cities.subtitle"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showManagement = true
            } label: {
                Text(String(localized: "sidebar.add_city"))
            }
            .buttonStyle(ModernButtonStyle())
        }
        .padding(32)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - City Card

private struct CityCard: View {
    let city: FavoriteCity
    let onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue.gradient)
                        .symbolRenderingMode(.hierarchical)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(city.name)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Spacer()
                }
                HStack(spacing: 6) {
                    Text(city.abbreviatedTimeZone)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(city.formattedUTCOffset)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.systemBlue)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(isHovered ? 0.4 : 0.2),
                                .systemBlue.opacity(isHovered ? 0.3 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: Color.systemBlue.opacity(isHovered ? 0.2 : 0.1),
                radius: isHovered ? 10 : 6,
                x: 0,
                y: isHovered ? 4 : 2
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Events Layout Style

enum EventsLayoutStyle {
    case split
    case compact
}

// MARK: - Events Content View

struct EventsContentView: View {
    // With @Observable, no property wrapper needed for read-only access!
    let viewModel: EventsViewModel
    @Binding var selectedEvent: Event?
    let layout: EventsLayoutStyle
    let onEventSelected: (Event) -> Void
    @Binding var showCacheManagement: Bool
    @State private var selectedFilter: EventFilter = .all
    @State private var filterConfig = FilterConfiguration()
    @State private var showFilterSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
#if os(macOS)
            // Header with buttons for macOS
            headerView

            Divider()
#endif

            // OFFLINE: Show status banner
            if viewModel.isOffline {
                offlineBanner
            }

            // Filter
            filterView

            Divider()

            // Content
            if viewModel.isLoading && viewModel.events.isEmpty {
                loadingContent
            } else if viewModel.events.isEmpty {
                emptyContent
            } else {
                eventsList
            }
        }
        .background(Color.appBackground)
        .navigationTitle(String(localized: "events.title"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refreshEvents() }
                } label: {
                    Label(String(localized: "events.refresh.help"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilterSheet = true
                } label: {
                    Label(String(localized: "events.filter.help"), systemImage: "line.3.horizontal.decrease.circle")
                }
                .badge(filterConfig.activeFilterCount > 0 ? filterConfig.activeFilterCount : 0)
            }
        }
#else
        .searchable(text: $filterConfig.searchText, prompt: String(localized: "search.events.prompt"))
#endif
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(config: filterConfig)
        }
        .refreshable {
            await viewModel.forceRefresh()
        }
    }
    
    // OFFLINE: Banner
    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text(String(localized: "offline.banner.title"))
            
            if let lastSync = viewModel.lastSyncDate {
                Text(String(localized: "offline.banner.last_updated_prefix") + "\(lastSync.formatted(.relative(presentation: .named)))")
                    .font(.caption)
            }
        }
        .font(.subheadline)
        .foregroundStyle(.white)
        .padding(.vertical, 8)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(Color.systemOrange)
    }

    // MARK: - Header View (macOS only)

    private var headerView: some View {
        HStack {
            // App Header
            HStack(spacing: 10) {
                #if os(macOS)
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                    )
                #else
                Image(systemName: "app.badge.fill")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color.systemBlue)
                #endif

                Text("PokeZone Buddy")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            // Filter Button
            Button {
                showFilterSheet = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(filterConfig.isActive ? Color.systemBlue : .secondary)
            }
            .buttonStyle(.plain)
            .badge(filterConfig.activeFilterCount > 0 ? filterConfig.activeFilterCount : 0)
            .help(String(localized: "events.filter.help"))

            // Refresh Button
            Button {
                Task { await viewModel.refreshEvents() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(viewModel.isLoading ? .tertiary : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .help(String(localized: "events.refresh.help"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var filterView: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EventFilter.allCases, id: \.self) { filter in
                        FilterButton(
                            filter: filter,
                            isSelected: selectedFilter == filter,
                            count: eventCount(for: filter)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden, axes: .horizontal)
            .hideScrollIndicatorsCompat()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Filtered Events
    
    private var filteredActiveEvents: [Event] {
        viewModel.activeEvents.filter { filterConfig.matches($0) }
    }
    
    private var filteredUpcomingEvents: [Event] {
        viewModel.upcomingEvents.filter { filterConfig.matches($0) }
    }
    
    private var filteredPastEvents: [Event] {
        viewModel.pastEvents.filter { filterConfig.matches($0) }
    }
    
    private var filteredAllEvents: [Event] {
        viewModel.events.filter { filterConfig.matches($0) }
    }
    
    private func eventCount(for filter: EventFilter) -> Int {
        switch filter {
        case .all:
            return filteredAllEvents.count
        case .live:
            return filteredActiveEvents.count
        case .upcoming:
            return filteredUpcomingEvents.count
        case .past:
            return filteredPastEvents.count
        }
    }
    
    private var eventsList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                switch selectedFilter {
                case .all:
                    allEventsView
                case .live:
                    liveEventsView
                case .upcoming:
                    upcomingEventsView
                case .past:
                    pastEventsView
                }
                
                creditsFooter
            }
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden, axes: .vertical)
        .hideScrollIndicatorsCompat()
    }
    
    @ViewBuilder
    private var allEventsView: some View {
        // Active Events
        if !filteredActiveEvents.isEmpty {
            Section {
                ForEach(filteredActiveEvents) { event in
                    EventRow(event: event, isSelected: layout == .split && selectedEvent?.id == event.id, isActive: true)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onEventSelected(event)
                        }
                }
            } header: {
                sectionHeader(title: String(localized: "section.live_events"), icon: "circle.fill", color: Color.systemGreen)
            }
        }
        
        // Upcoming Events
        if !filteredUpcomingEvents.isEmpty {
            Section {
                ForEach(filteredUpcomingEvents) { event in
                    EventRow(event: event, isSelected: layout == .split && selectedEvent?.id == event.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onEventSelected(event)
                        }
                }
            } header: {
                sectionHeader(
                    title: String(localized: "section.upcoming_events"),
                    icon: "clock.fill",
                    color: Color.systemOrange,
                    topPadding: filteredActiveEvents.isEmpty ? 8 : 20
                )
            }
        }
        
        // Past Events
        if !filteredPastEvents.isEmpty {
            Section {
                ForEach(filteredPastEvents.prefix(5)) { event in
                    EventRow(event: event, isSelected: layout == .split && selectedEvent?.id == event.id, isPast: true)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onEventSelected(event)
                        }
                }
            } header: {
                sectionHeader(title: String(localized: "section.past_events"), icon: "checkmark.circle.fill", color: Color.systemGray, topPadding: 20)
            }
        }
    }
    
    @ViewBuilder
    private var liveEventsView: some View {
        if filteredActiveEvents.isEmpty {
            emptyFilterState(icon: "circle.fill", message: String(localized: "filter.none.live"), color: Color.systemGreen)
        } else {
            ForEach(filteredActiveEvents) { event in
                EventRow(event: event, isSelected: layout == .split && selectedEvent?.id == event.id, isActive: true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onEventSelected(event)
                    }
            }
        }
    }
    
    @ViewBuilder
    private var upcomingEventsView: some View {
        if filteredUpcomingEvents.isEmpty {
            emptyFilterState(icon: "clock.fill", message: String(localized: "filter.none.upcoming"), color: Color.systemOrange)
        } else {
            ForEach(filteredUpcomingEvents) { event in
                EventRow(event: event, isSelected: layout == .split && selectedEvent?.id == event.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onEventSelected(event)
                    }
            }
        }
    }
    
    @ViewBuilder
    private var pastEventsView: some View {
        if filteredPastEvents.isEmpty {
            emptyFilterState(icon: "checkmark.circle.fill", message: String(localized: "filter.none.past"), color: Color.systemGray)
        } else {
            ForEach(filteredPastEvents) { event in
                EventRow(event: event, isSelected: layout == .split && selectedEvent?.id == event.id, isPast: true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onEventSelected(event)
                    }
            }
        }
    }
    
    private func sectionHeader(title: String, icon: String? = nil, color: Color = .secondary, topPadding: CGFloat = 8) -> some View {
        HStack {
            if let icon = icon {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundStyle(color)
                    Text(title)
                }
            } else {
                Text(title)
            }
            Spacer()
        }
        .sectionHeader()
        .padding(.horizontal, 20)
        .padding(.top, topPadding)
        .padding(.bottom, 4)
    }
    
    private func emptyFilterState(icon: String, message: String, color: Color) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(color.opacity(0.3))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(String(localized: "loading.events"))
                .secondaryStyle()
        }
        .frame(maxHeight: .infinity)
    }
    
    private var emptyContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text(String(localized: "empty.no_events"))
                .font(.system(size: 14, weight: .semibold))
        }
        .frame(maxHeight: .infinity)
    }
    
    private var creditsFooter: some View {
        VStack(spacing: 8) {
            Text(Constants.Legal.footerText)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            
            Text(Constants.Credits.fullCredit)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 32)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}

// MARK: - Event Detail Container

struct EventDetailContainerView: View {
    let event: Event?
    let cities: [FavoriteCity]
    
    var body: some View {
        Group {
            if let event = event {
                EventDetailView(event: event, favoriteCities: cities)
            } else {
                placeholderView
            }
        }
    }
    
    private var placeholderView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 8) {
                Text(String(localized: "placeholder.no_event_selected.title"))
                    .font(.system(size: 18, weight: .semibold))
                
                Text(String(localized: "placeholder.no_event_selected.subtitle"))
                    .secondaryStyle()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

// MARK: - Preview

#Preview {
    EventsListView()
        .modelContainer(for: [Event.self, FavoriteCity.self], inMemory: true)
        .frame(width: 1200, height: 800)
}
