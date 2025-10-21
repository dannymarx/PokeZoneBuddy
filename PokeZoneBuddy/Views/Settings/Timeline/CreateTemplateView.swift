//
//  CreateTemplateView.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-20.
//  Version 1.6.0 - Timeline Templates Management
//

import SwiftUI
import SwiftData

/// View for creating or editing a timeline template
struct CreateTemplateView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    /// The template to edit (nil for creating a new template)
    let templateToEdit: TimelineTemplate?

    // MARK: - Initialization

    init(templateToEdit: TimelineTemplate? = nil) {
        self.templateToEdit = templateToEdit
    }

    // MARK: - State

    @State private var timelineService: TimelineService?
    @State private var templateName = ""
    @State private var selectedEventType = "community-day"
    @State private var selectedCityIDs: Set<String> = []
    @State private var isDefault = false
    @State private var availableCities: [FavoriteCity] = []
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var searchText = ""

    // MARK: - Constants

    private let eventTypes = [
        "community-day",
        "raid-hour",
        "raid-day",
        "spotlight-hour",
        "go-fest",
        "research-day",
        "special-event",
        "all"
    ]

    // MARK: - Computed Properties

    private var isEditMode: Bool {
        templateToEdit != nil
    }

    private var navigationTitle: String {
        isEditMode
            ? String(localized: "timeline.templates.edit")
            : String(localized: "timeline.templates.create")
    }

    private var filteredCities: [FavoriteCity] {
        if searchText.isEmpty {
            return availableCities
        }
        return availableCities.filter { city in
            city.name.localizedCaseInsensitiveContains(searchText) ||
            city.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var canSave: Bool {
        !templateName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedCityIDs.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Template Details Section
                Section {
                    TextField(
                        String(localized: "timeline.template.name_placeholder"),
                        text: $templateName
                    )

                    Picker(
                        String(localized: "timeline.template.event_type"),
                        selection: $selectedEventType
                    ) {
                        ForEach(eventTypes, id: \.self) { type in
                            Text(formatEventType(type))
                                .tag(type)
                        }
                    }

                    Toggle(
                        String(localized: "timeline.templates.set_default"),
                        isOn: $isDefault
                    )
                } header: {
                    Text(String(localized: "timeline.template.details"))
                } footer: {
                    Text(String(localized: "timeline.template.details_footer"))
                        .font(.caption)
                }

                // Cities Selection Section
                Section {
                    if availableCities.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        ForEach(filteredCities) { city in
                            CitySelectionRow(
                                city: city,
                                isSelected: selectedCityIDs.contains(city.timeZoneIdentifier)
                            ) {
                                toggleCity(city)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(String(localized: "timeline.template.cities"))
                        Spacer()
                        Text("\(selectedCityIDs.count)")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    if !selectedCityIDs.isEmpty {
                        Text(String(localized: "timeline.template.cities_selected_footer"))
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(navigationTitle)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .searchable(
                text: $searchText,
                prompt: String(localized: "cities.search.placeholder")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save")) {
                        saveTemplate()
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .onAppear {
                setupService()
                loadCities()
                populateEditData()
            }
            .alert(
                String(localized: "common.error"),
                isPresented: .constant(errorMessage != nil),
                presenting: errorMessage
            ) { _ in
                Button(String(localized: "common.ok")) {
                    errorMessage = nil
                }
            } message: { message in
                Text(message)
            }
        }
    }

    // MARK: - Actions

    private func setupService() {
        guard timelineService == nil else { return }

        let timelineRepo = TimelineRepository(modelContext: modelContext)
        let cityRepo = CityRepository(modelContext: modelContext)
        timelineService = TimelineService(
            timelineRepository: timelineRepo,
            cityRepository: cityRepo
        )
    }

    private func loadCities() {
        Task {
            do {
                let cityRepo = CityRepository(modelContext: modelContext)
                let cities = try await cityRepo.fetchCities()

                await MainActor.run {
                    availableCities = cities.sorted { $0.name < $1.name }
                }
            } catch {
                await MainActor.run {
                    errorMessage = String(localized: "cities.error.load_failed")
                }
                AppLogger.service.error("Failed to load cities: \(error)")
            }
        }
    }

    private func populateEditData() {
        guard let template = templateToEdit else { return }

        templateName = template.name
        selectedEventType = template.eventType
        selectedCityIDs = Set(template.cityIdentifiers)
        isDefault = template.isDefault
    }

    private func toggleCity(_ city: FavoriteCity) {
        if selectedCityIDs.contains(city.timeZoneIdentifier) {
            selectedCityIDs.remove(city.timeZoneIdentifier)
        } else {
            selectedCityIDs.insert(city.timeZoneIdentifier)
        }
    }

    private func saveTemplate() {
        guard let service = timelineService, canSave else { return }

        isSaving = true

        Task {
            do {
                let cityIdentifiers = Array(selectedCityIDs)
                let trimmedName = templateName.trimmingCharacters(in: .whitespaces)

                if let template = templateToEdit {
                    // Edit existing template
                    try await service.updateTemplate(
                        template,
                        name: trimmedName,
                        cityIdentifiers: cityIdentifiers,
                        isDefault: isDefault
                    )
                } else {
                    // Create new template
                    try await service.saveTemplate(
                        name: trimmedName,
                        eventType: selectedEventType,
                        cityIdentifiers: cityIdentifiers,
                        isDefault: isDefault
                    )
                }

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    if let timelineError = error as? TimelineError {
                        errorMessage = timelineError.errorDescription
                    } else {
                        errorMessage = String(localized: "timeline.error.save_failed")
                    }
                    isSaving = false
                }
                AppLogger.service.error("Failed to save template: \(error)")
            }
        }
    }

    private func formatEventType(_ type: String) -> String {
        if type == "all" {
            return String(localized: "timeline.template.event_type.all")
        }
        return type
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

// MARK: - City Selection Row

private struct CitySelectionRow: View {
    let city: FavoriteCity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color.systemPurple : .secondary)

                // City Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)

                    Text(city.fullName)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Timezone
                Text(city.timeZoneIdentifier)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    CreateTemplateView()
        .modelContainer(for: FavoriteCity.self, inMemory: true)
}
