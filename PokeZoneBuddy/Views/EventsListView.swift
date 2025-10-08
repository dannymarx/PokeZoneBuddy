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
    @State private var showAbout = false
    @State private var showCacheManagement = false
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
        .sheet(isPresented: $showCitiesManagement) {
            CitiesManagementView(viewModel: citiesViewModel)
        }
#if os(iOS)
        .fullScreenCover(isPresented: $showAbout) {
            AboutView()
        }
#else
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
#endif
        .sheet(isPresented: $showCacheManagement) {
            SettingsView()
        }
    }
    
    private var splitLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            CitiesSidebarView(
                viewModel: citiesViewModel,
                eventsViewModel: eventsViewModel,
                showManagement: $showCitiesManagement,
                showAbout: $showAbout,
                showCacheManagement: $showCacheManagement,
                selectedEvent: $selectedEvent
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
            
        } content: {
            EventsContentView(
                viewModel: eventsViewModel,
                selectedEvent: $selectedEvent,
                layout: .split,
                onEventSelected: { event in
                    selectedEvent = event
                }
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
                onEventSelected: handleCompactSelection
            )
            .navigationDestination(for: String.self) { eventID in
                if let event = eventsViewModel.events.first(where: { $0.id == eventID }) {
                    EventDetailView(event: event, favoriteCities: citiesViewModel.favoriteCities)
                } else {
                    MissingEventView()
                }
            }
#if os(iOS)
            .toolbar { compactToolbar }
#endif
        }
    }
    
    private func handleCompactSelection(_ event: Event) {
        selectedEvent = event
        if navigationPath.last != event.id {
            navigationPath.append(event.id)
        }
    }
    
