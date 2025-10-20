//
//  EventTimelineView.swift
//  PokeZoneBuddy
//
//  Sequential event planning timeline for multi-city event participation.
//  Shows chronological event times across cities with travel gaps.
//

import SwiftUI

struct EventTimelineView: View {
    let event: Event
    let favoriteCities: [FavoriteCity]
    let plannerMenu: AnyView?

    private let timezoneService = TimezoneService.shared

    init(event: Event, favoriteCities: [FavoriteCity], plannerMenu: AnyView? = nil) {
        self.event = event
        self.favoriteCities = favoriteCities
        self.plannerMenu = plannerMenu
    }

    var body: some View {
        if let timeline = buildSequentialTimeline() {
            SequentialTimelineView(
                timeline: timeline,
                event: event,
                cities: favoriteCities,
                plannerMenu: plannerMenu
            )
        } else {
            TimelineEmptyState()
        }
    }

    // MARK: - Timeline Builder

    private func buildSequentialTimeline() -> SequentialTimeline? {
        guard !favoriteCities.isEmpty else { return nil }

        let userTimezone = timezoneService.userTimezone

        // Build city entries with converted times
        let cityEntries: [CityTimeEntry] = favoriteCities.compactMap { city -> CityTimeEntry? in
            guard let timezone = city.timeZone else { return nil }
            let converted = convertEventTimes(for: city, timezone: timezone, userTimezone: userTimezone)
            guard converted.end > converted.start else { return nil }

            return CityTimeEntry(
                id: "\(city.timeZoneIdentifier)-\(converted.start.timeIntervalSince1970)",
                cityName: city.displayName,
                startTime: converted.start,
                endTime: converted.end,
                timezone: userTimezone,
                color: Color.randomElement(for: city.timeZoneIdentifier)
            )
        }

        guard !cityEntries.isEmpty else { return nil }

        // Sort by start time (chronological order)
        let sortedEntries = cityEntries.sorted { $0.startTime < $1.startTime }

        // Build timeline items (events + gaps)
        var items: [TimelineItem] = []

        for (index, entry) in sortedEntries.enumerated() {
            // Add the event
            items.append(.event(entry))

            // Add gap if there's a next event
            if index < sortedEntries.count - 1 {
                let nextEntry = sortedEntries[index + 1]
                let gap = TimeGap(
                    id: "gap-\(index)",
                    startTime: entry.endTime,
                    endTime: nextEntry.startTime,
                    timezone: userTimezone
                )
                items.append(.gap(gap))
            }
        }

        guard let firstStart = sortedEntries.first?.startTime,
              let lastEnd = sortedEntries.last?.endTime else { return nil }

        return SequentialTimeline(
            items: items,
            totalStart: firstStart,
            totalEnd: lastEnd,
            timezone: userTimezone
        )
    }

    private func convertEventTimes(
        for city: FavoriteCity,
        timezone: TimeZone,
        userTimezone: TimeZone
    ) -> DateInterval {
        if event.isGlobalTime {
            return DateInterval(start: event.startTime, end: event.endTime)
        } else {
            let start = timezoneService.convertLocalEventTime(event.startTime, from: timezone, to: userTimezone)
            let end = timezoneService.convertLocalEventTime(event.endTime, from: timezone, to: userTimezone)
            return DateInterval(start: start, end: end)
        }
    }
}

// MARK: - Sequential Timeline View

private struct SequentialTimelineView: View {
    let timeline: SequentialTimeline
    let event: Event
    let cities: [FavoriteCity]
    let plannerMenu: AnyView?

    private var totalInterval: TimeInterval {
        timeline.totalEnd.timeIntervalSince(timeline.totalStart)
    }

    private var playInterval: TimeInterval {
        timeline.items.reduce(0) { partialResult, item in
            guard case .event(let entry) = item else {
                return partialResult
            }
            return partialResult + entry.endTime.timeIntervalSince(entry.startTime)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.systemBlue)

                Text(String(localized: "timeline.planning.title"))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                if let plannerMenu {
                    plannerMenu
                }

                DurationBadge(
                    totalInterval: totalInterval,
                    playInterval: playInterval
                )
            }

