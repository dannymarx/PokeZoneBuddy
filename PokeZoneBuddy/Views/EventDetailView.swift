//
//  EventDetailView.swift
//  PokeZoneBuddy
//
//  Moderne Event-Detail Ansicht für macOS 26
//

import SwiftUI

struct EventDetailView: View {
    
    // MARK: - Properties
    
    let event: Event
    let favoriteCities: [FavoriteCity]
    
    private let timezoneService = TimezoneService.shared
    
    // MARK: - Body
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    // Anchor for scrolling to top
                    Color.clear
                        .frame(height: 0)
                        .id("top")
                // Event Image Header
                if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                    eventImageHeader(url: url)
                }
                
                // Event Header
                eventHeaderSection
                
                // Countdown/Status
                EventCountdownView(event: event)
                
                // Event Info Cards
                eventInfoSection
                
                // Pokemon Details (Spotlight/Raid/CD)
                pokemonDetailsSection
                
                // Time Zones Section
                if !favoriteCities.isEmpty {
                    timeZonesSection
                } else {
                    noCitiesPlaceholder
                }
                
                // Copyright Footer
                copyrightFooter
                
                    Spacer(minLength: 40)
                }
                .padding(32)
                .frame(maxWidth: 800)
            }
            .onChange(of: event.id) { _, _ in
                // Scroll to top when event changes
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.windowBackground)
    }
    
    // MARK: - Event Image Header
    
    private func eventImageHeader(url: URL) -> some View {
        CachedAsyncImage(
            url: url
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(.quaternary)
                .overlay(
                    ProgressView()
                        .controlSize(.large)
                )
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
    }
    
    // MARK: - Event Header
    
    private var eventHeaderSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Event Type Badge
            HStack {
                ModernBadge(event.eventType, icon: "tag.fill", color: .blue)
                
                if event.isCurrentlyActive {
                    ModernBadge(String(localized: "badge.live_now"), icon: "circle.fill", color: .successGreen)
                        .shimmer()
                }
                
                Spacer()
            }
            
            // Event Name
            Text(event.name)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            // Event Heading
            Text(event.heading)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
            
            // Features Row
            HStack(spacing: 12) {
                if event.hasSpawns {
                    FeatureChip(icon: "location.fill", text: String(localized: "badge.spawns"), color: .green)
                }
                
                if event.hasFieldResearchTasks {
                    FeatureChip(icon: "doc.text.fill", text: String(localized: "badge.research_tasks"), color: .purple)
                }
                
                FeatureChip(
                    icon: event.isGlobalTime ? "globe" : "location.circle",
                    text: event.isGlobalTime ? String(localized: "badge.global_event") : String(localized: "badge.local_event"),
                    color: .orange
                )
            }
            
            // LeekDuck Link
            if let link = event.link, let url = URL(string: link) {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                        Text(String(localized: "link.view_on_leekduck"))
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Pokemon Details Section
    
    @ViewBuilder
    private var pokemonDetailsSection: some View {
        // Spotlight Hour Details
        if let spotlightDetails = event.spotlightDetails {
            SpotlightHourDetailView(details: spotlightDetails)
        }
        
        // Raid Battle Details
        if let raidDetails = event.raidDetails {
            RaidBattleDetailView(details: raidDetails)
        }
        
        // Community Day Details
        if let cdDetails = event.communityDayDetails {
            CommunityDayDetailView(details: cdDetails)
        }
    }
    
    // MARK: - Event Info Section
    
    private var eventInfoSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Duration Card
                InfoCard(
                    icon: "timer",
                    title: String(localized: "info.duration"),
                    value: event.formattedDuration,
                    color: .blue
                )
                
                // Status Card
                InfoCard(
                    icon: statusIcon,
                    title: String(localized: "info.status"),
                    value: statusText,
                    color: statusColor
                )
            }
            
            HStack(spacing: 16) {
                // Start Time Card
                InfoCard(
                    icon: "play.circle.fill",
                    title: String(localized: "info.start"),
                    value: timezoneService.formatDateForUser(event.startTime, includeDate: false),
                    color: .green
                )
                
                // End Time Card
                InfoCard(
                    icon: "stop.circle.fill",
                    title: String(localized: "info.end"),
                    value: timezoneService.formatDateForUser(event.endTime, includeDate: false),
                    color: .red
                )
            }
            
            // Full Date Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                    
                    Text(String(localized: "info.date"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.5)
                }
                
                Text(timezoneService.formatDateForUser(event.startTime, includeDate: true))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.quaternary.opacity(0.3))
            )
        }
    }
    
    // MARK: - Time Zones Section
    
    private var timeZonesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "timezones.title"))
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(String(localized: "timezones.subtitle"))
                .secondaryStyle()
            
            VStack(spacing: 12) {
                ForEach(favoriteCities) { city in
                    CityTimeCard(event: event, city: city)
                }
            }
        }
    }
    
    // MARK: - No Cities Placeholder
    
    private var noCitiesPlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle")
                .font(.system(size: 56))
                .foregroundStyle(.quaternary)
            
            VStack(spacing: 8) {
                Text(String(localized: "placeholder.no_cities_added.title"))
                    .font(.system(size: 18, weight: .semibold))
                
                Text(String(localized: "placeholder.no_cities_added.subtitle"))
                    .secondaryStyle()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.quaternary.opacity(0.2))
        )
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        if event.isCurrentlyActive {
            return "play.circle.fill"
        } else if event.isUpcoming {
            return "clock.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    private var statusText: String {
        if event.isCurrentlyActive {
            return String(localized: "status.live_now")
        } else if event.isUpcoming {
            return String(localized: "status.upcoming")
        } else {
            return String(localized: "status.ended")
        }
    }
    
    private var statusColor: Color {
        if event.isCurrentlyActive {
            return .successGreen
        } else if event.isUpcoming {
            return .warningOrange
        } else {
            return .secondary
        }
    }
    
    // MARK: - Copyright Footer
    
    private var copyrightFooter: some View {
        VStack(spacing: 8) {
            Text(Constants.Legal.footerText)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            
            Text(Constants.Credits.fullCredit)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
}

// MARK: - Feature Chip

private struct FeatureChip: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
        .foregroundStyle(color)
    }
}

