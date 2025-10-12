//
//  CitiesContentView.swift
//  PokeZoneBuddy
//
//  Middle column content for Cities view on macOS
//

#if os(macOS)
import SwiftUI
import SwiftData

struct CitiesContentView: View {

    // MARK: - Properties

    let viewModel: CitiesViewModel
    let onCitySelected: (FavoriteCity) -> Void
    let onAddCity: () -> Void

    @State private var selectedCityID: FavoriteCity.ID?

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.favoriteCities.isEmpty {
                emptyStateView
            } else {
                citiesList
            }
        }
        .navigationTitle(String(localized: "sidebar.your_cities"))
        .toolbar {
            if !viewModel.favoriteCities.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onAddCity()
                    } label: {
                        Label(String(localized: "action.add_city"), systemImage: "plus")
                    }
                }
            }
        }
    }

    // MARK: - Cities List

    private var citiesList: some View {
        List(selection: $selectedCityID) {
            ForEach(viewModel.favoriteCities, id: \.persistentModelID) { city in
                CityRowView(city: city, viewModel: viewModel)
                    .tag(city.persistentModelID)
                    .contentShape(Rectangle())
            }
            .onDelete { offsets in
                viewModel.removeCities(at: offsets)
            }
        }
        .listStyle(.inset)
        .onChange(of: selectedCityID) { _, newID in
            if let newID = newID,
               let city = viewModel.favoriteCities.first(where: { $0.persistentModelID == newID }) {
                onCitySelected(city)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "map.circle",
            title: String(localized: "placeholder.no_cities_yet.title"),
            subtitle: String(localized: "placeholder.no_cities_yet.subtitle"),
            action: .init(
                title: String(localized: "action.add_city"),
                systemImage: "plus.circle",
                handler: onAddCity
            )
        )
    }
}

// MARK: - City Row View

private struct CityRowView: View {

    let city: FavoriteCity
    let viewModel: CitiesViewModel

    private var spotCount: Int {
        viewModel.getSpots(for: city).count
    }

    private var flagOrIcon: String {
        if let country = CityDisplayHelpers.extractCountry(from: city.fullName),
           let flag = CityDisplayHelpers.flagEmoji(for: country) {
            return flag
        }
        return ""
    }

    private var continent: String {
        CityDisplayHelpers.continent(from: city.timeZoneIdentifier)
    }

    private var countryName: String? {
        CityDisplayHelpers.countryName(from: city.fullName)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Flag/Icon
            if !flagOrIcon.isEmpty {
                Text(flagOrIcon)
                    .font(.system(size: 44))
                    .frame(width: 56, height: 56)
            } else {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue.gradient)
                    .frame(width: 56, height: 56)
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(city.name)
                    .font(.system(size: 18, weight: .semibold))

                HStack(spacing: 8) {
                    if let country = countryName {
                        Text(country)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text("•")
                            .foregroundStyle(.quaternary)
                    }

                    Text(continent)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.quaternary)

                    Text(city.abbreviatedTimeZone)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.quaternary)

                    Text(city.formattedUTCOffset)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }

            Spacer()

            // Spot Count Badge with Liquid Glass
            if spotCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .symbolRenderingMode(.hierarchical)
                    Text("\(spotCount)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(.blue.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .blue.opacity(0.15), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var mockContext: ModelContext = {
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
        context.insert(mockCity)
        return context
    }()

    let viewModel = CitiesViewModel(modelContext: mockContext)

    NavigationStack {
        CitiesContentView(
            viewModel: viewModel,
            onCitySelected: { _ in },
            onAddCity: {}
        )
    }
}
#endif
