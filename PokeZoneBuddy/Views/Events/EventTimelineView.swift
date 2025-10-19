//
//  EventTimelineView.swift
//  PokeZoneBuddy
//
//  A clean, focused multi-city timeline for single-day events.
//

import SwiftUI

struct EventTimelineView: View {
    
    // MARK: - Properties
    
    let event: Event
    let favoriteCities: [FavoriteCity]
    
    private let timezoneService = TimezoneService.shared
    
    // MARK: - Body
    
    var body: some View {
        if let timeline = buildTimeline() {
            TimelineContentView(
                data: timeline,
                timezoneService: timezoneService
            )
        } else {
            EmptyTimelinePlaceholder()
        }
    }
    
    // MARK: - Timeline Construction
    
    private func buildTimeline() -> TimelineData? {
        let userTimezone = timezoneService.userTimezone
        let palette = Color.palette
        
        let cityTimelines = favoriteCities
            .sorted { $0.displayName < $1.displayName }
            .enumerated()
            .compactMap { index, city -> CityTimeline? in
                guard let timezone = city.timeZone else { return nil }
                
                let color = palette[index % palette.count]
                return buildCityTimeline(for: city, timezone: timezone, color: color, userTimezone: userTimezone)
            }
        
        guard cityTimelines.count >= 2 else { return nil }
        
        guard
            let earliestStart = cityTimelines.map(\.userInterval.start).min(),
            let latestEnd = cityTimelines.map(\.userInterval.end).max(),
            latestEnd > earliestStart
        else { return nil }
        
        let focusedRange = EventTimelineView.makeFocusedRange(start: earliestStart, end: latestEnd)
        let contentWidth = EventTimelineView.timelineWidth(for: focusedRange)
        let ticks = EventTimelineView.axisMarks(for: focusedRange, userTimezone: userTimezone)
        let laneAssignment = EventTimelineView.assignMarkers(for: cityTimelines)
        
        let headerStart = timezoneService.format(focusedRange.start, style: .dateTime, in: userTimezone)
        let headerEnd = timezoneService.format(focusedRange.end, style: .dateTime, in: userTimezone)
        let tzSummary = EventTimelineView.timezoneSummary(for: focusedRange.start, timezone: userTimezone)
        
        return TimelineData(
            range: focusedRange,
            contentWidth: contentWidth,
            tickMarks: ticks,
            summary: TimelineSummary(
                start: headerStart,
                end: headerEnd,
                timezoneDescription: tzSummary
            ),
            markers: laneAssignment.markers,
            maxLane: laneAssignment.maxLane
        )
    }
    
    private func buildCityTimeline(
        for city: FavoriteCity,
        timezone: TimeZone,
        color: Color,
        userTimezone: TimeZone
    ) -> CityTimeline? {
        let absoluteStart: Date
        let absoluteEnd: Date
        
        if event.isGlobalTime {
            absoluteStart = event.startTime
            absoluteEnd = event.endTime
        } else {
            absoluteStart = timezoneService.convertLocalEventTime(
                event.startTime,
                from: timezone,
                to: userTimezone
            )
            absoluteEnd = timezoneService.convertLocalEventTime(
                event.endTime,
                from: timezone,
                to: userTimezone
            )
        }
        
        guard absoluteEnd > absoluteStart else { return nil }
        
        let userDateString = timezoneService.format(absoluteStart, style: .date, in: userTimezone)
        let userStartString = timezoneService.format(absoluteStart, style: .time, in: userTimezone)
        let userEndString = timezoneService.format(absoluteEnd, style: .time, in: userTimezone)
        
        let cityDateString = timezoneService.format(absoluteStart, style: .date, in: timezone)
        let cityStartString = timezoneService.format(absoluteStart, style: .time, in: timezone)
        let cityEndString = timezoneService.format(absoluteEnd, style: .time, in: timezone)
        
        let userDescription = String(
            format: String(localized: "timeline.city.user_range"),
            userDateString,
            userStartString,
            userEndString
        )
        
        let cityDescription = String(
            format: String(localized: "timeline.city.local_range"),
            cityDateString,
            cityStartString,
            cityEndString
        )
        
        let offsetDescription = timezoneService.timeDifferenceDescription(
            from: userTimezone,
            to: timezone,
            at: absoluteStart
        )
        
        return CityTimeline(
            id: "\(city.timeZoneIdentifier)-\(city.displayName)",
            cityName: city.displayName,
            timezoneLabel: timezone.abbreviation() ?? timezone.identifier,
            userInterval: DateInterval(start: absoluteStart, end: absoluteEnd),
            userDescription: userDescription,
            cityDescription: cityDescription,
            offsetDescription: offsetDescription,
            color: color
        )
    }
}

// MARK: - Timeline Content View

