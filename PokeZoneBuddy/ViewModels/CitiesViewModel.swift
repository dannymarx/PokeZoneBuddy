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
    
    /// Suchergebnisse bei der Städtesuche
    private(set) var searchResults: [MKLocalSearchCompletion] = []
    
    /// Aktueller Suchtext
    var searchText: String = "" {
        didSet {
            // Cancel any pending debounce task
            searchTask?.cancel()

            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                // Immediately clear results when empty
                searchResults = []
                searchCompleter.cancel()
                return
            }

            // Debounce updates to reduce query frequency
            searchTask = Task { [weak self] in
                // 250ms debounce
                try? await Task.sleep(nanoseconds: 250_000_000)
                // Exit if cancelled
                if Task.isCancelled { return }
                await MainActor.run {
                    // MKLocalSearchCompleter verarbeitet den Query-Fragment selbstständig
                    self?.searchCompleter.queryFragment = trimmed
                }
            }
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
    

    // MARK: - Public Methods
    
    /// Lädt Lieblingsstädte aus der lokalen Datenbank
    func loadFavoriteCitiesFromDatabase() {
        do {
            let descriptor = FetchDescriptor<FavoriteCity>(
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            favoriteCities = try modelContext.fetch(descriptor)
        } catch {
            AppLogger.viewModel.error("Fehler beim Laden der Städte: \(String(describing: error))")
            errorMessage = "Failed to load saved cities"
            showError = true
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
            
            // Extrahiere Stadt-Informationen mit neuer MapKit API
            let cityName: String
            let fullName: String
            
            if #available(macOS 15.0, iOS 18.0, *) {
                // Neue API: addressRepresentations für strukturierte Daten
                cityName = mapItem.addressRepresentations?.cityName ?? completion.title
                
                // cityWithContext gibt automatisch "City, Country" oder "City, Region" zurück
                // z.B. "Tokyo, Japan" oder "Los Angeles, California"
                fullName = mapItem.addressRepresentations?.cityWithContext ?? completion.title
            } else {
                // Fallback für ältere Versionen
                cityName = mapItem.placemark.locality ?? completion.title
                // Für ältere Versionen nutzen wir completion.title als fullName
                fullName = completion.title
            }
            
            // Prüfen ob Stadt bereits existiert (basierend auf fullName)
            let normalizedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if favoriteCities.contains(where: {
                $0.fullName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedFullName
            }) {
                throw CityError.cityAlreadyExists
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
            
            AppLogger.viewModel.info("Stadt hinzugefügt: \(cityName)")
        } catch let error as CityError {
            AppLogger.viewModel.error("Fehler beim Hinzufügen: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            AppLogger.viewModel.error("Unbekannter Fehler: \(String(describing: error))")
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
            AppLogger.viewModel.info("Stadt entfernt: \(city.name)")
        } catch {
            AppLogger.viewModel.error("Fehler beim Entfernen: \(String(describing: error))")
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
            AppLogger.viewModel.info("Städte entfernt: \(offsets.count) Stadt(e)")
        } catch {
            AppLogger.viewModel.error("Fehler beim Entfernen: \(String(describing: error))")
            errorMessage = "Failed to remove cities"
            showError = true
        }
    }

    /// Verschiebt Städte in der Liste
    /// - Parameters:
    ///   - source: Quellindizes
    ///   - destination: Zielindex
    func moveCities(from source: IndexSet, to destination: Int) {
        // Note: SwiftData doesn't have built-in ordering, so we would need to add
        // an order property to FavoriteCity model. For now, we'll just update the array
        // which won't persist. This is a limitation we should document.
        // To properly implement this, we need to add a `sortOrder: Int` property to FavoriteCity

        // Just update the local array for immediate UI feedback
        // This won't persist across app launches without adding sortOrder to the model
        var updatedCities = favoriteCities
        updatedCities.move(fromOffsets: source, toOffset: destination)
        favoriteCities = updatedCities

        AppLogger.viewModel.info("Städte verschoben (nur UI, nicht persistiert)")
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
            errorMessage = "Invalid coordinates"
            showError = true
            return false
        }

        // Prüfe auf Duplikate (gleiche Koordinaten in gleicher Stadt)
        let isDuplicate = city.spots.contains { spot in
            abs(spot.latitude - latitude) < 0.000001 &&
            abs(spot.longitude - longitude) < 0.000001
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
            AppLogger.viewModel.info("Spots gelöscht: \(offsets.count) Spot(s) aus \(city.name)")
        } catch {
            AppLogger.viewModel.error("Fehler beim Löschen: \(String(describing: error))")
            errorMessage = "Failed to delete spots"
            showError = true
        }
    }

    /// Verschiebt Spots in der Liste (UI-only, nicht persistiert)
    /// - Parameters:
    ///   - source: Quellindizes
    ///   - destination: Zielindex
    ///   - city: Die Stadt, deren Spots verschoben werden
    func moveSpots(from source: IndexSet, to destination: Int, in city: FavoriteCity) {
        // Note: Similar to cities, this won't persist without adding sortOrder to CitySpot
        AppLogger.viewModel.info("Spots verschoben (nur UI, nicht persistiert)")
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

    // MARK: - Internal Methods (for SearchCompleterDelegate)
    
    /// Updates search results - called by delegate
    func updateSearchResults(_ results: [MKLocalSearchCompletion]) {
        searchResults = results
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

