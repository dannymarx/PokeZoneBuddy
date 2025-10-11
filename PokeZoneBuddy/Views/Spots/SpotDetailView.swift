//
//  SpotDetailView.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 06.10.2025.
//

import SwiftUI
import SwiftData

/// Detail-Ansicht für einen einzelnen Spot
struct SpotDetailView: View {

    // MARK: - Properties

    let spot: CitySpot
    let viewModel: CitiesViewModel
    let onEdit: (CitySpot) -> Void

    // MARK: - State

    @State private var showCopiedAlert: Bool = false

    init(
        spot: CitySpot,
        viewModel: CitiesViewModel,
        onEdit: @escaping (CitySpot) -> Void = { _ in }
    ) {
        self.spot = spot
        self.viewModel = viewModel
        self.onEdit = onEdit
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                coordinatesSection
                detailsSection
                notesSection
            }
            .formStyle(.grouped)
            .navigationTitle(spot.name)
            .toolbar {
                toolbarContent
            }
            .alert(String(localized: "spots.copied"), isPresented: $showCopiedAlert) {
                Button(String(localized: "common.ok"), role: .cancel) {}
            } message: {
                Text(String(localized: "spots.copied"))
            }
        }
    }

    // MARK: - View Components

    /// Koordinaten Section mit großer Anzeige und Copy Button
    @ViewBuilder
    private var coordinatesSection: some View {
        Section {
            VStack(spacing: 12) {
                // Große Koordinaten-Anzeige
                Text(spot.formattedCoordinates)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)

                // Copy Button
                Button {
                    copyCoordinates()
                } label: {
                    Label(String(localized: "spots.action.copyCoordinates"), systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        } header: {
            Text(String(localized: "spots.detail.coordinates"))
        }
        .accessibilityElement(children: .contain)
    }

    /// Details Section mit Name, Kategorie, Datum
    @ViewBuilder
    private var detailsSection: some View {
        Section {
            // Name
            LabeledContent(String(localized: "spots.add.name")) {
                Text(spot.name)
                    .foregroundStyle(.primary)
            }

            // Kategorie mit Icon
            LabeledContent(String(localized: "spots.add.category")) {
                spot.category.label
            }

            // Erstellt am
            LabeledContent(String(localized: "spots.detail.createdAt")) {
                Text(spot.createdAt, style: .date)
                    .foregroundStyle(.secondary)
            }

            // Favorit-Status
            LabeledContent(String(localized: "favorites.title")) {
                if spot.isFavorite {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(String(localized: "common.yes"))
                    }
                } else {
                    Text(String(localized: "common.no"))
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text(String(localized: "common.details"))
        }
    }

    /// Notizen Section (scrollbar wenn länger)
    @ViewBuilder
    private var notesSection: some View {
        if !spot.notes.isEmpty {
            Section {
                Text(spot.notes)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Text(String(localized: "spots.detail.notes"))
            }
        }
    }

    /// Toolbar mit Edit und Share Buttons
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    shareSpot()
                } label: {
                    Label(String(localized: "spots.action.share"), systemImage: "square.and.arrow.up")
                }

                Button {
                    onEdit(spot)
                } label: {
                    Label(String(localized: "spots.action.edit"), systemImage: "pencil")
                }

                Divider()

                Button {
                    viewModel.toggleSpotFavorite(spot)
                } label: {
                    if spot.isFavorite {
                        Label(String(localized: "favorites.remove"), systemImage: "star.slash")
                    } else {
                        Label(String(localized: "favorites.add"), systemImage: "star")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Computed Properties

    /// Formatierter Share-Text
    private var shareText: String {
        var text = "📍 \(spot.name)\n"
        text += String(localized: "spots.add.category") + ": \(spot.category.localizedName)\n"
        text += String(localized: "spots.detail.coordinates") + ": \(spot.formattedCoordinates)\n"

        if !spot.notes.isEmpty {
            text += "\n\(spot.notes)\n"
        }

        if let city = spot.city {
            text += "\nPokeZoneBuddy - \(city.displayName)"
        }

        return text
    }

    // MARK: - Methods

    /// Kopiert Koordinaten in die Zwischenablage
    private func copyCoordinates() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(spot.formattedCoordinates, forType: .string)
        #else
        UIPasteboard.general.string = spot.formattedCoordinates
        #endif

        showCopiedAlert = true
    }

    /// Teilt den Spot als Text
    private func shareSpot() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(shareText, forType: .string)

        // macOS: Zeige Feedback dass Text kopiert wurde
        showCopiedAlert = true
        #else
        // iOS: Nutze UIActivityViewController
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
}

// MARK: - Preview

#Preview("Spot Detail") {
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
        notes: "Famous intersection with many PokéStops. Great location for Community Day events. Always crowded but amazing spawns!",
        latitude: 35.661852,
        longitude: 139.700514,
        category: .pokestop,
        isFavorite: true,
        city: mockCity
    )

    let viewModel = CitiesViewModel(modelContext: context)

    SpotDetailView(spot: mockSpot, viewModel: viewModel)
        .modelContainer(container)
}

#Preview("Spot Detail - Gym") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FavoriteCity.self,
        CitySpot.self,
        configurations: config
    )

    let context = container.mainContext

    let mockSpot = CitySpot(
        name: "Tokyo Tower",
        notes: "Iconic landmark, great for raids",
        latitude: 35.658517,
        longitude: 139.745438,
        category: .gym,
        isFavorite: false
    )

    let viewModel = CitiesViewModel(modelContext: context)

    SpotDetailView(spot: mockSpot, viewModel: viewModel)
        .modelContainer(container)
}
