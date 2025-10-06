//
//  FavoriteCity.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.2025.
//

import Foundation
import SwiftData

/// Repräsentiert eine Lieblingsstadt des Users mit Timezone-Informationen
/// Wird lokal mit SwiftData gespeichert
@Model
final class FavoriteCity {
    /// Eindeutige ID für die Stadt
    var id: UUID
    
    /// Stadtname (z.B. "Tokyo", "New York")
    var name: String
    
    /// TimeZone Identifier (z.B. "Asia/Tokyo", "America/New_York")
    /// Verwendet Apple's TimeZone-System für präzise Konvertierungen
    var timeZoneIdentifier: String
    
    /// Vollständiger Name mit Kontext (z.B. "Tokyo, Japan", "Los Angeles, California")
    /// Wird von MapKit's addressRepresentations.cityWithContext bereitgestellt
    var fullName: String
    
    /// Wann wurde diese Stadt hinzugefügt
    var addedDate: Date

    /// Gespeicherte Spots (Koordinaten) für diese Stadt
    /// Cascade-Delete: Wenn die Stadt gelöscht wird, werden auch alle Spots gelöscht
    @Relationship(deleteRule: .cascade) var spots: [CitySpot] = []

    /// Berechnete Property für das TimeZone-Objekt
    var timeZone: TimeZone? {
        return TimeZone(identifier: timeZoneIdentifier)
    }

    /// Anzahl der gespeicherten Spots für diese Stadt
    var spotCount: Int {
        return spots.count
    }
    
    /// Initializer für neue Lieblingsstädte
    /// - Parameters:
    ///   - name: Stadtname
    ///   - timeZoneIdentifier: TimeZone Identifier (z.B. "Europe/Berlin")
    ///   - fullName: Vollständiger Name mit Kontext (z.B. "Tokyo, Japan")
    init(
        name: String,
        timeZoneIdentifier: String,
        fullName: String
    ) {
        self.id = UUID()
        self.name = name
        self.timeZoneIdentifier = timeZoneIdentifier
        self.fullName = fullName
        self.addedDate = Date()
    }
}

// MARK: - Convenience Extensions

extension FavoriteCity {
    /// Display-Name für die UI (verwendet fullName)
    var displayName: String {
        return fullName
    }
    
    /// Aktuelle Zeit in dieser Stadt
    var currentTime: Date {
        return Date()
    }
    
    /// Formatierte Zeitzone (z.B. "JST", "EDT", "CET")
    var abbreviatedTimeZone: String {
        guard let tz = timeZone else { return "UTC" }
        return tz.abbreviation() ?? timeZoneIdentifier
    }
    
    /// UTC Offset in Stunden (z.B. +9 für Tokyo, -5 für NYC)
    var utcOffsetHours: Int {
        guard let tz = timeZone else { return 0 }
        return tz.secondsFromGMT() / 3600
    }
    
    /// Formatierter UTC Offset String (z.B. "UTC+9", "UTC-5")
    var formattedUTCOffset: String {
        let offset = utcOffsetHours
        if offset >= 0 {
            return "UTC+\(offset)"
        } else {
            return "UTC\(offset)"
        }
    }
}

// MARK: - Comparable for Sorting
// Note: @Model macht die Klasse bereits Identifiable via persistentModelID

extension FavoriteCity: Comparable {
    public static func < (lhs: FavoriteCity, rhs: FavoriteCity) -> Bool {
        // Sortiere alphabetisch nach Name
        return lhs.name < rhs.name
    }
}
