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
                    )

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
                    .fill(.quaternary.opacity(0.3))
            )
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
                            .fill(.quaternary.opacity(0.3))
                    )
            }

            if spots.isEmpty {
                Text(String(localized: "spots.section.empty"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 8) {
                    ForEach(spots.prefix(5)) { spot in
                        SpotCompactRow(spot: spot)
                    }

                    if spots.count > 5 {
                        Text(String(localized: "common.and_more", defaultValue: "And \(spots.count - 5) more..."))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                }
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

// MARK: - Spot Compact Row

private struct SpotCompactRow: View {
    let spot: CitySpot

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(categoryColor.gradient)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(spot.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                if !spot.notes.isEmpty {
                    Text(spot.notes)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if spot.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary.opacity(0.2))
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
