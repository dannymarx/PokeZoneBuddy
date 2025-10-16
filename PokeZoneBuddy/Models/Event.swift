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
    
    /// Gibt an ob die Zeit in UTC gespeichert ist (technische Bedeutung)
    /// true = Zeit ist in UTC (hat "Z" im Datum) → Location-specific event (z.B. Safari Zone)
    /// false = Zeit ist als lokale Zeitkomponenten gespeichert → Global event (alle spielen zur gleichen lokalen Zeit)
    /// HINWEIS: Name ist technisch, nicht gameplay-bezogen! Für UI-Anzeige invertieren.
    var isGlobalTime: Bool
    
    /// Optionale Bild-URL für Event-Grafik
    var imageURL: String?
    
    /// Hat das Event Pokemon Spawns?
    var hasSpawns: Bool
    
    /// Hat das Event Field Research Tasks?
    var hasFieldResearchTasks: Bool
    
    /// Spotlight Hour Details (wenn eventType = "pokemon-spotlight-hour")
    @Relationship(deleteRule: .cascade)
    var spotlightDetails: SpotlightDetails?
    
    /// Raid Battle Details (wenn eventType = "raid-battles" oder "raid-hour")
    @Relationship(deleteRule: .cascade)
    var raidDetails: RaidDetails?
    
    /// Community Day Details (wenn eventType = "community-day")
    @Relationship(deleteRule: .cascade)
    var communityDayDetails: CommunityDayDetails?
    
    /// Timestamp wann das Event zuletzt aktualisiert wurde
    var lastUpdated: Date
    
    /// Initializer für neue Events
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
        hasFieldResearchTasks: Bool = false,
        spotlightDetails: SpotlightDetails? = nil,
        raidDetails: RaidDetails? = nil,
        communityDayDetails: CommunityDayDetails? = nil
    ) {
        self.id = id
        self.name = name.htmlDecodedFast
        self.eventType = eventType
        self.heading = heading.htmlDecodedFast
        self.link = link
        self.startTime = startTime
        self.endTime = endTime
        self.isGlobalTime = isGlobalTime
        self.imageURL = imageURL
        self.hasSpawns = hasSpawns
        self.hasFieldResearchTasks = hasFieldResearchTasks
        self.spotlightDetails = spotlightDetails
        self.raidDetails = raidDetails
        self.communityDayDetails = communityDayDetails
        self.lastUpdated = Date()
    }
}

// MARK: - Spotlight Hour Details

@Model
final class SpotlightDetails {
    var featuredPokemonName: String
    var featuredPokemonImage: String
    var canBeShiny: Bool
    var bonus: String  // z.B. "2× Catch Stardust"
    var allFeaturedPokemon: [PokemonInfo]
    
    init(
        featuredPokemonName: String,
        featuredPokemonImage: String,
        canBeShiny: Bool,
        bonus: String,
        allFeaturedPokemon: [PokemonInfo]
    ) {
        self.featuredPokemonName = featuredPokemonName.htmlDecodedFast
        self.featuredPokemonImage = featuredPokemonImage
        self.canBeShiny = canBeShiny
        self.bonus = bonus.htmlDecodedFast
        self.allFeaturedPokemon = allFeaturedPokemon
    }
}

// MARK: - Raid Battle Details

@Model
final class RaidDetails {
    var bosses: [PokemonInfo]
    var availableShinies: [PokemonInfo]
    
    init(bosses: [PokemonInfo], availableShinies: [PokemonInfo]) {
        self.bosses = bosses
        self.availableShinies = availableShinies
    }
}

// MARK: - Community Day Details

@Model
final class CommunityDayDetails {
    var featuredPokemon: [PokemonInfo]
    var shinies: [PokemonInfo]
    var bonuses: [CommunityDayBonus]
    var bonusDisclaimers: [String]
    var specialResearch: [SpecialResearchStep]

    init(
        featuredPokemon: [PokemonInfo],
        shinies: [PokemonInfo],
        bonuses: [CommunityDayBonus],
        bonusDisclaimers: [String] = [],
        specialResearch: [SpecialResearchStep] = []
    ) {
        self.featuredPokemon = featuredPokemon
        self.shinies = shinies
        self.bonuses = bonuses
        self.bonusDisclaimers = bonusDisclaimers
        self.specialResearch = specialResearch
    }

    /// Computed property for backwards compatibility
    var hasSpecialResearch: Bool {
        return !specialResearch.isEmpty
    }
}

// MARK: - Supporting Models

@Model
final class PokemonInfo {
    var name: String
    var imageURL: String
    var canBeShiny: Bool
    
    init(name: String, imageURL: String, canBeShiny: Bool = false) {
        self.name = name.htmlDecodedFast
        self.imageURL = imageURL
        self.canBeShiny = canBeShiny
    }
}

@Model
final class CommunityDayBonus {
    var text: String
    var iconURL: String?

    init(text: String, iconURL: String? = nil) {
        self.text = text.htmlDecodedFast
        self.iconURL = iconURL
    }
}

// MARK: - Special Research Models

@Model
final class SpecialResearchStep {
    var name: String
    var stepNumber: Int
    var tasks: [ResearchTask]
    var rewards: [ResearchReward]

