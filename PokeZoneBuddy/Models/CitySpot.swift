//
//  CitySpot.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 06.10.2025.
//

import Foundation
import SwiftData

/// Repräsentiert einen gespeicherten Spot (Koordinate) innerhalb einer Stadt
/// Ermöglicht das Speichern von wichtigen Locations wie Gyms, PokéStops oder Treffpunkten
/// Note: @Model classes are automatically Identifiable via persistentModelID
@Model
final class CitySpot {
    /// Name des Spots (z.B. "Central Park Gym Cluster")
    var name: String

    /// Mehrzeilige Notizen zum Spot (z.B. "5 Gyms, viele Spawns, gute Raid-Location")
    var notes: String

    /// Breitengrad der Koordinate
    var latitude: Double

    /// Längengrad der Koordinate
    var longitude: Double

    /// Kategorie des Spots (Gym, PokéStop, Meeting Point, Other)
    var category: SpotCategory

    /// Wann wurde dieser Spot erstellt
    var createdAt: Date

    /// Ist dieser Spot als Favorit markiert
    private(set) var isFavorite: Bool

    /// Relationship zur zugehörigen Stadt (optional, wird automatisch gesetzt)
    var city: FavoriteCity?

    /// Formatierte Koordinaten als String im Format "lat,long"
    var formattedCoordinates: String {
        return "\(latitude),\(longitude)"
    }

    /// Initializer für neue Spots
    /// - Parameters:
    ///   - name: Name des Spots
    ///   - notes: Notizen zum Spot
    ///   - latitude: Breitengrad
    ///   - longitude: Längengrad
    ///   - category: Kategorie des Spots
    ///   - isFavorite: Ob der Spot als Favorit markiert ist (Standard: false)
    ///   - city: Zugehörige Stadt (optional)
    init(
        name: String,
        notes: String = "",
        latitude: Double,
        longitude: Double,
        category: SpotCategory,
        isFavorite: Bool = false,
        city: FavoriteCity? = nil
    ) {
        self.name = name
        self.notes = notes
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.createdAt = Date()
        self.isFavorite = isFavorite
        self.city = city
    }

    /// Setzt den Favoriten-Status
    /// - Parameter isFavorite: Neuer Favoriten-Status
    func setFavorite(_ isFavorite: Bool) {
        self.isFavorite = isFavorite
    }
}

// MARK: - SpotCategory Enum

/// Kategorien für gespeicherte Spots
enum SpotCategory: String, CaseIterable, Codable {
    case gym = "gym"
    case pokestop = "pokestop"
    case meetingPoint = "meetingPoint"
    case other = "other"

    /// SF Symbol Icon für die Kategorie
    var icon: String {
        switch self {
        case .gym:
            return "figure.martial.arts"
        case .pokestop:
            return "mappin.circle.fill"
        case .meetingPoint:
            return "person.2.fill"
        case .other:
            return "location.fill"
        }
    }

    /// Lokalisierter Name für die UI
    var localizedName: String {
        switch self {
        case .gym:
            return String(localized: "spots.category.gym")
        case .pokestop:
            return String(localized: "spots.category.pokestop")
        case .meetingPoint:
            return String(localized: "spots.category.meetingPoint")
        case .other:
            return String(localized: "spots.category.other")
        }
    }
}

// MARK: - Convenience Extensions

extension CitySpot {
    /// Kopiert Koordinaten als String in die Zwischenablage-freundliches Format
    var coordinatesForClipboard: String {
        return formattedCoordinates
    }

    /// Gibt an ob der Spot gültige Koordinaten hat
    var hasValidCoordinates: Bool {
        return latitude >= -90 && latitude <= 90 &&
               longitude >= -180 && longitude <= 180
    }
}

// MARK: - Comparable for Sorting

extension CitySpot: Comparable {
    public static func < (lhs: CitySpot, rhs: CitySpot) -> Bool {
        // Favoriten zuerst, dann alphabetisch nach Name
        if lhs.isFavorite != rhs.isFavorite {
            return lhs.isFavorite && !rhs.isFavorite
        }
        return lhs.name < rhs.name
    }
}

