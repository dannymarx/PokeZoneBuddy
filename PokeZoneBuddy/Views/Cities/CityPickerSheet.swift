//
//  CityPickerSheet.swift
//  PokeZoneBuddy
//
//  Sheet for selecting a city before adding a spot
//

import SwiftUI
import SwiftData

/// Sheet for selecting a city to add a spot to
struct CityPickerSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    var cities: [FavoriteCity]
    let onCitySelected: (FavoriteCity) -> Void

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if cities.isEmpty {
                    emptyStateView
                } else {
                    citiesList
                }
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: "spots.select_city.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                toolbarContent
            }
        }
        #if os(macOS)
        .presentationSizing(.fitted)
        #endif
    }

    // MARK: - View Components

    /// Empty state when no cities are available
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "map.circle")
                .font(.system(size: 72))
                .foregroundStyle(.quaternary)

            VStack(spacing: 8) {
                Text(String(localized: "placeholder.no_cities.title"))
                    .font(.system(size: 20, weight: .semibold))

                Text(String(localized: "spots.select_city.empty.subtitle"))
                    .secondaryStyle()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// List of cities
    private var citiesList: some View {
        List {
            ForEach(cities, id: \.persistentModelID) { city in
                Button {
                    onCitySelected(city)
                    dismiss()
                } label: {
                    CityPickerRowView(city: city)
                }
                .buttonStyle(.plain)
            }
        }
        #if os(macOS)
        .listStyle(.inset)
        #else
        .listStyle(.insetGrouped)
        #endif
    }

    /// Toolbar content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "common.cancel")) {
                dismiss()
            }
        }
    }
}

// MARK: - City Picker Row View

private struct CityPickerRowView: View {
    let city: FavoriteCity

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
                    .font(.system(size: 40))
                    .frame(width: 50, height: 50)
            } else {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue.gradient)
                    .frame(width: 50, height: 50)
            }

            // City Info
            VStack(alignment: .leading, spacing: 6) {
                Text(city.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

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
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FavoriteCity.self,
        configurations: config
    )

    let mockCities = [
        FavoriteCity(name: "Tokyo", timeZoneIdentifier: "Asia/Tokyo", fullName: "Tokyo, Japan"),
        FavoriteCity(name: "New York", timeZoneIdentifier: "America/New_York", fullName: "New York, USA"),
        FavoriteCity(name: "London", timeZoneIdentifier: "Europe/London", fullName: "London, UK")
    ]

    CityPickerSheet(cities: mockCities) { city in
        print("Selected: \(city.name)")
    }
    .modelContainer(container)
}
