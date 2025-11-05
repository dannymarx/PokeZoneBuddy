//
//  TimelineImageRenderer.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-20.
//  Version 1.6.0 - Multi-City Timeline Plans & Templates
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

// MARK: - Timeline Image Renderer

/// Service for rendering timeline views as shareable images
/// Uses ImageRenderer to capture SwiftUI views as platform-specific images
@MainActor
final class TimelineImageRenderer {

    // MARK: - Constants

    private let targetSize = CGSize(width: 1080, height: 1920) // 9:16 portrait canvas
    private let scale: CGFloat = 2.0 // Retina resolution

    // MARK: - Public Methods

    /// Renders a timeline view as an image
    /// - Parameters:
    ///   - event: The event to render
    ///   - cities: The cities in the timeline
    ///   - planName: The name of the plan (for branding)
    ///   - colorScheme: The color scheme (light or dark)
    /// - Returns: Platform-specific image (UIImage on iOS, NSImage on macOS)
    func render(
        event: Event,
        cities: [FavoriteCity],
        planName: String,
        colorScheme: ColorScheme
    ) async -> PlatformImage? {
        guard let snapshot = TimelineSnapshotBuilder(event: event, favoriteCities: cities).build() else {
            AppLogger.service.error("Failed to build timeline snapshot for image export")
            return nil
        }

        let exportView = TimelineExportView(
            planName: planName,
            event: event,
            snapshot: snapshot,
            colorScheme: colorScheme,
            canvasSize: targetSize
        )
        .environment(\.colorScheme, colorScheme)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = scale
        renderer.proposedSize = ProposedViewSize(width: targetSize.width, height: targetSize.height)

        #if os(iOS)
        guard let uiImage = renderer.uiImage else {
            AppLogger.service.error("Failed to render timeline image")
            return nil
        }

        AppLogger.service.info("Rendered timeline image: \(planName)")
        return uiImage

        #elseif os(macOS)
        guard let nsImage = renderer.nsImage else {
            AppLogger.service.error("Failed to render timeline image")
            return nil
        }

        AppLogger.service.info("Rendered timeline image: \(planName)")
        return nsImage
        #endif
    }

    /// Saves rendered image to temporary directory
    /// - Parameters:
    ///   - image: The image to save
    ///   - planName: The plan name (used for filename)
    /// - Returns: URL of the saved file
    func saveToTemporaryDirectory(
        image: PlatformImage,
        planName: String
    ) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let sanitizedName = sanitizePlanName(planName)
        let filename = "PokeZoneBuddy_\(sanitizedName)_\(Date().timeIntervalSince1970).png"
        let fileURL = tempDirectory.appendingPathComponent(filename)

        #if os(iOS)
        guard let data = image.pngData() else {
            throw TimelineImageError.failedToEncodeImage
        }
        #elseif os(macOS)
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let data = bitmapImage.representation(using: .png, properties: [:]) else {
            throw TimelineImageError.failedToEncodeImage
        }
        #endif

