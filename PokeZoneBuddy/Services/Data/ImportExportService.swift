//
//  ImportExportService.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 13.10.2025.
//

import Foundation
import SwiftData

// MARK: - Import/Export Service

/// Service responsible for exporting and importing app data in JSON format
@MainActor
final class ImportExportService {

    // MARK: - Export

    /// Exports all cities and spots to a JSON file
    /// - Parameter cities: Array of FavoriteCity objects to export
    /// - Returns: Data object containing the JSON representation
    /// - Throws: EncodingError if the data cannot be encoded
    static func exportData(cities: [FavoriteCity]) throws -> Data {
        let exportCities = cities.map { ExportCity(from: $0) }
        let exportData = ExportData(cities: exportCities)

        let spotCount = cities.reduce(0) { $0 + $1.spots.count }
        AppLogger.service.info("Starting export of \(cities.count) cities with \(spotCount) spots")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(exportData)
            AppLogger.service.logSuccess("Export completed", count: cities.count, itemName: "city")
            return data
        } catch {
            AppLogger.service.logError("Export data", error: error)
            throw error
        }
    }

    /// Generates a filename for the export with current date
    /// - Returns: String in format "PokeZoneBuddy_Export_YYYY-MM-DD.json"
    static func generateExportFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return "PokeZoneBuddy_Export_\(dateString).json"
    }

    // MARK: - Import

    /// Import result containing statistics about the import operation
    struct ImportResult {
        let citiesImported: Int
        let spotsImported: Int
        let citiesSkipped: Int
        let errors: [String]

        var hasErrors: Bool {
            !errors.isEmpty
        }

        var summary: String {
            var parts: [String] = []

            if citiesImported > 0 {
                parts.append("\(citiesImported) \(citiesImported == 1 ? "city" : "cities")")
            }
            if spotsImported > 0 {
                parts.append("\(spotsImported) \(spotsImported == 1 ? "spot" : "spots")")
            }
            if citiesSkipped > 0 {
                parts.append("\(citiesSkipped) duplicate \(citiesSkipped == 1 ? "city" : "cities") skipped")
            }

            let imported = parts.isEmpty ? "No data imported" : "Imported: " + parts.joined(separator: ", ")

            if hasErrors {
                return imported + "\nErrors: \(errors.count)"
            }
            return imported
        }
    }

    /// Import mode for handling existing data
    enum ImportMode {
        case merge      // Add new cities, skip existing ones
        case replace    // Delete all existing data before import
    }

    /// Validates and imports data from JSON
    /// - Parameters:
    ///   - data: JSON data to import
    ///   - mode: Import mode (merge or replace)
    ///   - modelContext: SwiftData ModelContext for persistence
    ///   - existingCities: Array of existing cities (used for duplicate detection)
    /// - Returns: ImportResult with statistics
    static func importData(
        from data: Data,
        mode: ImportMode,
        modelContext: ModelContext,
        existingCities: [FavoriteCity]
    ) throws -> ImportResult {
        AppLogger.service.info("Starting import in \(mode == .merge ? "merge" : "replace") mode")

        // Decode JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData: ExportData
        do {
            exportData = try decoder.decode(ExportData.self, from: data)
        } catch {
            AppLogger.service.logError("Decode import data", error: error)
            throw error
        }

        // Validate version (for future compatibility)
        guard !exportData.version.isEmpty else {
            AppLogger.service.error("Import validation failed: Missing version information")
            throw ImportError.invalidFormat("Missing version information")
        }

        AppLogger.service.info("Import file contains \(exportData.cities.count) cities (version: \(exportData.version))")

        // Handle replace mode
        if mode == .replace {
            AppLogger.service.info("Deleting \(existingCities.count) existing cities (replace mode)")
            for city in existingCities {
                modelContext.delete(city)
            }
            try modelContext.save()
        }

        // Import cities and spots
        var citiesImported = 0
        var spotsImported = 0
        var citiesSkipped = 0
        var errors: [String] = []

        // Build set of existing timezone identifiers for duplicate detection
        var existingTimezones = Set(existingCities.map { $0.timeZoneIdentifier })

        // Refresh after potential deletion
        if mode == .replace {
            existingTimezones.removeAll()
        }

        for exportCity in exportData.cities {
            do {
                // Validate city data
                try validateCity(exportCity)

                // Check for duplicates (based on timezone identifier)
                if existingTimezones.contains(exportCity.timeZoneIdentifier) {
                    citiesSkipped += 1
                    continue
                }

                // Create new city
                let newCity = FavoriteCity(
                    name: exportCity.name,
                    timeZoneIdentifier: exportCity.timeZoneIdentifier,
                    fullName: exportCity.fullName
                )
                newCity.addedDate = exportCity.addedDate

                modelContext.insert(newCity)
                existingTimezones.insert(exportCity.timeZoneIdentifier)

                // Import spots for this city
                var citySpotCoordinates: Set<String> = []

                for exportSpot in exportCity.spots {
                    do {
                        // Validate spot data
                        try validateSpot(exportSpot)

                        // Check for duplicate coordinates within the same city
                        let coordKey = "\(exportSpot.latitude),\(exportSpot.longitude)"
                        if citySpotCoordinates.contains(coordKey) {
                            continue // Skip duplicate spot silently
                        }

                        // Parse category
                        guard let category = SpotCategory(rawValue: exportSpot.category) else {
                            errors.append("Invalid category '\(exportSpot.category)' for spot '\(exportSpot.name)'")
                            continue
                        }

                        // Create new spot
                        let newSpot = CitySpot(
                            name: exportSpot.name,
                            notes: exportSpot.notes,
                            latitude: exportSpot.latitude,
                            longitude: exportSpot.longitude,
                            category: category,
                            isFavorite: exportSpot.isFavorite,
                            city: newCity
                        )
                        newSpot.createdAt = exportSpot.createdAt

                        modelContext.insert(newSpot)
                        citySpotCoordinates.insert(coordKey)
                        spotsImported += 1

                    } catch {
                        errors.append("Spot '\(exportSpot.name)': \(error.localizedDescription)")
                    }
                }

                citiesImported += 1

            } catch {
                errors.append("City '\(exportCity.name)': \(error.localizedDescription)")
            }
        }

        // Save all changes
        do {
            try modelContext.save()
        } catch {
            AppLogger.service.logError("Save imported data", error: error)
            throw error
        }

        let result = ImportResult(
            citiesImported: citiesImported,
            spotsImported: spotsImported,
            citiesSkipped: citiesSkipped,
            errors: errors
        )

        // Log summary
        if result.hasErrors {
            AppLogger.service.warn("Import completed with errors: \(citiesImported) cities, \(spotsImported) spots, \(citiesSkipped) skipped, \(errors.count) errors")
        } else {
            AppLogger.service.info("Import completed successfully: \(citiesImported) cities, \(spotsImported) spots, \(citiesSkipped) skipped")
        }

        return result
    }

    // MARK: - Validation

    /// Validates city data
    private static func validateCity(_ city: ExportCity) throws {
        guard !city.name.isEmpty else {
            throw ImportError.invalidData("City name is empty")
        }

        guard !city.timeZoneIdentifier.isEmpty else {
            throw ImportError.invalidData("Timezone identifier is empty")
        }

        // Validate timezone identifier
        guard TimeZone(identifier: city.timeZoneIdentifier) != nil else {
            throw ImportError.invalidData("Invalid timezone identifier: \(city.timeZoneIdentifier)")
        }
    }

    /// Validates spot data
    private static func validateSpot(_ spot: ExportSpot) throws {
        guard !spot.name.isEmpty else {
            throw ImportError.invalidData("Spot name is empty")
        }

        // Validate coordinates
        guard spot.latitude >= -90 && spot.latitude <= 90 else {
            throw ImportError.invalidData("Invalid latitude: \(spot.latitude)")
        }

        guard spot.longitude >= -180 && spot.longitude <= 180 else {
            throw ImportError.invalidData("Invalid longitude: \(spot.longitude)")
        }
    }

    // MARK: - Preview Data

    /// Analyzes import data without actually importing it
    /// - Parameter data: JSON data to analyze
    /// - Returns: Tuple with city count and spot count
    /// - Throws: DecodingError if the data is invalid
    static func previewImportData(from data: Data) throws -> (cities: Int, spots: Int) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let exportData = try decoder.decode(ExportData.self, from: data)
            let spotCount = exportData.cities.reduce(0) { $0 + $1.spots.count }

            AppLogger.service.debug("Preview import: \(exportData.cities.count) cities, \(spotCount) spots")
            return (cities: exportData.cities.count, spots: spotCount)
        } catch {
            AppLogger.service.logError("Preview import data", error: error)
            throw error
        }
    }
}

// MARK: - Import Errors

enum ImportError: LocalizedError {
    case invalidFormat(String)
    case invalidData(String)
    case unsupportedVersion(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let message):
            return "Invalid file format: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .unsupportedVersion(let version):
            return "Unsupported version: \(version)"
        }
    }
}
