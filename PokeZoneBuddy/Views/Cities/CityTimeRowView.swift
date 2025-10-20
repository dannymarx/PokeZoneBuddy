//
//  CityTimeRowView.swift
//  PokeZoneBuddy
//
//  Moderne Zeitumrechnungs-Komponente für macOS 26
//

import SwiftUI

/// Zeigt die Zeitumrechnung für ein Event in einer bestimmten Stadt
struct CityTimeRowView: View {
    
    // MARK: - Properties
    
    let event: Event
    let city: FavoriteCity
    
    private let timezoneService = TimezoneService.shared
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // City Header
            cityHeader
            
            Divider()
            
            // Time Conversion
            if let cityTimezone = city.timeZone {
                timeConversionContent(cityTimezone: cityTimezone)
            } else {
                timezoneErrorView
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - City Header

    private var cityHeader: some View {
        HStack(spacing: 12) {
            // Flag/Icon - Compact with liquid glass
            if !flagOrIcon.isEmpty {
                Text(flagOrIcon)
                    .font(.system(size: 32))
                    .frame(width: 40, height: 40)
            } else {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: Color.systemBlue.opacity(0.2), radius: 3, x: 0, y: 1)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(city.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)

                // Compact single-line info
                HStack(spacing: 4) {
                    if let country = countryName {
                        Text(country)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text("•")
                            .font(.system(size: 11))
                            .foregroundStyle(.quaternary)
                    }

                    Text(continent)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("•")
                        .font(.system(size: 11))
                        .foregroundStyle(.quaternary)

                    Text(city.abbreviatedTimeZone)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("•")
                        .font(.system(size: 11))
                        .foregroundStyle(.quaternary)

                    Text(city.formattedUTCOffset)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.systemBlue)
                        .lineLimit(1)
                }
                .lineLimit(1)
                .truncationMode(.tail)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Helper Properties

    private var flagOrIcon: String {
        if let country = CityDisplayHelpers.extractCountry(from: city.fullName),
           let flag = CityDisplayHelpers.flagEmoji(for: country) {
            return flag
        }
        return ""
    }

    private var continent: String {
        CityDisplayHelpers.continent(from: city.timeZoneIdentifier)
    }

    private var countryName: String? {
        CityDisplayHelpers.countryName(from: city.fullName)
    }

    // MARK: - Time Conversion Content
    
    private func timeConversionContent(cityTimezone: TimeZone) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if event.isGlobalTime {
                // Location-specific event: Both times are converted normally from UTC
                TimeInfoBlock(
                    icon: "building.2.fill",
                    label: String(format: String(localized: "city_time.event_time_in"), city.name),
                    time: timezoneService.formatTimeRange(
                        startDate: event.startTime,
                        endDate: event.endTime,
                        timezone: cityTimezone,
                        includeDate: true
                    ),
                    color: Color.systemBlue
                )
                
                // Arrow
                HStack {
                    Spacer()
                    Image(systemName: "arrow.down")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.vertical, 4)
                
                TimeInfoBlock(
                    icon: "person.fill",
                    label: String(localized: "city_time.your_local_time"),
                    time: timezoneService.formatTimeRange(
                        startDate: event.startTime,
                        endDate: event.endTime,
                        timezone: timezoneService.userTimezone,
                        includeDate: true
                    ),
                    color: Color.systemGreen,
                    highlighted: true
                )
            } else {
                // Global event: Show same local time in city, converted time for user
                TimeInfoBlock(
                    icon: "building.2.fill",
                    label: String(format: String(localized: "city_time.event_time_in"), city.name),
                    time: timezoneService.formatEventTimeRange(
                        startDate: event.startTime,
                        endDate: event.endTime,
                        timezone: cityTimezone,
                        isGlobalTime: false,
                        includeDate: true
                    ),
                    color: Color.systemBlue
                )
                
                // Arrow
                HStack {
                    Spacer()
                    Image(systemName: "arrow.down")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.vertical, 4)
                
                TimeInfoBlock(
                    icon: "person.fill",
                    label: String(localized: "city_time.your_local_time"),
                    time: timezoneService.formatLocalEventInUserTime(
                        startDate: event.startTime,
                        endDate: event.endTime,
                        cityTimezone: cityTimezone,
                        userTimezone: timezoneService.userTimezone,
                        includeDate: true
                    ),
                    color: Color.systemGreen,
                    highlighted: true
                )
            }
            
            // Time Difference Info
            timeDifferenceInfo(cityTimezone: cityTimezone)
        }
    }
    
    // MARK: - Time Difference Info
    
    private func timeDifferenceInfo(cityTimezone: TimeZone) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            
            Text(timezoneService.timeDifferenceDescription(
                from: timezoneService.userTimezone,
                to: cityTimezone,
                at: event.startTime
            ))
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
    
    // MARK: - Timezone Error View
    
    private var timezoneErrorView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.systemOrange)
            
            Text(String(localized: "timezone.load_failed"))
                .secondaryStyle()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.systemOrange.opacity(0.1))
        )
    }
}

// MARK: - Time Info Block

private struct TimeInfoBlock: View {
    let icon: String
    let label: String
    let time: String
    let color: Color
    var highlighted: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(time)
                    .font(.system(size: 15, weight: highlighted ? .semibold : .medium))
                    .foregroundStyle(highlighted ? color : .primary)
                    .monospacedDigit()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(highlighted ? color.opacity(0.08) : Color.systemGray.opacity(0.15))
        )
    }
}

// MARK: - Preview

#Preview {
    let previewEvent = Event(
        id: "preview-event",
        name: "Community Day: Bulbasaur",
        eventType: "community-day",
        heading: "Community Day",
        startTime: Date().addingTimeInterval(86400),
        endTime: Date().addingTimeInterval(86400 + 10800),
        isGlobalTime: false
    )
    
    let previewCity = FavoriteCity(
        name: "Tokyo",
        timeZoneIdentifier: "Asia/Tokyo",
        fullName: "Tokyo, Japan"
    )
    
    VStack {
        CityTimeRowView(event: previewEvent, city: previewCity)
            .padding(20)
    }
    .frame(width: 600, height: 400)
    .background(Color.appBackground)
}
