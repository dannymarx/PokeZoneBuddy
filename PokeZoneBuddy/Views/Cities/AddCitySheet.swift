//
//  AddCitySheet.swift
//  PokeZoneBuddy
//
//  Sheet for searching and adding new cities
//

import SwiftUI
import SwiftData
import MapKit

/// Sheet for searching and adding new cities to favorites
struct AddCitySheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @Bindable var viewModel: CitiesViewModel

    // MARK: - State

    @State private var isSearching = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.searchText.isEmpty {
                    emptyStateView
                } else if viewModel.searchResults.isEmpty {
                    if isSearching {
                        searchingView
                    } else {
                        noResultsView
                    }
                } else {
                    searchResultsList
                }
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: "action.add_city"))
#if os(iOS)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: String(localized: "dialog.add_city")
            )
#else
            .searchable(
                text: $viewModel.searchText,
                prompt: String(localized: "dialog.add_city")
            )
#endif
            .toolbar {
                toolbarContent
            }
            .onChange(of: viewModel.searchText) { _, newValue in
                if !newValue.isEmpty {
                    isSearching = true
                    // Reset searching state after a delay
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        isSearching = false
                    }
                }
            }
        }
    }

    // MARK: - View Components

    /// Empty state when no search has been performed
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 72))
                .foregroundStyle(.quaternary)

            VStack(spacing: 8) {
                Text(String(localized: "placeholder.search_cities.title"))
                    .font(.system(size: 20, weight: .semibold))

                Text(String(localized: "placeholder.search_cities.subtitle"))
                    .secondaryStyle()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Searching indicator
    private var searchingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
            Text(String(localized: "loading.searching"))
                .secondaryStyle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// No results found view
    private var noResultsView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text(String(localized: "search.no_results"))
                .secondaryStyle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// List of search results
    private var searchResultsList: some View {
        List {
            ForEach(viewModel.searchResults, id: \.self) { completion in
                Button {
                    addCity(completion)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(completion.title)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)

                        if !completion.subtitle.isEmpty {
                            Text(completion.subtitle)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
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

    // MARK: - Methods

    /// Adds the selected city to favorites
    private func addCity(_ completion: MKLocalSearchCompletion) {
        Task {
            await viewModel.addCity(completion)
            // Close the sheet after adding
            dismiss()
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

    let viewModel = CitiesViewModel(modelContext: container.mainContext)

    AddCitySheet(viewModel: viewModel)
        .modelContainer(container)
}
