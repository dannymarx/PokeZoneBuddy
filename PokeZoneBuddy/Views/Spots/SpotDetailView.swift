//
//  SpotDetailView.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 06.10.2025.
//

import SwiftUI
import SwiftData
import MapKit

/// Detail-Ansicht für einen einzelnen Spot
struct SpotDetailView: View {

    // MARK: - Properties

    let spot: CitySpot
    let viewModel: CitiesViewModel
    let onEdit: (CitySpot) -> Void
    let isSheet: Bool

    // MARK: - State

    @State private var showCopiedAlert: Bool = false
    @State private var showEditSheet: Bool = false
    @State private var cameraPosition: MapCameraPosition
    @Environment(\.dismiss) private var dismiss

    init(
        spot: CitySpot,
        viewModel: CitiesViewModel,
        isSheet: Bool = false,
        onEdit: @escaping (CitySpot) -> Void = { _ in }
    ) {
        self.spot = spot
        self.viewModel = viewModel
        self.isSheet = isSheet
        self.onEdit = onEdit

        // Initialize camera position to spot location
        let coordinate = CLLocationCoordinate2D(
            latitude: spot.latitude,
            longitude: spot.longitude
        )
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        ))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                spotHeader
                coordinatesSection
                mapSection
                notesSection
                metadataSection
            }
        }
        .background(Color.appBackground)
        .navigationTitle("")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showEditSheet) {
            EditSpotSheet(spot: spot, viewModel: viewModel)
                #if os(macOS)
                .presentationSizing(.fitted)
                #endif
        }
        .alert(String(localized: "spots.copied"), isPresented: $showCopiedAlert) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(String(localized: "spots.copied"))
        }
        .onChange(of: spot.persistentModelID) { _, _ in
            // Update camera position when spot changes
            let coordinate = CLLocationCoordinate2D(
                latitude: spot.latitude,
                longitude: spot.longitude
            )
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }
        }
    }

    // MARK: - View Components

    /// Modern Spot Header with all key information
    @ViewBuilder
    private var spotHeader: some View {
        VStack(spacing: 16) {
            // Spot Name
            Text(spot.name)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)

            // Location Information
            if let city = spot.city {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.systemBlue)
                        Text(city.name)
                            .font(.system(size: 16, weight: .medium))
                    }

                    HStack(spacing: 12) {
                        // Continent
                        Label(continent(for: city), systemImage: "globe")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)

                        Text("•")
                            .foregroundStyle(.quaternary)

                        // Current time in city
                        Label(currentTimeInCity(city), systemImage: "clock.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    // Category Badge - Below location info
                    HStack(spacing: 4) {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(spot.category.localizedName)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(spot.category.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(spot.category.color.opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(spot.category.color.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: spot.category.color.opacity(0.2), radius: 3, x: 0, y: 2)
                }
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
    }

    /// Coordinates Section with Copy Button
    @ViewBuilder
    private var coordinatesSection: some View {
        VStack(spacing: 16) {
            // Coordinates Display
            Text(spot.formattedCoordinates)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                )

            // Copy Button
            Button {
                copyCoordinates()
            } label: {
                Label(String(localized: "spots.action.copy_coordinates"), systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    /// Embedded Apple Maps Section
    @ViewBuilder
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("label.location")
                .font(.system(size: 18, weight: .semibold))
                .padding(.horizontal, 20)

            Map(position: $cameraPosition) {
                Marker(spot.name, coordinate: spotCoordinate)
                    .tint(spot.category.color)
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }

    /// Notes Section
    @ViewBuilder
    private var notesSection: some View {
        if !spot.notes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "spots.detail.notes"))
                    .font(.system(size: 18, weight: .semibold))

                Text(spot.notes)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    /// Metadata Section
    @ViewBuilder
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("section.information")
                .font(.system(size: 18, weight: .semibold))

            VStack(spacing: 0) {
                metadataRow(
                    icon: "calendar",
                    title: String(localized: "spots.detail.created_at"),
                    value: spot.createdAt.formatted(date: .long, time: .omitted)
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }

    @ViewBuilder
    private func metadataRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.systemBlue)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(16)
    }

    /// Toolbar mit Edit Button
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(macOS)
        // macOS: Close button when presented as sheet
        if isSheet {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Label(String(localized: "common.close"), systemImage: "xmark.circle.fill")
                }
            }
        }

        // macOS: Edit button
        ToolbarItem(placement: .primaryAction) {
            Button {
                if isSheet {
                    // When presented as sheet, use internal sheet
                    showEditSheet = true
                } else {
                    // Otherwise, call the callback
                    onEdit(spot)
                }
            } label: {
                Label(String(localized: "spots.action.edit"), systemImage: "pencil")
            }
        }
        #else
        // iOS: Close button when presented as sheet
        if isSheet {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Label(String(localized: "common.close"), systemImage: "xmark.circle.fill")
                }
            }
        }

        // iOS: Edit button
        ToolbarItem(placement: .primaryAction) {
            Button {
                if isSheet {
                    // When presented as sheet, use internal sheet
                    showEditSheet = true
                } else {
                    // Otherwise, call the callback
                    onEdit(spot)
                }
            } label: {
                Label(String(localized: "spots.action.edit"), systemImage: "pencil")
            }
        }
        #endif
    }

    // MARK: - Computed Properties

    private var spotCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: spot.latitude,
            longitude: spot.longitude
        )
    }

    private var categoryIcon: String {
        switch spot.category {
        case .pokestop: return "mappin.circle.fill"
        case .gym: return "dumbbell.fill"
        case .meetingPoint: return "person.2.fill"
        case .other: return "mappin.and.ellipse"
        }
    }

    private func continent(for city: FavoriteCity) -> String {
        CityDisplayHelpers.continent(from: city.timeZoneIdentifier)
    }

    private func currentTimeInCity(_ city: FavoriteCity) -> String {
        guard let timezone = TimeZone(identifier: city.timeZoneIdentifier) else {
            return "—"
        }

        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
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

    context.insert(mockCity)
    context.insert(mockSpot)

    let viewModel = CitiesViewModel(modelContext: context)

    return SpotDetailView(spot: mockSpot, viewModel: viewModel)
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

    let mockCity = FavoriteCity(
        name: "Berlin",
        timeZoneIdentifier: "Europe/Berlin",
        fullName: "Berlin, Germany"
    )

    let mockSpot = CitySpot(
        name: "Brandenburg Gate",
        notes: "Historic landmark, perfect raid spot with multiple gyms nearby.",
        latitude: 52.516275,
        longitude: 13.377704,
        category: .gym,
        isFavorite: false,
        city: mockCity
    )

    context.insert(mockCity)
    context.insert(mockSpot)

    let viewModel = CitiesViewModel(modelContext: context)

    return SpotDetailView(spot: mockSpot, viewModel: viewModel)
        .modelContainer(container)
}
