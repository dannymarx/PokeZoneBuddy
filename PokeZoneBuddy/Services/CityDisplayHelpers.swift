//
//  CityDisplayHelpers.swift
//  PokeZoneBuddy
//
//  Helper utilities for displaying city information with flags and continents
//

import Foundation

/// Helper for mapping countries to flag emojis and continents
enum CityDisplayHelpers {

    // MARK: - Flag Emoji Mapping

    /// Converts a country name to its flag emoji
    /// - Parameter countryName: The name of the country
    /// - Returns: Flag emoji string, or nil if not found
    static func flagEmoji(for countryName: String) -> String? {
        let normalized = countryName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Map common country names to their ISO 3166-1 alpha-2 codes
        let countryCodeMap: [String: String] = [
            // Major countries
            "united states": "US",
            "usa": "US",
            "united states of america": "US",
            "japan": "JP",
            "united kingdom": "GB",
            "uk": "GB",
            "great britain": "GB",
            "england": "GB",
            "scotland": "GB",
            "wales": "GB",
            "germany": "DE",
            "deutschland": "DE",
            "france": "FR",
            "italy": "IT",
            "italia": "IT",
            "spain": "ES",
            "españa": "ES",
            "canada": "CA",
            "australia": "AU",
            "new zealand": "NZ",
            "china": "CN",
            "south korea": "KR",
            "korea": "KR",
            "india": "IN",
            "brazil": "BR",
            "brasil": "BR",
            "mexico": "MX",
            "méxico": "MX",
            "russia": "RU",
            "netherlands": "NL",
            "holland": "NL",
            "belgium": "BE",
            "belgië": "BE",
            "belgique": "BE",
            "switzerland": "CH",
            "schweiz": "CH",
            "suisse": "CH",
            "austria": "AT",
            "österreich": "AT",
            "sweden": "SE",
            "sverige": "SE",
            "norway": "NO",
            "norge": "NO",
            "denmark": "DK",
            "danmark": "DK",
            "finland": "FI",
            "suomi": "FI",
            "poland": "PL",
            "polska": "PL",
            "portugal": "PT",
            "greece": "GR",
            "ελλάδα": "GR",
            "ireland": "IE",
            "éire": "IE",
            "czechia": "CZ",
            "czech republic": "CZ",
            "hungary": "HU",
            "magyarország": "HU",
            "romania": "RO",
            "românia": "RO",
            "turkey": "TR",
            "türkiye": "TR",
            "south africa": "ZA",
            "egypt": "EG",
            "israel": "IL",
            "saudi arabia": "SA",
            "uae": "AE",
            "united arab emirates": "AE",
            "thailand": "TH",
            "singapore": "SG",
            "malaysia": "MY",
            "indonesia": "ID",
            "philippines": "PH",
            "vietnam": "VN",
            "argentina": "AR",
            "chile": "CL",
            "colombia": "CO",
            "peru": "PE",
            "perú": "PE",
            "iceland": "IS",
            "ísland": "IS",
            "luxembourg": "LU",
            "hong kong": "HK",
            "taiwan": "TW",
            "ukraine": "UA",
            "україна": "UA"
        ]

        guard let countryCode = countryCodeMap[normalized] else {
            return nil
        }

        return flagEmoji(fromCountryCode: countryCode)
    }

    /// Converts ISO 3166-1 alpha-2 country code to flag emoji
    /// - Parameter countryCode: Two-letter country code (e.g., "US", "JP")
    /// - Returns: Flag emoji string
    private static func flagEmoji(fromCountryCode countryCode: String) -> String {
        let base: UInt32 = 127397
        var emoji = ""

        for scalar in countryCode.uppercased().unicodeScalars {
            if let scalarValue = UnicodeScalar(base + scalar.value) {
                emoji.append(String(scalarValue))
            }
        }

        return emoji
    }

    // MARK: - Continent Mapping

    /// Determines the continent from a timezone identifier
    /// - Parameter timezoneIdentifier: Timezone identifier (e.g., "Asia/Tokyo")
    /// - Returns: Continent name, or "Unknown" if not determinable
    static func continent(from timezoneIdentifier: String) -> String {
        let components = timezoneIdentifier.split(separator: "/")
        guard let region = components.first?.lowercased() else {
            return String(localized: "continent.unknown")
        }

        switch region {
        case "africa":
            return String(localized: "continent.africa")
        case "america":
            // Distinguish between North and South America based on timezone
            if timezoneIdentifier.contains("Argentina") ||
               timezoneIdentifier.contains("Buenos_Aires") ||
               timezoneIdentifier.contains("Sao_Paulo") ||
               timezoneIdentifier.contains("Santiago") ||
               timezoneIdentifier.contains("Lima") ||
               timezoneIdentifier.contains("Bogota") ||
               timezoneIdentifier.contains("Caracas") {
                return String(localized: "continent.south_america")
            } else {
                return String(localized: "continent.north_america")
            }
        case "antarctica":
            return String(localized: "continent.antarctica")
        case "arctic":
            return String(localized: "continent.arctic")
        case "asia":
            return String(localized: "continent.asia")
        case "atlantic":
            return String(localized: "continent.atlantic")
        case "australia":
            return String(localized: "continent.oceania")
        case "europe":
            return String(localized: "continent.europe")
        case "indian":
            return String(localized: "continent.indian_ocean")
        case "pacific":
            return String(localized: "continent.oceania")
        default:
            return String(localized: "continent.unknown")
        }
    }

    /// Extracts country name from full city name
    /// - Parameter fullName: Full city name (e.g., "Tokyo, Japan")
    /// - Returns: Country name, or nil if not extractable
    static func extractCountry(from fullName: String) -> String? {
        let components = fullName.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        // Full name format is typically "City, Country" or "City, Region, Country"
        if components.count >= 2 {
            return components.last
        }

        return nil
    }
}
