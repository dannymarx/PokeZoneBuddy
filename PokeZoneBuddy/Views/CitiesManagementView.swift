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
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                Divider()
                
                // Search Section
                searchSection
                
                Divider()
                
                // Content
                contentSection
            }
            .background(Color.appBackground)
            
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
#if os(macOS)
                    .keyboardShortcut(.cancelAction)
#endif
                }
            }
            .alert(String(localized: "alert.error.title"), isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? String(localized: "alert.error.unknown"))
            }
        }
#if os(macOS)
        .frame(minWidth: 600, minHeight: 700)
#endif
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "map.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "cities.manage_title"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text("\(viewModel.favoriteCities.count) of \(Constants.Limits.maxFavoriteCities) cities")
                    .secondaryStyle()
            }
            
            Spacer()
        }
        .padding(24)
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                
                TextField(String(localized: "search.placeholder"), text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.quaternary.opacity(0.3))
            )
            
            if viewModel.searchText.isEmpty {
                Text(String(localized: "search.hint"))
                    .captionStyle()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        Group {
            if viewModel.searchText.isEmpty {
                favoriteCitiesView
            } else {
                searchResultsView
            }
        }
    }
    
    // MARK: - Favorite Cities View
    
    private var favoriteCitiesView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if viewModel.favoriteCities.isEmpty {
                noCitiesPlaceholder
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.favoriteCities) { city in
                        NavigationLink {
                            CityDetailWrapperFromManagement(city: city)
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
    
    // MARK: - Search Results View
    
    private var searchResultsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if viewModel.searchResults.isEmpty {
                noResultsPlaceholder
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.searchResults, id: \.self) { completion in
                        SearchResultRow(
                            completion: completion,
                            isAdding: viewModel.isAddingCity
                        ) {
                            Task {
                                await viewModel.addCity(completion)
                            }
                        }
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
    
    private var noResultsPlaceholder: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 72))
                .foregroundStyle(.quaternary)
            
            VStack(spacing: 8) {
                Text(String(localized: "placeholder.no_results.title"))
                    .font(.system(size: 20, weight: .semibold))
                
                Text(String(localized: "placeholder.no_results.subtitle"))
                    .secondaryStyle()
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

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let completion: MKLocalSearchCompletion
    let isAdding: Bool
    let onAdd: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(.quaternary.opacity(0.5))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "location.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(completion.title)
                    .font(.system(size: 16, weight: .semibold))
                
                if !completion.subtitle.isEmpty {
                    Text(completion.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Add Button
            if isAdding {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isHovering ? Color.blue.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHovering = hovering
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isHovering ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
    }
}

private struct CityDetailWrapperFromManagement: View {
    @Environment(\.modelContext) private var modelContext
    let city: FavoriteCity
    var body: some View {
        let vm = CitiesViewModel(modelContext: modelContext)
        CityDetailView(city: city, viewModel: vm)
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(for: FavoriteCity.self, configurations: .init(isStoredInMemoryOnly: true))
    let viewModel = CitiesViewModel(modelContext: container.mainContext)
    
    CitiesManagementView(viewModel: viewModel)
}
