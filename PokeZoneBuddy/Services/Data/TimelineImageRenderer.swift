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

    private let targetWidth: CGFloat = 1200
    private let targetHeight: CGFloat = 800
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
        // Create the timeline view
        let timelineView = EventTimelineView(
            event: event,
            favoriteCities: cities
        )

        // Wrap in container with branding
        let containerView = TimelineExportContainer(
            content: timelineView,
            planName: planName,
            colorScheme: colorScheme
        )

        // Render to image
        let renderer = ImageRenderer(content: containerView)
        renderer.scale = scale

        // Set color scheme
        #if os(iOS)
        renderer.proposedSize = ProposedViewSize(
            width: targetWidth,
            height: targetHeight
        )
        #elseif os(macOS)
        renderer.proposedSize = ProposedViewSize(
            width: targetWidth,
            height: targetHeight
        )
        #endif

        // Generate the image
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

// MARK: - Timeline Export Container

/// Container view that wraps the timeline with branding
private struct TimelineExportContainer: View {
    let content: EventTimelineView
    let planName: String
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main timeline content
            content
                .padding(DesignSystem.Spacing.xl)

            // Branding footer
            BrandingFooter(planName: planName)
        }
        .frame(width: 1200, height: 800)
        .background(backgroundColor)
        .preferredColorScheme(colorScheme)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
}

// MARK: - Branding Footer

/// Footer with app branding and plan name
private struct BrandingFooter: View {
    let planName: String

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Divider()
                .padding(.horizontal, DesignSystem.Spacing.xl)

            HStack {
                // App icon/logo placeholder
                Image(systemName: "map.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.systemBlue)

                Text("Created with PokeZoneBuddy")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("•")
                    .foregroundStyle(.tertiary)

                Text(planName)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .background(Color.secondary.opacity(0.05))
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

// MARK: - Platform-Specific Extensions

#if os(iOS)
extension UIImage {
    /// Get PNG data representation
    func pngData() -> Data? {
        return self.pngData()
    }
}
#endif

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