            Text(String(localized: "timeline.planning.subtitle"))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Timeline graph
            VStack(spacing: 0) {
                ForEach(Array(timeline.items.enumerated()), id: \.offset) { index, item in
                    switch item {
                    case .event(let entry):
                        EventSegmentView(entry: entry, isFirst: index == 0)
                    case .gap(let gap):
                        GapSegmentView(gap: gap)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

// MARK: - Event Segment View

private struct EventSegmentView: View {
    let entry: CityTimeEntry
    let isFirst: Bool

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = entry.timezone
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }

    private var startTime: String {
        timeFormatter.string(from: entry.startTime)
    }

    private var endTime: String {
        timeFormatter.string(from: entry.endTime)
    }

    private var duration: String {
        let interval = entry.endTime.timeIntervalSince(entry.startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return String(localized: "timeline.duration.hours_minutes \(hours) \(minutes)")
        } else if hours > 0 {
            return String(localized: "timeline.duration.hours \(hours)")
        } else {
            return String(localized: "timeline.duration.minutes \(minutes)")
        }
    }

    private var timezoneAbbr: String {
        entry.timezone.abbreviation(for: entry.startTime)
            ?? entry.timezone.abbreviation()
            ?? entry.timezone.identifier
    }

    var body: some View {
        VStack(spacing: 0) {
            // Connection line from previous segment
            if !isFirst {
                Rectangle()
                    .fill(entry.color.opacity(0.3))
                    .frame(width: 3, height: 12)
            }

            // Event card
            HStack(spacing: 16) {
                // Left accent line
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [entry.color, entry.color.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 12) {
                    // City name
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(entry.color)

                        Text(entry.cityName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)

                        Spacer()
                    }

                    // Time info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)

                            Text("\(startTime) - \(endTime) \(timezoneAbbr)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                                .monospacedDigit()
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "timer")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)

                            Text(duration)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(entry.color.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(entry.color.opacity(0.3), lineWidth: 1.5)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Gap Segment View

private struct GapSegmentView: View {
    let gap: TimeGap

    private var gapInterval: TimeInterval {
        gap.endTime.timeIntervalSince(gap.startTime)
    }

    private var duration: String {
        let interval = gapInterval
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if interval <= 0 {
            return String(localized: "timeline.gap.none")
        } else if hours > 0 && minutes > 0 {
            return String(localized: "timeline.gap.hours_minutes \(hours) \(minutes)")
        } else if hours > 0 {
            return String(localized: "timeline.gap.hours \(hours)")
        } else {
            return String(localized: "timeline.gap.minutes \(minutes)")
        }
    }

    private var isNegative: Bool {
        gap.endTime <= gap.startTime
    }

    private var isCooldownRisk: Bool {
        guard !isNegative else { return false }
        return gapInterval > 0 && gapInterval < 7_200
    }

    private var capsuleFillColor: Color {
        if isNegative {
            return Color.systemRed.opacity(0.1)
        } else if isCooldownRisk {
            return Color.systemOrange.opacity(0.12)
        }
        return Color.primary.opacity(0.04)
    }

    private var capsuleStrokeColor: Color {
        if isNegative {
            return Color.systemRed.opacity(0.2)
        } else if isCooldownRisk {
            return Color.systemOrange.opacity(0.25)
        }
        return Color.primary.opacity(0.08)
    }

    private var indicatorColor: Color {
        if isNegative {
            return Color.systemRed
        } else if isCooldownRisk {
            return Color.systemOrange
        }
        return Color.secondary
    }

    private var cooldownWarningView: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.systemOrange)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "timeline.gap.cooldown_warning.title"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.systemOrange)

                Text(String(localized: "timeline.gap.cooldown_warning.detail"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.systemOrange.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Dashed connection line
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .fill(indicatorColor.opacity(isNegative ? 0.3 : 0.2))
                .frame(width: 3, height: 24)

            // Gap indicator
            VStack(spacing: isCooldownRisk ? 8 : 0) {
                HStack(spacing: 10) {
                    Image(systemName: isNegative ? "exclamationmark.triangle.fill" : "arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(indicatorColor)

                    Text(isNegative ? String(localized: "timeline.gap.overlap") : duration)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(indicatorColor)
                }

                if isCooldownRisk {
                    cooldownWarningView
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, isCooldownRisk ? 12 : 8)
            .background(
                Capsule()
                    .fill(capsuleFillColor)
            )
            .overlay(
                Capsule()
                    .strokeBorder(capsuleStrokeColor, lineWidth: 1)
            )
            .padding(.horizontal, 16)

            // Continuation line
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .fill(indicatorColor.opacity(isNegative ? 0.3 : 0.2))
                .frame(width: 3, height: 24)
        }
    }
}

// MARK: - Duration Badge

private struct DurationBadge: View {
    let totalInterval: TimeInterval
    let playInterval: TimeInterval

    private var totalLabel: String {
        localized("timeline.badge.total", fallback: "Total")
    }

    private var playLabel: String {
        localized("timeline.badge.play", fallback: "Playing")
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return String(localized: "timeline.total.hours_minutes \(hours) \(minutes)")
        } else if hours > 0 {
            return String(localized: "timeline.total.hours \(hours)")
        } else {
            return String(localized: "timeline.total.minutes \(minutes)")
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            MetricCapsule(
                icon: "clock.badge.checkmark.fill",
                tint: Color.systemGreen,
                title: totalLabel,
                value: formattedDuration(totalInterval)
            )

            MetricCapsule(
                icon: "gamecontroller.fill",
                tint: Color.systemBlue,
                title: playLabel,
                value: formattedDuration(playInterval)
            )
        }
    }

    private func localized(_ key: String, fallback: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: .main, value: fallback, comment: "")
    }
}

private struct MetricCapsule: View {
    let icon: String
    let tint: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(tint.opacity(0.12))
        )
        .overlay(
            Capsule()
                .strokeBorder(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Dashed Line Shape

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

// MARK: - Empty State

private struct TimelineEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.circle")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)

            Text(String(localized: "timeline.unavailable.title"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(String(localized: "timeline.unavailable.subtitle"))
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}

// MARK: - Supporting Models

private struct SequentialTimeline {
    let items: [TimelineItem]
    let totalStart: Date
    let totalEnd: Date
    let timezone: TimeZone
}

private enum TimelineItem {
    case event(CityTimeEntry)
    case gap(TimeGap)
}

private struct CityTimeEntry: Identifiable {
    let id: String
    let cityName: String
    let startTime: Date
    let endTime: Date
    let timezone: TimeZone
    let color: Color
}

private struct TimeGap: Identifiable {
    let id: String
    let startTime: Date
    let endTime: Date
    let timezone: TimeZone
}


// MARK: - Color Extension

private extension Color {
    static let palette: [Color] = [
        .systemBlue,
        .systemMint,
        .systemOrange,
        .systemPurple,
        .systemTeal,
        .systemPink,
        .systemIndigo,
        .systemCyan,
        .systemGreen,
        .systemRed
    ]

    static func randomElement(for key: String) -> Color {
        let hash = abs(key.hashValue)
        let index = hash % palette.count
        return palette[index]
    }
}
