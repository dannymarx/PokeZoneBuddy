//
//  ExportModels.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 13.10.2025.
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
