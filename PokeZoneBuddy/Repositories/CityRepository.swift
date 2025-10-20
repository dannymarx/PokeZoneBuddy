//
//  CityRepository.swift
//  PokeZoneBuddy
//
//  Created by Claude on 10/16/25.
//

import Foundation
import SwiftData

// MARK: - Repository Protocol

protocol CityRepositoryProtocol {
    func fetchCities() async throws -> [FavoriteCity]
    func fetchCity(persistentModelID: PersistentIdentifier) async throws -> FavoriteCity?
    func saveCity(_ city: FavoriteCity) async throws
    func deleteCity(_ city: FavoriteCity) async throws
    func updateCity(_ city: FavoriteCity) async throws

    // Spot operations
    func fetchSpots(for city: FavoriteCity) async throws -> [CitySpot]
    func fetchAllSpots() async throws -> [CitySpot]
    func saveSpot(_ spot: CitySpot, to city: FavoriteCity) async throws
    func deleteSpot(_ spot: CitySpot) async throws
    func updateSpot(_ spot: CitySpot) async throws
    func toggleSpotFavorite(_ spot: CitySpot) async throws
}

// MARK: - Repository Implementation

@MainActor
final class CityRepository: CityRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - City Operations

    func fetchCities() async throws -> [FavoriteCity] {
        let descriptor = FetchDescriptor<FavoriteCity>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCity(persistentModelID: PersistentIdentifier) async throws -> FavoriteCity? {
        return modelContext.model(for: persistentModelID) as? FavoriteCity
    }

    func saveCity(_ city: FavoriteCity) async throws {
        modelContext.insert(city)
        try modelContext.save()
    }

    func deleteCity(_ city: FavoriteCity) async throws {
        modelContext.delete(city)
        try modelContext.save()
    }

    func updateCity(_ city: FavoriteCity) async throws {
        try modelContext.save()
    }

    // MARK: - Spot Operations

    func fetchSpots(for city: FavoriteCity) async throws -> [CitySpot] {
        let cityID = city.id
        let descriptor = FetchDescriptor<CitySpot>(
            predicate: #Predicate { $0.city?.id == cityID },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAllSpots() async throws -> [CitySpot] {
        let descriptor = FetchDescriptor<CitySpot>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func saveSpot(_ spot: CitySpot, to city: FavoriteCity) async throws {
        spot.city = city
        modelContext.insert(spot)
        try modelContext.save()
    }

    func deleteSpot(_ spot: CitySpot) async throws {
        modelContext.delete(spot)
        try modelContext.save()
    }

    func updateSpot(_ spot: CitySpot) async throws {
        try modelContext.save()
    }

    func toggleSpotFavorite(_ spot: CitySpot) async throws {
        spot.setFavorite(!spot.isFavorite)
        try modelContext.save()
    }
}
