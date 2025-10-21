//
//  CitiesViewModel.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.2025.
//  Updated to @Observable for macOS 26 - Version 0.4
//

import Foundation
import SwiftData
import MapKit
import SwiftUI
import Observation

@MainActor
@Observable
final class CitiesViewModel {
    
    // MARK: - Properties

    /// Liste aller Lieblingsstädte
    private(set) var favoriteCities: [FavoriteCity] = []

    /// Trigger to force view updates when data changes
    private(set) var dataVersion: Int = 0

    /// Suchergebnisse bei der Städtesuche
    private(set) var searchResults: [MKLocalSearchCompletion] = []

    /// Current sort option
    var sortOption: CitySortOption = .name {
        didSet {
            sortCities()
        }
    }

    /// Current sort order (ascending/descending)
    var sortOrder: SortOrder = .ascending {
        didSet {
            sortCities()
        }
    }
    
    /// Aktueller Suchtext
    var searchText: String = "" {
        didSet {
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            updateSearch(query: trimmed)
        }
    }
    
    /// Gibt an ob gerade eine Stadt hinzugefügt wird
    private(set) var isAddingCity = false
    
    /// Fehlermeldung falls beim Hinzufügen etwas schief geht
    private(set) var errorMessage: String?
    
    /// Zeigt ob ein Fehler aufgetreten ist
    var showError = false
    
    /// Debounce task for search input to reduce unnecessary queries
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    
    /// MKLocalSearchCompleter für Städte-Suche
    private let searchCompleter: MKLocalSearchCompleter = {
        let completer = MKLocalSearchCompleter()
        // Use address but filter results to show only cities
        completer.resultTypes = [.address]
        return completer
    }()
    
    /// Delegate für SearchCompleter (must be stored property, not lazy with @Observable)
    private var searchCompleterDelegate: SearchCompleterDelegate?
    
    // MARK: - Initialization
    
    /// Initialisiert das ViewModel mit den benötigten Dependencies
    /// - Parameter modelContext: SwiftData ModelContext für Persistierung
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Setup delegate after initialization
        self.searchCompleterDelegate = SearchCompleterDelegate(viewModel: self)
        self.searchCompleter.delegate = self.searchCompleterDelegate
        
