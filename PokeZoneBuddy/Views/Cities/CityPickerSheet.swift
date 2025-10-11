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
        .frame(minWidth: 480, idealWidth: 520, minHeight: 400, idealHeight: 500)
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
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white)
                            )

                        // City Info
                        VStack(alignment: .leading, spacing: 6) {
                            Text(city.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)

                            Text(city.fullName)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
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