private struct TimelineContentView: View {
    let data: TimelineData
    let timezoneService: TimezoneService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            
            TimelineScrollContainer(
                data: data,
                timezoneService: timezoneService
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .foregroundStyle(Color.systemBlue)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(String(localized: "timeline.title"))
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
            }
            
            Text(String(localized: "timeline.subtitle"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            let summaryText = String(
                format: String(localized: "timeline.local_window.summary"),
                data.summary.start,
                data.summary.end,
                data.summary.timezoneDescription
            )
            
            Text(summaryText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.systemBlue)
        }
    }
}

// MARK: - Single Timeline Track

// MARK: - Scroll Container & Timeline Track

#if os(macOS)
private struct TimelineScrollContainer: View {
    let data: TimelineData
    let timezoneService: TimezoneService
    
    @State private var offset: CGFloat = 0
    @GestureState private var drag: CGFloat = 0
    
    private let rubberBand: CGFloat = 120
    
    var body: some View {
        GeometryReader { geometry in
            let viewport = max(geometry.size.width, 1)
            let totalWidth = data.contentWidth
            let maxOffset = max(totalWidth - viewport, 0)
            
            let activeDrag = drag
            let rawOffset = clamp(offset - activeDrag, lower: -rubberBand, upper: maxOffset + rubberBand)
            let clampedOffset = clamp(rawOffset, lower: 0, upper: maxOffset)
            
            ZStack(alignment: .topLeading) {
                TimelineTrackRenderView(
                    data: data,
                    timezoneService: timezoneService
                )
                .frame(width: totalWidth)
                .offset(x: -clampedOffset)
                .accessibilityHidden(true)
            }
            .frame(width: viewport, height: TimelineTrackRenderView.totalHeight(for: data), alignment: .topLeading)
            .clipped()
            .contentShape(Rectangle())
            .overlay(alignment: .leading) {
                edgeFade(visible: clampedOffset > 4, direction: .leading)
            }
            .overlay(alignment: .trailing) {
                edgeFade(visible: clampedOffset < maxOffset - 4, direction: .trailing)
            }
            .gesture(
                DragGesture(minimumDistance: 4, coordinateSpace: .local)
                    .updating($drag) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let projected = offset - value.predictedEndTranslation.width
                        offset = clamp(projected, lower: 0, upper: maxOffset)
                    }
            )
            .overlay(
                HStack(spacing: 16) {
                    timelineButton(systemName: "chevron.left") {
                        offset = clamp(offset - viewport * 0.4, lower: 0, upper: maxOffset)
                    }
                    .opacity(maxOffset > 0 ? 1 : 0)
                    
                    Spacer()
                    
                    timelineButton(systemName: "chevron.right") {
                        offset = clamp(offset + viewport * 0.4, lower: 0, upper: maxOffset)
                    }
                    .opacity(maxOffset > 0 ? 1 : 0)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8),
                alignment: .top
            )
        }
        .frame(height: TimelineTrackRenderView.totalHeight(for: data))
        .onAppear { offset = 0 }
    }
    
    private func timelineButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .tint(.secondary.opacity(0.3))
    }
    
    private func edgeFade(visible: Bool, direction: Edge) -> some View {
        Group {
            if visible {
                LinearGradient(
                    colors: [Color.black.opacity(0.18), .clear],
                    startPoint: direction == .leading ? .leading : .trailing,
                    endPoint: direction == .leading ? .trailing : .leading
                )
                .blendMode(.plusLighter)
                .frame(width: 24)
                .allowsHitTesting(false)
            }
        }
    }
    
    private func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), upper)
    }
}
#else
private struct TimelineScrollContainer: View {
    let data: TimelineData
    let timezoneService: TimezoneService
    
    var body: some View {
        ScrollView(.horizontal) {
            TimelineTrackRenderView(
                data: data,
                timezoneService: timezoneService
            )
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
        }
        .scrollIndicators(.hidden)
    }
}
#endif

private struct TimelineTrackRenderView: View {
    let data: TimelineData
    let timezoneService: TimezoneService
    
    private static let capsuleHeight: CGFloat = 28
    private static let laneSpacing: CGFloat = 16
    private static let axisSpacing: CGFloat = 28
    private static let tickLabelOffset: CGFloat = 18
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(data.markers) { marker in
                CityMarkerChip(
                    marker: marker,
                    range: data.range,
                    contentWidth: data.contentWidth,
                    capsuleHeight: Self.capsuleHeight,
                    laneSpacing: Self.laneSpacing
                )
            }
            
