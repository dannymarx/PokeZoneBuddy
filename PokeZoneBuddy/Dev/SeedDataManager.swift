//
//  SeedDataManager.swift
//  PokéZoneBuddy
//
//  Utility for seeding sample data during development, QA, and App Store screenshots.
//  No #if DEBUG guard — needed in release builds for screenshot workflows.
//
//  Usage (Xcode scheme → Run → Arguments Passed On Launch):
//    -SeedSampleData     Clears all FavoriteCity/CitySpot rows and inserts fresh sample data.
//    -ClearSampleData    Clears all FavoriteCity/CitySpot rows without re-seeding.
//

import Foundation
import SwiftData

/// Caseless enum used as a pure namespace for sample-data operations.
/// Never instantiated — call static methods directly.
enum SeedDataManager {

    // MARK: - Launch Argument Keys

    private static let seedArgument  = "-SeedSampleData"
    private static let clearArgument = "-ClearSampleData"

    // MARK: - Entry Point

    /// Inspect `ProcessInfo.processInfo.arguments` and act accordingly.
    /// Call once from `PokeZoneBuddyApp.init()` before services are set up.
    static func handleLaunchArguments(with context: ModelContext) {
        let args = ProcessInfo.processInfo.arguments
        if args.contains(seedArgument) {
            AppLogger.app.info("[SeedDataManager] -SeedSampleData detected — seeding sample data")
            seed(into: context)
        } else if args.contains(clearArgument) {
            AppLogger.app.info("[SeedDataManager] -ClearSampleData detected — clearing all city data")
            clearAll(in: context)
        }
    }

    // MARK: - Seed

    /// Clears existing FavoriteCity/CitySpot data then inserts 4 sample cities.
    /// Idempotent — safe to call on every qualifying launch.
    static func seed(into context: ModelContext) {
        clearAll(in: context)
        let data = sampleData()
        for (city, spots) in data {
            context.insert(city)
            for spot in spots {
                spot.city = city
                context.insert(spot)
            }
        }
        do {
            try context.save()
            AppLogger.app.info("[SeedDataManager] Seeded \(data.count) sample cities")
        } catch {
            AppLogger.app.error("[SeedDataManager] Failed to save seed data: \(error.localizedDescription)")
        }
    }

    // MARK: - Clear

    /// Deletes every FavoriteCity from the context.
    /// Cascade rule on FavoriteCity.spots removes associated CitySpot rows automatically.
    static func clearAll(in context: ModelContext) {
        do {
            let cities = try context.fetch(FetchDescriptor<FavoriteCity>())
            for city in cities { context.delete(city) }
            try context.save()
            AppLogger.app.info("[SeedDataManager] Cleared \(cities.count) existing cities")
        } catch {
            AppLogger.app.error("[SeedDataManager] Failed to clear cities: \(error.localizedDescription)")
        }
    }

    // MARK: - Sample Data

    private static func sampleData() -> [(FavoriteCity, [CitySpot])] {
        [
            // ------------------------------------------------------------------
            // Tokyo, Japan  (UTC+9)
            // ------------------------------------------------------------------
            (
                FavoriteCity(
                    name: "Tokyo",
                    timeZoneIdentifier: "Asia/Tokyo",
                    fullName: "Tokyo, Japan"
                ),
                [
                    CitySpot(
                        name: "Shinjuku Gyoen Gym Cluster",
                        notes: "3 gyms within 200m near south entrance. EX-raid eligible.",
                        latitude: 35.6851,
                        longitude: 139.7100,
                        category: .gym,
                        isFavorite: true
                    ),
                    CitySpot(
                        name: "Shibuya Crossing PokéStops",
                        notes: "10+ PokéStops around the crossing and Hachiko statue. Great lure chain spot.",
                        latitude: 35.6595,
                        longitude: 139.7004,
                        category: .pokestop
                    ),
                    CitySpot(
                        name: "Yoyogi Park Community Day Hub",
                        notes: "Traditional Community Day meetup for Tokyo players. Good spawn density.",
                        latitude: 35.6715,
                        longitude: 139.6942,
                        category: .meetingPoint
                    )
                ]
            ),

            // ------------------------------------------------------------------
            // New York City, USA  (UTC-5 / UTC-4 DST)
            // ------------------------------------------------------------------
            (
                FavoriteCity(
                    name: "New York",
                    timeZoneIdentifier: "America/New_York",
                    fullName: "New York City, New York"
                ),
                [
                    CitySpot(
                        name: "Central Park Gym Row",
                        notes: "Row of gyms near Bethesda Fountain. High foot traffic, fast turnover.",
                        latitude: 40.7745,
                        longitude: -73.9718,
                        category: .gym,
                        isFavorite: true
                    ),
                    CitySpot(
                        name: "Columbus Circle PokéStop Hub",
                        notes: "6+ PokéStops reachable from the plaza centre. Great for incense walks.",
                        latitude: 40.7681,
                        longitude: -73.9819,
                        category: .pokestop
                    ),
                    CitySpot(
                        name: "Sheep Meadow Raid Meetup",
                        notes: "Classic NYC raid meetup location before walking to active gyms.",
                        latitude: 40.7717,
                        longitude: -73.9764,
                        category: .meetingPoint
                    )
                ]
            ),

            // ------------------------------------------------------------------
            // London, England  (UTC+0 / UTC+1 BST)
            // ------------------------------------------------------------------
            (
                FavoriteCity(
                    name: "London",
                    timeZoneIdentifier: "Europe/London",
                    fullName: "London, England"
                ),
                [
                    CitySpot(
                        name: "Hyde Park Corner Gym",
                        notes: "EX-raid eligible gym at southeast corner of Hyde Park. Usually contested.",
                        latitude: 51.5028,
                        longitude: -0.1527,
                        category: .gym
                    ),
                    CitySpot(
                        name: "South Kensington Museum Mile",
                        notes: "Exhibition Road — best PokéStop corridor in London. Museums = dense stops.",
                        latitude: 51.4967,
                        longitude: -0.1764,
                        category: .pokestop,
                        isFavorite: true
                    )
                ]
            ),

            // ------------------------------------------------------------------
            // Sydney, Australia  (UTC+10 / UTC+11 AEDT)
            // ------------------------------------------------------------------
            (
                FavoriteCity(
                    name: "Sydney",
                    timeZoneIdentifier: "Australia/Sydney",
                    fullName: "Sydney, New South Wales"
                ),
                [
                    CitySpot(
                        name: "Hyde Park CBD Gym Strip",
                        notes: "4+ gyms running north–south through Hyde Park. Easy raid-walk.",
                        latitude: -33.8731,
                        longitude: 151.2111,
                        category: .gym
                    ),
                    CitySpot(
                        name: "Circular Quay Waterfront PokéStops",
                        notes: "Very high PokéStop density near ferry terminal. Spawn boosts near water.",
                        latitude: -33.8614,
                        longitude: 151.2101,
                        category: .pokestop,
                        isFavorite: true
                    ),
                    CitySpot(
                        name: "The Domain Community Day Field",
                        notes: "Large open grass area adjacent to the CBD. Standard Sydney Community Day spot.",
                        latitude: -33.8693,
                        longitude: 151.2168,
                        category: .meetingPoint
                    )
                ]
            )
        ]
    }
}
