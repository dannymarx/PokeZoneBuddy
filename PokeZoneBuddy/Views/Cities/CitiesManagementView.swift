//
//  CitiesManagementView.swift
//  PokeZoneBuddy
//
//  Moderne Städte-Verwaltung für macOS 26
//

import SwiftUI
import SwiftData
import MapKit

struct CitiesManagementView: View {
    
    // MARK: - Properties

    // With @Observable, use @Bindable for two-way bindings!
    @Bindable var viewModel: CitiesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var activeCityForSpots: FavoriteCity?
    @State private var activeSpotForSpots: CitySpot?
    @State private var showAddCity = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            contentSection
                .background(Color.appBackground)
                .navigationTitle(String(localized: "cities.manage_title"))
#if os(iOS)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(String(localized: "action.add_city")) {
                            showAddCity = true
                        }
                    }

                    if !viewModel.favoriteCities.isEmpty {
                        ToolbarItem(placement: .topBarLeading) {
                            EditButton()
                        }
                    }
                }
#else
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: "common.done")) {
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                }
#endif
                .alert(String(localized: "alert.error.title"), isPresented: $viewModel.showError) {
                    Button("OK") {
                        viewModel.showError = false
                    }
                } message: {
                    Text(viewModel.errorMessage ?? String(localized: "alert.error.unknown"))
                }
        }
        .sheet(item: $activeCityForSpots) { city in
            SpotListView(
                viewModel: viewModel,
                city: city,
                initialSpot: activeSpotForSpots
            )
#if os(iOS)
            .presentationDetents([.fraction(0.9), .large])
            .presentationDragIndicator(.visible)
#elseif os(macOS)
            .presentationSizing(.fitted)
#endif
        }
        .sheet(isPresented: $showAddCity) {
            AddCitySheet(viewModel: viewModel)
#if os(iOS)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
#elseif os(macOS)
            .presentationSizing(.fitted)
#endif
        }
        .onChange(of: activeCityForSpots) { newValue in
            if case .none = newValue {
                activeSpotForSpots = nil
            }
        }
#if os(macOS)
        .frame(minWidth: 600, minHeight: 700)
#endif
    }
    
    // MARK: - Content Section

    private var contentSection: some View {
        favoriteCitiesView
    }
    
    // MARK: - Favorite Cities View

    private var favoriteCitiesView: some View {
        Group {
            if viewModel.favoriteCities.isEmpty {
                noCitiesPlaceholder
            } else {
                List {
                    ForEach(viewModel.favoriteCities, id: \.persistentModelID) { city in
                        Button {
                            activeSpotForSpots = viewModel.getSpots(for: city).first
                            activeCityForSpots = city
                        } label: {
                            FavoriteCityRowContent(city: city)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        viewModel.removeCities(at: offsets)
                    }
                }
#if os(macOS)
                .listStyle(.inset)
#else
                .listStyle(.insetGrouped)
#endif
            }
        }
    }
    
    // MARK: - Placeholders

    private var noCitiesPlaceholder: some View {
        EmptyStateView(
            icon: "map.circle",
            title: String(localized: "placeholder.no_cities_yet.title"),
            subtitle: String(localized: "placeholder.no_cities_yet.subtitle")
        )
    }
    
}

// MARK: - Favorite City Row Content

private struct FavoriteCityRowContent: View {
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
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(for: FavoriteCity.self, configurations: .init(isStoredInMemoryOnly: true))
    let viewModel = CitiesViewModel(modelContext: container.mainContext)
    
    CitiesManagementView(viewModel: viewModel)
}
