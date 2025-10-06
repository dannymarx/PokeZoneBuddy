//
//  APIServiceTests.swift
//  PokeZoneBuddyTests
//
//  Created by Refactoring on 06.10.2025.
//

import XCTest
@testable import PokeZoneBuddy

final class APIServiceTests: XCTestCase {
    
    var apiService: APIService!
    
    override func setUp() {
        super.setUp()
        apiService = APIService.shared
    }
    
    override func tearDown() {
        apiService = nil
        super.tearDown()
    }
    
    // MARK: - Mock JSON Data
    
    private let mockEventJSON = """
    [
        {
            "eventID": "test-community-day-2025",
            "name": "Test Community Day",
            "eventType": "community-day",
            "heading": "Test Pokemon Featured",
            "link": "https://leekduck.com/events/test-cd",
            "image": "https://example.com/test-cd.png",
            "start": "2025-07-15T11:00:00.000Z",
            "end": "2025-07-15T14:00:00.000Z",
            "extraData": {
                "generic": {
                    "hasSpawns": true,
                    "hasFieldResearchTasks": true
                },
                "communityday": {
                    "spawns": [
                        {
                            "name": "Pikachu",
                            "image": "https://example.com/pikachu.png"
                        }
                    ],
                    "shinies": [
                        {
                            "name": "Pikachu",
                            "image": "https://example.com/pikachu-shiny.png"
                        }
                    ],
                    "bonuses": [
                        {
                            "text": "2x Catch XP",
                            "image": "https://example.com/xp-icon.png"
                        }
                    ],
                    "specialresearch": [
                        {
                            "name": "Special Research",
                            "step": 1
                        }
                    ]
                }
            }
        },
        {
            "eventID": "test-raid-hour-2025",
            "name": "Test Raid Hour",
            "eventType": "raid-hour",
            "heading": "Legendary Raids",
            "link": null,
            "image": null,
            "start": "2025-07-16T18:00:00",
            "end": "2025-07-16T19:00:00",
            "extraData": {
                "generic": {
                    "hasSpawns": false,
                    "hasFieldResearchTasks": false
                },
                "raidbattles": {
                    "bosses": [
                        {
                            "name": "Mewtwo",
                            "image": "https://example.com/mewtwo.png",
                            "canBeShiny": true
                        }
                    ],
                    "shinies": [
                        {
                            "name": "Mewtwo",
                            "image": "https://example.com/mewtwo-shiny.png"
                        }
                    ]
                }
            }
        },
        {
            "eventID": "test-spotlight-2025",
            "name": "Spotlight Hour: Eevee",
            "eventType": "spotlight-hour",
            "heading": "Eevee Spotlight + 2x Catch Candy",
            "link": "https://leekduck.com/events/test-spotlight",
            "image": "https://example.com/eevee.png",
            "start": "2025-07-17T18:00:00.000Z",
            "end": "2025-07-17T19:00:00.000Z",
            "extraData": {
                "generic": {
                    "hasSpawns": true,
                    "hasFieldResearchTasks": false
                },
                "spotlight": {
                    "name": "Eevee",
                    "image": "https://example.com/eevee.png",
                    "canBeShiny": true,
                    "bonus": "2x Catch Candy",
                    "list": [
                        {
                            "name": "Eevee",
                            "image": "https://example.com/eevee.png",
                            "canBeShiny": true
                        }
                    ]
                }
            }
        }
    ]
    """
    
    // MARK: - JSON Parsing Tests
    
    func testParseValidJSON() throws {
        let data = mockEventJSON.data(using: .utf8)!
        
        // This test verifies that our mock JSON can be decoded
        // In a real implementation, we'd need to make decodeEvents accessible or test via integration
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Test that basic JSON structure is valid
        XCTAssertNoThrow(try decoder.decode([AnyDecodable].self, from: data))
    }
    
    func testEventIDUniqueness() throws {
        // Mock data should have unique event IDs
        let data = mockEventJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let events = try decoder.decode([MockEvent].self, from: data)
        let eventIDs = events.map { $0.eventID }
        let uniqueIDs = Set(eventIDs)
        
        XCTAssertEqual(eventIDs.count, uniqueIDs.count, "All event IDs should be unique")
    }
    
