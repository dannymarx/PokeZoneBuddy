//
//  APIService.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.2025.
//

import Foundation

/// Service für den Abruf von Pokemon GO Events von der ScrapedDuck API
/// API URL: https://raw.githubusercontent.com/bigfoott/ScrapedDuck/data/events.json
/// Credits: Daten von LeekDuck.com via ScrapedDuck by bigfoott
final class APIService {
    
    // MARK: - Singleton
    static let shared = APIService()
    private init() {}
    
    // MARK: - Properties
    
    /// Base URL für die ScrapedDuck API
    private let baseURL = "https://raw.githubusercontent.com/bigfoott/ScrapedDuck/data/events.json"
    
    /// URLSession für Netzwerk-Requests
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
    
    // MARK: - Public Methods
    
    /// Lädt alle verfügbaren Pokemon GO Events von der API
    /// - Returns: Array von Event-Objekten
    /// - Throws: APIError bei Fehlern
    func fetchEvents() async throws -> [Event] {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        do {
            // Netzwerk-Request durchführen
            let (data, response) = try await session.data(from: url)
            
            // HTTP Response validieren
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }
            
            // JSON dekodieren
            let decoder = JSONDecoder()
            // Custom Date Decoder für verschiedene Formate
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // DateFormatter für verschiedene ISO8601 Varianten
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                // Format 1: "2025-08-04T18:00:00.000Z" (mit Z)
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                // Format 2: "2025-08-04T18:00:00.000" (ohne Z, aber mit milliseconds)
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                // Format 3: "2025-08-04T18:00:00" (ohne milliseconds)
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                // Format 4: Mit Z am Ende hinzufügen wenn nicht vorhanden
                if !dateString.hasSuffix("Z") {
                    let modifiedString = dateString + "Z"
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    if let date = formatter.date(from: modifiedString) {
                        return date
                    }
                }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string: \(dateString)"
                )
            }
            
            // API gibt direkt ein Array zurück
            let apiEvents = try decoder.decode([APIEvent].self, from: data)
            
            // API Events in App Events konvertieren
            let events = apiEvents.compactMap { apiEvent -> Event? in
                // Prüfe ob Event global oder lokal ist (basierend auf "Z" im Datum-String)
                // Die API gibt das nicht direkt zurück, also müssen wir es aus dem raw JSON auslesen
                // Für jetzt: Annahme dass Events ohne "Z" lokal sind
                let isGlobal = false // TODO: Aus raw JSON auslesen wenn nötig
                
                return Event(
                    id: apiEvent.eventID,
                    name: apiEvent.name,
                    eventType: apiEvent.eventType,
                    heading: apiEvent.heading,
                    link: apiEvent.link,
                    startTime: apiEvent.start,
                    endTime: apiEvent.end,
                    isGlobalTime: isGlobal,
                    imageURL: apiEvent.image,
                    hasSpawns: apiEvent.extraData?.generic.hasSpawns ?? false,
                    hasFieldResearchTasks: apiEvent.extraData?.generic.hasFieldResearchTasks ?? false
                )
            }
            
            print("✅ \(events.count) Events von API geladen")
            return events
            
        } catch let error as APIError {
            throw error
        } catch let decodingError as DecodingError {
            print("❌ Decoding Fehler: \(decodingError)")
            throw APIError.decodingError(decodingError)
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - API Response Models

/// Event-Struktur wie sie von der API kommt
private struct APIEvent: Decodable {
    let eventID: String
    let name: String
    let eventType: String
    let heading: String
    let link: String?
    let image: String?
    let start: Date
    let end: Date
    let extraData: ExtraData?
    
    struct ExtraData: Decodable {
        let generic: GenericData
        
        struct GenericData: Decodable {
            let hasSpawns: Bool
            let hasFieldResearchTasks: Bool
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case eventID
        case name
        case eventType
        case heading
        case link
        case image
        case start
        case end
        case extraData
    }
}

// MARK: - API Errors

/// Fehlertypen für API-Operationen
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case decodingError(DecodingError)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Die API-URL ist ungültig"
        case .invalidResponse:
            return "Ungültige Antwort vom Server"
        case .httpError(let statusCode):
            return "HTTP Fehler: \(statusCode)"
        case .networkError(let error):
            return "Netzwerkfehler: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Fehler beim Verarbeiten der Daten: \(error.localizedDescription)"
        case .noData:
            return "Keine Daten vom Server erhalten"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL, .invalidResponse, .decodingError:
            return "Bitte versuche es später erneut oder kontaktiere den Support"
        case .httpError:
            return "Der Server ist möglicherweise überlastet. Bitte versuche es später erneut"
        case .networkError:
            return "Überprüfe deine Internetverbindung und versuche es erneut"
        case .noData:
            return "Bitte versuche es später erneut"
        }
    }
}
