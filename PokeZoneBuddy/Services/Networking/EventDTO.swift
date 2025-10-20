//
//  EventDTO.swift
//  PokeZoneBuddy
//
//  Created by Claude on 20.10.2025.
//  Sendable Data Transfer Objects for API layer to comply with Swift 6 concurrency
//

import Foundation

// MARK: - Event DTO

/// Sendable data transfer object for Event
/// Used to safely transfer event data across actor boundaries before converting to SwiftData models
struct EventDTO: Sendable {
    let id: String
    let name: String
    let eventType: String
    let heading: String
    let link: String?
    let startTime: Date
    let endTime: Date
    let isGlobalTime: Bool
    let imageURL: String?
    let hasSpawns: Bool
    let hasFieldResearchTasks: Bool
    let spotlightDetails: SpotlightDetailsDTO?
    let raidDetails: RaidDetailsDTO?
    let communityDayDetails: CommunityDayDetailsDTO?
}

// MARK: - Spotlight Details DTO

struct SpotlightDetailsDTO: Sendable {
    let featuredPokemonName: String
    let featuredPokemonImage: String
    let canBeShiny: Bool
    let bonus: String
    let allFeaturedPokemon: [PokemonInfoDTO]
}

// MARK: - Raid Details DTO

struct RaidDetailsDTO: Sendable {
    let bosses: [PokemonInfoDTO]
    let availableShinies: [PokemonInfoDTO]
}

// MARK: - Community Day Details DTO

struct CommunityDayDetailsDTO: Sendable {
    let featuredPokemon: [PokemonInfoDTO]
    let shinies: [PokemonInfoDTO]
    let bonuses: [CommunityDayBonusDTO]
    let bonusDisclaimers: [String]
    let specialResearch: [SpecialResearchStepDTO]
}

// MARK: - Supporting DTOs

struct PokemonInfoDTO: Sendable {
    let name: String
    let imageURL: String
    let canBeShiny: Bool
}

struct CommunityDayBonusDTO: Sendable {
    let text: String
    let iconURL: String?
}

struct SpecialResearchStepDTO: Sendable {
    let name: String
    let stepNumber: Int
    let tasks: [ResearchTaskDTO]
    let rewards: [ResearchRewardDTO]
}

struct ResearchTaskDTO: Sendable {
    let text: String
    let reward: ResearchRewardDTO
}

struct ResearchRewardDTO: Sendable {
    let text: String
    let imageURL: String
}
