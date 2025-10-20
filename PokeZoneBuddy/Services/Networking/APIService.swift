//
//  APIService.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.2025.
//  Version 0.4 - Added Offline Support with URLCache
//

import Foundation

/// Actor to manage concurrent request deduplication
private actor RequestCoordinator {
    private var ongoingTask: Task<[EventDTO], Error>?

    func getOrCreateTask(forceRefresh: Bool, performFetch: @escaping (Bool) async throws -> [EventDTO]) async throws -> [EventDTO] {
        // If there's an existing task, reuse it
        if let existingTask = ongoingTask {
            return try await existingTask.value
        }

        // Create new task
        let task = Task<[EventDTO], Error> {
            try await performFetch(forceRefresh)
        }
        ongoingTask = task

        // Wait for completion and clean up
        do {
            let result = try await task.value
            ongoingTask = nil
            return result
        } catch {
            ongoingTask = nil
            throw error
        }
    }
}

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

    /// Request coordinator for concurrent request management
    private let requestCoordinator = RequestCoordinator()
    
    /// URLSession für Netzwerk-Requests mit optimiertem Caching
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60

        // Reduce network error verbosity
        config.waitsForConnectivity = true

        // OPTIMIZED: URLCache für automatisches Image + API Caching
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cacheURL = cachesDirectory.appendingPathComponent("PokeZoneBuddyCache")

        let cache = URLCache(
            memoryCapacity: 50_000_000,   // 50 MB memory (Images + API responses)
            diskCapacity: 200_000_000,    // 200 MB disk (plenty for offline mode)
            directory: cacheURL
        )

        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad

        return URLSession(configuration: config)
    }()
    
    // MARK: - Public Methods
    
    /// Lädt alle verfügbaren Pokemon GO Events von der API
    /// OFFLINE: Falls Netzwerk nicht verfügbar, wird auf gecachte Daten zurückgegriffen
    /// - Parameter forceRefresh: Wenn true, ignoriert Cache und lädt von Server
    /// - Returns: Array von EventDTO-Objekten (Sendable data transfer objects)
    /// - Throws: APIError bei Fehlern
    func fetchEvents(forceRefresh: Bool = false) async throws -> [EventDTO] {
        return try await requestCoordinator.getOrCreateTask(forceRefresh: forceRefresh) { [weak self] forceRefresh in
            guard let self = self else {
                throw APIError.invalidResponse
            }
            return try await self.performFetch(forceRefresh: forceRefresh)
        }
    }

    /// Internal method to perform the actual network fetch
    private func performFetch(forceRefresh: Bool) async throws -> [EventDTO] {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)

        // OFFLINE: Cache policy
        if forceRefresh {
            request.cachePolicy = .reloadIgnoringLocalCacheData
        } else {
            request.cachePolicy = .returnCacheDataElseLoad
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // OFFLINE: Accept cached data even if stale
            if httpResponse.statusCode == 200 || request.cachePolicy == .returnCacheDataElseLoad {
                let events = try decodeEvents(from: data)
                AppLogger.network.info("Loaded \(events.count) events (from \(httpResponse.statusCode == 200 ? "network" : "cache"))")
                return events
            }

            throw APIError.httpError(statusCode: httpResponse.statusCode)

        } catch {
            // Check if this is a cancellation error - don't treat as fatal
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                AppLogger.network.debug("Request was cancelled, attempting cache fallback")
            }

            // OFFLINE: Try to return cached data on error
            if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
                let events = try decodeEvents(from: cachedResponse.data)
                AppLogger.network.warn("Using cached events due to error: \(error)")
                return events
            }

            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// Dekodiert Event-Daten von JSON
    private func decodeEvents(from data: Data) throws -> [EventDTO] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = DateFormatter()
            // Note: POSIX-like parsing remains robust as we pin timezone to GMT.
            formatter.locale = Locale.autoupdatingCurrent
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
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
        
        let apiEvents = try decoder.decode([APIEvent].self, from: data)

        // Convert to EventDTO models (Sendable)
        return apiEvents.compactMap { apiEvent -> EventDTO? in
            let startHasZ = apiEvent.rawStartTime?.hasSuffix("Z") ?? false
            let endHasZ = apiEvent.rawEndTime?.hasSuffix("Z") ?? false
            let isGlobal = startHasZ || endHasZ

            // Parse extraData for detailed info
            var spotlightDetails: SpotlightDetailsDTO?
            var raidDetails: RaidDetailsDTO?
            var communityDayDetails: CommunityDayDetailsDTO?

            if let extraData = apiEvent.extraData {
                // Spotlight Hour
                if let spotlight = extraData.spotlight {
                    let pokemonList = spotlight.list.map { pokemon in
                        PokemonInfoDTO(
                            name: pokemon.name,
                            imageURL: pokemon.image,
                            canBeShiny: pokemon.canBeShiny
                        )
                    }

                    spotlightDetails = SpotlightDetailsDTO(
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
                        PokemonInfoDTO(
                            name: boss.name,
                            imageURL: boss.image,
                            canBeShiny: boss.canBeShiny
                        )
                    }

                    let shinies = raidBattles.shinies.map { shiny in
                        PokemonInfoDTO(
                            name: shiny.name,
                            imageURL: shiny.image,
                            canBeShiny: true
                        )
                    }

                    raidDetails = RaidDetailsDTO(
                        bosses: bosses,
                        availableShinies: shinies
                    )
                }

                // Community Day
                if let cd = extraData.communityday {
                    let spawns = cd.spawns.map { spawn in
                        PokemonInfoDTO(
                            name: spawn.name,
                            imageURL: spawn.image,
                            canBeShiny: true
                        )
                    }

                    let shinies = cd.shinies.map { shiny in
                        PokemonInfoDTO(
                            name: shiny.name,
                            imageURL: shiny.image,
                            canBeShiny: true
                        )
                    }

                    let bonuses = cd.bonuses.map { bonus in
                        CommunityDayBonusDTO(
                            text: bonus.text,
                            iconURL: bonus.image
                        )
                    }

                    // Parse special research steps
                    var specialResearch: [SpecialResearchStepDTO] = []
                    if let researchData = cd.specialresearch {
                        specialResearch = researchData.compactMap { research in
                            guard let tasks = research.tasks, let rewards = research.rewards else {
                                return nil
                            }

                            let researchTasks = tasks.map { task in
                                let taskReward = ResearchRewardDTO(
                                    text: task.reward.text,
                                    imageURL: task.reward.image
                                )
                                return ResearchTaskDTO(text: task.text, reward: taskReward)
                            }

                            let researchRewards = rewards.map { reward in
                                ResearchRewardDTO(text: reward.text, imageURL: reward.image)
                            }

                            return SpecialResearchStepDTO(
                                name: research.name,
                                stepNumber: research.step,
                                tasks: researchTasks,
                                rewards: researchRewards
                            )
                        }
                    }

                    communityDayDetails = CommunityDayDetailsDTO(
                        featuredPokemon: spawns,
                        shinies: shinies,
                        bonuses: bonuses,
                        bonusDisclaimers: cd.bonusDisclaimers ?? [],
                        specialResearch: specialResearch
                    )
                }
            }

            return EventDTO(
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
            let bonusDisclaimers: [String]?
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
                let tasks: [TaskData]?
                let rewards: [RewardData]?

                struct TaskData: Decodable {
                    let text: String
                    let reward: RewardData
                }

                struct RewardData: Decodable {
                    let text: String
                    let image: String
                }
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

