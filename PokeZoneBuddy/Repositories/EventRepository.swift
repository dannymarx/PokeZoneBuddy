//
//  EventRepository.swift
//  PokeZoneBuddy
//
//  Created by Claude on 10/16/25.
//

import Foundation
import SwiftData

// MARK: - Repository Protocol

protocol EventRepositoryProtocol {
    func fetchEvents() async throws -> [Event]
    func fetchEvent(id: String) async throws -> Event?
    func saveEvent(_ event: Event) async throws
    func saveEvents(_ events: [Event]) async throws
    func deleteEvent(id: String) async throws
    func deleteAllEvents() async throws
}

// MARK: - Repository Implementation

@MainActor
final class EventRepository: EventRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchEvents() async throws -> [Event] {
        let descriptor = FetchDescriptor<Event>(
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchEvent(id: String) async throws -> Event? {
        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func saveEvent(_ event: Event) async throws {
        modelContext.insert(event)
        try modelContext.save()
    }

    func saveEvents(_ events: [Event]) async throws {
        for event in events {
            modelContext.insert(event)
        }
        try modelContext.save()
    }

    func deleteEvent(id: String) async throws {
        guard let event = try await fetchEvent(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(event)
        try modelContext.save()
    }

    func deleteAllEvents() async throws {
        let descriptor = FetchDescriptor<Event>()
        let events = try modelContext.fetch(descriptor)
        for event in events {
            modelContext.delete(event)
        }
        try modelContext.save()
    }
}

// MARK: - Repository Errors

enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed(Error)
    case deleteFailed(Error)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested item was not found"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete: \(error.localizedDescription)"
        case .invalidData:
            return "The data is invalid"
        }
    }
}