        // Lieblingsstädte aus Datenbank laden
        loadFavoriteCitiesFromDatabase()
    }

    // MARK: - Search Helper

    /// Update search query with debouncing to reduce task churn
    /// - Parameter query: The trimmed search query
    @MainActor
    private func updateSearch(query: String) {
        // Cancel any pending debounce task
        searchTask?.cancel()

        // Immediately clear results when empty
        guard !query.isEmpty else {
            searchResults = []
            searchCompleter.cancel()
            return
        }

        // Debounce updates to reduce query frequency
        searchTask = Task {
            do {
                // 250ms debounce
                try await Task.sleep(for: .milliseconds(250))
                // Exit if cancelled
                guard !Task.isCancelled else { return }
                // MKLocalSearchCompleter processes the query fragment
                searchCompleter.queryFragment = query
            } catch {
                // Task cancelled - normal during typing
            }
        }
    }

    // MARK: - Public Methods
    
    /// Lädt Lieblingsstädte aus der lokalen Datenbank
    func loadFavoriteCitiesFromDatabase() {
        do {
            let descriptor = FetchDescriptor<FavoriteCity>()
            favoriteCities = try modelContext.fetch(descriptor)
            sortCities()
            dataVersion += 1  // Increment to trigger view updates
            AppLogger.viewModel.debug("Loaded \(favoriteCities.count) cities from database")
        } catch {
            AppLogger.viewModel.logError("Load cities from database", error: error)
            errorMessage = "Failed to load saved cities"
            showError = true
        }
    }

    /// Sorts the cities list based on current sort option and order
    private func sortCities() {
        let ascending = sortOrder == .ascending

        switch sortOption {
        case .name:
            favoriteCities.sort { city1, city2 in
                ascending ? city1.name < city2.name : city1.name > city2.name
            }

        case .country:
            favoriteCities.sort { city1, city2 in
                let country1 = CityDisplayHelpers.extractCountry(from: city1.fullName) ?? ""
                let country2 = CityDisplayHelpers.extractCountry(from: city2.fullName) ?? ""
                return ascending ? country1 < country2 : country1 > country2
            }

        case .continent:
            favoriteCities.sort { city1, city2 in
                let continent1 = CityDisplayHelpers.continent(from: city1.timeZoneIdentifier)
                let continent2 = CityDisplayHelpers.continent(from: city2.timeZoneIdentifier)
                return ascending ? continent1 < continent2 : continent1 > continent2
            }

        case .timeZone:
            favoriteCities.sort { city1, city2 in
                let offset1 = city1.utcOffsetHours
                let offset2 = city2.utcOffsetHours
                return ascending ? offset1 < offset2 : offset1 > offset2
            }

        case .dateAdded:
            favoriteCities.sort { city1, city2 in
                return ascending ? city1.addedDate < city2.addedDate : city1.addedDate > city2.addedDate
            }

        case .spotCount:
            favoriteCities.sort { city1, city2 in
                let count1 = city1.spotCount
                let count2 = city2.spotCount
                return ascending ? count1 < count2 : count1 > count2
            }
        }
    }
    
    /// Fügt eine neue Stadt zu den Favoriten hinzu
    /// - Parameter completion: MKLocalSearchCompletion aus der Suche
    func addCity(_ completion: MKLocalSearchCompletion) async {
        guard !isAddingCity else { return }
        
        isAddingCity = true
        errorMessage = nil
        showError = false
        
        do {
            // MKLocalSearch durchführen um Details zu bekommen
            let request = MKLocalSearch.Request(completion: completion)
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            guard let mapItem = response.mapItems.first else {
                throw CityError.noResultsFound
            }
            
            // macOS 15+ / iOS 18+: Nutzung der neuen MapKit-APIs
            guard let tzIdentifier = mapItem.timeZone?.identifier else {
                throw CityError.timezoneNotFound
            }
            
            // Extrahiere Stadt-Informationen
            let cityName: String
            let fullName: String

            // Get city name
            if #available(macOS 15.0, iOS 18.0, *) {
                cityName = mapItem.addressRepresentations?.cityName ?? completion.title
            } else {
                cityName = mapItem.placemark.locality ?? completion.title
            }

            // Build full name with city and country
            // Extract country from completion subtitle or use subtitle as is
            let subtitle = completion.subtitle

            // Check if subtitle has format "City, Country" or just "Country"
            // If it contains the city name, extract the country part
            if subtitle.contains(cityName) {
                // Subtitle is like "Berlin, Germany" - extract everything after city
                let components = subtitle.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                if components.count >= 2 {
                    // Take the last component as country
                    fullName = "\(cityName), \(components.last!)"
                } else {
                    fullName = "\(cityName), \(subtitle)"
                }
            } else if !subtitle.isEmpty {
                // Subtitle is the country/region
                fullName = "\(cityName), \(subtitle)"
            } else {
                // No subtitle, just use city name
                fullName = cityName
            }
            
            // Check by timezone identifier (the true unique key)
            if favoriteCities.contains(where: { $0.timeZoneIdentifier == tzIdentifier }) {
                throw CityError.cityAlreadyExists
            }

            // Optional: Warn if names are similar but different timezones
            let normalizedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if favoriteCities.contains(where: {
                $0.fullName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedFullName &&
                $0.timeZoneIdentifier != tzIdentifier
            }) {
                AppLogger.viewModel.warn("Adding city with same name but different timezone: \(fullName) (\(tzIdentifier))")
            }
            
            // Neue Stadt erstellen und speichern
            let newCity = FavoriteCity(
                name: cityName,
                timeZoneIdentifier: tzIdentifier,
                fullName: fullName
            )
            
            modelContext.insert(newCity)
            try modelContext.save()
            
            // Liste neu laden
            loadFavoriteCitiesFromDatabase()

            // Suche zurücksetzen
            searchText = ""
            searchResults = []

            AppLogger.viewModel.infoPrivate("Added city: \(cityName)")
        } catch let error as CityError {
            AppLogger.viewModel.logError("Add city", error: error, context: completion.title)
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            AppLogger.viewModel.logError("Add city (unknown error)", error: error, context: completion.title)
            errorMessage = "Failed to add the city"
            showError = true
        }
        
        isAddingCity = false
    }
    
    /// Entfernt eine Stadt aus den Favoriten
    /// - Parameter city: Die zu entfernende Stadt
    func removeCity(_ city: FavoriteCity) {
        modelContext.delete(city)

        do {
            try modelContext.save()
            loadFavoriteCitiesFromDatabase()
            AppLogger.viewModel.infoPrivate("Removed city: \(city.name)")
        } catch {
            AppLogger.viewModel.logError("Remove city", error: error, context: city.name)
            errorMessage = "Failed to remove the city"
            showError = true
        }
    }

    /// Entfernt mehrere Städte anhand ihrer Indizes
    /// - Parameter offsets: IndexSet der zu entfernenden Städte
    func removeCities(at offsets: IndexSet) {
        for index in offsets {
            let city = favoriteCities[index]
            modelContext.delete(city)
        }

        do {
            try modelContext.save()
            loadFavoriteCitiesFromDatabase()
            AppLogger.viewModel.logSuccess("Removed cities", count: offsets.count, itemName: "city")
        } catch {
            AppLogger.viewModel.logError("Remove multiple cities", error: error)
            errorMessage = "Failed to remove cities"
            showError = true
        }
    }

    // MARK: - Spot Management

    /// Fügt einen neuen Spot zu einer Stadt hinzu
    /// - Parameters:
    ///   - city: Die Stadt, zu der der Spot hinzugefügt werden soll
    ///   - name: Name des Spots
    ///   - notes: Notizen zum Spot
    ///   - latitude: Breitengrad
    ///   - longitude: Längengrad
    ///   - category: Kategorie des Spots
    /// - Returns: true bei Erfolg, false bei Fehler
    func addSpot(
        to city: FavoriteCity,
        name: String,
        notes: String,
        latitude: Double,
        longitude: Double,
        category: SpotCategory
    ) -> Bool {
        // Validierung der Koordinaten
        guard CoordinateParsingService.parseCoordinates(
            from: "\(latitude),\(longitude)"
        ) != nil else {
            AppLogger.viewModel.error("Spot-Validierung fehlgeschlagen: Ungültige Koordinaten")
            errorMessage = "validation.invalid_coordinates"
            showError = true
            return false
        }

        // Prüfe auf Duplikate (gleiche Koordinaten in gleicher Stadt)
        // Uses Haversine distance with 10 meter threshold for realistic duplicate detection
        let isDuplicate = city.spots.contains { spot in
            coordinatesAreDuplicate(lat1: spot.latitude, lon1: spot.longitude,
                                  lat2: latitude, lon2: longitude)
        }

        if isDuplicate {
            AppLogger.viewModel.error(
                "Spot-Duplikat erkannt: Koordinaten existieren bereits in \(city.name)"
            )
            errorMessage = "A spot with these coordinates already exists in this city"
            showError = true
            return false
        }

        // Neuen Spot erstellen
        let newSpot = CitySpot(
            name: name,
            notes: notes,
            latitude: latitude,
            longitude: longitude,
            category: category,
            city: city
        )

        modelContext.insert(newSpot)

        do {
            try modelContext.save()
            // Incremental update instead of full reload
            dataVersion += 1
            AppLogger.viewModel.info(
                "Spot hinzugefügt: \(name) in \(city.name) (\(category.localizedName))"
            )
            return true
        } catch {
            AppLogger.viewModel.error(
                "Fehler beim Speichern des Spots: \(String(describing: error))"
            )
            errorMessage = "Failed to save the spot"
            showError = true
            return false
        }
    }

    /// Löscht einen Spot
    /// - Parameter spot: Der zu löschende Spot
    func deleteSpot(_ spot: CitySpot) {
        let spotName = spot.name
        let cityName = spot.city?.name ?? "Unknown"

        modelContext.delete(spot)

        do {
            try modelContext.save()
            // Incremental update instead of full reload
            dataVersion += 1
            AppLogger.viewModel.info("Spot gelöscht: \(spotName) aus \(cityName)")
        } catch {
            AppLogger.viewModel.error(
                "Fehler beim Löschen des Spots: \(String(describing: error))"
            )
            errorMessage = "Failed to delete the spot"
            showError = true
        }
    }

    /// Entfernt mehrere Spots einer Stadt anhand ihrer Indizes
    /// - Parameters:
    ///   - offsets: IndexSet der zu entfernenden Spots
    ///   - city: Die Stadt, deren Spots gelöscht werden sollen
    func deleteSpots(at offsets: IndexSet, from city: FavoriteCity) {
        let spots = getSpots(for: city)
        for index in offsets {
            let spot = spots[index]
            modelContext.delete(spot)
        }

        do {
            try modelContext.save()
            // Incremental update instead of full reload
            dataVersion += 1
            AppLogger.viewModel.logSuccess("Deleted spots from \(city.name)", count: offsets.count, itemName: "spot")
        } catch {
            AppLogger.viewModel.logError("Delete multiple spots", error: error, context: city.name)
            errorMessage = "Failed to delete spots"
            showError = true
        }
    }

    /// Aktualisiert einen bestehenden Spot
    /// - Parameters:
    ///   - spot: Der zu aktualisierende Spot
    ///   - name: Neuer Name
    ///   - notes: Neue Notizen
    ///   - category: Neue Kategorie
    func updateSpot(
        _ spot: CitySpot,
        name: String,
        notes: String,
        category: SpotCategory
    ) {
        spot.name = name
        spot.notes = notes
        spot.category = category

        do {
            try modelContext.save()
            // Incremental update instead of full reload
            dataVersion += 1
            AppLogger.viewModel.info(
                "Spot aktualisiert: \(name) (\(category.localizedName))"
            )
        } catch {
            AppLogger.viewModel.error(
                "Fehler beim Aktualisieren des Spots: \(String(describing: error))"
            )
            errorMessage = "Failed to update the spot"
            showError = true
        }
    }

    /// Toggelt den Favoriten-Status eines Spots
    /// - Parameter spot: Der Spot, dessen Favoriten-Status geändert werden soll
    func toggleSpotFavorite(_ spot: CitySpot) {
        let newStatus = !spot.isFavorite
        spot.setFavorite(newStatus)

        do {
            try modelContext.save()
            // Incremental update instead of full reload
            dataVersion += 1
            AppLogger.viewModel.info(
                "Spot Favoriten-Status geändert: \(spot.name) -> \(newStatus)"
            )
        } catch {
            AppLogger.viewModel.error(
                "Fehler beim Ändern des Favoriten-Status: \(String(describing: error))"
            )
            errorMessage = "Failed to update favorite status"
            showError = true
        }
    }

    /// Lädt alle Spots für eine Stadt, sortiert nach Erstellungsdatum (neueste zuerst)
    /// - Parameter city: Die Stadt, deren Spots geladen werden sollen
    /// - Returns: Array von CitySpots, sortiert nach createdAt descending
    func getSpots(for city: FavoriteCity) -> [CitySpot] {
        return city.spots.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Import/Export

    /// Exports all city and spot data to JSON
    /// - Returns: Data object containing the JSON representation
    /// - Throws: EncodingError if the data cannot be encoded
    func exportAllData() throws -> Data {
        AppLogger.viewModel.info("Starting export of \(favoriteCities.count) cities")
        let result = try ImportExportService.exportData(cities: favoriteCities)
        AppLogger.viewModel.info("Export completed successfully, data size: \(result.count) bytes")
        return result
    }

    /// Generates a filename for the export
    /// - Returns: String in format "PokeZoneBuddy_Export_YYYY-MM-DD.json"
    func generateExportFilename() -> String {
        return ImportExportService.generateExportFilename()
    }

    /// Previews import data without actually importing
    /// - Parameter url: URL to the JSON file
    /// - Returns: Tuple with city count and spot count
    /// - Throws: Error if file cannot be read or parsed
    func previewImport(from url: URL) async throws -> (cities: Int, spots: Int) {
        let data = try Data(contentsOf: url)
        return try ImportExportService.previewImportData(from: data)
    }

    /// Imports data from a JSON file
    /// - Parameters:
    ///   - url: URL to the JSON file
    ///   - mode: Import mode (merge or replace)
    /// - Returns: ImportResult with statistics
    /// - Throws: Error if import fails
    func importData(from url: URL, mode: ImportExportService.ImportMode) async throws -> ImportExportService.ImportResult {
        let data = try Data(contentsOf: url)
        let result = try ImportExportService.importData(
            from: data,
            mode: mode,
            modelContext: modelContext,
            existingCities: favoriteCities
        )

        // Reload cities after import
        loadFavoriteCitiesFromDatabase()

        return result
    }

    // MARK: - Internal Methods (for SearchCompleterDelegate)

    /// Updates search results - called by delegate
    func updateSearchResults(_ results: [MKLocalSearchCompletion]) {
        // Filter to only show city-like results
        searchResults = results.filter { isCityResult($0) }
    }

    /// Determines if a search completion result appears to be a city
    /// - Parameter completion: The search completion to check
    /// - Returns: true if the result looks like a city
    private func isCityResult(_ completion: MKLocalSearchCompletion) -> Bool {
        let title = completion.title
        let titleLower = title.lowercased()
        let subtitle = completion.subtitle
        let subtitleLower = subtitle.lowercased()

        // Exclude "Search Nearby" results
        if subtitleLower.contains("search nearby") ||
           subtitleLower.contains("suche in der nähe") ||
           subtitleLower.contains("nearby") {
            return false
        }

        // Exclude if title contains numbers (street addresses often have numbers)
        if titleLower.rangeOfCharacter(from: .decimalDigits) != nil {
            return false
        }

        // Check if subtitle contains the title (street within a city)
        // Example: title "Main Street", subtitle "Main Street, New York"
        if !subtitle.isEmpty && subtitleLower.contains(titleLower) {
            return false
        }

        // Comprehensive street indicators
        let streetIndicators = [
            "street", "str.", "str ", "straße", "strasse",
            "avenue", "ave.", "ave ",
            "road", "rd.", "rd ",
            "boulevard", "blvd.", "blvd ",
            "lane", "ln.", "ln ",
            "drive", "dr.", "dr ",
            "way", "weg",
            "court", "ct.", "ct ",
            "place", "pl.", "pl ",
            "circle", "cir.", "cir ",
            "parkway", "pkwy",
            "allee", "alley",
            "gasse",
            "platz",
            "terrace",
            "highway", "hwy"
        ]

        // Check if title ends with or contains street indicators
        for indicator in streetIndicators {
            // Check if word ends with indicator or has it as a separate word
            if titleLower.hasSuffix(indicator) ||
               titleLower.hasSuffix("." + indicator) ||
               titleLower.contains(" " + indicator + " ") ||
               titleLower.contains(" " + indicator) {
                return false
            }
        }

        // Cities typically have comma-separated subtitle with region/country
        // Streets typically have the full address in subtitle
        return true
    }

    // MARK: - Coordinate Helper

    /// Check if two coordinates are duplicates using Haversine distance
    /// - Parameters:
    ///   - lat1: Latitude of first coordinate
    ///   - lon1: Longitude of first coordinate
    ///   - lat2: Latitude of second coordinate
    ///   - lon2: Longitude of second coordinate
    /// - Returns: True if coordinates are within 10 meters of each other
    private func coordinatesAreDuplicate(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Bool {
        let threshold: Double = 10.0 // meters

        // Quick check for exact matches (within floating-point precision)
        if abs(lat1 - lat2) < 0.0000001 && abs(lon1 - lon2) < 0.0000001 {
            return true
        }

        // Haversine distance for nearby coordinates
        let R = 6371000.0 // Earth radius in meters
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        let distance = R * c

        return distance < threshold
    }
}

// MARK: - Search Completer Delegate

/// Delegate für MKLocalSearchCompleter
private class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    weak var viewModel: CitiesViewModel?
    
    init(viewModel: CitiesViewModel) {
        self.viewModel = viewModel
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            viewModel?.updateSearchResults(completer.results)
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        AppLogger.viewModel.error("Search Completer error: \(String(describing: error))")
    }
}

// MARK: - City Errors

/// Fehlertypen für City-Operationen
enum CityError: LocalizedError {
    case noResultsFound
    case invalidLocation
    case timezoneNotFound
    case cityAlreadyExists
    
    var errorDescription: String? {
        switch self {
        case .noResultsFound:
            return "No results found"
        case .invalidLocation:
            return "Invalid location"
        case .timezoneNotFound:
            return "Could not determine time zone"
        case .cityAlreadyExists:
            return "This city is already in your favorites"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noResultsFound:
            return "Try a different search term"
        case .invalidLocation:
            return "Choose a different place"
        case .timezoneNotFound:
            return "Try a different city"
        case .cityAlreadyExists:
            return "This city already exists"
        }
    }
}

