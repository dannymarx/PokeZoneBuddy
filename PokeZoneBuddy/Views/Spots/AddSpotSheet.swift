//
//  AddSpotSheet.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 06.10.2025.
//

import SwiftUI
import SwiftData
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Sheet zum Hinzufügen eines neuen Spots zu einer Stadt
struct AddSpotSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let city: FavoriteCity
    let viewModel: CitiesViewModel

    // MARK: - State

    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var category: SpotCategory = .other
    @State private var coordinateInput: String = ""
    @State private var parsedCoords: (latitude: Double, longitude: Double)? = nil
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    // MARK: - Computed Properties

    /// Validierung: Alle Pflichtfelder ausgefüllt und Koordinaten geparst
    private var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !coordinateInput.isEmpty &&
               parsedCoords != nil
    }

    /// Formatierte Koordinaten für Display
    private var formattedParsedCoordinates: String {
        guard let coords = parsedCoords else { return "" }
        return CoordinateParsingService.formatForExport(
            latitude: coords.latitude,
            longitude: coords.longitude
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                spotDetailsSection
                coordinatesSection
                helpSection
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "spots.add.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                toolbarContent
            }
            .alert(String(localized: "alert.error.title"), isPresented: $showError) {
                Button(String(localized: "common.ok"), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, idealWidth: 550, minHeight: 500, idealHeight: 600)
        #endif
    }

    // MARK: - View Components

    /// Section für Spot-Details (Name, Notizen, Kategorie)
    @ViewBuilder
    private var spotDetailsSection: some View {
        Section {
            TextField(String(localized: "spots.add.name"), text: $name)
                .accessibilityLabel("Spot name")
                .textFieldStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "spots.add.notes"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $notes)
                    .frame(minHeight: 80, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(editorBackgroundColor)
                    .cornerRadius(6)
                    .accessibilityLabel("Spot notes")
            }

            Picker(String(localized: "spots.add.category"), selection: $category) {
                ForEach(SpotCategory.allCases, id: \.self) { category in
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                        Text(category.localizedName)
                    }
                    .tag(category)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Spot category")
        } header: {
            Text(String(localized: "spots.add.title"))
        }
    }

    /// Section für Koordinaten-Eingabe mit Live-Parsing
    @ViewBuilder
    private var coordinatesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                TextField(
                    String(localized: "spots.add.coordinates"),
                    text: $coordinateInput,
                    prompt: Text(String(localized: "spots.add.coordinates.placeholder"))
                )
                .textFieldStyle(.plain)
                .accessibilityLabel("Coordinate input")
                .onChange(of: coordinateInput) { _, newValue in
                    parseCoordinates(from: newValue)
                }

                // Visual Feedback für Parsing-Ergebnis
                if !coordinateInput.isEmpty {
                    if parsedCoords != nil {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "spots.add.coordinates.success"))
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text(formattedParsedCoordinates)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Valid coordinates: \(formattedParsedCoordinates)")
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(String(localized: "spots.add.coordinates.error"))
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Invalid coordinates")
                    }
                }
            }
        } header: {
            Text(String(localized: "spots.detail.coordinates"))
        } footer: {
            Text(String(localized: "spots.add.coordinates.hint"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Section mit Hilfe-Informationen für gültige Formate
    @ViewBuilder
    private var helpSection: some View {
        Section {
            DisclosureGroup(String(localized: "spots.add.help.title")) {
                VStack(alignment: .leading, spacing: 12) {
                    FormatExample(
                        title: "Plain coordinates",
                        example: "40.760386,-73.828352"
                    )

                    FormatExample(
                        title: "Google Maps URL",
                        example: "?q=40.760386,-73.828352"
                    )

                    FormatExample(
                        title: "Apple Maps URL",
                        example: "ll=40.760386,-73.828352"
                    )

                    FormatExample(
                        title: "Degrees/Minutes/Seconds",
                        example: "40°45'37.4\"N 73°49'42.1\"W"
                    )
                }
                .padding(.vertical, 8)
            }
            .accessibilityElement(children: .contain)
        } header: {
            Text(String(localized: "spots.add.help.title"))
        }
    }

    /// Toolbar mit Cancel und Save Buttons
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "spots.add.cancel")) {
                dismiss()
            }
            .accessibilityLabel("Cancel adding spot")
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(String(localized: "spots.add.save")) {
                saveSpot()
            }
            .disabled(!isValid)
            .accessibilityLabel("Save spot")
            .accessibilityHint(isValid ? "Tap to save the spot" : "Fill in all required fields")
        }
    }

    // MARK: - Methods

    /// Parst Koordinaten aus dem Input-String
    private func parseCoordinates(from input: String) {
        parsedCoords = CoordinateParsingService.parseCoordinates(from: input)
    }

    /// Speichert den neuen Spot
    private func saveSpot() {
        guard let coords = parsedCoords else {
            errorMessage = String(localized: "spots.add.coordinates.error")
            showError = true
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        let success = viewModel.addSpot(
            to: city,
            name: trimmedName,
            notes: notes,
            latitude: coords.latitude,
            longitude: coords.longitude,
            category: category
        )

        if success {
            dismiss()
        } else {
            // ViewModel hat bereits errorMessage gesetzt
            errorMessage = viewModel.errorMessage ?? String(localized: "alert.error.unknown")
            showError = true
        }
    }
    
    // MARK: - Helpers
    private var editorBackgroundColor: Color {
    #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
    #else
        Color(uiColor: .secondarySystemBackground)
    #endif
    }
}

// MARK: - Supporting Views

/// Hilfs-View für Format-Beispiele
private struct FormatExample: View {
    let title: String
    let example: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Text(example)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Preview

#Preview("Add Spot Sheet") {
    // Mock City
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

    let viewModel = CitiesViewModel(modelContext: context)

    return AddSpotSheet(city: mockCity, viewModel: viewModel)
        .modelContainer(container)
}
