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
                            Button {
                                selectedSpotID = spot.persistentModelID
                                onSpotSelected(city, spot)
                            } label: {
                                SpotRowCompactView(spot: spot)
                            }
                            .buttonStyle(.plain)
                            .tag(spot.persistentModelID)
                        }
                        .onDelete { offsets in
                            viewModel.deleteSpots(at: offsets, from: city)
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
}

// MARK: - Spot Row Compact View

private struct SpotRowCompactView: View {

    let spot: CitySpot

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Circle()
                .fill(categoryColor.gradient)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                )

            // Spot Info
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                if !spot.notes.isEmpty {
                    Text(spot.notes)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Favorite Indicator
            if spot.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 4)
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
