//
//  EventTimelineView.swift
//  PokeZoneBuddy
//
//  Created for streamlined multi-city planning.
//

import SwiftUI

struct EventTimelineView: View {
    let event: Event
    let favoriteCities: [FavoriteCity]
    
    private let timezoneService = TimezoneService.shared
    
    var body: some View {
        if let layout = buildTimelineLayout() {
            TimelineLayoutView(layout: layout, timezoneService: timezoneService)
        } else {
            TimelineEmptyState()
        }
    }
    
    // MARK: - Layout Builder
    
    private func buildTimelineLayout() -> TimelineLayout? {
        guard !favoriteCities.isEmpty else { return nil }
        
        let userTimezone = timezoneService.userTimezone
        let cityRows: [TimelineCity] = favoriteCities.compactMap { city -> TimelineCity? in
            guard let timezone = city.timeZone else { return nil }
            let converted = convertEventTimes(for: city, timezone: timezone, userTimezone: userTimezone)
            guard converted.end > converted.start else { return nil }
            
            let userStart = timezoneService.format(converted.start, style: .time, in: userTimezone)
            let userTimezoneAbbr = userTimezone.abbreviation(for: converted.start)
                ?? userTimezone.abbreviation()
                ?? userTimezone.identifier
            
            return TimelineCity(
                id: "\(city.timeZoneIdentifier)-\(converted.start.timeIntervalSince1970)",
                name: city.displayName,
                start: converted.start,
                end: converted.end,
                userStartLabel: "\(userStart) \(userTimezoneAbbr)",
                color: Color.randomElement(for: city.timeZoneIdentifier)
            )
        }
        
        guard !cityRows.isEmpty else { return nil }
        
        guard
            let earliest = cityRows.map(\.start).min(),
            let latest = cityRows.map(\.end).max(),
            latest > earliest
        else { return nil }
        
        let duration = latest.timeIntervalSince(earliest)
        let padding = TimelineLayout.padding(for: duration)
        let clampedRange = DateInterval(
            start: earliest.addingTimeInterval(-padding),
            end: latest.addingTimeInterval(padding)
        )
        
        let lanes = TimelineLayout.assignLanes(for: cityRows)
        let contentWidth = TimelineLayout.width(for: clampedRange)
        let ticks = TimelineLayout.tickMarks(for: clampedRange, timezone: userTimezone)
        
        return TimelineLayout(
            range: clampedRange,
            contentWidth: contentWidth,
            tickMarks: ticks,
            axisTimezone: userTimezone,
            markers: lanes.markers,
            laneCount: lanes.maxLane + 1
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

// MARK: - Timeline Layout View

private struct TimelineLayoutView: View {
    let layout: TimelineLayout
    let timezoneService: TimezoneService
    
    private let capsuleHeight: CGFloat = 32
    private let laneSpacing: CGFloat = 18
    private let axisSpacing: CGFloat = 32
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                ZStack(alignment: .topLeading) {
                    ForEach(layout.markers) { marker in
                        CityChipView(
                            marker: marker,
                            layout: layout,
                            capsuleHeight: capsuleHeight,
                            laneSpacing: laneSpacing
                        )
                    }
                    axisView
                }
                .frame(width: layout.contentWidth, height: totalHeight, alignment: .topLeading)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 12)
        }
    }
    
    private var totalHeight: CGFloat {
        CGFloat(layout.laneCount) * (capsuleHeight + laneSpacing) + axisSpacing
    }
    
    private var axisY: CGFloat {
        CGFloat(layout.laneCount) * (capsuleHeight + laneSpacing) + 8
    }
    
    private var axisView: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.primary.opacity(0.18))
                .frame(width: layout.contentWidth, height: 1)
                .offset(y: axisY)
            
            ForEach(layout.tickMarks, id: \.timeIntervalSinceReferenceDate) { tick in
                let position = position(for: tick)
                VStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.25))
                        .frame(width: 1, height: 12)
                    Text(timezoneService.format(tick, style: .time, in: layout.axisTimezone))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .offset(x: position - 0.5, y: axisY + 4)
            }
        }
    }
    
    private func position(for date: Date) -> CGFloat {
        let progress = TimelineLayout.progress(for: date, in: layout.range)
        return CGFloat(progress) * layout.contentWidth
    }
}

// MARK: - Chip View

private struct CityChipView: View {
    let marker: TimelineMarker
    let layout: TimelineLayout
    let capsuleHeight: CGFloat
    let laneSpacing: CGFloat
    
    private var laneOffset: CGFloat {
        CGFloat(marker.lane) * (capsuleHeight + laneSpacing)
    }
    
