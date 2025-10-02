//
//  Event.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.2025.
//

import Foundation
import SwiftData

/// Repräsentiert ein Pokemon GO Event mit allen relevanten Informationen
/// Diese Daten kommen von der ScrapedDuck API
@Model
final class Event {
    /// Eindeutige ID aus der API (z.B. "community-day-october-2025")
    @Attribute(.unique) var id: String
    
    /// Name des Events (z.B. "Community Day: Bulbasaur")
    var name: String
    
    /// Event-Typ (z.B. "community-day", "raid-hour", "spotlight-hour")
    var eventType: String
    
    /// Event Heading/Kategorie (z.B. "Community Day", "Raid Hour")
    var heading: String
    
    /// Link zur LeekDuck Event-Seite
    var link: String?
    
    /// Startzeit des Events
    /// Wenn isGlobalTime = true: UTC Zeit
    /// Wenn isGlobalTime = false: Local timezone des Users
    var startTime: Date
    
    /// Endzeit des Events
    /// Wenn isGlobalTime = true: UTC Zeit
    /// Wenn isGlobalTime = false: Local timezone des Users
    var endTime: Date
    
    /// Gibt an ob das Event global zur gleichen Zeit startet (UTC)
    /// true = Event startet global zur selben Zeit (hat "Z" im Datum)
    /// false = Event startet basierend auf lokaler Zeit
    var isGlobalTime: Bool
    
    /// Optionale Bild-URL für Event-Grafik
    var imageURL: String?
    
    /// Hat das Event Pokemon Spawns?
    var hasSpawns: Bool
    
    /// Hat das Event Field Research Tasks?
    var hasFieldResearchTasks: Bool
    
    /// Timestamp wann das Event zuletzt aktualisiert wurde
    var lastUpdated: Date
    
    /// Initializer für neue Events
    /// - Parameters:
    ///   - id: Eindeutige Event-ID
    ///   - name: Event-Name
    ///   - eventType: Art des Events
    ///   - heading: Event-Kategorie
    ///   - link: Link zur Event-Seite
    ///   - startTime: Startzeitpunkt
    ///   - endTime: Endzeitpunkt
    ///   - isGlobalTime: Ob Event global zur selben Zeit startet
    ///   - imageURL: Optionale Bild-URL
    ///   - hasSpawns: Hat Pokemon Spawns
    ///   - hasFieldResearchTasks: Hat Field Research Tasks
    init(
        id: String,
        name: String,
        eventType: String,
        heading: String,
        link: String? = nil,
        startTime: Date,
        endTime: Date,
        isGlobalTime: Bool,
        imageURL: String? = nil,
        hasSpawns: Bool = false,
        hasFieldResearchTasks: Bool = false
    ) {
        self.id = id
        self.name = name
        self.eventType = eventType
        self.heading = heading
        self.link = link
        self.startTime = startTime
        self.endTime = endTime
        self.isGlobalTime = isGlobalTime
        self.imageURL = imageURL
        self.hasSpawns = hasSpawns
        self.hasFieldResearchTasks = hasFieldResearchTasks
        self.lastUpdated = Date()
    }
}

// MARK: - Convenience Extensions

extension Event {
    /// Prüft ob das Event aktuell läuft
    var isCurrentlyActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }
    
    /// Prüft ob das Event in der Zukunft liegt
    var isUpcoming: Bool {
        return startTime > Date()
    }
    
    /// Prüft ob das Event bereits vorbei ist
    var isPast: Bool {
        return endTime < Date()
    }
    
    /// Dauer des Events in Stunden
    var durationInHours: Double {
        return endTime.timeIntervalSince(startTime) / 3600
    }
    
    /// Formatierte Event-Dauer (z.B. "3h" oder "1h 30min")
    var formattedDuration: String {
        let hours = Int(durationInHours)
        let minutes = Int((durationInHours - Double(hours)) * 60)
        
        if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(minutes)min"
        }
    }
    
    /// Icon basierend auf Event-Features
    var eventIcon: String {
        if hasSpawns && hasFieldResearchTasks {
            return "star.fill"
        } else if hasSpawns {
            return "location.fill"
        } else if hasFieldResearchTasks {
            return "doc.text.fill"
        } else {
            return "calendar"
        }
    }
}

// Note: @Model macht die Klasse automatisch Identifiable via persistentModelID
// Keine manuelle Identifiable Extension nötig!
