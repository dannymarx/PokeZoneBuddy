//
//  CitySortOption.swift
//  PokeZoneBuddy
//
//  Sort options for city lists
//

import Foundation

/// Sorting options for city lists
enum CitySortOption: String, CaseIterable, Identifiable {
    case name
    case country
    case continent
    case timeZone
    case dateAdded
    case spotCount

    var id: String { rawValue }

    /// Localized display name for the sort option
    var localizedName: String {
        switch self {
        case .name:
            return String(localized: "sort.name")
        case .country:
            return String(localized: "sort.country")
        case .continent:
            return String(localized: "sort.continent")
        case .timeZone:
            return String(localized: "sort.timezone")
        case .dateAdded:
            return String(localized: "sort.date_added")
        case .spotCount:
            return String(localized: "sort.spot_count")
        }
    }

    /// SF Symbol icon for the sort option
    var icon: String {
        switch self {
        case .name:
            return "textformat.abc"
        case .country:
            return "flag"
        case .continent:
            return "globe"
        case .timeZone:
            return "clock"
        case .dateAdded:
            return "calendar"
        case .spotCount:
            return "mappin.circle"
        }
    }
}

/// Sort order direction
enum SortOrder: String, CaseIterable {
    case ascending
    case descending

    /// Localized display name for the sort order
    var localizedName: String {
        switch self {
        case .ascending:
            return String(localized: "sort.ascending")
        case .descending:
            return String(localized: "sort.descending")
        }
    }

    /// SF Symbol icon for the sort order
    var icon: String {
        switch self {
        case .ascending:
            return "arrow.up"
        case .descending:
            return "arrow.down"
        }
    }

    /// Toggle the sort order
    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}