    init(name: String, stepNumber: Int, tasks: [ResearchTask], rewards: [ResearchReward]) {
        self.name = name.htmlDecodedFast
        self.stepNumber = stepNumber
        self.tasks = tasks
        self.rewards = rewards
    }
}

@Model
final class ResearchTask {
    var text: String
    var reward: ResearchReward

    init(text: String, reward: ResearchReward) {
        self.text = text.htmlDecodedFast
        self.reward = reward
    }
}

@Model
final class ResearchReward {
    var text: String
    var imageURL: String

    init(text: String, imageURL: String) {
        self.text = text.htmlDecodedFast
        self.imageURL = imageURL
    }
}

// MARK: - Convenience Extensions

extension Event {
    /// Display name with HTML entities decoded (for UI display)
    /// Always decodes to ensure compatibility with old cached data
    var displayName: String {
        return name.htmlDecodedFast
    }

    /// Display heading with HTML entities decoded (for UI display)
    /// Always decodes to ensure compatibility with old cached data
    var displayHeading: String {
        return heading.htmlDecodedFast
    }

    /// Prüft ob das Event aktuell läuft
    var isCurrentlyActive: Bool {
        let now = Date()
        let start = actualStartTime
        let end = actualEndTime
        return now >= start && now <= end
    }
    
    /// Prüft ob das Event in der Zukunft liegt
    var isUpcoming: Bool {
        return actualStartTime > Date()
    }
    
    /// Prüft ob das Event bereits vorbei ist
    var isPast: Bool {
        return actualEndTime < Date()
    }
    
    /// Die tatsächliche Startzeit unter Berücksichtigung von isGlobalTime
    var actualStartTime: Date {
        if isGlobalTime {
            // Location-specific event: Die Zeit ist bereits in UTC
            return startTime
        } else {
            // Global event: UTC-Komponenten als lokale Zeit interpretieren
            return convertLocalTimeToUserTime(startTime)
        }
    }

    /// Die tatsächliche Endzeit unter Berücksichtigung von isGlobalTime
    var actualEndTime: Date {
        if isGlobalTime {
            // Location-specific event: Die Zeit ist bereits in UTC
            return endTime
        } else {
            // Global event: UTC-Komponenten als lokale Zeit interpretieren
            return convertLocalTimeToUserTime(endTime)
        }
    }
    
    /// Konvertiert UTC-Komponenten zu User's lokaler Zeit
    private func convertLocalTimeToUserTime(_ date: Date) -> Date {
        // Extrahiere Zeitkomponenten aus UTC
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let components = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        // Interpretiere diese Komponenten als User's lokale Zeit
        var userCalendar = Calendar(identifier: .gregorian)
        userCalendar.timeZone = TimeZone.current
        return userCalendar.date(from: components) ?? date
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
            return String(format: String(localized: "duration.hours_short"), hours)
        } else {
            return String(format: String(localized: "duration.hours_minutes_short"), hours, minutes)
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
    
    /// Event Type Color für farbcodierte Badges
    var eventTypeColor: String {
        switch eventType {
        case "community-day":
            return "green"
        case "raid-hour", "raid-day", "raid-battles", "raid-weekend":
            return "red"
        case "pokemon-spotlight-hour":
            return "yellow"
        case "go-battle-league":
            return "purple"
        case "research", "ticketed-event":
            return "blue"
        case "season":
            return "orange"
        default:
            return "gray"
        }
    }
    
    /// Countdown Text für kommende Events
    var countdownText: String? {
        guard isUpcoming else { return nil }
        
        let now = Date()
        let timeInterval = actualStartTime.timeIntervalSince(now)
        
        let days = Int(timeInterval / 86400)
        let hours = Int((timeInterval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if days > 0 {
            return String(format: String(localized: "countdown.starts_in_days_hours"), days, hours)
        } else if hours > 0 {
            return String(format: String(localized: "countdown.starts_in_hours_minutes"), hours, minutes)
        } else if minutes > 0 {
            return String(format: String(localized: "countdown.starts_in_minutes"), minutes)
        } else {
            return String(localized: "countdown.starting_soon.short")
        }
    }
    
    /// Time Remaining Text für laufende Events
    var timeRemainingText: String? {
        guard isCurrentlyActive else { return nil }
        
        let now = Date()
        let timeInterval = actualEndTime.timeIntervalSince(now)
        
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return String(format: String(localized: "countdown.ends_in_hours_minutes"), hours, minutes)
        } else if minutes > 0 {
            return String(format: String(localized: "countdown.ends_in_minutes"), minutes)
        } else {
            return String(localized: "countdown.ending_soon")
        }
    }
    
    /// Progress (0.0 - 1.0) für laufende Events
    var eventProgress: Double {
        guard isCurrentlyActive else { return 0.0 }
        
        let totalDuration = actualEndTime.timeIntervalSince(actualStartTime)
        let elapsed = Date().timeIntervalSince(actualStartTime)
        
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }
}

// Note: @Model macht die Klasse automatisch Identifiable via persistentModelID
// Keine manuelle Identifiable Extension nötig!

