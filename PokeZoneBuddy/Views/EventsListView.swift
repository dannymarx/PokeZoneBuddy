//
//  EventsListView.swift
//  PokeZoneBuddy
//
//  Moderne macOS 26 Haupt-View
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
                showManagement: $showCitiesManagement
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
            
        } content: {
            // CONTENT: Events
            EventsContentView(
                viewModel: eventsVM,
                selectedEvent: $selectedEvent
            )
            .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 450)
            
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
        .alert("Fehler", isPresented: Binding(
            get: { eventsVM.showError },
            set: { eventsVM.showError = $0 }
        )) {
            Button("OK") {
                eventsVM.showError = false
            }
        } message: {
            Text(eventsVM.errorMessage ?? "Ein unbekannter Fehler ist aufgetreten")
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
            Text("Wird geladen...")
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Deine Städte")
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
                .help("Stadt hinzufügen")
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
        }
        .background(.windowBackground)
    }
    
    private var noCitiesPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 4) {
                Text("Keine Städte")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Füge Städte hinzu um Event-Zeiten zu sehen")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showManagement = true
            } label: {
                Text("Stadt hinzufügen")
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

// MARK: - Events Content View

private struct EventsContentView: View {
    @ObservedObject var viewModel: EventsViewModel
    @Binding var selectedEvent: Event?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
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
                Text("Events")
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
            .help("Events aktualisieren")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var eventsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
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
                        HStack {
                            Text("Kommende Events")
                                .sectionHeader()
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
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
                        HStack {
                            Text("Vergangene Events")
                                .sectionHeader()
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 4)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }
    
    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Lade Events...")
                .secondaryStyle()
        }
        .frame(maxHeight: .infinity)
    }
    
    private var emptyContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("Keine Events gefunden")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event Name & Duration
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
                
                Text(event.formattedDuration)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            // Badges
            HStack(spacing: 6) {
                ModernBadge(event.eventType, icon: "tag.fill", color: .blue)
                
                if event.hasSpawns {
                    ModernBadge("Spawns", icon: "location.fill", color: .green)
                }
                
                if event.isCurrentlyActive {
                    ModernBadge("Live", icon: "circle.fill", color: .successGreen)
                }
            }
            
            // Date
            Text(formatEventDate(event.startTime))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .padding(.horizontal, 16)
        .opacity(isPast ? 0.6 : 1.0)
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
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
                Text("Kein Event ausgewählt")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Wähle ein Event aus der Liste")
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