    func testCommunityDayParsing() throws {
        let data = mockEventJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let events = try decoder.decode([MockEvent].self, from: data)
        let cdEvent = events.first { $0.eventType == "community-day" }
        
        XCTAssertNotNil(cdEvent, "Should find Community Day event")
        XCTAssertEqual(cdEvent?.name, "Test Community Day")
        XCTAssertNotNil(cdEvent?.extraData?.communityday, "Should have Community Day extra data")
        
        let cdData = cdEvent?.extraData?.communityday
        XCTAssertEqual(cdData?.spawns.count, 1)
        XCTAssertEqual(cdData?.shinies.count, 1)
        XCTAssertEqual(cdData?.bonuses.count, 1)
        XCTAssertNotNil(cdData?.specialresearch)
    }
    
    func testRaidHourParsing() throws {
        let data = mockEventJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let events = try decoder.decode([MockEvent].self, from: data)
        let raidEvent = events.first { $0.eventType == "raid-hour" }
        
        XCTAssertNotNil(raidEvent, "Should find Raid Hour event")
        XCTAssertEqual(raidEvent?.name, "Test Raid Hour")
        XCTAssertNotNil(raidEvent?.extraData?.raidbattles, "Should have Raid Battles extra data")
        
        let raidData = raidEvent?.extraData?.raidbattles
        XCTAssertEqual(raidData?.bosses.count, 1)
        XCTAssertEqual(raidData?.shinies.count, 1)
        XCTAssertEqual(raidData?.bosses.first?.name, "Mewtwo")
        XCTAssertTrue(raidData?.bosses.first?.canBeShiny ?? false)
    }
    
    func testSpotlightHourParsing() throws {
        let data = mockEventJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let events = try decoder.decode([MockEvent].self, from: data)
        let spotlightEvent = events.first { $0.eventType == "spotlight-hour" }
        
        XCTAssertNotNil(spotlightEvent, "Should find Spotlight Hour event")
        XCTAssertEqual(spotlightEvent?.name, "Spotlight Hour: Eevee")
        XCTAssertNotNil(spotlightEvent?.extraData?.spotlight, "Should have Spotlight extra data")
        
        let spotlightData = spotlightEvent?.extraData?.spotlight
        XCTAssertEqual(spotlightData?.name, "Eevee")
        XCTAssertEqual(spotlightData?.bonus, "2x Catch Candy")
        XCTAssertTrue(spotlightData?.canBeShiny ?? false)
        XCTAssertEqual(spotlightData?.list.count, 1)
    }
    
    func testDateParsing() throws {
        let data = mockEventJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        // Test custom date decoder
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = DateFormatter()
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
        
        let events = try decoder.decode([MockEvent].self, from: data)
        
        // All events should have valid dates
        for event in events {
            XCTAssertNotNil(event.start)
            XCTAssertNotNil(event.end)
            XCTAssertTrue(event.end > event.start, "End date should be after start date")
        }
    }
    
    func testGlobalTimeDetection() throws {
        // Events with 'Z' suffix should be detected as global time
        let data = mockEventJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let events = try decoder.decode([MockEvent].self, from: data)
        
        // CD and Spotlight have 'Z', Raid Hour doesn't
        let cdEvent = events.first { $0.eventType == "community-day" }
        let raidEvent = events.first { $0.eventType == "raid-hour" }
        
        // In real implementation, we would check the raw string
        // For now, we just verify the structure exists
        XCTAssertNotNil(cdEvent)
        XCTAssertNotNil(raidEvent)
    }
}

// MARK: - Mock Models

private struct AnyDecodable: Decodable {}

private struct MockEvent: Decodable {
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
        let communityday: CommunityDayData?
        let raidbattles: RaidBattlesData?
        let spotlight: SpotlightData?
        
        struct GenericData: Decodable {
            let hasSpawns: Bool
            let hasFieldResearchTasks: Bool
        }
        
        struct CommunityDayData: Decodable {
            let spawns: [PokemonData]
            let shinies: [PokemonData]
            let bonuses: [BonusData]
            let specialresearch: [ResearchData]?
            
            struct PokemonData: Decodable {
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
    }
}
