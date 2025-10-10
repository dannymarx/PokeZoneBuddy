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
        ScrollView(.vertical, showsIndicators: false) {
            if viewModel.favoriteCities.isEmpty {
                noCitiesPlaceholder
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.favoriteCities) { city in
                        Button {
                            activeSpotForSpots = viewModel.getSpots(for: city).first
                            activeCityForSpots = city
                        } label: {
                            FavoriteCityRow(city: city) {
                                withAnimation(.spring(response: 0.3)) {
                                    viewModel.removeCity(city)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)
            }
        }
        .scrollIndicators(.hidden, axes: .vertical)
        .hideScrollIndicatorsCompat()
    }
    
    // MARK: - Placeholders
    
    private var noCitiesPlaceholder: some View {
        VStack(spacing: 24) {
            Image(systemName: "map.circle")
                .font(.system(size: 72))
                .foregroundStyle(.quaternary)
            
            VStack(spacing: 8) {
                Text(String(localized: "placeholder.no_cities_yet.title"))
                    .font(.system(size: 20, weight: .semibold))
                
                Text(String(localized: "placeholder.no_cities_yet.subtitle"))
                    .secondaryStyle()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}

// MARK: - Favorite City Row

private struct FavoriteCityRow: View {
    let city: FavoriteCity
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
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
            
            // Delete Button
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundStyle(.red)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isHovering ? Color.red.opacity(0.1) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(for: FavoriteCity.self, configurations: .init(isStoredInMemoryOnly: true))
    let viewModel = CitiesViewModel(modelContext: container.mainContext)
    
    CitiesManagementView(viewModel: viewModel)
}
