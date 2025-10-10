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
            ForEach(viewModel.favoriteCities) { city in
                Button {
                    selectedCityID = city.id
                    onCitySelected(city)
                } label: {
                    CityRowView(city: city, viewModel: viewModel)
                }
                .buttonStyle(.plain)
                .tag(city.id)
            }
        }
        .listStyle(.inset)
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

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                )

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(city.name)
                    .font(.system(size: 16, weight: .semibold))

                HStack(spacing: 8) {
                    Text(city.fullName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.quaternary)

                    Text(city.abbreviatedTimeZone)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.quaternary)

                    Text(city.formattedUTCOffset)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }

            Spacer()

            // Spot Count Badge
            if spotCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                    Text("\(spotCount)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(.quaternary.opacity(0.3))
                )
            }
        }
        .padding(.vertical, 8)
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
