//
//  CoordinateParsingService.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 06.10.2025.
//

import Foundation

/// Service zum Parsen und Formatieren von Koordinaten aus verschiedenen Formaten
struct CoordinateParsingService {

    // MARK: - Main Parsing Method

    /// Extrahiert Koordinaten aus verschiedenen String-Formaten
    /// - Parameter input: Der zu parsende String (URLs, Plain Coordinates, etc.)
    /// - Returns: Tuple mit Latitude und Longitude, oder nil bei Parsing-Fehler
    ///
    /// Unterstützte Formate:
    /// - Plain: "40.760386,-73.828352"
    /// - Mit Space: "40.760386, -73.828352"
    /// - Google Maps: "?q=40.760386,-73.828352" oder "@40.760386,-73.828352"
    /// - Apple Maps: "ll=40.760386,-73.828352"
    /// - Grad/Minuten/Sekunden: "40°45'37.4\"N 73°49'42.1\"W"
    static func parseCoordinates(from input: String) -> (latitude: Double, longitude: Double)? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            AppLogger.app.error("CoordinateParsingService: Empty input string")
            return nil
        }

        // Versuche verschiedene Parsing-Strategien in Reihenfolge
        if let coords = parseGoogleMapsURL(from: trimmed) {
            return validateAndReturn(latitude: coords.latitude, longitude: coords.longitude)
        }

        if let coords = parseAppleMapsURL(from: trimmed) {
            return validateAndReturn(latitude: coords.latitude, longitude: coords.longitude)
        }

        if let coords = parseDMSFormat(from: trimmed) {
            return validateAndReturn(latitude: coords.latitude, longitude: coords.longitude)
        }

        if let coords = parsePlainCoordinates(from: trimmed) {
            return validateAndReturn(latitude: coords.latitude, longitude: coords.longitude)
        }

        AppLogger.app.error("CoordinateParsingService: Could not parse coordinates from: \(trimmed)")
        return nil
    }

    // MARK: - Format for Export

    /// Formatiert Koordinaten für Export (6 Dezimalstellen)
    /// - Parameters:
    ///   - latitude: Breitengrad
    ///   - longitude: Längengrad
    /// - Returns: Formatierter String im Format "lat,long"
    static func formatForExport(latitude: Double, longitude: Double) -> String {
        return String(format: "%.6f,%.6f", latitude, longitude)
    }

    // MARK: - Private Helper Methods

    /// Validiert Koordinaten und gibt sie zurück
    private static func validateAndReturn(
        latitude: Double,
        longitude: Double
    ) -> (latitude: Double, longitude: Double)? {
        guard isValidLatitude(latitude) && isValidLongitude(longitude) else {
            AppLogger.app.error(
                "CoordinateParsingService: Invalid coordinates - lat: \(latitude), long: \(longitude)"
            )
            return nil
        }
        return (latitude, longitude)
    }

    /// Prüft ob ein Breitengrad gültig ist (-90 bis +90)
    private static func isValidLatitude(_ latitude: Double) -> Bool {
        return latitude >= -90.0 && latitude <= 90.0
    }

    /// Prüft ob ein Längengrad gültig ist (-180 bis +180)
    private static func isValidLongitude(_ longitude: Double) -> Bool {
        return longitude >= -180.0 && longitude <= 180.0
    }

    /// Parst Google Maps URLs
    /// Format: "?q=40.760386,-73.828352" oder "@40.760386,-73.828352"
    private static func parseGoogleMapsURL(from input: String) -> (latitude: Double, longitude: Double)? {
        // Google Maps: ?q= oder @ vor Koordinaten
        let googlePattern = #"[?@]q?=?(-?\d+\.?\d*),\s*(-?\d+\.?\d*)"#

        guard let regex = try? NSRegularExpression(pattern: googlePattern),
              let match = regex.firstMatch(
                in: input,
                range: NSRange(input.startIndex..., in: input)
              ),
              match.numberOfRanges == 3 else {
            return nil
        }

        return extractCoordinatesFromMatch(match, in: input)
    }

    /// Parst Apple Maps URLs
    /// Format: "ll=40.760386,-73.828352"
    private static func parseAppleMapsURL(from input: String) -> (latitude: Double, longitude: Double)? {
        let applePattern = #"ll=(-?\d+\.?\d*),\s*(-?\d+\.?\d*)"#

        guard let regex = try? NSRegularExpression(pattern: applePattern),
              let match = regex.firstMatch(
                in: input,
                range: NSRange(input.startIndex..., in: input)
              ),
              match.numberOfRanges == 3 else {
            return nil
        }

        return extractCoordinatesFromMatch(match, in: input)
    }

    /// Parst Plain Koordinaten (mit oder ohne Space)
    /// Format: "40.760386,-73.828352" oder "40.760386, -73.828352"
    private static func parsePlainCoordinates(from input: String) -> (latitude: Double, longitude: Double)? {
        let plainPattern = #"^(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)$"#

        guard let regex = try? NSRegularExpression(pattern: plainPattern),
              let match = regex.firstMatch(
                in: input,
                range: NSRange(input.startIndex..., in: input)
              ),
              match.numberOfRanges == 3 else {
            return nil
        }

        return extractCoordinatesFromMatch(match, in: input)
    }

    /// Parst Grad/Minuten/Sekunden Format
    /// Format: "40°45'37.4"N 73°49'42.1"W"
    private static func parseDMSFormat(from input: String) -> (latitude: Double, longitude: Double)? {
        // DMS Pattern: 40°45'37.4"N 73°49'42.1"W
        let dmsPattern = #"(\d+)°(\d+)'([\d.]+)\"([NS])\s+(\d+)°(\d+)'([\d.]+)\"([EW])"#

        guard let regex = try? NSRegularExpression(pattern: dmsPattern),
              let match = regex.firstMatch(
                in: input,
                range: NSRange(input.startIndex..., in: input)
              ),
              match.numberOfRanges == 9 else {
            return nil
        }

        // Extract latitude components
        guard let latDegreesRange = Range(match.range(at: 1), in: input),
              let latMinutesRange = Range(match.range(at: 2), in: input),
              let latSecondsRange = Range(match.range(at: 3), in: input),
              let latDirectionRange = Range(match.range(at: 4), in: input),
              let latDegrees = Double(input[latDegreesRange]),
              let latMinutes = Double(input[latMinutesRange]),
              let latSeconds = Double(input[latSecondsRange]) else {
            return nil
        }

        let latDirection = String(input[latDirectionRange])

        // Extract longitude components
        guard let lonDegreesRange = Range(match.range(at: 5), in: input),
              let lonMinutesRange = Range(match.range(at: 6), in: input),
              let lonSecondsRange = Range(match.range(at: 7), in: input),
              let lonDirectionRange = Range(match.range(at: 8), in: input),
              let lonDegrees = Double(input[lonDegreesRange]),
              let lonMinutes = Double(input[lonMinutesRange]),
              let lonSeconds = Double(input[lonSecondsRange]) else {
            return nil
        }

        let lonDirection = String(input[lonDirectionRange])

        // Convert DMS to Decimal Degrees
        let latitude = convertDMSToDecimal(
            degrees: latDegrees,
            minutes: latMinutes,
            seconds: latSeconds,
            direction: latDirection
        )

        let longitude = convertDMSToDecimal(
            degrees: lonDegrees,
            minutes: lonMinutes,
            seconds: lonSeconds,
            direction: lonDirection
        )

        return (latitude, longitude)
    }

    /// Extrahiert Koordinaten aus einem Regex-Match
    private static func extractCoordinatesFromMatch(
        _ match: NSTextCheckingResult,
        in input: String
    ) -> (latitude: Double, longitude: Double)? {
        guard let latRange = Range(match.range(at: 1), in: input),
              let lonRange = Range(match.range(at: 2), in: input),
              let latitude = Double(input[latRange]),
              let longitude = Double(input[lonRange]) else {
            return nil
        }

        return (latitude, longitude)
    }

    /// Konvertiert Grad/Minuten/Sekunden zu Dezimal-Graden
    private static func convertDMSToDecimal(
        degrees: Double,
        minutes: Double,
        seconds: Double,
        direction: String
    ) -> Double {
        var decimal = degrees + (minutes / 60.0) + (seconds / 3600.0)

        // Süd und West sind negativ
        if direction == "S" || direction == "W" {
            decimal = -decimal
        }

        return decimal
    }
}