            axisLayer
        }
        .frame(width: data.contentWidth, height: Self.totalHeight(for: data), alignment: .topLeading)
    }
    
    private var axisLayer: some View {
        let axisY = CGFloat(data.maxLane + 1) * (Self.capsuleHeight + Self.laneSpacing) + 8
        
        return ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.primary.opacity(0.18))
                .frame(width: data.contentWidth, height: 1)
                .offset(y: axisY)
            
            ForEach(data.tickMarks, id: \.timeIntervalSinceReferenceDate) { tick in
                let x = position(for: tick)
                
                VStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.25))
                        .frame(width: 1, height: 12)
                    
                    Text(timezoneService.format(tick, style: .time, in: timezoneService.userTimezone))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(maxWidth: 70, alignment: .center)
                }
                .offset(x: x - 0.5, y: axisY + 4)
            }
        }
    }
    
    private func position(for date: Date) -> CGFloat {
        let progress = EventTimelineView.normalizedProgress(for: date, in: data.range)
        return CGFloat(progress) * data.contentWidth
    }
    
    static func totalHeight(for data: TimelineData) -> CGFloat {
        let trackHeight = CGFloat(data.maxLane + 1) * (capsuleHeight + laneSpacing)
        return trackHeight + axisSpacing + tickLabelOffset + 32
    }
}
#if os(macOS)
#else
private struct TimelineTrackView: View {
    let data: TimelineData
    let timezoneService: TimezoneService
    
    var body: some View {
        TimelineTrackRenderView(data: data, timezoneService: timezoneService)
    }
}
#endif

private struct CityMarkerChip: View {
    let marker: CityMarker
    let range: DateInterval
    let contentWidth: CGFloat
    let capsuleHeight: CGFloat
    let laneSpacing: CGFloat
    
    private var laneOffset: CGFloat {
        CGFloat(marker.lane) * (capsuleHeight + laneSpacing)
    }
    
