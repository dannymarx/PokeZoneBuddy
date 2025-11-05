//
//  ExportModels.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 13.10.2025.
//  Updated by Claude Code on 2025-10-20 for v1.6.0 Timeline Plans
//

import Foundation

// MARK: - Export Data Container

/// Top-level container for all exported data
struct ExportData: Codable {
    /// Version string for future compatibility
    let version: String

    /// Date when this export was created
    let exportDate: Date

    /// All cities with their spots
    let cities: [ExportCity]

    /// Current export format version
    static let currentVersion = "1.0"

    init(cities: [ExportCity], exportDate: Date = Date()) {
        self.version = ExportData.currentVersion
        self.exportDate = exportDate
        self.cities = cities
    }
}

// MARK: - Export City

/// Codable transfer object for FavoriteCity
struct ExportCity: Codable {
    let name: String
    let timeZoneIdentifier: String
    let fullName: String
    let addedDate: Date
    let spots: [ExportSpot]

    init(from city: FavoriteCity) {
        self.name = city.name
        self.timeZoneIdentifier = city.timeZoneIdentifier
        self.fullName = city.fullName
        self.addedDate = city.addedDate
        // Safely map spots, filtering out any nil values if needed
        self.spots = city.spots.compactMap { spot in
            return ExportSpot(from: spot)
        }
    }
}

// MARK: - Export Spot

/// Codable transfer object for CitySpot
struct ExportSpot: Codable {
    let name: String
    let notes: String
    let latitude: Double
    let longitude: Double
    let category: String
    let createdAt: Date
    let isFavorite: Bool

    init(from spot: CitySpot) {
        self.name = spot.name
        self.notes = spot.notes
        self.latitude = spot.latitude
        self.longitude = spot.longitude
        self.category = spot.category.rawValue
        self.createdAt = spot.createdAt
        self.isFavorite = spot.isFavorite
    }
}

// MARK: - Timeline Plan Export (v1.6.0)

/// Exportable timeline plan in portable JSON format
/// File extension: .pzb (PokeZoneBuddy file)
struct ExportableTimelinePlan: Codable {
    /// Version string for format compatibility
    let version: String

    /// App version that created this export
    let appVersion: String

    /// Export timestamp
    let exportDate: Date

    /// Plan name
    let planName: String

    /// Event type
    let eventType: String

    /// Event name (optional - null for templates)
    let eventName: String?

    /// Event ID (optional - null for templates)
    let eventID: String?

    /// Cities in this plan
    let cities: [ExportableCity]

    /// Current export format version
    static let currentVersion = "1.0"

    /// Nested city structure for timeline plans
    struct ExportableCity: Codable {
        let name: String
        let timeZoneIdentifier: String
        let fullName: String
    }

    /// Initialize from a TimelinePlan
    init(from plan: TimelinePlan, cities: [FavoriteCity], appVersion: String) {
        self.version = ExportableTimelinePlan.currentVersion
        self.appVersion = appVersion
        self.exportDate = Date()
        self.planName = plan.name
        self.eventType = plan.eventType
        self.eventName = plan.eventName
        self.eventID = plan.eventID
        self.cities = cities.map { city in
            ExportableCity(
                name: city.name,
                timeZoneIdentifier: city.timeZoneIdentifier,
                fullName: city.fullName
            )
        }
    }

    /// Initialize from a TimelineTemplate
    init(from template: TimelineTemplate, cities: [FavoriteCity], appVersion: String) {
        self.version = ExportableTimelinePlan.currentVersion
        self.appVersion = appVersion
        self.exportDate = Date()
        self.planName = template.name
        self.eventType = template.eventType
        self.eventName = nil
        self.eventID = nil
        self.cities = cities.map { city in
            ExportableCity(
                name: city.name,
                timeZoneIdentifier: city.timeZoneIdentifier,
                fullName: city.fullName
            )
        }
    }

    /// Initialize from raw data (for import)
    init(
        planName: String,
        eventType: String,
        eventName: String?,
        eventID: String?,
        cities: [ExportableCity],
        appVersion: String
    ) {
        self.version = ExportableTimelinePlan.currentVersion
        self.appVersion = appVersion
        self.exportDate = Date()
        self.planName = planName
        self.eventType = eventType
        self.eventName = eventName
        self.eventID = eventID
        self.cities = cities
    }
}