#if os(iOS)
    @ToolbarContentBuilder
    private var compactToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showCitiesManagement = true
            } label: {
                Label(String(localized: "sidebar.your_cities"), systemImage: "mappin.circle")
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button(String(localized: "settings.title")) {
                    showCacheManagement = true
                }
                Button(String(localized: "about.title")) {
                    showAbout = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
#endif
    
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
    @Binding var showAbout: Bool
    @Binding var showCacheManagement: Bool
    @Binding var selectedEvent: Event?

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
            // Header
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
            
            Divider()
            
            // Cities List
            ScrollView(.vertical, showsIndicators: false) {
                if viewModel.favoriteCities.isEmpty {
                    noCitiesPlaceholder
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.favoriteCities) { city in
                            CityCard(city: city)
                        }
                    }
                    .padding(16)
                }
            }
            .scrollIndicators(.hidden, axes: .vertical)
            .hideScrollIndicatorsCompat()

            // Favorite Events Section
            if !favoriteEvents.isEmpty {
                Divider()

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

                    // Favorites List
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

            Divider()

            // Settings Button
            settingsButton

            // About Button
            aboutButton
        }
        .background(Color.appBackground)
        .hideScrollIndicatorsCompat()
        .animation(.default, value: favoriteEvents.isEmpty)
    }
    
    private var aboutButton: some View {
        Button {
            showAbout = true
        } label: {
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                Text(String(localized: "about.title"))
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
    
    var body: some View {
        NavigationLink {
            // We need a CitiesViewModel to drive CityDetailView. Attempt to get it from environment using modelContext.
            CityDetailWrapper(city: city)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue.gradient)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(city.name)
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
                        .foregroundStyle(.blue)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CityDetailWrapper: View {
    @Environment(\.modelContext) private var modelContext
    let city: FavoriteCity
    var body: some View {
        let viewModel = CitiesViewModel(modelContext: modelContext)
        CityDetailView(city: city, viewModel: viewModel)
    }
}

// MARK: - Event Filter

enum EventFilter: String, CaseIterable {
    case all = "filter.all"
    case live = "filter.live"
    case upcoming = "filter.upcoming"
    case past = "filter.past"
    
    var icon: String {
        switch self {
        case .all: return "calendar"
        case .live: return "circle.fill"
        case .upcoming: return "clock.fill"
        case .past: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .live: return .green
        case .upcoming: return .orange
        case .past: return .gray
        }
    }

    var localizedKey: LocalizedStringKey { .init(self.rawValue) }
}

private enum EventsLayoutStyle {
    case split
    case compact
}

// MARK: - Filter Button

private struct FilterButton: View {
    let filter: EventFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 11, weight: .semibold))

                Text(filter.localizedKey)

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? filter.color : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? filter.color.opacity(0.2) : Color.secondary.opacity(0.15))
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? filter.color.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? filter.color.opacity(0.4) : Color.secondary.opacity(0.2), lineWidth: 1.5)
            )
            .foregroundStyle(isSelected ? filter.color : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Events Content View

private struct EventsContentView: View {
    // With @Observable, no property wrapper needed for read-only access!
    let viewModel: EventsViewModel
    @Binding var selectedEvent: Event?
    let layout: EventsLayoutStyle
    let onEventSelected: (Event) -> Void
    @State private var selectedFilter: EventFilter = .all
    @State private var filterConfig = FilterConfiguration()
    @State private var showFilterSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
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
        .searchable(text: $filterConfig.searchText, prompt: String(localized: "search.events.prompt"))
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
        .background(Color.orange)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "events.title"))
                    .titleStyle()
                
                if let lastUpdate = viewModel.lastUpdateText {
                    Text(lastUpdate)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Filter Button
            Button {
                showFilterSheet = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(filterConfig.isActive ? .blue : .secondary)
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
                sectionHeader(title: String(localized: "section.live_events"), icon: "circle.fill", color: .green)
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
                    color: .orange,
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
                sectionHeader(title: String(localized: "section.past_events"), icon: "checkmark.circle.fill", color: .gray, topPadding: 20)
            }
        }
    }
    
    @ViewBuilder
    private var liveEventsView: some View {
        if filteredActiveEvents.isEmpty {
            emptyFilterState(icon: "circle.fill", message: String(localized: "filter.none.live"), color: .green)
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
            emptyFilterState(icon: "clock.fill", message: String(localized: "filter.none.upcoming"), color: .orange)
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
            emptyFilterState(icon: "checkmark.circle.fill", message: String(localized: "filter.none.past"), color: .gray)
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

// MARK: - Event Row

private struct EventRow: View {
    let event: Event
    let isSelected: Bool
    var isPast: Bool = false
    var isActive: Bool = false
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        // Show UTC time components without timezone conversion
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale.current
        return formatter
    }()

    private func formatEventDate(_ date: Date) -> String {
        return Self.dateFormatter.string(from: date)
    }
    
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
                            .overlay(
                                ProgressView()
                                    .controlSize(.small)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(.quaternary)
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Event Name & Countdown
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isPast ? .secondary : .primary)
                            .lineLimit(2)

                        Text(event.displayHeading)
                            .captionStyle()
                    }
                    
                    Spacer()
                    
                    CompactCountdownBadge(event: event)
                    
                    FavoriteButton(eventID: event.id)
                        .padding(.leading, 4)
                }
                
                // Badges
                HStack(spacing: 6) {
                    ModernBadge(event.displayHeading, icon: "tag.fill", color: eventTypeColor)
                    
                    if event.hasSpawns {
                        ModernBadge(String(localized: "badge.spawns"), icon: "location.fill", color: .green)
                    }
                }
                
                // Date
                Text(formatEventDate(event.startTime))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : (isActive ? Color.green.opacity(0.05) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isSelected ? Color.accentColor.opacity(0.3) : (isActive ? Color.green.opacity(0.3) : Color.clear),
                    lineWidth: isActive ? 2 : (isSelected ? 2 : 0)
                )
        )
        .padding(.horizontal, 20)
        .opacity(isPast ? 0.6 : 1.0)
    }
    
    private var eventTypeColor: Color {
        switch event.eventType {
        case "community-day":
            return .green
        case "raid-hour", "raid-day", "raid-battles", "raid-weekend":
            return .red
        case "pokemon-spotlight-hour":
            return .yellow
        case "go-battle-league":
            return .purple
        case "research", "ticketed-event":
            return .blue
        default:
            return .gray
        }
    }
}

// MARK: - Event Detail Container

private struct EventDetailContainerView: View {
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