    var body: some View {
        let startX = position(for: marker.timeline.userInterval.start)
        let endX = position(for: marker.timeline.userInterval.end)
        let minimumWidth = CityMarkerChip.minimumWidth(for: range, contentWidth: contentWidth)
        var width = max(endX - startX, minimumWidth)
        var originX = startX
        
        if width > contentWidth {
            width = contentWidth
            originX = 0
        } else if originX + width > contentWidth {
            originX = contentWidth - width
        }
        if originX < 0 { originX = 0 }
        
        return VStack(alignment: .leading, spacing: 6) {
            Text(marker.timeline.cityName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(marker.timeline.color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Text(marker.timeline.userDescription)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .lineLimit(1)
            
            Text(marker.timeline.cityDescription)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
            
            Text(marker.timeline.offsetDescription)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: width, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(marker.timeline.color.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(marker.timeline.color.opacity(0.35), lineWidth: 1)
        )
        .offset(x: originX, y: laneOffset)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(marker.timeline.cityName). \(marker.timeline.userDescription). \(marker.timeline.cityDescription). \(marker.timeline.offsetDescription)."
        )
    }
    
    private func position(for date: Date) -> CGFloat {
        let progress = EventTimelineView.normalizedProgress(for: date, in: range)
        return CGFloat(progress) * contentWidth
    }
    
    private static func minimumWidth(for range: DateInterval, contentWidth: CGFloat) -> CGFloat {
        let hours = max(range.duration / 3_600, 0.5)
        let target: CGFloat
        switch hours {
        case ..<4: target = 160
        case ..<8: target = 120
        case ..<16: target = 100
        case ..<32: target = 84
        default: target = 64
        }
        return min(target, contentWidth)
    }
}

// MARK: - Placeholder

private struct EmptyTimelinePlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                
                Text(String(localized: "timeline.unavailable.title"))
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Text(String(localized: "timeline.unavailable.subtitle"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}

// MARK: - Data Structures

private struct TimelineData {
    let range: DateInterval
    let contentWidth: CGFloat
    let tickMarks: [Date]
    let summary: TimelineSummary
    let markers: [CityMarker]
    let maxLane: Int
}

private struct TimelineSummary {
    let start: String
    let end: String
    let timezoneDescription: String
}

private struct CityTimeline: Identifiable {
    let id: String
    let cityName: String
    let timezoneLabel: String
    let userInterval: DateInterval
    let userDescription: String
    let cityDescription: String
    let offsetDescription: String
    let color: Color
}

private struct CityMarker: Identifiable {
    let id: String
    let timeline: CityTimeline
    let lane: Int
}

// MARK: - Helper Extensions & Functions

private extension EventTimelineView {
    
    static func makeFocusedRange(start: Date, end: Date) -> DateInterval {
        let duration = end.timeIntervalSince(start)
        let padding = clampPadding(duration: duration)
        return DateInterval(
            start: start.addingTimeInterval(-padding),
            end: end.addingTimeInterval(padding)
        )
    }
    
    static func clampPadding(duration: TimeInterval) -> TimeInterval {
        let suggested = max(duration * 0.1, 600) // at least 10 minutes
        let maxPadding: TimeInterval = 10_800    // at most 3 hours
        return min(suggested, maxPadding)
    }
    
    static func assignMarkers(for timelines: [CityTimeline]) -> (markers: [CityMarker], maxLane: Int) {
        var laneEndTimes: [Date] = []
        var markers: [CityMarker] = []
        var maxLane = 0
        
        for timeline in timelines.sorted(by: { $0.userInterval.start < $1.userInterval.start }) {
            var assignedLane = 0
            var reuseLane = false
            
            for (index, endTime) in laneEndTimes.enumerated() {
                if timeline.userInterval.start >= endTime {
                    assignedLane = index
                    laneEndTimes[index] = timeline.userInterval.end
                    reuseLane = true
                    break
                }
            }
            
            if !reuseLane {
                assignedLane = laneEndTimes.count
                laneEndTimes.append(timeline.userInterval.end)
            }
            
            markers.append(
                CityMarker(
                    id: timeline.id,
                    timeline: timeline,
                    lane: assignedLane
                )
            )
            maxLane = max(maxLane, assignedLane)
        }
        
        return (markers, maxLane)
    }
    
    static func axisMarks(for range: DateInterval, userTimezone: TimeZone) -> [Date] {
        let totalSeconds = range.duration
        guard totalSeconds > 0 else { return [range.start, range.end] }
        
        let totalHours = totalSeconds / 3_600
        let step: Double
        
        switch totalHours {
        case ..<3: step = 0.5
        case ..<8: step = 1
        case ..<16: step = 2
        case ..<24: step = 3
        case ..<40: step = 4
        default: step = max(ceil(totalHours / 10.0), 4)
        }
        
        let stepSeconds = step * 3_600
        let lowerReference = range.start.timeIntervalSinceReferenceDate
        var currentInterval = floor(lowerReference / stepSeconds) * stepSeconds
        
        var marks: [Date] = []
        var iterations = 0
        
        while iterations < 80 {
            let currentDate = Date(timeIntervalSinceReferenceDate: currentInterval)
            if currentDate >= range.start - 0.5 && currentDate <= range.end + 0.5 {
                marks.append(currentDate)
            }
            if currentDate > range.end + stepSeconds { break }
            currentInterval += stepSeconds
            iterations += 1
        }
        
        if marks.isEmpty {
            marks = [range.start, range.end]
        } else {
            if let first = marks.first, first > range.start + 60 {
                let delta = first.timeIntervalSince(range.start)
                if delta > stepSeconds * 0.35 {
                    marks.insert(range.start, at: 0)
                } else {
                    marks[0] = range.start
                }
            }
            
            if let last = marks.last, last < range.end - 60 {
                let delta = range.end.timeIntervalSince(last)
                if delta > stepSeconds * 0.35 {
                    marks.append(range.end)
                } else {
                    marks[marks.count - 1] = range.end
                }
            }
        }
        
        return marks
    }
    
    static func timelineWidth(for range: DateInterval) -> CGFloat {
        let duration = range.duration
        guard duration > 0 else { return 600 }
        
        let hours = duration / 3_600
        let pointsPerHour: CGFloat
        
        switch hours {
        case ..<2: pointsPerHour = 200
        case ..<6: pointsPerHour = 150
        case ..<12: pointsPerHour = 120
        case ..<24: pointsPerHour = 100
        case ..<36: pointsPerHour = 84
        case ..<48: pointsPerHour = 72
        default: pointsPerHour = 60
        }
        
        let minimumWidth: CGFloat = 540
        let maximumWidth: CGFloat = 3200
        let proposedWidth = CGFloat(hours) * pointsPerHour
        return min(max(proposedWidth, minimumWidth), maximumWidth)
    }
    
    static func timezoneSummary(for referenceDate: Date, timezone: TimeZone) -> String {
        let abbreviation = timezone.abbreviation(for: referenceDate)
            ?? timezone.abbreviation()
            ?? timezone.identifier
        let offset = offsetString(for: referenceDate, timezone: timezone)
        return "\(abbreviation) \(offset)"
    }
    
    static func offsetString(for referenceDate: Date, timezone: TimeZone) -> String {
        let seconds = timezone.secondsFromGMT(for: referenceDate)
        let totalMinutes = abs(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let sign = seconds >= 0 ? "+" : "-"
        
        if minutes == 0 {
            return "UTC\(sign)\(String(format: "%02d", hours))"
        } else {
            return "UTC\(sign)\(String(format: "%02d:%02d", hours, minutes))"
        }
    }
    
    static func normalizedProgress(for date: Date, in range: DateInterval) -> Double {
        guard range.duration > 0 else { return 0 }
        let clampedDate = min(max(date, range.start), range.end)
        let elapsed = clampedDate.timeIntervalSince(range.start)
        return min(max(elapsed / range.duration, 0), 1)
    }
}

private extension DateInterval {
    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
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
}
