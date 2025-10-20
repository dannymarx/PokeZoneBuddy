//
//  EventDTO+Conversion.swift
//  PokeZoneBuddy
//
//  Created by Claude on 20.10.2025.
//  Converts Sendable DTOs to SwiftData Event models
//

import Foundation

// MARK: - EventDTO to Event Conversion

extension EventDTO {
    /// Converts EventDTO to Event model
    /// This should be called in a ModelContext task (not necessarily main actor)
    nonisolated func toEvent() -> Event {
        return Event(
            id: id,
            name: name,
            eventType: eventType,
            heading: heading,
            link: link,
            startTime: startTime,
            endTime: endTime,
            isGlobalTime: isGlobalTime,
            imageURL: imageURL,
            hasSpawns: hasSpawns,
            hasFieldResearchTasks: hasFieldResearchTasks,
            spotlightDetails: spotlightDetails?.toSpotlightDetails(),
            raidDetails: raidDetails?.toRaidDetails(),
            communityDayDetails: communityDayDetails?.toCommunityDayDetails()
        )
    }
}

// MARK: - SpotlightDetailsDTO to SpotlightDetails Conversion

extension SpotlightDetailsDTO {
    nonisolated func toSpotlightDetails() -> SpotlightDetails {
        return SpotlightDetails(
            featuredPokemonName: featuredPokemonName,
            featuredPokemonImage: featuredPokemonImage,
            canBeShiny: canBeShiny,
            bonus: bonus,
            allFeaturedPokemon: allFeaturedPokemon.map { $0.toPokemonInfo() }
        )
    }
}

// MARK: - RaidDetailsDTO to RaidDetails Conversion

extension RaidDetailsDTO {
    nonisolated func toRaidDetails() -> RaidDetails {
        return RaidDetails(
            bosses: bosses.map { $0.toPokemonInfo() },
            availableShinies: availableShinies.map { $0.toPokemonInfo() }
        )
    }
}

// MARK: - CommunityDayDetailsDTO to CommunityDayDetails Conversion

extension CommunityDayDetailsDTO {
    nonisolated func toCommunityDayDetails() -> CommunityDayDetails {
        return CommunityDayDetails(
            featuredPokemon: featuredPokemon.map { $0.toPokemonInfo() },
            shinies: shinies.map { $0.toPokemonInfo() },
            bonuses: bonuses.map { $0.toCommunityDayBonus() },
            bonusDisclaimers: bonusDisclaimers,
            specialResearch: specialResearch.map { $0.toSpecialResearchStep() }
        )
    }
}

// MARK: - Supporting DTO to Model Conversions

extension PokemonInfoDTO {
    nonisolated func toPokemonInfo() -> PokemonInfo {
        return PokemonInfo(
            name: name,
            imageURL: imageURL,
            canBeShiny: canBeShiny
        )
    }
}

extension CommunityDayBonusDTO {
    nonisolated func toCommunityDayBonus() -> CommunityDayBonus {
        return CommunityDayBonus(
            text: text,
            iconURL: iconURL
        )
    }
}

extension SpecialResearchStepDTO {
    nonisolated func toSpecialResearchStep() -> SpecialResearchStep {
        return SpecialResearchStep(
            name: name,
            stepNumber: stepNumber,
            tasks: tasks.map { $0.toResearchTask() },
            rewards: rewards.map { $0.toResearchReward() }
        )
    }
}

extension ResearchTaskDTO {
    nonisolated func toResearchTask() -> ResearchTask {
        return ResearchTask(
            text: text,
            reward: reward.toResearchReward()
        )
    }
}

extension ResearchRewardDTO {
    nonisolated func toResearchReward() -> ResearchReward {
        return ResearchReward(
            text: text,
            imageURL: imageURL
        )
    }
}