        try data.write(to: fileURL)
        AppLogger.service.info("Saved timeline image to: \(fileURL.path)")
        return fileURL
    }

    // MARK: - Private Helpers

    private func sanitizePlanName(_ name: String) -> String {
        // Remove invalid filename characters
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

// MARK: - Timeline Export View

private struct TimelineExportView: View {
    let planName: String
    let event: Event
    let snapshot: TimelineSnapshot
    let colorScheme: ColorScheme
    let canvasSize: CGSize

    private let timezoneService = TimezoneService.shared

    private var eventRangeText: String {
        timezoneService.formatEventTimeRange(
            startDate: event.startTime,
            endDate: event.endTime,
            timezone: snapshot.userTimezone,
            isGlobalTime: event.isGlobalTime,
            includeDate: true
        )
    }

    private var headerSubtitle: String {
        String(localized: "timeline.export.share.subtitle", defaultValue: "Timeline Plan Snapshot")
    }

    var body: some View {
        ZStack {
            backgroundLayer
            decorativeHighlights

            VStack(alignment: .leading, spacing: 32) {
                header
                summaryCard
                timelineList
                Spacer(minLength: 0)
                footer
            }
            .padding(48)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: TimelineExportPalette.backgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(colorScheme == .dark ? 0.25 : 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var decorativeHighlights: some View {
        ZStack {
            TimelineExportPalette.highlightCircle
                .offset(x: -canvasSize.width * 0.25, y: -canvasSize.height * 0.28)
            TimelineExportPalette.highlightCircle
                .scaleEffect(0.65)
                .offset(x: canvasSize.width * 0.3, y: canvasSize.height * 0.35)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 24) {
            AppBadge()
            VStack(alignment: .leading, spacing: 6) {
                Text("PokeZoneBuddy")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                Text(headerSubtitle)
                    .font(DesignSystem.Typography.body(18))
                    .foregroundStyle(Color.white.opacity(0.75))
                Text(planName)
                    .font(DesignSystem.Typography.captionSemibold(16))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .singleLineTruncated()
            }
            Spacer()
        }
    }

    private var summaryCard: some View {
        TimelineExportSummaryCard(
            eventName: event.name,
            eventType: event.heading,
            eventRangeText: eventRangeText,
            timezoneLabel: snapshot.timezoneLabel,
            totalDuration: snapshot.totalDuration,
            activeDuration: snapshot.activeDuration
        )
    }

    private var timelineList: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(String(localized: "timeline.export.timeline.title", defaultValue: "City Schedule"))
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.9))

            ForEach(snapshot.items) { item in
                switch item {
                case .city(let city):
                    TimelineExportCityCard(city: city)
                case .gap(let gap):
                    TimelineExportGapCard(gap: gap)
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(Color.white.opacity(0.2))

            HStack(alignment: .center, spacing: 16) {
                TimelineExportMetric(
                    icon: "clock.badge.checkmark.fill",
                    title: String(localized: "timeline.export.total.play", defaultValue: "Playing"),
                    value: TimelineExportFormatter.durationString(snapshot.activeDuration)
                )
                TimelineExportMetric(
                    icon: "hourglass",
                    title: String(localized: "timeline.export.total.window", defaultValue: "Total Window"),
                    value: TimelineExportFormatter.durationString(snapshot.totalDuration)
                )
                Spacer()
            }

            Text(String(localized: "timeline.export.tagline", defaultValue: "Plan smarter raids across the globe."))
                .font(DesignSystem.Typography.caption(14))
                .foregroundStyle(Color.white.opacity(0.72))

            Text(snapshot.generatedAtString)
                .font(DesignSystem.Typography.caption(12))
                .foregroundStyle(Color.white.opacity(0.55))
        }
    }
}

// MARK: - Snapshot Builder

private struct TimelineSnapshotBuilder {
    let event: Event
    let favoriteCities: [FavoriteCity]

    private let timezoneService = TimezoneService.shared

    func build() -> TimelineSnapshot? {
        let userTimezone = timezoneService.userTimezone

        let cityEntries: [TimelineSnapshot.City] = favoriteCities.compactMap { city in
            guard let timezone = city.timeZone else { return nil }
            let interval = convertInterval(for: city, cityTimezone: timezone, userTimezone: userTimezone)
            guard interval.duration > 0 else { return nil }

            return TimelineSnapshot.City(
                id: "\(city.timeZoneIdentifier)-\(interval.start.timeIntervalSince1970)",
                cityName: city.displayName,
                startTime: interval.start,
                endTime: interval.end,
                timezone: userTimezone,
                accentColor: TimelineExportPalette.shade(for: city.timeZoneIdentifier)
            )
        }
        .sorted(by: { $0.startTime < $1.startTime })

        guard let first = cityEntries.first, let last = cityEntries.last else {
            return nil
        }

        var items: [TimelineSnapshot.Item] = []
        var activeDuration: TimeInterval = 0

        for (index, entry) in cityEntries.enumerated() {
            activeDuration += entry.endTime.timeIntervalSince(entry.startTime)
            items.append(.city(entry))

            if index < cityEntries.count - 1 {
                let next = cityEntries[index + 1]
                let gap = TimelineSnapshot.Gap(
                    id: "gap-\(index)",
                    startTime: entry.endTime,
                    endTime: next.startTime,
                    timezone: userTimezone
                )
                items.append(.gap(gap))
            }
        }

        let totalInterval = DateInterval(start: first.startTime, end: last.endTime)

        return TimelineSnapshot(
            items: items,
            totalDuration: totalInterval.duration,
            activeDuration: activeDuration,
            userTimezone: userTimezone,
            generatedAt: Date()
        )
    }

    private func convertInterval(
        for city: FavoriteCity,
        cityTimezone: TimeZone,
        userTimezone: TimeZone
    ) -> DateInterval {
        if event.isGlobalTime {
            return DateInterval(start: event.startTime, end: event.endTime)
        } else {
            let start = timezoneService.convertLocalEventTime(event.startTime, from: cityTimezone, to: userTimezone)
            let end = timezoneService.convertLocalEventTime(event.endTime, from: cityTimezone, to: userTimezone)
            return DateInterval(start: start, end: end)
        }
    }
}

// MARK: - Snapshot Models

private struct TimelineSnapshot {
    enum Item: Identifiable {
        case city(City)
        case gap(Gap)

        var id: String {
            switch self {
            case .city(let city):
                return city.id
            case .gap(let gap):
                return gap.id
            }
        }
    }

    struct City: Identifiable {
        let id: String
        let cityName: String
        let startTime: Date
        let endTime: Date
        let timezone: TimeZone
        let accentColor: Color

        var timeRangeText: String {
            TimezoneService.shared.formatTimeRange(
                startDate: startTime,
                endDate: endTime,
                timezone: timezone,
                includeDate: false
            )
        }

        var durationText: String {
            TimelineExportFormatter.durationString(endTime.timeIntervalSince(startTime))
        }
    }

    struct Gap: Identifiable {
        let id: String
        let startTime: Date
        let endTime: Date
        let timezone: TimeZone

        var duration: TimeInterval {
            endTime.timeIntervalSince(startTime)
        }

        var isNegative: Bool {
            duration < 0
        }
    }

    let items: [Item]
    let totalDuration: TimeInterval
    let activeDuration: TimeInterval
    let userTimezone: TimeZone
    let generatedAt: Date

    var timezoneLabel: String {
        let abbreviation = userTimezone.abbreviation() ?? userTimezone.identifier
        return String(
            format: String(localized: "timeline.export.timezone", defaultValue: "Your Timezone: %@"),
            abbreviation
        )
    }

    var generatedAtString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.autoupdatingCurrent
        formatter.timeZone = userTimezone
        return String(
            format: String(localized: "timeline.export.generated_at", defaultValue: "Generated %@"),
            formatter.string(from: generatedAt)
        )
    }
}

// MARK: - Supporting Views

private struct TimelineExportSummaryCard: View {
    let eventName: String
    let eventType: String
    let eventRangeText: String
    let timezoneLabel: String
    let totalDuration: TimeInterval
    let activeDuration: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(eventName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(eventType)
                    .font(DesignSystem.Typography.captionSemibold(16))
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 6) {
                Label(eventRangeText, systemImage: "calendar.circle.fill")
                    .font(DesignSystem.Typography.bodySemibold(17))
                    .foregroundStyle(Color.white.opacity(0.9))
                Label(timezoneLabel, systemImage: "globe")
                    .font(DesignSystem.Typography.body(15))
                    .foregroundStyle(Color.white.opacity(0.74))
            }

            HStack(spacing: 16) {
                TimelineExportMetric(
                    icon: "gamecontroller.fill",
                    title: String(localized: "timeline.export.summary.play", defaultValue: "Active Play"),
                    value: TimelineExportFormatter.durationString(activeDuration)
                )
                TimelineExportMetric(
                    icon: "hourglass.bottomhalf.fill",
                    title: String(localized: "timeline.export.summary.total", defaultValue: "Total Window"),
                    value: TimelineExportFormatter.durationString(totalDuration)
                )
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

private struct TimelineExportCityCard: View {
    let city: TimelineSnapshot.City

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                Circle()
                    .fill(city.accentColor)
                    .frame(width: 16, height: 16)
                Text(city.cityName)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label(city.timeRangeText, systemImage: "clock.fill")
                    .foregroundStyle(Color.white.opacity(0.85))
                    .font(DesignSystem.Typography.bodySemibold(17))
                Label(city.durationText, systemImage: "figure.run")
                    .foregroundStyle(Color.white.opacity(0.7))
                    .font(DesignSystem.Typography.captionSemibold(15))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(city.accentColor.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(city.accentColor.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

private struct TimelineExportGapCard: View {
    let gap: TimelineSnapshot.Gap

    var body: some View {
        let durationText = TimelineExportFormatter.durationString(abs(gap.duration))
        let isOverlap = gap.isNegative
        let symbol = isOverlap ? "exclamationmark.triangle.fill" : "airplane"
        let label = isOverlap ?
            String(localized: "timeline.export.gap.overlap", defaultValue: "Overlap detected") :
            String(localized: "timeline.export.gap.travel", defaultValue: "Travel / Break")
        let tint: Color = isOverlap ? Color.systemOrange : Color.white.opacity(0.82)

        return HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(DesignSystem.Typography.bodySemibold(16))
                    .foregroundStyle(tint)
                Text(durationText)
                    .font(DesignSystem.Typography.captionMedium(14))
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

private struct TimelineExportMetric: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DesignSystem.Typography.captionSemibold(13))
                    .foregroundStyle(Color.white.opacity(0.7))
                Text(value)
                    .font(DesignSystem.Typography.bodySemibold(18))
                    .foregroundStyle(Color.white)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

private struct AppBadge: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [TimelineExportPalette.accent, TimelineExportPalette.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: TimelineExportPalette.accent.opacity(0.35), radius: 24, x: 0, y: 18)

            Image(systemName: "map.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 6)
        }
    }
}

// MARK: - Palette & Formatting Helpers

private enum TimelineExportPalette {
    static let accent = Color(red: 0.60, green: 0.42, blue: 0.98)
    static let accentSecondary = Color(red: 0.45, green: 0.26, blue: 0.86)

    static let backgroundGradient: [Color] = [
        Color(red: 0.16, green: 0.09, blue: 0.32),
        Color(red: 0.19, green: 0.10, blue: 0.44),
        Color(red: 0.24, green: 0.13, blue: 0.58)
    ]

    static var highlightCircle: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [accent.opacity(0.45), accentSecondary.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 420, height: 420)
            .blur(radius: 0)
            .opacity(0.32)
    }

    static func shade(for key: String) -> Color {
        let palette: [Color] = [
            Color(red: 0.74, green: 0.58, blue: 1.00),
            Color(red: 0.67, green: 0.50, blue: 0.98),
            Color(red: 0.82, green: 0.66, blue: 1.00),
            Color(red: 0.63, green: 0.44, blue: 0.94),
            Color(red: 0.78, green: 0.59, blue: 0.99)
        ]
        let index = abs(key.hashValue) % palette.count
        return palette[index]
    }
}

private enum TimelineExportFormatter {
    static func durationString(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        switch (hours, minutes) {
        case (let h, let m) where h > 0 && m > 0:
            return String(localized: "timeline.duration.hours_minutes \(h) \(m)")
        case (let h, _) where h > 0:
            return String(localized: "timeline.duration.hours \(h)")
        default:
            return String(localized: "timeline.duration.minutes \(minutes)")
        }
    }
}

// MARK: - Errors

enum TimelineImageError: LocalizedError {
    case failedToRender
    case failedToEncodeImage
    case failedToSaveFile

    var errorDescription: String? {
        switch self {
        case .failedToRender:
            return String(localized: "timeline.error.failed_to_render")
        case .failedToEncodeImage:
            return String(localized: "timeline.error.failed_to_encode")
        case .failedToSaveFile:
            return String(localized: "timeline.error.failed_to_save")
        }
    }
}

#if os(macOS)
extension NSImage {
    /// Get PNG data representation
    func pngData() -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}
#endif
