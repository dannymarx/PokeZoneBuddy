//
//  NotificationImageService.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-12.
//

import Foundation
import UserNotifications
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Service for downloading and preparing images for notifications
class NotificationImageService {

    static let shared = NotificationImageService()

    private let fileManager = FileManager.default
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Public Methods

    /// Download and create notification attachment from URL
    /// - Parameter urlString: The URL string of the image
    /// - Returns: UNNotificationAttachment if successful, nil otherwise
    func createAttachment(from urlString: String?) async -> UNNotificationAttachment? {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return nil
        }

        do {
            // Download image data
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                AppLogger.notifications.error("Failed to download image: invalid response")
                return nil
            }

            // Get file extension from URL or content type
            let fileExtension = getFileExtension(from: url, response: httpResponse)

            // Create temporary file
            let tempDirectory = fileManager.temporaryDirectory
            let filename = UUID().uuidString + "." + fileExtension
            let fileURL = tempDirectory.appendingPathComponent(filename)

            // Write data to file
            try data.write(to: fileURL)

            // Create attachment
            let attachment = try UNNotificationAttachment(
                identifier: UUID().uuidString,
                url: fileURL,
                options: [UNNotificationAttachmentOptionsTypeHintKey: getUTType(for: fileExtension)]
            )

            AppLogger.notifications.info("Created notification attachment from: \(urlString)")
            return attachment

        } catch {
            AppLogger.notifications.error("Failed to create notification attachment: \(error.localizedDescription)")
            return nil
        }
    }

    /// Get the best image URL for an event
    /// - Parameter event: The event
    /// - Returns: The best available image URL
    func getBestImageURL(for event: Event) -> String? {
        // Priority:
        // 1. Community Day featured Pokemon
        // 2. Spotlight Hour featured Pokemon
        // 3. Raid Boss (first one)
        // 4. Event image URL

        if let communityDay = event.communityDayDetails {
            if let firstPokemon = communityDay.featuredPokemon.first {
                return firstPokemon.imageURL
            }
        }

        if let spotlight = event.spotlightDetails {
            return spotlight.featuredPokemonImage
        }

        if let raid = event.raidDetails {
            if let firstBoss = raid.bosses.first {
                return firstBoss.imageURL
            }
        }

        return event.imageURL
    }

    // MARK: - Helper Methods

    private func getFileExtension(from url: URL, response: HTTPURLResponse) -> String {
        // Try to get from URL
        let urlExtension = url.pathExtension.lowercased()
        if !urlExtension.isEmpty && ["jpg", "jpeg", "png", "gif", "webp"].contains(urlExtension) {
            return urlExtension
        }

        // Try to get from content type
        if let contentType = response.value(forHTTPHeaderField: "Content-Type") {
            if contentType.contains("jpeg") || contentType.contains("jpg") {
                return "jpg"
            } else if contentType.contains("png") {
                return "png"
            } else if contentType.contains("gif") {
                return "gif"
            } else if contentType.contains("webp") {
                return "webp"
            }
        }

        // Default to png
        return "png"
    }

    private func getUTType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg":
            return "public.jpeg"
        case "png":
            return "public.png"
        case "gif":
            return "public.gif"
        case "webp":
            return "public.webp"
        default:
            return "public.image"
        }
    }

    /// Clean up old temporary notification images
    func cleanupTemporaryImages() {
        let tempDirectory = fileManager.temporaryDirectory

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: tempDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )

            let now = Date()
            let oneDayAgo = now.addingTimeInterval(-86400)

            for fileURL in contents {
                // Only delete image files
                let fileExtension = fileURL.pathExtension.lowercased()
                guard ["jpg", "jpeg", "png", "gif", "webp"].contains(fileExtension) else {
                    continue
                }

                // Check creation date
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   creationDate < oneDayAgo {
                    try? fileManager.removeItem(at: fileURL)
                }
            }

            AppLogger.notifications.debug("Cleaned up temporary notification images")
        } catch {
            AppLogger.notifications.error("Failed to cleanup temporary images: \(error.localizedDescription)")
        }
    }
}