// MARK: - Info Card

private struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - City Time Card

private struct CityTimeCard: View {
    let event: Event
    let city: FavoriteCity
    
    private let timezoneService = TimezoneService.shared

    // Helper: Reinterpret a Date to another timezone, keeping the wall-clock components identical
    private func relocalizeKeepingWallTime(_ date: Date, from: TimeZone, to: TimeZone) -> Date {
        var sourceCal = Calendar(identifier: .gregorian)
        sourceCal.timeZone = from
        let comps = sourceCal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        var targetCal = Calendar(identifier: .gregorian)
        targetCal.timeZone = to
        return targetCal.date(from: comps) ?? date
    }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // City Header
            HStack(spacing: 12) {
                Text(city.name)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            
            Divider()
            
            // Time Information
            if let cityTimezone = city.timeZone {
                VStack(alignment: .leading, spacing: 12) {
                    let userTZ = timezoneService.userTimezone
                    let cityStart = relocalizeKeepingWallTime(event.startTime, from: userTZ, to: cityTimezone)
                    let cityEnd = relocalizeKeepingWallTime(event.endTime, from: userTZ, to: cityTimezone)

                    // Event Time in City (use city timezone, but wall time as local event time)
                    TimeInfoRow(
                        icon: "building.2.fill",
                        label: String(format: String(localized: "city_time.event_time_in"), city.name),
                        time: timezoneService.formatTimeRange(
                            startDate: cityStart,
                            endDate: cityEnd,
                            timezone: cityTimezone,
                            includeDate: true
                        )
                    )
                    
                    // Your Time (use user timezone, but wall time as local event time)
                    TimeInfoRow(
                        icon: "person.fill",
                        label: String(localized: "city_time.your_local_time"),
                        time: timezoneService.formatTimeRange(
                            startDate: cityStart,
                            endDate: cityEnd,
                            timezone: userTZ,
                            includeDate: true
                        ),
                        highlighted: true
                    )
                    
                    // Time Difference
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                        
                        Text(timezoneService.timeDifferenceDescription(
                            from: cityTimezone,
                            to: timezoneService.userTimezone,
                            at: event.startTime
                        ))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Time Info Row

private struct TimeInfoRow: View {
    let icon: String
    let label: String
    let time: String
    var highlighted: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(highlighted ? .blue : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(time)
                    .font(.system(size: 15, weight: highlighted ? .semibold : .medium))
                    .foregroundStyle(highlighted ? .blue : .primary)
                    .monospacedDigit()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(highlighted ? Color.blue.opacity(0.08) : Color.clear)
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
        link: "https://leekduck.com/events/example",
        startTime: Date().addingTimeInterval(86400),
        endTime: Date().addingTimeInterval(86400 + 10800),
        isGlobalTime: false,
        imageURL: nil,
        hasSpawns: true,
        hasFieldResearchTasks: true
    )
    
    let previewCities = [
        FavoriteCity(
            name: "Tokyo",
            timeZoneIdentifier: "Asia/Tokyo",
            fullName: "Tokyo, Japan"
        ),
        FavoriteCity(
            name: "New York",
            timeZoneIdentifier: "America/New_York",
            fullName: "New York, USA"
        )
    ]
    
    return NavigationStack {
        EventDetailView(
            event: previewEvent,
            favoriteCities: previewCities
        )
    }
    .frame(width: 900, height: 700)
}

