//
//  CitySortPicker.swift
//  PokeZoneBuddy
//
//  Sort picker component for city lists
//

import SwiftUI
import SwiftData

/// Sort picker menu for city lists
struct CitySortPicker: View {

    @Bindable var viewModel: CitiesViewModel

    var body: some View {
        Menu {
            // Sort option picker
            Picker(String(localized: "sort.sort_by"), selection: $viewModel.sortOption) {
                ForEach(CitySortOption.allCases) { option in
                    Label(option.localizedName, systemImage: option.icon)
                        .tag(option)
                }
            }

            Divider()

            // Sort order toggle
            Button {
                viewModel.sortOrder.toggle()
            } label: {
                Label(
                    viewModel.sortOrder.localizedName,
                    systemImage: viewModel.sortOrder.icon
                )
            }
        } label: {
            Label(String(localized: "sort.title"), systemImage: "arrow.up.arrow.down")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FavoriteCity.self,
        configurations: config
    )

    let viewModel = CitiesViewModel(modelContext: container.mainContext)

    CitySortPicker(viewModel: viewModel)
}
