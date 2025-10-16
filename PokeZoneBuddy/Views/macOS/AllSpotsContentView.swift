//
//  AllSpotsContentView.swift
//  PokeZoneBuddy
//
//  Middle column content for All Spots view on macOS
//

#if os(macOS)
import SwiftUI
import SwiftData

struct AllSpotsContentView: View {

    // MARK: - Properties

    let viewModel: CitiesViewModel
    let onSpotSelected: (FavoriteCity, CitySpot) -> Void
    let onAddSpot: () -> Void

    @State private var selectedSpotID: CitySpot.ID?
    @State private var isEditMode = false

    // MARK: - Computed Properties

    private var allSpots: [CitySpot] {
        viewModel.favoriteCities.flatMap { city in
            viewModel.getSpots(for: city)
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.favoriteCities.isEmpty {
                noCitiesView
            } else if allSpots.isEmpty {
                noSpotsView
            } else {
                spotsList
            }
        }
        .navigationTitle(String(localized: "spots.section.title"))
        .toolbar {
            if !viewModel.favoriteCities.isEmpty {
                ToolbarItem(placement: .automatic) {
                    Button(isEditMode ? String(localized: "common.done") : String(localized: "common.edit")) {
                        withAnimation {
                            isEditMode.toggle()
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onAddSpot()
                    } label: {
                        Label(String(localized: "spots.add.title"), systemImage: "plus")
                    }
                }
            }
        }
    }

    // MARK: - Spots List

    private var spotsList: some View {
        List(selection: $selectedSpotID) {
            ForEach(viewModel.favoriteCities, id: \.persistentModelID) { city in
                let spots = viewModel.getSpots(for: city)
                if !spots.isEmpty {
                    Section(city.name) {
                        ForEach(spots, id: \.persistentModelID) { spot in
                            HStack(spacing: 8) {
                                if isEditMode {
                                    Button {
                                        deleteSpot(spot, from: city)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red)
                                            .font(.system(size: 20))
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button {
                                    if !isEditMode {
                                        selectedSpotID = spot.persistentModelID
                                        onSpotSelected(city, spot)
                                    }
                                } label: {
                                    SpotRowCompactView(spot: spot)
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                                .tag(spot.persistentModelID)
                                .disabled(isEditMode)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Empty States

    private var noCitiesView: some View {
        EmptyStateView(
            icon: "map.circle",
            title: String(localized: "placeholder.no_cities.title"),
            subtitle: String(localized: "placeholder.no_cities.subtitle")
        )
    }

    private var noSpotsView: some View {
        EmptyStateView(
            icon: "mappin.slash",
            title: String(localized: "spots.section.empty"),
            subtitle: String(localized: "spots.section.empty.description"),
            action: .init(
                title: String(localized: "spots.add.title"),
                systemImage: "plus.circle",
                handler: onAddSpot
            )
        )
    }

    // MARK: - Methods

    private func deleteSpot(_ spot: CitySpot, from city: FavoriteCity) {
        withAnimation {
            viewModel.deleteSpot(spot)
        }
    }
}

// MARK: - Spot Row Compact View

private struct SpotRowCompactView: View {

    let spot: CitySpot

    var body: some View {
        VStack(spacing: 8) {
            // Title and Badge Row
            HStack(spacing: 12) {
                // Name - Left aligned
                Text(spot.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                Spacer(minLength: 8)

                // Favorite Indicator with glow
                if spot.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.yellow)
                        .symbolRenderingMode(.hierarchical)
                        .shadow(color: .yellow.opacity(0.3), radius: 2, x: 0, y: 1)
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
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
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
        case .pokestop: return .blue
        case .gym: return .red
        case .meetingPoint: return .purple
        case .other: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var mockViewModel: CitiesViewModel = {
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

        let mockSpot = CitySpot(
            name: "Shibuya Crossing",
            notes: "Famous intersection",
            latitude: 35.661852,
            longitude: 139.700514,
            category: .pokestop,
            isFavorite: true,
            city: mockCity
        )

        context.insert(mockCity)
        context.insert(mockSpot)
        try? context.save()

        let viewModel = CitiesViewModel(modelContext: context)
        viewModel.loadFavoriteCitiesFromDatabase()
        return viewModel
    }()

    NavigationStack {
        AllSpotsContentView(
            viewModel: mockViewModel,
            onSpotSelected: { _, _ in },
            onAddSpot: {}
        )
    }
}
#endif
