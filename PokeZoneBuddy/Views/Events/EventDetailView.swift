//
//  EventDetailView.swift
//  PokeZoneBuddy
//
//  Moderne Event-Detail Ansicht für macOS 26
//  Version 0.4 - URLCache + AsyncImage
//

import SwiftUI

struct EventDetailView: View {
    
    // MARK: - Properties
    
    let event: Event
    let favoriteCities: [FavoriteCity]
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private let timezoneService = TimezoneService.shared
    
    // MARK: - Body
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: contentAlignment, spacing: contentSpacing) {
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

                    // Multi-city Timeline (single-day events)
                    if shouldShowTimeline {
                        EventTimelineView(
                            event: event,
                            favoriteCities: favoriteCities
                        )
                        .transition(.opacity.combined(with: .scale))
                    }

                    // Event Reminder Settings
                    if event.isUpcoming {
                        EventReminderDetailView(event: event)
                    }

                    // Time Zones Section
                    if !favoriteCities.isEmpty {
                        timeZonesSection
                    } else {
                        noCitiesPlaceholder
                    }
                    
                    // Copyright Footer
                    copyrightFooter
                    
                    Spacer(minLength: usesCompactLayout ? 24 : 40)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .frame(
                    maxWidth: maxContentWidth ?? .infinity,
                    alignment: usesCompactLayout ? .leading : .center
                )
            }
            .scrollIndicators(.hidden, axes: .vertical)
            .hideScrollIndicatorsCompat()
            .onChange(of: event.id) { _, _ in
                // Scroll to top when event changes
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
    
    // MARK: - Event Image Header
    
    private func eventImageHeader(url: URL) -> some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.05))
                    )
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            case .failure, .empty:
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.quaternary.opacity(0.4))
                    
                    ProgressView()
                        .controlSize(.large)
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
            @unknown default:
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.quaternary.opacity(0.4))
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
            }
        }
    }
    
    // MARK: - Event Header
    
    private var eventHeaderSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Event Type Badge with Liquid Glass
            HStack {
                ModernBadge(event.eventType, icon: "tag.fill", color: Color.systemBlue)
                    .liquidGlassBadge(color: Color.systemBlue)

                if event.isCurrentlyActive {
                    ModernBadge(String(localized: "badge.live_now"), icon: "circle.fill", color: Color.systemGreen)
                        .liquidGlassBadge(color: Color.systemGreen)
                        .liquidGlassAnimated()
                }

                Spacer()

                // Favorite Button with enhanced icon
                FavoriteButton(eventID: event.id)
                    .font(.system(size: 24))
                    .symbolRenderingMode(.hierarchical)
            }
            
            // Event Name
            Text(event.displayName)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            // Event Heading
            Text(event.displayHeading)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // Features Row
            if !featureChipItems.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: chipMinimumWidth), spacing: 12)],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(featureChipItems) { chip in
                        FeatureChip(
                            icon: chip.icon,
                            text: chip.text,
                            color: chip.color
                        )
                        .liquidGlassBadge(color: chip.color)
                    }
                }
            }
            
            // LeekDuck Link
            if let link = event.link, let url = URL(string: link) {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                        Text(String(localized: "link.view_on_leekduck"))
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.systemBlue)
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
            infoRowLayout {
                InfoCard(
                    icon: "timer",
                    title: String(localized: "info.duration"),
                    value: event.formattedDuration,
                    color: Color.systemBlue
                )
                
                InfoCard(
                    icon: statusIcon,
                    title: String(localized: "info.status"),
                    value: statusText,
                    color: statusColor
                )
            }
            
            infoRowLayout {
                InfoCard(
                    icon: "play.circle.fill",
                    title: String(localized: "info.start"),
                    value: formatEventTime(event.startTime),
                    color: Color.systemGreen
                )
                
                InfoCard(
                    icon: "stop.circle.fill",
                    title: String(localized: "info.end"),
                    value: formatEventTime(event.endTime),
                    color: Color.systemRed
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
                
                Text(formatEventDateTime(event.startTime))
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
    
    @ViewBuilder
    private func infoRowLayout<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if usesCompactLayout {
            VStack(spacing: 16, content: content)
        } else {
            HStack(spacing: 16, content: content)
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
        VStack(spacing: 24) {
            Image(systemName: "map.circle")
                .font(.system(size: 64))
                .foregroundStyle(.quaternary)

            VStack(spacing: 8) {
                Text(String(localized: "placeholder.no_cities_added.title"))
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)

                Text(String(localized: "placeholder.no_cities_added.subtitle"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .padding(usesCompactLayout ? 24 : 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.quaternary.opacity(0.2))
        )
    }
    
    // MARK: - Computed Properties
    
    private var usesCompactLayout: Bool {
#if os(iOS)
        if dynamicTypeSize.isAccessibilitySize {
            return true
        }
        if let horizontalSizeClass {
            return horizontalSizeClass == .compact
        }
        return true
#else
        dynamicTypeSize.isAccessibilitySize
#endif
    }
    
    private var horizontalPadding: CGFloat {
        usesCompactLayout ? 20 : 32
    }
    
    private var verticalPadding: CGFloat {
        usesCompactLayout ? 24 : 32
    }
    
    private var contentSpacing: CGFloat {
        usesCompactLayout ? 20 : 24
    }
    
    private var contentAlignment: HorizontalAlignment {
        usesCompactLayout ? .leading : .center
    }
    
    private var maxContentWidth: CGFloat? { nil }
    
    private var chipMinimumWidth: CGFloat {
        usesCompactLayout ? 120 : 160
    }
    
    private var featureChipItems: [FeatureChipItem] {
        var items: [FeatureChipItem] = []
        
        if event.hasSpawns {
            items.append(
                FeatureChipItem(
                    id: "spawns",
                    icon: "location.fill",
                    text: String(localized: "badge.spawns"),
                    color: Color.systemGreen
                )
            )
        }
        
        if event.hasFieldResearchTasks {
            items.append(
                FeatureChipItem(
                    id: "research",
                    icon: "doc.text.fill",
                    text: String(localized: "badge.research_tasks"),
                    color: Color.systemPurple
                )
            )
        }
        
        items.append(
            FeatureChipItem(
                id: event.isGlobalTime ? "local_event" : "global_event",
                icon: event.isGlobalTime ? "location.circle" : "globe",
                text: event.isGlobalTime ? String(localized: "badge.local_event") : String(localized: "badge.global_event"),
                color: Color.systemOrange
            )
        )
        
        return items
    }
    
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
            return .systemGreen
        } else if event.isUpcoming {
            return .systemOrange
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
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 20)
    }
    
    // MARK: - Helper Methods
    
    /// Formats event time (shows UTC time components without conversion)
    private func formatEventTime(_ date: Date) -> String {
        let tz = TimeZone(secondsFromGMT: 0) ?? .gmt
        return TimezoneService.shared.format(date, style: .time, in: tz)
    }
    
    /// Formats event date and time (shows UTC components without conversion)
    private func formatEventDateTime(_ date: Date) -> String {
        let tz = TimeZone(secondsFromGMT: 0) ?? .gmt
        return TimezoneService.shared.format(date, style: .dateTime, in: tz)
    }
    
    private var shouldShowTimeline: Bool {
        guard isSingleDayEvent else { return false }
        return favoriteCities.filter { $0.timeZone != nil }.count >= 2
    }
    
    private var isSingleDayEvent: Bool {
        guard event.endTime > event.startTime else { return false }
        
        let utc = TimeZone(secondsFromGMT: 0) ?? .gmt
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        
        guard calendar.isDate(event.startTime, inSameDayAs: event.endTime) else {
            return false
        }
        
        let duration = event.endTime.timeIntervalSince(event.startTime)
        return duration <= 86_400
    }
}

// MARK: - Feature Chip

private struct FeatureChipItem: Identifiable {
    let id: String
    let icon: String
    let text: String
    let color: Color
}

// MARK: - City Time Card

private struct CityTimeCard: View {
    let event: Event
    let city: FavoriteCity
    
    private let timezoneService = TimezoneService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // City Header
            HStack(spacing: 12) {
                Text(city.name)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            
            Divider()
            
            // Time Information - Only show "Your Local Time"
            if let cityTimezone = city.timeZone {
                VStack(alignment: .leading, spacing: 12) {
                    if event.isGlobalTime {
                        // Location-specific event: Convert normally from UTC
                        ImprovedTimeDisplay(
                            startDate: event.startTime,
                            endDate: event.endTime,
                            timezone: timezoneService.userTimezone
                        )
                    } else {
                        // Global event: Convert from city timezone to user timezone
                        let absoluteStart = timezoneService.convertLocalEventTime(
                            event.startTime,
                            from: cityTimezone,
                            to: timezoneService.userTimezone
                        )
                        let absoluteEnd = timezoneService.convertLocalEventTime(
                            event.endTime,
                            from: cityTimezone,
                            to: timezoneService.userTimezone
                        )
                        
                        ImprovedTimeDisplay(
                            startDate: absoluteStart,
                            endDate: absoluteEnd,
                            timezone: timezoneService.userTimezone
                        )
                    }
                    
                    // Time Difference
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
                    
                    // Add to Calendar Button (macOS only)
                    #if os(macOS)
                    Divider()
                        .padding(.vertical, 8)
                    
                    AddToCalendarButton(event: event, city: city)
                        .frame(maxWidth: .infinity)
                    #endif
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .systemBlue.opacity(0.2),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.systemBlue.opacity(0.12), radius: 12, x: 0, y: 4)
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
                .foregroundStyle(highlighted ? Color.systemBlue : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(time)
                    .font(.system(size: 15, weight: highlighted ? .semibold : .medium))
                    .foregroundStyle(highlighted ? Color.systemBlue : .primary)
                    .monospacedDigit()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(highlighted ? Color.systemBlue.opacity(0.08) : Color.clear)
        )
    }
}

// MARK: - Improved Time Display

private struct ImprovedTimeDisplay: View {
    let startDate: Date
    let endDate: Date
    let timezone: TimeZone
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = timezone
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.timeZone = timezone
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }
    
    private var timeString: String {
        let start = timeFormatter.string(from: startDate)
        let end = timeFormatter.string(from: endDate)
        return "\(start) - \(end)"
    }
    
    private var dateString: String {
        dateFormatter.string(from: startDate)
    }
    
    private var timezoneString: String {
        timezone.abbreviation() ?? timezone.identifier
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(Color.systemBlue)
                    .imageScale(.small)
                Text(String(localized: "city_time.your_local_time"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // TIME - Most prominent
            Text(timeString)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.systemBlue)
                .monospacedDigit()
            
            // DATE - Secondary
            HStack(spacing: 4) {
                Text(dateString)
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                Text("•")
                    .foregroundStyle(.tertiary)
                
                Text(timezoneString)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.systemBlue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
