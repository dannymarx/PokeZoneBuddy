//
//  EventsListView.swift
//  PokeZoneBuddy
//
//  Moderne macOS 26 Haupt-View
//  Version 0.2 - Mit Filtern, Thumbnails, Countdown-Badges
//

import SwiftUI
import SwiftData

struct EventsListView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var eventsViewModel: EventsViewModel?
    @State private var citiesViewModel: CitiesViewModel?
    @State private var selectedEvent: Event?
    @State private var showCitiesManagement = false
    @State private var showAbout = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
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
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // SIDEBAR: Cities
            CitiesSidebarView(
                viewModel: citiesVM,
                showManagement: $showCitiesManagement,
                showAbout: $showAbout
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
            
        } content: {
            // CONTENT: Events
            EventsContentView(
                viewModel: eventsVM,
                selectedEvent: $selectedEvent
            )
            .navigationSplitViewColumnWidth(min: 420, ideal: 460, max: 540)
            
        } detail: {
            // DETAIL: Event Details
            EventDetailContainerView(
                event: selectedEvent,
                cities: citiesVM.favoriteCities
            )
        }
        .navigationSplitViewStyle(.balanced)
        .onReceive(NotificationCenter.default.publisher(for: .refreshEvents)) { _ in
            Task { await eventsVM.refreshEvents() }
        }
        .sheet(isPresented: $showCitiesManagement) {
            CitiesManagementView(viewModel: citiesVM)
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .alert(String(localized: "alert.error.title"), isPresented: Binding(
            get: { eventsVM.showError },
            set: { eventsVM.showError = $0 }
        )) {
            Button(String(localized: "common.ok")) {
                eventsVM.showError = false
            }
        } message: {
            Text(eventsVM.errorMessage ?? String(localized: "alert.error.unknown"))
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
        .background(.windowBackground)
    }
    
    // MARK: - Initialize ViewModels
    
    private func initializeViewModels() {
        eventsViewModel = EventsViewModel(modelContext: modelContext)
        citiesViewModel = CitiesViewModel(modelContext: modelContext)
        
        if let eventsVM = eventsViewModel, eventsVM.events.isEmpty {
            Task { await eventsVM.fetchEvents() }
        }
    }
}

// MARK: - Cities Sidebar View

private struct CitiesSidebarView: View {
    @ObservedObject var viewModel: CitiesViewModel
    @Binding var showManagement: Bool
    @Binding var showAbout: Bool
    
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
            ScrollView {
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
            
            Divider()
            
            // About Button
            aboutButton
        }
        .background(.windowBackground)
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
    @ObservedObject var viewModel: EventsViewModel
    @Binding var selectedEvent: Event?
    @State private var selectedFilter: EventFilter = .all
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
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
        .background(.windowBackground)
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
        }
        .frame(maxWidth: .infinity)
    }
    
    private func eventCount(for filter: EventFilter) -> Int {
        switch filter {
        case .all:
            return viewModel.events.count
        case .live:
            return viewModel.activeEvents.count
        case .upcoming:
            return viewModel.upcomingEvents.count
        case .past:
            return viewModel.pastEvents.count
        }
    }
    
    private var eventsList: some View {
        ScrollView {
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
            }
            .padding(.vertical, 12)
        }
    }
    
    @ViewBuilder
    private var allEventsView: some View {
        // Active Events
        if !viewModel.activeEvents.isEmpty {
            Section {
                ForEach(viewModel.activeEvents) { event in
                    EventRow(event: event, isSelected: selectedEvent?.id == event.id, isActive: true)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEvent = event
                        }
                }
            } header: {
                sectionHeader(title: String(localized: "section.live_events"), icon: "circle.fill", color: .green)
            }
        }
        
        // Upcoming Events
        if !viewModel.upcomingEvents.isEmpty {
            Section {
                ForEach(viewModel.upcomingEvents) { event in
                    EventRow(event: event, isSelected: selectedEvent?.id == event.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEvent = event
                        }
                }
            } header: {
                sectionHeader(
                    title: String(localized: "section.upcoming_events"),
                    icon: "clock.fill",
                    color: .orange,
                    topPadding: viewModel.activeEvents.isEmpty ? 8 : 20
                )
            }
        }
        
        // Past Events
        if !viewModel.pastEvents.isEmpty {
            Section {
                ForEach(viewModel.pastEvents.prefix(5)) { event in
                    EventRow(event: event, isSelected: selectedEvent?.id == event.id, isPast: true)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEvent = event
                        }
                }
            } header: {
                sectionHeader(title: String(localized: "section.past_events"), icon: "checkmark.circle.fill", color: .gray, topPadding: 20)
            }
        }
    }
    
    @ViewBuilder
    private var liveEventsView: some View {
        if viewModel.activeEvents.isEmpty {
            emptyFilterState(icon: "circle.fill", message: String(localized: "filter.none.live"), color: .green)
        } else {
            ForEach(viewModel.activeEvents) { event in
                EventRow(event: event, isSelected: selectedEvent?.id == event.id, isActive: true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEvent = event
                    }
            }
        }
    }
    
    @ViewBuilder
    private var upcomingEventsView: some View {
        if viewModel.upcomingEvents.isEmpty {
            emptyFilterState(icon: "clock.fill", message: String(localized: "filter.none.upcoming"), color: .orange)
        } else {
            ForEach(viewModel.upcomingEvents) { event in
                EventRow(event: event, isSelected: selectedEvent?.id == event.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEvent = event
                    }
            }
        }
    }
    
    @ViewBuilder
    private var pastEventsView: some View {
        if viewModel.pastEvents.isEmpty {
            emptyFilterState(icon: "checkmark.circle.fill", message: String(localized: "filter.none.past"), color: .gray)
        } else {
            ForEach(viewModel.pastEvents) { event in
                EventRow(event: event, isSelected: selectedEvent?.id == event.id, isPast: true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEvent = event
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
}

// MARK: - Event Row

private struct EventRow: View {
    let event: Event
    let isSelected: Bool
    var isPast: Bool = false
    var isActive: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Thumbnail
            if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                CachedAsyncImage(
                    url: url
                ) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay(
                            ProgressView()
                                .controlSize(.small)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Event Name & Countdown
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isPast ? .secondary : .primary)
                            .lineLimit(2)
                        
                        Text(event.heading)
                            .captionStyle()
                    }
                    
                    Spacer()
                    
                    CompactCountdownBadge(event: event)
                }
                
                // Badges
                HStack(spacing: 6) {
                    ModernBadge(event.heading, icon: "tag.fill", color: eventTypeColor)
                    
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
    
    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
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
        .background(.windowBackground)
    }
}

// MARK: - Preview

#Preview {
    EventsListView()
        .modelContainer(for: [Event.self, FavoriteCity.self], inMemory: true)
        .frame(width: 1200, height: 800)
}

