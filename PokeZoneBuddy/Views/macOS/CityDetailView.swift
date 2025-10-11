//
//  CityDetailView.swift
//  PokeZoneBuddy
//
//  Detail view for a city on macOS
//

#if os(macOS)
import SwiftUI
import SwiftData
import MapKit

struct CityDetailView: View {

    // MARK: - Properties

    let city: FavoriteCity
    let viewModel: CitiesViewModel

    @State private var showDeleteConfirmation = false
    @State private var showAddSpot = false

    // MARK: - Computed Properties

    private var spots: [CitySpot] {
        viewModel.getSpots(for: city)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                cityInfoSection

                Divider()

                spotsSection

                Divider()

                dangerZoneSection
            }
            .padding(32)
        }
        .background(Color.appBackground)
        .navigationTitle(city.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSpot = true
                } label: {
                    Label(String(localized: "spots.add.title"), systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSpot) {
            AddSpotSheet(city: city, viewModel: viewModel)
                .presentationSizing(.fitted)
        }
        .alert(String(localized: "alert.delete.city.title"), isPresented: $showDeleteConfirmation) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "common.delete"), role: .destructive) {
                viewModel.removeCity(city)
            }
        } message: {
            Text(String(localized: "alert.delete.city.message"))
        }
    }

    // MARK: - City Info Section

    private var cityInfoSection: some View {
        VStack(spacing: 20) {
            // City Header
            HStack(spacing: 16) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                            .symbolRenderingMode(.hierarchical)
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(city.name)
                        .font(.system(size: 24, weight: .bold))

                    Text(city.fullName)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Time Zone Info
            VStack(spacing: 12) {
                infoRow(
                    icon: "clock",
                    title: String(localized: "cities.timezone"),
                    value: city.abbreviatedTimeZone
                )

                infoRow(
                    icon: "globe",
                    title: String(localized: "cities.utc_offset"),
                    value: city.formattedUTCOffset
                )

                infoRow(
                    icon: "clock.fill",
                    title: String(localized: "cities.current_time"),
                    value: currentTimeInCity
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.25),
                                .blue.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Spots Section

    private var spotsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(localized: "spots.section.title"))
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text("\(spots.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(.blue.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .blue.opacity(0.15), radius: 3, x: 0, y: 1)
            }

            if spots.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.quaternary)

                    Text(String(localized: "spots.section.empty"))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    Button {
                        showAddSpot = true
                    } label: {
                        Label(String(localized: "spots.add.title"), systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                List {
                    ForEach(spots, id: \.persistentModelID) { spot in
                        SpotDetailRow(spot: spot, viewModel: viewModel)
                    }
                    .onDelete { offsets in
                        viewModel.deleteSpots(at: offsets, from: city)
                    }
                }
                .listStyle(.inset)
                .frame(minHeight: 200)
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "common.danger_zone"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.red)

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label(String(localized: "cities.delete"), systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helper Views

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
            }

            Spacer()
        }
    }

    // MARK: - Computed Time

    private var currentTimeInCity: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: city.timeZoneIdentifier)
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - Spot Detail Row

private struct SpotDetailRow: View {
    let spot: CitySpot
    let viewModel: CitiesViewModel

    @State private var showEditSpot = false

    var body: some View {
        Button {
            showEditSpot = true
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(categoryColor.gradient)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: categoryIcon)
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.name)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(spot.category.localizedName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(categoryColor)

                        if !spot.notes.isEmpty {
                            Text("•")
                                .foregroundStyle(.quaternary)

                            Text(spot.notes)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                if spot.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditSpot) {
            EditSpotSheet(spot: spot, viewModel: viewModel)
                .presentationSizing(.fitted)
        }
    }

    private var categoryIcon: String {
        switch spot.category {
        case .pokestop: return "mappin.circle.fill"
        case .gym: return "dumbbell.fill"
        case .meetingPoint: return "person.2.fill"
        case .other: return "mappin.and.ellipse"
        }
    }

    private var categoryColor: Color {
        switch spot.category {
        case .pokestop: return .blue
        case .gym: return .red
        case .meetingPoint: return .purple
        case .other: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var mockData: (FavoriteCity, CitiesViewModel) = {
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
            notes: "Famous intersection",
            latitude: 35.661852,
            longitude: 139.700514,
            category: .pokestop,
            isFavorite: true,
            city: mockCity
        )

        context.insert(mockCity)
        context.insert(mockSpot)

        let viewModel = CitiesViewModel(modelContext: context)
        return (mockCity, viewModel)
    }()

    NavigationStack {
        CityDetailView(city: mockData.0, viewModel: mockData.1)
    }
}
#endif
