//
//  SpotListView.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 06.10.2025.
//

import SwiftUI
import SwiftData
import Observation

/// Zeigt alle Spots einer Stadt und erlaubt Details in einem einheitlichen Flow
struct SpotListView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    // MARK: - Properties

    @Bindable var viewModel: CitiesViewModel
    let city: FavoriteCity
    let initialSpot: CitySpot?

    // MARK: - State

    @State private var activeSpotID: CitySpot.ID?
    @State private var navigationPath: [CitySpot.ID] = []
    @State private var showingAddSpot = false
    @State private var editingSpot: CitySpot?
    @State private var didSeedSelection = false
    @State private var isEditMode = false

    // MARK: - Types

    private enum LayoutStyle {
        case split
        case stack
    }

    // MARK: - Body

    var body: some View {
        let style = layoutStyle

        Group {
            switch style {
            case .split:
                splitLayout
            case .stack:
                stackLayout
            }
        }
#if os(macOS)
        .frame(minWidth: 760, minHeight: 640)
#endif
        .sheet(isPresented: $showingAddSpot) {
            AddSpotSheet(city: city, viewModel: viewModel)
        }
        .sheet(item: $editingSpot) { spot in
            EditSpotSheet(spot: spot, viewModel: viewModel)
        }
        .onAppear {
            seedSelectionIfNeeded(for: style)
        }
        .onChange(of: style) { _, newStyle in
            syncSelection(for: newStyle)
        }
        .onChange(of: spots) { _, _ in
            cleanupSelection(for: style)
        }
        .onChange(of: navigationPath) { _, newPath in
            guard style == .stack else { return }
            let currentID = newPath.last
            if activeSpotID != currentID {
                activeSpotID = currentID
            }
        }
        .onChange(of: activeSpotID) { _, newValue in
            guard style == .stack else { return }
            if navigationPath.last != newValue {
                navigationPath = newValue.map { [$0] } ?? []
            }
        }
    }

    // MARK: - Layout Variants

    /// Split-Layout für macOS und breite iPad-Layouts
    private var splitLayout: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width
            let columnWidth = max(340, min(availableWidth * 0.35, 540))

            NavigationSplitView {
                Group {
                    if spots.isEmpty {
                        emptyStateView
                    } else {
                        splitList(columnWidth: columnWidth)
                    }
                }
                .navigationTitle(String(localized: "spots.section.manage_title"))
            } detail: {
                if let spot = spot(for: activeSpotID) {
                    SpotDetailView(spot: spot, viewModel: viewModel) { editingSpot = $0 }
                } else if spots.isEmpty {
                    emptyStateView
                } else {
                    selectionPlaceholder
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                }

                #if os(macOS)
                if !spots.isEmpty {
                    ToolbarItem(placement: .automatic) {
                        Button(isEditMode ? String(localized: "common.done") : String(localized: "common.edit")) {
                            withAnimation {
                                isEditMode.toggle()
                            }
                        }
                    }
                }
                #endif

                ToolbarItem(placement: .primaryAction) {
                    addSpotButton
                }
            }
            .navigationSplitViewColumnWidth(
                min: columnWidth,
                ideal: columnWidth,
                max: columnWidth
            )
            .navigationSplitViewStyle(.balanced)
        }
    }

    /// Stack-Layout für iPhone
    private var stackLayout: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if spots.isEmpty {
                    emptyStateView
                } else {
                    stackList
                }
            }
            .navigationTitle(String(localized: "spots.section.manage_title"))
            .navigationDestination(for: CitySpot.ID.self) { id in
                if let spot = spot(for: id) {
                    SpotDetailView(spot: spot, viewModel: viewModel) { editingSpot = $0 }
                } else {
                    selectionPlaceholder
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                }

                #if os(macOS)
                if !spots.isEmpty {
                    ToolbarItem(placement: .automatic) {
                        Button(isEditMode ? String(localized: "common.done") : String(localized: "common.edit")) {
                            withAnimation {
                                isEditMode.toggle()
                            }
                        }
                    }
                }
                #endif

                ToolbarItem(placement: .primaryAction) {
                    addSpotButton
                }
            }
        }
    }

    // MARK: - List Variants

    /// Liste für Split-Layout mit Selection-Binding
    @ViewBuilder
    private func splitList(columnWidth: CGFloat) -> some View {
        List(selection: $activeSpotID) {
            ForEach(spots, id: \.persistentModelID) { spot in
                SimpleSpotRow(spot: spot)
                    .tag(spot.persistentModelID)
                    .contentShape(Rectangle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        deleteButton(for: spot)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        editButton(for: spot)
                        favoriteButton(for: spot)
                    }
            }
            .onDelete { offsets in
                deleteSpots(at: offsets)
            }
        }
        #if !os(macOS)
        .environment(\.editMode, .constant(isEditMode ? .active : .inactive))
        #endif
        .scrollIndicators(.hidden)
        .hideScrollIndicatorsCompat()
        #if os(macOS)
        .listStyle(.inset)
        #else
        .listStyle(.insetGrouped)
        #endif
        .frame(width: columnWidth)
    }

    /// Liste für Stack-Layout mit NavigationLinks
    private var stackList: some View {
        List {
            ForEach(spots, id: \.persistentModelID) { spot in
                NavigationLink(value: spot.persistentModelID) {
                    SharedSpotRow(
                        spot: spot,
                        onEdit: { editingSpot = spot },
                        onDelete: { deleteSpot(spot) }
                    )
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    deleteButton(for: spot)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    editButton(for: spot)
                    favoriteButton(for: spot)
                }
            }
            .onDelete { offsets in
                deleteSpots(at: offsets)
            }
        }
        #if !os(macOS)
        .environment(\.editMode, .constant(isEditMode ? .active : .inactive))
        #endif
        .scrollIndicators(.hidden)
        .hideScrollIndicatorsCompat()
        #if os(macOS)
        .listStyle(.inset)
        #else
        .listStyle(.insetGrouped)
        #endif
    }

    // MARK: - Buttons

    /// Add Button für Toolbar
    private var addSpotButton: some View {
        Button(String(localized: "spots.add.title")) {
            showingAddSpot = true
        }
    }

    /// Edit Button für Swipe Actions
    @ViewBuilder
    private func editButton(for spot: CitySpot) -> some View {
        Button {
            editingSpot = spot
        } label: {
            Label(String(localized: "spots.action.edit"), systemImage: "pencil")
        }
        .tint(.systemBlue)
    }

    /// Delete Button für Swipe Actions
    @ViewBuilder
    private func deleteButton(for spot: CitySpot) -> some View {
        Button(role: .destructive) {
            deleteSpot(spot)
        } label: {
            Label(String(localized: "spots.action.delete"), systemImage: "trash")
        }
        .tint(.systemRed)
    }

    /// Favorite Toggle Button für Swipe Actions
    @ViewBuilder
    private func favoriteButton(for spot: CitySpot) -> some View {
        Button {
            toggleFavorite(spot)
        } label: {
            if spot.isFavorite {
                Label(String(localized: "favorites.remove"), systemImage: "star.slash")
            } else {
                Label(String(localized: "favorites.add"), systemImage: "star")
            }
        }
        .tint(.systemYellow)
    }

    // MARK: - View Components

    /// Empty State für leere Spots
    @ViewBuilder
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label(String(localized: "spots.section.empty"), systemImage: "mappin.slash")
        } description: {
            Text(String(localized: "spots.section.empty.description"))
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "spots.section.empty") + ". " + String(localized: "spots.section.empty.description"))
    }

    /// Placeholder wenn ein Spot ausgewählt werden soll
    private var selectionPlaceholder: some View {
        ContentUnavailableView {
            Label(String(localized: "spots.section.title"), systemImage: "mappin.and.ellipse")
        } description: {
            Text(String(localized: "spots.section.empty.description"))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Computed Properties

    /// Aktuelle Liste der Spots für die Stadt
    private var spots: [CitySpot] {
        // Force recomputation when dataVersion changes
        _ = viewModel.dataVersion
        return viewModel.getSpots(for: city)
    }

    /// Layout-Style basierend auf Plattform und Size Class
    private var layoutStyle: LayoutStyle {
        #if os(macOS)
        return .split
        #else
        if horizontalSizeClass == .regular {
            return .split
        } else {
            return .stack
        }
        #endif
    }

    /// Binding für List-Selection im Split-Layout
    private var bindingToActiveSpot: Binding<CitySpot.ID?> {
        Binding {
            activeSpotID
        } set: { newValue in
            activeSpotID = newValue
        }
    }

    // MARK: - Methods

    /// Löscht einen Spot und aktualisiert Selektionen
    private func deleteSpot(_ spot: CitySpot) {
        if activeSpotID == spot.persistentModelID {
            activeSpotID = nil
        }
        if navigationPath.last == spot.persistentModelID {
            navigationPath.removeAll()
        }
        viewModel.deleteSpot(spot)
    }

    /// Löscht Spots an den angegebenen Offsets
    private func deleteSpots(at offsets: IndexSet) {
        for index in offsets {
            let spot = spots[index]
            deleteSpot(spot)
        }
    }

    /// Toggelt den Favoriten-Status
    private func toggleFavorite(_ spot: CitySpot) {
        viewModel.toggleSpotFavorite(spot)
    }

    /// Liefert den Spot für eine ID, falls vorhanden
    private func spot(for id: CitySpot.ID?) -> CitySpot? {
        guard let id else { return nil }
        return spots.first(where: { $0.persistentModelID == id })
    }

    /// Prüft ob eine ID in der aktuellen Liste existiert
    private func resolveExistingID(from id: CitySpot.ID?) -> CitySpot.ID? {
        guard let id else { return nil }
        return spots.contains(where: { $0.persistentModelID == id }) ? id : nil
    }

    /// Initialisiert die Auswahl nur einmal
    private func seedSelectionIfNeeded(for style: LayoutStyle) {
        guard !didSeedSelection else { return }

        let initialID = resolveExistingID(from: initialSpot?.persistentModelID)
        let fallbackID = initialID ?? spots.first?.persistentModelID

        switch style {
        case .split:
            activeSpotID = fallbackID
        case .stack:
            activeSpotID = fallbackID
            if let fallbackID {
                navigationPath = [fallbackID]
            }
        }

        didSeedSelection = true
    }

    /// Synchronisiert Auswahl beim Layout-Wechsel
    private func syncSelection(for style: LayoutStyle) {
        switch style {
        case .split:
            if let pathID = navigationPath.last,
               let resolved = resolveExistingID(from: pathID) {
                activeSpotID = resolved
            } else if activeSpotID == nil {
                activeSpotID = spots.first?.persistentModelID
            }
        case .stack:
            if let activeSpotID,
               resolveExistingID(from: activeSpotID) != nil {
                if navigationPath.last != activeSpotID {
                    navigationPath = [activeSpotID]
                }
            } else if let firstID = spots.first?.persistentModelID {
                activeSpotID = firstID
                navigationPath = [firstID]
            } else {
                navigationPath.removeAll()
            }
        }
    }

    /// Entfernt ungültige Selektionen wenn Spots sich ändern
    private func cleanupSelection(for style: LayoutStyle) {
        if resolveExistingID(from: activeSpotID) == nil {
            if style == .split {
                activeSpotID = spots.first?.persistentModelID
            } else if let firstID = spots.first?.persistentModelID {
                activeSpotID = firstID
                navigationPath = [firstID]
            } else {
                activeSpotID = nil
            }
        }

        if let last = navigationPath.last,
           resolveExistingID(from: last) == nil {
            if let firstID = spots.first?.persistentModelID {
                navigationPath = [firstID]
            } else {
                navigationPath.removeAll()
            }
        }
    }
}

// MARK: - Simple Spot Row (for selectable lists)

private struct SimpleSpotRow: View {
    let spot: CitySpot

    var body: some View {
        VStack(spacing: 8) {
            // Title and Badge Row
            HStack(spacing: 12) {
                // Name - Left aligned
                Text(spot.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                Spacer(minLength: 8)

                // Favorite Star
                if spot.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.systemYellow)
                        .symbolRenderingMode(.hierarchical)
                        .shadow(color: Color.systemYellow.opacity(0.3), radius: 2, x: 0, y: 1)
                }

                // Category badge - Right aligned
                HStack(spacing: 4) {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 11, weight: .semibold))
                    Text(spot.category.localizedName)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(categoryColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(categoryColor.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(categoryColor.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: categoryColor.opacity(0.2), radius: 2, x: 0, y: 1)
            }

            // Notes
            if !spot.notes.isEmpty {
                HStack {
                    Text(spot.notes)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }

    private var categoryIcon: String {
        switch spot.category {
        case .pokestop: return "mappin.circle.fill"
        case .gym: return "dumbbell.fill"
        case .meetingPoint: return "person.2.fill"
        case .other: return "mappin.and.ellipse"
        }
    }

    private var categoryColor: Color {
        switch spot.category {
        case .pokestop: return .systemBlue
        case .gym: return .systemRed
        case .meetingPoint: return .systemPurple
        case .other: return .systemGray
        }
    }
}

// MARK: - Preview

#Preview("Spot Flow - Regular Width") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FavoriteCity.self,
        CitySpot.self,
        configurations: config
    )

    let context = container.mainContext

    let mockCity = FavoriteCity(
        name: "Tokyo",
        timeZoneIdentifier: "Asia/Tokyo",
        fullName: "Tokyo, Japan"
    )

    let mockSpots = [
        CitySpot(
            name: "Shibuya Crossing",
            notes: "Famous intersection with many PokéStops",
            latitude: 35.661852,
            longitude: 139.700514,
            category: .pokestop,
            isFavorite: true,
            city: mockCity
        ),
        CitySpot(
            name: "Tokyo Tower Gym",
            notes: "Iconic landmark, great for raids",
            latitude: 35.658517,
            longitude: 139.745438,
            category: .gym,
            city: mockCity
        ),
    ]

    context.insert(mockCity)
    mockSpots.forEach { context.insert($0) }
    try? context.save()

    let viewModel = CitiesViewModel(modelContext: context)
    viewModel.loadFavoriteCitiesFromDatabase()

    return SpotListView(viewModel: viewModel, city: mockCity, initialSpot: mockSpots.first)
        .modelContainer(container)
}

#Preview("Spot Flow - Compact Width") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FavoriteCity.self,
        CitySpot.self,
        configurations: config
    )

    let context = container.mainContext

    let mockCity = FavoriteCity(
        name: "Berlin",
        timeZoneIdentifier: "Europe/Berlin",
        fullName: "Berlin, Germany"
    )

    let mockSpot = CitySpot(
        name: "Brandenburger Tor",
        latitude: 52.5163,
        longitude: 13.3777,
        category: .gym,
        isFavorite: false,
        city: mockCity
    )

    context.insert(mockCity)
    context.insert(mockSpot)
    try? context.save()

    let viewModel = CitiesViewModel(modelContext: context)
    viewModel.loadFavoriteCitiesFromDatabase()

    return NavigationStack {
        SpotListView(viewModel: viewModel, city: mockCity, initialSpot: nil)
    }
    .modelContainer(container)
}
