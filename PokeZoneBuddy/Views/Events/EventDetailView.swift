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
    @State private var selectedCityIDs: Set<String> = []

    private var eventImageURL: URL? {
        guard let imageURL = event.imageURL else { return nil }
        return URL(string: imageURL)
    }
    
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
                    if let url = eventImageURL {
                        eventImageHeader(url: url)
                    }
                    
                    // Event Header
                    eventHeaderSection
                    
                    // Countdown/Status (fallback when no image header)
                    if eventImageURL == nil {
                        EventCountdownView(event: event)
                    }
                    
                    // Event Meta & Reminders
                    eventMetaCard
                    
                    // Pokemon Details (Spotlight/Raid/CD)
                    pokemonDetailsSection

                    // Multi-city Timeline (single-day events)
                    if shouldDisplayMultiCitySection {
                        if shouldShowTimeline(for: selectedTimelineCities) {
                            EventTimelineView(
                                event: event,
                                favoriteCities: selectedTimelineCities
                            )
                            .transition(.opacity.combined(with: .scale))
                        } else {
                            timelineSelectionPlaceholder
                        }
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
            .onAppear(perform: syncSelectedCities)
            .onChange(of: selectableCityIdentifiers) { _, _ in
                syncSelectedCities()
            }
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
        .overlay { countdownOverlay() }
    }

    private func countdownOverlay() -> some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                EventCountdownView(event: event)
                    .frame(width: min(geometry.size.width * 0.6, 420))
                    .padding(.bottom, 12)
                    .shadow(color: Color.black.opacity(0.18), radius: 14, y: 6)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
            .allowsHitTesting(false)
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
    
    // MARK: - Event Meta Card

    private var eventMetaCard: some View {
        VStack(spacing: 0) {
            LazyVGrid(
                columns: metaColumns,
                alignment: .leading,
                spacing: usesCompactLayout ? 12 : 16
            ) {
                ForEach(eventMetaItems) { item in
                    EventMetaCell(item: item)
                }

                if event.isUpcoming {
                    reminderTile
                        .gridCellColumns(metaColumnCount)
                        .padding(.top, usesCompactLayout ? 4 : 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    private var reminderTile: some View {
        EventReminderDetailView(event: event, layout: .embedded)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, usesCompactLayout ? 0 : 4)
    }

    private var eventMetaItems: [EventMetaItem] {
        [
            EventMetaItem(
                id: "duration",
                title: String(localized: "info.duration"),
                value: event.formattedDuration
            ),
            EventMetaItem(
                id: "status",
                title: String(localized: "info.status"),
                value: statusText
            ),
            EventMetaItem(
                id: "start",
                title: String(localized: "info.start"),
                value: formatEventTime(event.startTime)
            ),
            EventMetaItem(
                id: "end",
                title: String(localized: "info.end"),
                value: formatEventTime(event.endTime)
            ),
            EventMetaItem(
                id: "date",
                title: String(localized: "info.date"),
                value: formatEventDateTime(event.startTime)
            )
        ]
    }

    private var metaColumns: [GridItem] {
        if usesCompactLayout {
            return [GridItem(.flexible())]
        } else {
            return [
                GridItem(.flexible(), spacing: 24),
                GridItem(.flexible(), spacing: 24)
            ]
        }
    }

    private var metaColumnCount: Int {
        usesCompactLayout ? 1 : 2
    }
    
    // MARK: - Time Zones Section

    private var timeZonesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(String(localized: "timezones.title"))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                if shouldDisplayMultiCitySection && !selectedCityIDs.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCityIDs.removeAll()
                        }
                    } label: {
                        Label(
                            String(localized: "timeline.selection.deselect_all"),
                            systemImage: "xmark.circle.fill"
                        )
                        .font(.system(size: 13, weight: .semibold))
                        .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "timeline.selection.deselect_all"))
                }
            }

            Text(String(localized: "timezones.subtitle"))
                .secondaryStyle()

            // Adaptive grid layout
            LazyVGrid(
                columns: gridColumns,
                alignment: .leading,
                spacing: 16
            ) {
                ForEach(favoriteCities) { city in
                    CityTimeCard(
                        event: event,
                        city: city,
                        selectionBinding: timelineSelectionBinding(for: city)
                    )
                }
            }
        }
    }

    // Grid column configuration - responsive to window size
    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: cardMinimumWidth, maximum: cardMaximumWidth), spacing: 16)]
    }

    private var cardMinimumWidth: CGFloat {
        usesCompactLayout ? 280 : 320
    }

    private var cardMaximumWidth: CGFloat {
        usesCompactLayout ? 400 : 480
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

    private var timelineSelectionPlaceholder: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.systemBlue)

                Text(String(localized: "timeline.planning.title"))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Text(String(localized: "timeline.planning.subtitle"))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text(String(localized: "timeline.selection.empty"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.systemBlue)
                }

                Text(String(localized: "timeline.selection.empty.helper"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
    }

    private func timelineSelectionBinding(for city: FavoriteCity) -> Binding<Bool>? {
        guard shouldDisplayMultiCitySection, city.timeZone != nil else { return nil }
        let identifier = city.timeZoneIdentifier
        return Binding(
            get: { selectedCityIDs.contains(identifier) },
            set: { isSelected in
                setCitySelection(city, isSelected: isSelected)
            }
        )
    }

    private func setCitySelection(_ city: FavoriteCity, isSelected: Bool) {
        guard city.timeZone != nil else { return }
        let identifier = city.timeZoneIdentifier
        if isSelected {
            selectedCityIDs.insert(identifier)
        } else {
            guard selectedCityIDs.contains(identifier) else { return }
            var newSelection = selectedCityIDs
            newSelection.remove(identifier)
            selectedCityIDs = newSelection
        }
    }

    private var maxContentWidth: CGFloat? { nil }

    private var selectableCities: [FavoriteCity] {
        favoriteCities.filter { $0.timeZone != nil }
    }
    
    private var selectableCityIdentifiers: [String] {
        selectableCities.map { $0.timeZoneIdentifier }.sorted()
    }
    
    private var selectedTimelineCities: [FavoriteCity] {
        let ids = selectedCityIDs
        return selectableCities.filter { ids.contains($0.timeZoneIdentifier) }
    }

    private var shouldDisplayMultiCitySection: Bool {
        isSingleDayEvent && !selectableCities.isEmpty
    }
    
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
    
    private func shouldShowTimeline(for cities: [FavoriteCity]) -> Bool {
        guard isSingleDayEvent else { return false }
        return !cities.isEmpty
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

    private func syncSelectedCities() {
        guard shouldDisplayMultiCitySection else {
            selectedCityIDs = []
            return
        }
        let validIDs = Set(selectableCities.map { $0.timeZoneIdentifier })
        if validIDs.isEmpty {
            selectedCityIDs = []
        } else {
            selectedCityIDs = selectedCityIDs.intersection(validIDs)
        }
    }
}

// MARK: - Event Meta

private struct EventMetaItem: Identifiable {
    let id: String
    let title: String
    let value: String
}

private struct EventMetaCell: View {
    let item: EventMetaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)

            Text(item.value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Feature Chip

private struct FeatureChipItem: Identifiable {
    let id: String
    let icon: String
    let text: String
    let color: Color
}

// MARK: - City Time Card (Compact Grid Version)

private struct CityTimeCard: View {
    let event: Event
    let city: FavoriteCity
    let selectionBinding: Binding<Bool>?

    private let timezoneService = TimezoneService.shared

    init(event: Event, city: FavoriteCity, selectionBinding: Binding<Bool>? = nil) {
        self.event = event
        self.city = city
        self.selectionBinding = selectionBinding
    }

    private var isSelected: Bool {
        selectionBinding?.wrappedValue ?? false
    }

    private var selectionStrokeStyle: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.systemBlue.opacity(0.45))
        }
        return AnyShapeStyle(Color.primary.opacity(0.1))
    }

    private var selectionShadow: Color {
        isSelected ? Color.systemBlue.opacity(0.15) : Color.black.opacity(0.05)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Compact Header
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? Color.systemBlue : .secondary)

                Text(city.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                Spacer(minLength: 4)

                if let selectionBinding {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectionBinding.wrappedValue.toggle()
                        }
                    } label: {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.systemBlue : Color.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        String(
                            format: String(
                                localized: isSelected
                                ? "timeline.selection.accessibility.selected"
                                : "timeline.selection.accessibility.unselected"
                            ),
                            city.displayName
                        )
                    )
                }
            }

            Divider()
                .padding(.vertical, 2)

            // Compact Time Display
            if let cityTimezone = city.timeZone {
                VStack(alignment: .leading, spacing: 10) {
                    if event.isGlobalTime {
                        CompactTimeDisplay(
                            startDate: event.startTime,
                            endDate: event.endTime,
                            timezone: timezoneService.userTimezone
                        )
                    } else {
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

                        CompactTimeDisplay(
                            startDate: absoluteStart,
                            endDate: absoluteEnd,
                            timezone: timezoneService.userTimezone
                        )
                    }

                    // Compact Time Difference
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)

                        Text(timezoneService.timeDifferenceDescription(
                            from: timezoneService.userTimezone,
                            to: cityTimezone,
                            at: event.startTime
                        ))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }

                    // Add to Calendar Button (macOS only)
                    #if os(macOS)
                    Divider()
                        .padding(.vertical, 4)

                    AddToCalendarButton(event: event, city: city)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity)
                    #endif
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)

                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.systemBlue.opacity(0.08))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(selectionStrokeStyle, lineWidth: 1.5)
        )
        .shadow(color: selectionShadow, radius: 8, x: 0, y: 3)
    }
}

// MARK: - Compact Time Display

private struct CompactTimeDisplay: View {
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
        formatter.dateStyle = .medium
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
        VStack(alignment: .leading, spacing: 6) {
            // TIME - Most prominent
            Text(timeString)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.systemBlue)
                .monospacedDigit()

            // DATE - Secondary
            HStack(spacing: 4) {
                Text(dateString)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text("•")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 10))

                Text(timezoneString)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
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
