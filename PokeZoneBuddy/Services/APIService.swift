//
//  APIService.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.2025.
//  Updated for v0.2 on 02.10.2025
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
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                
                // CRITICAL: For local events (no 'Z'), we still parse as UTC
                // but they will be displayed without timezone conversion (same time everywhere)
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                // Try different date formats
                let formats = [
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                    "yyyy-MM-dd'T'HH:mm:ss.SSS",
                    "yyyy-MM-dd'T'HH:mm:ss"
                ]
                
                for format in formats {
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string: \(dateString)"
                )
            }
            
            // Decode API events
            let apiEvents = try decoder.decode([APIEvent].self, from: data)
            
            // Convert to App Events
            let events = apiEvents.compactMap { apiEvent -> Event? in
                // Check if event has global time (contains Z in date string)
                // Check both start and end times for 'Z' suffix
                let startHasZ = apiEvent.rawStartTime?.hasSuffix("Z") ?? false
                let endHasZ = apiEvent.rawEndTime?.hasSuffix("Z") ?? false
                let isGlobal = startHasZ || endHasZ
                
                // Parse extraData for detailed info
                var spotlightDetails: SpotlightDetails?
                var raidDetails: RaidDetails?
                var communityDayDetails: CommunityDayDetails?
                
                if let extraData = apiEvent.extraData {
                    // Spotlight Hour
                    if let spotlight = extraData.spotlight {
                        let pokemonList = spotlight.list.map { pokemon in
                            PokemonInfo(
                                name: pokemon.name,
                                imageURL: pokemon.image,
                                canBeShiny: pokemon.canBeShiny
                            )
                        }
                        
                        spotlightDetails = SpotlightDetails(
                            featuredPokemonName: spotlight.name,
                            featuredPokemonImage: spotlight.image,
                            canBeShiny: spotlight.canBeShiny,
                            bonus: spotlight.bonus,
                            allFeaturedPokemon: pokemonList
                        )
                    }
                    
                    // Raid Battles
                    if let raidBattles = extraData.raidbattles {
                        let bosses = raidBattles.bosses.map { boss in
                            PokemonInfo(
                                name: boss.name,
                                imageURL: boss.image,
                                canBeShiny: boss.canBeShiny
                            )
                        }
                        
                        let shinies = raidBattles.shinies.map { shiny in
                            PokemonInfo(
                                name: shiny.name,
                                imageURL: shiny.image,
                                canBeShiny: true
                            )
                        }
                        
                        raidDetails = RaidDetails(
                            bosses: bosses,
                            availableShinies: shinies
                        )
                    }
                    
                    // Community Day
                    if let cd = extraData.communityday {
                        let spawns = cd.spawns.map { spawn in
                            PokemonInfo(
                                name: spawn.name,
                                imageURL: spawn.image,
                                canBeShiny: true
                            )
                        }
                        
                        let shinies = cd.shinies.map { shiny in
                            PokemonInfo(
                                name: shiny.name,
                                imageURL: shiny.image,
                                canBeShiny: true
                            )
                        }
                        
                        let bonuses = cd.bonuses.map { bonus in
                            CommunityDayBonus(
                                text: bonus.text,
                                iconURL: bonus.image
                            )
                        }
                        
                        communityDayDetails = CommunityDayDetails(
                            featuredPokemon: spawns,
                            shinies: shinies,
                            bonuses: bonuses,
                            hasSpecialResearch: cd.specialresearch != nil && !cd.specialresearch!.isEmpty
                        )
                    }
                }
                
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
                    hasFieldResearchTasks: apiEvent.extraData?.generic.hasFieldResearchTasks ?? false,
                    spotlightDetails: spotlightDetails,
                    raidDetails: raidDetails,
                    communityDayDetails: communityDayDetails
                )
            }
            
            print("✅ \(events.count) events loaded from API")
            return events
            
        } catch let error as APIError {
            throw error
        } catch let decodingError as DecodingError {
            print("❌ Decoding error: \(decodingError)")
            throw APIError.decodingError(decodingError)
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - API Response Models

private struct APIEvent: Decodable {
    let eventID: String
    let name: String
    let eventType: String
    let heading: String
    let link: String?
    let image: String?
    let start: Date
    let end: Date
    let rawStartTime: String?
    let rawEndTime: String?
    let extraData: ExtraData?
    
    struct ExtraData: Decodable {
        let generic: GenericData
        let spotlight: SpotlightData?
        let raidbattles: RaidBattlesData?
        let communityday: CommunityDayData?
        
        struct GenericData: Decodable {
            let hasSpawns: Bool
            let hasFieldResearchTasks: Bool
        }
        
        struct SpotlightData: Decodable {
            let name: String
            let image: String
            let canBeShiny: Bool
            let bonus: String
            let list: [PokemonData]
            
            struct PokemonData: Decodable {
                let name: String
                let image: String
                let canBeShiny: Bool
            }
        }
        
        struct RaidBattlesData: Decodable {
            let bosses: [BossData]
            let shinies: [ShinyData]
            
            struct BossData: Decodable {
                let name: String
                let image: String
                let canBeShiny: Bool
            }
            
            struct ShinyData: Decodable {
                let name: String
                let image: String
            }
        }
        
        struct CommunityDayData: Decodable {
            let spawns: [SpawnData]
            let shinies: [ShinyData]
            let bonuses: [BonusData]
            let specialresearch: [ResearchData]?
            
            struct SpawnData: Decodable {
                let name: String
                let image: String
            }
            
            struct ShinyData: Decodable {
                let name: String
                let image: String
            }
            
            struct BonusData: Decodable {
                let text: String
                let image: String?
            }
            
            struct ResearchData: Decodable {
                let name: String
                let step: Int
            }
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        eventID = try container.decode(String.self, forKey: .eventID)
        name = try container.decode(String.self, forKey: .name)
        eventType = try container.decode(String.self, forKey: .eventType)
        heading = try container.decode(String.self, forKey: .heading)
        link = try container.decodeIfPresent(String.self, forKey: .link)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        start = try container.decode(Date.self, forKey: .start)
        end = try container.decode(Date.self, forKey: .end)
        extraData = try container.decodeIfPresent(ExtraData.self, forKey: .extraData)
        
        // Try to get raw time strings to determine if event is global (has 'Z')
        if let rawContainer = try? decoder.container(keyedBy: RawCodingKeys.self) {
            rawStartTime = try? rawContainer.decode(String.self, forKey: .start)
            rawEndTime = try? rawContainer.decode(String.self, forKey: .end)
        } else {
            rawStartTime = nil
            rawEndTime = nil
        }
    }
    
    enum RawCodingKeys: String, CodingKey {
        case start
        case end
    }
}

// MARK: - API Errors

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
            return "The API URL is invalid"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to process data: \(error.localizedDescription)"
        case .noData:
            return "No data received from server"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL, .invalidResponse, .decodingError:
            return "Please try again later or contact support"
        case .httpError:
            return "The server may be busy. Please try again later"
        case .networkError:
            return "Check your internet connection and try again"
        case .noData:
            return "Please try again later"
        }
    }
}
