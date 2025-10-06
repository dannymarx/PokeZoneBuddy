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
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                searchResults = []
                searchCompleter.cancel()
            } else {
                // MKLocalSearchCompleter verarbeitet den Query-Fragment selbstständig
                searchCompleter.queryFragment = trimmed
            }
        }
    }
    
    /// Gibt an ob gerade eine Stadt hinzugefügt wird
    private(set) var isAddingCity = false
    
    /// Fehlermeldung falls beim Hinzufügen etwas schief geht
    private(set) var errorMessage: String?
    
    /// Zeigt ob ein Fehler aufgetreten ist
    var showError = false
    
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
    
    deinit {
        searchCompleter.delegate = nil
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