    var body: some View {
        let startX = position(for: marker.start)
        let endX = position(for: marker.end)
        let width = CityChipView.minimumWidth(for: layout.range, contentWidth: layout.contentWidth, startX: startX, endX: endX)
        let adjustedStart = max(min(startX, layout.contentWidth - width), 0)
        
        HStack(spacing: 10) {
            Text(marker.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(marker.color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Spacer(minLength: 6)
            
            Text(marker.userStartLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: width, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(marker.color.opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(marker.color.opacity(0.35), lineWidth: 1)
        )
        .offset(x: adjustedStart, y: laneOffset)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(marker.name), \(marker.userStartLabel)")
    }
    
    private func position(for date: Date) -> CGFloat {
        let progress = TimelineLayout.progress(for: date, in: layout.range)
        return CGFloat(progress) * layout.contentWidth
    }
    
    private static func minimumWidth(for range: DateInterval, contentWidth: CGFloat, startX: CGFloat, endX: CGFloat) -> CGFloat {
        let duration = range.duration
        guard duration > 0 else { return min(160, max(contentWidth, 160)) }
        let hours = duration / 3_600
        let base: CGFloat
        switch hours {
        case ..<4: base = 240
        case ..<8: base = 200
        case ..<16: base = 160
        case ..<32: base = 140
        default: base = 120
        }
        return min(max(endX - startX, base), contentWidth)
    }
}

// MARK: - Empty State

private struct TimelineEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text(String(localized: "timeline.unavailable.title"))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}

// MARK: - Supporting Models

private struct TimelineLayout {
    let range: DateInterval
    let contentWidth: CGFloat
    let tickMarks: [Date]
    let axisTimezone: TimeZone
    let markers: [TimelineMarker]
    let laneCount: Int
    
    static func padding(for duration: TimeInterval) -> TimeInterval {
        let suggested = max(duration * 0.1, 900)
        return min(suggested, 10_800)
    }
    
    static func width(for range: DateInterval) -> CGFloat {
        let hours = max(range.duration / 3_600, 1)
        let perHour: CGFloat
        switch hours {
        case ..<2: perHour = 220
        case ..<6: perHour = 180
        case ..<12: perHour = 140
        case ..<24: perHour = 110
        case ..<36: perHour = 90
        default: perHour = 72
        }
        return min(max(CGFloat(hours) * perHour, 600), 3600)
    }
    
    static func tickMarks(for range: DateInterval, timezone: TimeZone) -> [Date] {
        let totalSeconds = range.duration
        guard totalSeconds > 0 else { return [range.start, range.end] }
        let hours = totalSeconds / 3_600
        let stepHours: Double
        switch hours {
        case ..<3: stepHours = 0.5
        case ..<8: stepHours = 1
        case ..<16: stepHours = 2
        case ..<32: stepHours = 3
        default: stepHours = max(ceil(hours / 8.0), 4)
        }
        let step = stepHours * 3_600
        var ticks: [Date] = []
        var current = floor(range.start.timeIntervalSinceReferenceDate / step) * step
        var count = 0
        while count < 80 {
            let date = Date(timeIntervalSinceReferenceDate: current)
            if date >= range.start - 60 && date <= range.end + 60 {
                ticks.append(date)
            }
            if date > range.end + step { break }
            current += step
            count += 1
        }
        if ticks.isEmpty { ticks = [range.start, range.end] }
        if let first = ticks.first, first > range.start + 60 { ticks.insert(range.start, at: 0) }
        if let last = ticks.last, last < range.end - 60 { ticks.append(range.end) }
        return ticks
    }
    
    static func progress(for date: Date, in range: DateInterval) -> Double {
        guard range.duration > 0 else { return 0 }
        let clamped = min(max(date, range.start), range.end)
        return clamped.timeIntervalSince(range.start) / range.duration
    }
    
    static func assignLanes(for cities: [TimelineCity]) -> (markers: [TimelineMarker], maxLane: Int) {
        var laneEndTimes: [Date] = []
        var markers: [TimelineMarker] = []
        var highestLane = 0
        
        for city in cities.sorted(by: { $0.start < $1.start }) {
            var assignedLane = 0
            var reused = false
            for (index, endTime) in laneEndTimes.enumerated() where city.start >= endTime {
                assignedLane = index
                laneEndTimes[index] = city.end
                reused = true
                break
            }
            if !reused {
                assignedLane = laneEndTimes.count
                laneEndTimes.append(city.end)
            }
            highestLane = max(highestLane, assignedLane)
            markers.append(
                TimelineMarker(
                    id: city.id,
                    name: city.name,
                    start: city.start,
                    end: city.end,
                    userStartLabel: city.userStartLabel,
                    color: city.color,
                    lane: assignedLane
                )
            )
        }
        return (markers, highestLane)
    }
}

private struct TimelineCity {
    let id: String
    let name: String
    let start: Date
    let end: Date
    let userStartLabel: String
    let color: Color
}

private struct TimelineMarker: Identifiable {
    let id: String
    let name: String
    let start: Date
    let end: Date
    let userStartLabel: String
    let color: Color
    let lane: Int
}

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
