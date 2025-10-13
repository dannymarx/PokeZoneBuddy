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
                ToolbarItem(placement: .automatic) {
                    CitySortPicker(viewModel: viewModel)
                }

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
        HStack(spacing: 12) {
            // Flag/Icon - Compact liquid glass
            if !flagOrIcon.isEmpty {
                Text(flagOrIcon)
                    .font(.system(size: 32))
                    .frame(width: 40, height: 40)
            } else {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: .blue.opacity(0.2), radius: 3, x: 0, y: 1)
            }

            // Info - Compact layout
            VStack(alignment: .leading, spacing: 3) {
                Text(city.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                // Compact single-line info
                HStack(spacing: 4) {
                    if let country = countryName {
                        Text(country)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text("•")
                            .font(.system(size: 11))
                            .foregroundStyle(.quaternary)
                    }

                    Text(continent)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("•")
                        .font(.system(size: 11))
                        .foregroundStyle(.quaternary)

                    Text(city.abbreviatedTimeZone)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("•")
                        .font(.system(size: 11))
                        .foregroundStyle(.quaternary)

                    Text(city.formattedUTCOffset)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
                .lineLimit(1)
                .truncationMode(.tail)
            }

            Spacer(minLength: 0)

            // Spot Count Badge with Liquid Glass - Compact
            if spotCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .symbolRenderingMode(.hierarchical)
                    Text("\(spotCount)")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(.blue.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .blue.opacity(0.12), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
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
