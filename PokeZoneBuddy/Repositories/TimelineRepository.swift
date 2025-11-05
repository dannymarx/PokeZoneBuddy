//
//  TimelineRepository.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-20.
//  Version 1.6.0 - Multi-City Timeline Plans & Templates
//

import Foundation
import SwiftData

// MARK: - Repository Protocol

/// Protocol for timeline plan and template data access
protocol TimelineRepositoryProtocol {
    // MARK: Plans

    /// Fetch all plans for a specific event
    /// - Parameter eventID: The event's unique identifier
    /// - Returns: Array of timeline plans, sorted by modification date (newest first)
    func fetchPlans(for eventID: String) async throws -> [TimelinePlan]

    /// Fetch all plans
    /// - Returns: Array of all timeline plans
    func fetchAllPlans() async throws -> [TimelinePlan]

    /// Save a new plan
    /// - Parameter plan: The timeline plan to save
    func savePlan(_ plan: TimelinePlan) async throws

    /// Update an existing plan
    /// - Parameter plan: The timeline plan to update
    func updatePlan(_ plan: TimelinePlan) async throws

    /// Delete a plan
    /// - Parameter plan: The timeline plan to delete
    func deletePlan(_ plan: TimelinePlan) async throws

    // MARK: Templates

    /// Fetch all templates
    /// - Returns: Array of all timeline templates
    func fetchTemplates() async throws -> [TimelineTemplate]

    /// Fetch template for a specific event type
    /// - Parameters:
    ///   - eventType: The event type to match
    ///   - defaultOnly: If true, only return the default template
    /// - Returns: The matching template, or nil if not found
    func fetchTemplate(for eventType: String, defaultOnly: Bool) async throws -> TimelineTemplate?

    /// Save a new template
    /// - Parameter template: The timeline template to save
    func saveTemplate(_ template: TimelineTemplate) async throws

    /// Update an existing template
    /// - Parameter template: The timeline template to update
    func updateTemplate(_ template: TimelineTemplate) async throws

    /// Delete a template
    /// - Parameter template: The timeline template to delete
    func deleteTemplate(_ template: TimelineTemplate) async throws
}

// MARK: - Repository Implementation

@MainActor
final class TimelineRepository: TimelineRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Plans

    func fetchPlans(for eventID: String) async throws -> [TimelinePlan] {
        let descriptor = FetchDescriptor<TimelinePlan>(
            predicate: #Predicate { $0.eventID == eventID },
            sortBy: [SortDescriptor(\.dateModified, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAllPlans() async throws -> [TimelinePlan] {
        let descriptor = FetchDescriptor<TimelinePlan>(
            sortBy: [SortDescriptor(\.dateModified, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func savePlan(_ plan: TimelinePlan) async throws {
        modelContext.insert(plan)
        try modelContext.save()
    }

    func updatePlan(_ plan: TimelinePlan) async throws {
        plan.dateModified = Date()
        try modelContext.save()
    }

    func deletePlan(_ plan: TimelinePlan) async throws {
        modelContext.delete(plan)
        try modelContext.save()
    }

    // MARK: - Templates

    func fetchTemplates() async throws -> [TimelineTemplate] {
        let descriptor = FetchDescriptor<TimelineTemplate>(
            sortBy: [SortDescriptor(\.dateModified, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchTemplate(for eventType: String, defaultOnly: Bool) async throws -> TimelineTemplate? {
        let descriptor: FetchDescriptor<TimelineTemplate>

        if defaultOnly {
            descriptor = FetchDescriptor<TimelineTemplate>(
                predicate: #Predicate { template in
                    template.eventType == eventType && template.isDefault == true
                },
                sortBy: [SortDescriptor(\.dateModified, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<TimelineTemplate>(
                predicate: #Predicate { $0.eventType == eventType },
                sortBy: [SortDescriptor(\.dateModified, order: .reverse)]
            )
        }

        let templates = try modelContext.fetch(descriptor)
        return templates.first
    }

    func saveTemplate(_ template: TimelineTemplate) async throws {
        // If this template is being set as default, unset any existing default for this event type
        if template.isDefault {
            let existingDefaults = try await fetchExistingDefaults(for: template.eventType)
            for existing in existingDefaults where existing.id != template.id {
                existing.isDefault = false
            }
        }

        modelContext.insert(template)
        try modelContext.save()
    }

    func updateTemplate(_ template: TimelineTemplate) async throws {
        // If this template is being set as default, unset any existing default for this event type
        if template.isDefault {
            let existingDefaults = try await fetchExistingDefaults(for: template.eventType)
            for existing in existingDefaults where existing.id != template.id {
                existing.isDefault = false
            }
        }

        template.dateModified = Date()
        try modelContext.save()
    }

    func deleteTemplate(_ template: TimelineTemplate) async throws {
        modelContext.delete(template)
        try modelContext.save()
    }

    // MARK: - Private Helpers

    private func fetchExistingDefaults(for eventType: String) async throws -> [TimelineTemplate] {
        let descriptor = FetchDescriptor<TimelineTemplate>(
            predicate: #Predicate { template in
                template.eventType == eventType && template.isDefault == true
            }
        )
        return try modelContext.fetch(descriptor)
    }
}
