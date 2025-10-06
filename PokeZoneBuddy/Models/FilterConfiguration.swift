//
//  FilterConfiguration.swift
//  PokeZoneBuddy
//
//  Created by Claude on 03.10.2025.
//  Version 0.4 - Fixed for SwiftData Predicate compatibility
//

import Foundation
import Observation

/// Configuration for filtering events
/// Uses @Observable for modern SwiftUI state management
@Observable
class FilterConfiguration {
    
    // MARK: - Properties
    
    /// Selected event type raw values for filtering (stored as Strings for SwiftData Predicate compatibility)
    var selectedTypes: Set<String> = []
    
    /// Search text for filtering by name/description
    var searchText: String = ""
    
    // MARK: - Computed Properties
    
    /// Returns true if any filter is active
    var isActive: Bool {
        !selectedTypes.isEmpty || !searchText.isEmpty
    }
    
    /// Count of active filters (for badge display)
    var activeFilterCount: Int {
        selectedTypes.count + (searchText.isEmpty ? 0 : 1)
    }
    
    // MARK: - Methods
    
    /// Checks if an event matches the current filter configuration
    /// - Parameter event: The event to check
    /// - Returns: True if the event matches all active filters
    func matches(_ event: Event) -> Bool {
        // Type filter
        if !selectedTypes.isEmpty {
            if !selectedTypes.contains(event.eventType) {
                return false
            }
        }
        
        // Search text filter
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            let matchesName = event.name.lowercased().contains(searchLower)
            let matchesHeading = event.heading.lowercased().contains(searchLower)
            let matchesType = event.eventType.lowercased().contains(searchLower)
            
            if !matchesName && !matchesHeading && !matchesType {
                return false
            }
        }
        
        return true
    }
    
    /// Resets all filters to default state
    func reset() {
        selectedTypes.removeAll()
        searchText = ""
    }
    
    /// Toggle event type filter
    func toggleEventType(_ type: EventType) {
        if selectedTypes.contains(type.rawValue) {
            selectedTypes.remove(type.rawValue)
        } else {
            selectedTypes.insert(type.rawValue)
        }
    }
    
    /// Check if event type is selected
    func isEventTypeSelected(_ type: EventType) -> Bool {
        return selectedTypes.contains(type.rawValue)
    }
}

// MARK: - Event Type Enum

/// All possible Pokemon GO event types
/// Matches the eventType strings from ScrapedDuck API
enum EventType: String, CaseIterable, Identifiable {
    case communityDay = "community-day"
    case raidBattles = "raid-battles"
    case raidHour = "raid-hour"
    case raidDay = "raid-day"
    case raidWeekend = "raid-weekend"
    case spotlightHour = "pokemon-spotlight-hour"
    case battleLeague = "go-battle-league"
    case research = "research"
    case ticketedEvent = "ticketed-event"
    case season = "season"
    case other = "other"
    
    var id: String { rawValue }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .communityDay:
            return String(localized: "event_type.community_day")
        case .raidBattles:
            return String(localized: "event_type.raid_battles")
        case .raidHour:
            return String(localized: "event_type.raid_hour")
        case .raidDay:
            return String(localized: "event_type.raid_day")
        case .raidWeekend:
            return String(localized: "event_type.raid_weekend")
        case .spotlightHour:
            return String(localized: "event_type.spotlight_hour")
        case .battleLeague:
            return String(localized: "event_type.battle_league")
        case .research:
            return String(localized: "event_type.research")
        case .ticketedEvent:
            return String(localized: "event_type.ticketed_event")
        case .season:
            return String(localized: "event_type.season")
        case .other:
            return String(localized: "event_type.other")
        }
    }
    
    /// Icon for UI
    var icon: String {
        switch self {
        case .communityDay:
            return "person.3.fill"
        case .raidBattles, .raidHour, .raidDay, .raidWeekend:
            return "flame.fill"
        case .spotlightHour:
            return "star.fill"
        case .battleLeague:
            return "trophy.fill"
        case .research:
            return "doc.text.magnifyingglass"
        case .ticketedEvent:
            return "ticket.fill"
        case .season:
            return "sparkles"
        case .other:
            return "calendar"
        }
    }
    
    /// Color for UI
    var color: String {
        switch self {
        case .communityDay:
            return "green"
        case .raidBattles, .raidHour, .raidDay, .raidWeekend:
            return "red"
        case .spotlightHour:
            return "yellow"
        case .battleLeague:
            return "purple"
        case .research, .ticketedEvent:
            return "blue"
        case .season:
            return "orange"
        case .other:
            return "gray"
        }
    }
}
