//
//  CityDetailView.swift
//  PokeZoneBuddy
//
//  Detail view for a city on macOS
//

#if os(macOS)
import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct CityDetailView: View {

    // MARK: - Properties

    let city: FavoriteCity
    let viewModel: CitiesViewModel

    @State private var showDeleteConfirmation = false
    @State private var showAddSpot = false

    // MARK: - Computed Properties

    private var spots: [CitySpot] {
        // Force recomputation when favoriteCities changes (which happens after any spot operation)
        _ = viewModel.favoriteCities.count
        return viewModel.getSpots(for: city)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                cityInfoSection

                Divider()

                spotsSection

                Divider()

                dangerZoneSection
            }
            .padding(32)
        }
        .hideScrollIndicatorsCompat()
        .background(Color.appBackground)
        .navigationTitle(city.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSpot = true
                } label: {
                    Label(String(localized: "spots.add.title"), systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSpot) {
            AddSpotSheet(city: city, viewModel: viewModel)
                .presentationSizing(.fitted)
        }
        .alert(String(localized: "alert.delete.city.title"), isPresented: $showDeleteConfirmation) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "common.delete"), role: .destructive) {
                viewModel.removeCity(city)
            }
        } message: {
            Text(String(localized: "alert.delete.city.message"))
        }
    }

    // MARK: - City Info Section

    private var cityInfoSection: some View {
        VStack(spacing: 20) {
            // City Header
            HStack(spacing: 16) {
                // Flag/Icon
                if !flagOrIcon.isEmpty {
                    Text(flagOrIcon)
                        .font(.system(size: 56))
                        .frame(width: 72, height: 72)
                } else {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue.gradient)
                        .frame(width: 72, height: 72)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(city.name)
                        .font(.system(size: 24, weight: .bold))

                    HStack(spacing: 8) {
                        if let country = countryName {
                            Text(country)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)

                            Text("•")
                                .foregroundStyle(.quaternary)
                        }

                        Text(continent)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text("•")
                            .foregroundStyle(.quaternary)

                        Text(city.abbreviatedTimeZone)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text("•")
                            .foregroundStyle(.quaternary)

                        Text(city.formattedUTCOffset)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.systemBlue)
                    }
                }

                Spacer()
            }

            // Time Zone Info Card
            VStack(spacing: 12) {
                infoRow(
                    icon: "clock.fill",
                    title: String(localized: "cities.current_time"),
                    value: currentTimeInCity
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.primary.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)

            // Open in Maps Button
            Button {
                openInMaps()
            } label: {
                Label(String(localized: "cities.open_in_maps"), systemImage: "map.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: - Helper Properties

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

    // MARK: - Spots Section

    private var spotsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(localized: "spots.section.title"))
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text("\(spots.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.systemBlue.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.systemBlue.opacity(0.15), radius: 3, x: 0, y: 1)
            }

            if spots.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.quaternary)

                    Text(String(localized: "spots.section.empty"))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    Button {
                        showAddSpot = true
                    } label: {
                        Label(String(localized: "spots.add.title"), systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                List {
                    ForEach(spots, id: \.persistentModelID) { spot in
                        SpotDetailRow(spot: spot, viewModel: viewModel)
                    }
                    .onDelete { offsets in
                        viewModel.deleteSpots(at: offsets, from: city)
                    }
                }
                .listStyle(.inset)
                .frame(minHeight: 200)
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "common.danger_zone"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.systemRed)

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label(String(localized: "cities.delete"), systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helper Views

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.systemBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
            }

            Spacer()
        }
    }

    // MARK: - Computed Time

    private var currentTimeInCity: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: city.timeZoneIdentifier)
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

    // MARK: - Actions

    /// Opens the city in the Maps app
    private func openInMaps() {
        // Create a search request for the city
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = city.fullName

        // Perform the search
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response,
                  let mapItem = response.mapItems.first else {
                // If search fails, try with just the city name
                openInMapsWithCityName()
                return
            }

            // Open the map item in Maps app
            mapItem.name = city.name

            // Use location coordinate
            let coordinate = mapItem.location.coordinate
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate),
                MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            ])
        }
    }

    /// Fallback method to open Maps with just the city name
    private func openInMapsWithCityName() {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = city.name

        let search = MKLocalSearch(request: searchRequest)
        search.start { response, _ in
            guard let mapItem = response?.mapItems.first else {
                return
            }
            mapItem.name = city.name
            mapItem.openInMaps()
        }
    }
}

// MARK: - Spot Detail Row

private struct SpotDetailRow: View {
    let spot: CitySpot
    let viewModel: CitiesViewModel

    @State private var showSpotDetail = false

    var body: some View {
        Button {
            showSpotDetail = true
        } label: {
            VStack(spacing: 8) {
                // Title and Badge Row
                HStack(spacing: 12) {
                    // Name - Left aligned
                    Text(spot.name)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    if spot.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
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
                    .foregroundStyle(spot.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(spot.category.color.opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(spot.category.color.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: spot.category.color.opacity(0.2), radius: 2, x: 0, y: 1)
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSpotDetail) {
            SpotDetailView(spot: spot, viewModel: viewModel, isSheet: true)
        }
    }

    private var categoryIcon: String {
        switch spot.category {
        case .pokestop: return "mappin.circle.fill"
        case .gym: return "dumbbell.fill"
        case .meetingPoint: return "person.2.fill"
        case .other: return "mappin.and.ellipse"
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var mockData: (FavoriteCity, CitiesViewModel) = {
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

        let viewModel = CitiesViewModel(modelContext: context)
        return (mockCity, viewModel)
    }()

    NavigationStack {
        CityDetailView(city: mockData.0, viewModel: mockData.1)
    }
}
#endif
