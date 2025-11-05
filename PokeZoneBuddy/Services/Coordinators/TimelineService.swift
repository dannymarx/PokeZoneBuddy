//
//  TimelineService.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-20.
//  Version 1.6.0 - Multi-City Timeline Plans & Templates
//

import Foundation
import Observation

// MARK: - Service Protocol

protocol TimelineServiceProtocol {
    // Plan Management
    func loadPlans(for eventID: String) async throws
    func loadAllPlans() async throws
    func savePlan(name: String, eventID: String, eventName: String, eventType: String, cityIdentifiers: [String]) async throws
    func updatePlan(_ plan: TimelinePlan, name: String, cityIdentifiers: [String]) async throws
    func deletePlan(_ plan: TimelinePlan) async throws

    // Template Management
    func loadTemplates() async throws
    func loadDefaultTemplate(for eventType: String) async throws -> TimelineTemplate?
    func saveTemplate(name: String, eventType: String, cityIdentifiers: [String], isDefault: Bool) async throws
    func updateTemplate(_ template: TimelineTemplate, name: String, cityIdentifiers: [String], isDefault: Bool) async throws
    func deleteTemplate(_ template: TimelineTemplate) async throws

    // Export/Import
    func exportPlan(_ plan: TimelinePlan) async throws -> Data
    func exportTemplate(_ template: TimelineTemplate) async throws -> Data
    func importPlan(from data: Data) async throws -> ImportResult
}

// MARK: - Service Implementation

@Observable
@MainActor
final class TimelineService: TimelineServiceProtocol {

    // MARK: - Published State

    /// Currently loaded plans
    private(set) var plans: [TimelinePlan] = []

    /// Currently loaded templates
    private(set) var templates: [TimelineTemplate] = []

    /// Loading state
    private(set) var isLoading = false

    /// Error message
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let timelineRepository: TimelineRepositoryProtocol
    private let cityRepository: CityRepositoryProtocol

    // MARK: - Constants

    private let appVersion: String

    // MARK: - Initialization

    init(
        timelineRepository: TimelineRepositoryProtocol,
        cityRepository: CityRepositoryProtocol,
        appVersion: String = "1.6.1"
    ) {
        self.timelineRepository = timelineRepository
        self.cityRepository = cityRepository
        self.appVersion = appVersion
    }

    // MARK: - Plan Management

    /// Load plans for a specific event
    func loadPlans(for eventID: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            plans = try await timelineRepository.fetchPlans(for: eventID)
            AppLogger.service.info("Loaded \(plans.count) plans for event: \(eventID)")
        } catch {
            errorMessage = "Failed to load plans"
            AppLogger.service.error("Failed to load plans: \(error)")
            throw error
        }
    }

    /// Load all plans
    func loadAllPlans() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            plans = try await timelineRepository.fetchAllPlans()
            AppLogger.service.info("Loaded \(plans.count) plans")
        } catch {
            errorMessage = "Failed to load all plans"
            AppLogger.service.error("Failed to load all plans: \(error)")
            throw error
        }
    }

    /// Save a new plan
    func savePlan(
        name: String,
        eventID: String,
        eventName: String,
        eventType: String,
        cityIdentifiers: [String]
    ) async throws {
        // Validate
        try validatePlanData(name: name, cityIdentifiers: cityIdentifiers)

        // Create plan
        let plan = TimelinePlan(
            name: name,
            eventID: eventID,
            eventName: eventName,
            eventType: eventType,
            cityIdentifiers: cityIdentifiers
        )

        // Save
        try await timelineRepository.savePlan(plan)
        AppLogger.service.info("Saved plan: \(name) with \(cityIdentifiers.count) cities")

        // Reload plans
        try await loadPlans(for: eventID)
    }

    /// Update an existing plan
    func updatePlan(
        _ plan: TimelinePlan,
        name: String,
        cityIdentifiers: [String]
    ) async throws {
        // Validate
        try validatePlanData(name: name, cityIdentifiers: cityIdentifiers)

        // Update properties
        plan.name = name
        plan.cityIdentifiers = cityIdentifiers

        // Save
        try await timelineRepository.updatePlan(plan)
        AppLogger.service.info("Updated plan: \(name)")

        // Reload plans
        try await loadPlans(for: plan.eventID)
    }

    /// Delete a plan
    func deletePlan(_ plan: TimelinePlan) async throws {
        let eventID = plan.eventID
        try await timelineRepository.deletePlan(plan)
        AppLogger.service.info("Deleted plan: \(plan.name)")

        // Reload plans with simplified logic and error handling
        do {
            if plans.contains(where: { $0.eventID == eventID }) {
                // If we have plans for this event, reload for that event
                try await loadPlans(for: eventID)
            } else {
                // Otherwise reload all plans
                try await loadAllPlans()
            }
        } catch {
            AppLogger.service.error("Failed to reload plans after deletion: \(error)")
            plans = [] // Clear state on error
        }
    }

    // MARK: - Template Management

    /// Load all templates
    func loadTemplates() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            templates = try await timelineRepository.fetchTemplates()
            AppLogger.service.info("Loaded \(templates.count) templates")
        } catch {
            errorMessage = "Failed to load templates"
            AppLogger.service.error("Failed to load templates: \(error)")
            throw error
        }
    }

    /// Load default template for event type
    func loadDefaultTemplate(for eventType: String) async throws -> TimelineTemplate? {
        return try await timelineRepository.fetchTemplate(for: eventType, defaultOnly: true)
    }

    /// Save a new template
    func saveTemplate(
        name: String,
        eventType: String,
        cityIdentifiers: [String],
        isDefault: Bool
    ) async throws {
        // Validate
        try validateTemplateData(name: name, eventType: eventType, cityIdentifiers: cityIdentifiers)

        // Create template
        let template = TimelineTemplate(
            name: name,
            eventType: eventType,
            cityIdentifiers: cityIdentifiers,
            isDefault: isDefault
        )

        // Save
        try await timelineRepository.saveTemplate(template)
        AppLogger.service.info("Saved template: \(name) for event type: \(eventType)")

        // Reload templates
        try await loadTemplates()
    }

    /// Update an existing template
    func updateTemplate(
        _ template: TimelineTemplate,
        name: String,
        cityIdentifiers: [String],
        isDefault: Bool
    ) async throws {
        // Validate
        try validateTemplateData(name: name, eventType: template.eventType, cityIdentifiers: cityIdentifiers)

        // Update properties
        template.name = name
        template.cityIdentifiers = cityIdentifiers
        template.isDefault = isDefault

        // Save
        try await timelineRepository.updateTemplate(template)
        AppLogger.service.info("Updated template: \(name)")

        // Reload templates
        try await loadTemplates()
    }

    /// Delete a template
    func deleteTemplate(_ template: TimelineTemplate) async throws {
        try await timelineRepository.deleteTemplate(template)
        AppLogger.service.info("Deleted template: \(template.name)")

        // Reload templates
        try await loadTemplates()
    }

    // MARK: - Export/Import

    /// Export a plan to JSON data
    func exportPlan(_ plan: TimelinePlan) async throws -> Data {
        // Resolve city identifiers to FavoriteCity objects
        let cities = try await resolveCities(from: plan.cityIdentifiers)

        // Create exportable plan
        let exportablePlan = ExportableTimelinePlan(
            from: plan,
            cities: cities,
            appVersion: appVersion
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(exportablePlan)
        AppLogger.service.info("Exported plan: \(plan.name)")
        return data
    }

    /// Export a template to JSON data
    func exportTemplate(_ template: TimelineTemplate) async throws -> Data {
        // Resolve city identifiers to FavoriteCity objects
        let cities = try await resolveCities(from: template.cityIdentifiers)

        // Create exportable plan
        let exportablePlan = ExportableTimelinePlan(
            from: template,
            cities: cities,
            appVersion: appVersion
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(exportablePlan)
        AppLogger.service.info("Exported template: \(template.name)")
        return data
    }

    /// Import a plan from JSON data
    func importPlan(from data: Data) async throws -> ImportResult {
        // Decode JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportablePlan = try decoder.decode(ExportableTimelinePlan.self, from: data)

        // Validate
        try validateImportedPlan(exportablePlan)

        // Extract city identifiers
        let cityIdentifiers = exportablePlan.cities.map { $0.timeZoneIdentifier }

        // Validate cities
        _ = try await validateAndResolveCities(from: exportablePlan.cities)

        // Determine if this is a plan or template (based on eventID presence)
        let isTemplate = exportablePlan.eventID == nil

        if isTemplate {
            // Import as template
            let template = TimelineTemplate(
                name: exportablePlan.planName,
                eventType: exportablePlan.eventType,
                cityIdentifiers: cityIdentifiers,
                isDefault: false
            )

            try await timelineRepository.saveTemplate(template)
            AppLogger.service.info("Imported template: \(template.name)")

            return ImportResult(
                planName: exportablePlan.planName,
                citiesCount: cityIdentifiers.count,
                eventType: exportablePlan.eventType,
                isTemplate: true,
                errors: []
            )
        } else {
            // Import as plan
            guard let eventID = exportablePlan.eventID,
                  let eventName = exportablePlan.eventName else {
                throw TimelineError.invalidImportData("Missing event ID or name")
            }

            let plan = TimelinePlan(
                name: exportablePlan.planName,
                eventID: eventID,
                eventName: eventName,
                eventType: exportablePlan.eventType,
                cityIdentifiers: cityIdentifiers
            )

            try await timelineRepository.savePlan(plan)
            AppLogger.service.info("Imported plan: \(plan.name)")

            return ImportResult(
                planName: exportablePlan.planName,
                citiesCount: cityIdentifiers.count,
                eventType: exportablePlan.eventType,
                isTemplate: false,
                errors: []
            )
        }
    }

    // MARK: - Validation

    private func validatePlanData(name: String, cityIdentifiers: [String]) throws {
        guard !name.isEmpty else {
            throw TimelineError.emptyPlanName
        }

        guard !cityIdentifiers.isEmpty else {
            throw TimelineError.noCitiesSelected
        }
    }

    private func validateTemplateData(name: String, eventType: String, cityIdentifiers: [String]) throws {
        guard !name.isEmpty else {
            throw TimelineError.emptyTemplateName
        }

        guard !eventType.isEmpty else {
            throw TimelineError.invalidEventType
        }

        guard !cityIdentifiers.isEmpty else {
            throw TimelineError.noCitiesSelected
        }
    }

    private func validateImportedPlan(_ plan: ExportableTimelinePlan) throws {
        // Check version compatibility
        guard plan.version == ExportableTimelinePlan.currentVersion else {
            throw TimelineError.unsupportedVersion(plan.version)
        }

        // Validate plan name
        guard !plan.planName.isEmpty else {
            throw TimelineError.invalidImportData("Plan name is empty")
        }

        // Validate cities
        guard !plan.cities.isEmpty else {
            throw TimelineError.invalidImportData("No cities in plan")
        }

        // Validate timezone identifiers
        for city in plan.cities {
            guard TimeZone(identifier: city.timeZoneIdentifier) != nil else {
                throw TimelineError.invalidTimezone(city.timeZoneIdentifier)
            }
        }
    }

    // MARK: - Helper Methods

    /// Resolve city identifiers to FavoriteCity objects
    private func resolveCities(from identifiers: [String]) async throws -> [FavoriteCity] {
        let allCities = try await cityRepository.fetchCities()
        let cityMap = Dictionary(uniqueKeysWithValues: allCities.map { ($0.timeZoneIdentifier, $0) })

        var resolvedCities: [FavoriteCity] = []
        for identifier in identifiers {
            guard let city = cityMap[identifier] else {
                AppLogger.service.warn("City not found for identifier: \(identifier)")
                continue
            }
            resolvedCities.append(city)
        }

        return resolvedCities
    }

    /// Validate and resolve cities from import data
    private func validateAndResolveCities(from exportCities: [ExportableTimelinePlan.ExportableCity]) async throws -> [String] {
        for exportCity in exportCities {
            // Validate timezone
            guard TimeZone(identifier: exportCity.timeZoneIdentifier) != nil else {
                throw TimelineError.invalidTimezone(exportCity.timeZoneIdentifier)
            }
        }

        return exportCities.map { $0.timeZoneIdentifier }
    }
}

// MARK: - Import Result

struct ImportResult {
    let planName: String
    let citiesCount: Int
    let eventType: String
    let isTemplate: Bool
    let errors: [String]

    var hasErrors: Bool {
        !errors.isEmpty
    }

    var summary: String {
        let type = isTemplate ? "template" : "plan"
        return "Imported \(type): \(planName) with \(citiesCount) cities"
    }
}

// MARK: - Errors

enum TimelineError: LocalizedError {
    case emptyPlanName
    case emptyTemplateName
    case noCitiesSelected
    case invalidEventType
    case invalidTimezone(String)
    case unsupportedVersion(String)
    case invalidImportData(String)

    var errorDescription: String? {
        switch self {
        case .emptyPlanName:
            return String(localized: "timeline.error.empty_plan_name")
        case .emptyTemplateName:
            return String(localized: "timeline.error.empty_template_name")
        case .noCitiesSelected:
            return String(localized: "timeline.error.no_cities")
        case .invalidEventType:
            return String(localized: "timeline.error.invalid_event_type")
        case .invalidTimezone(let identifier):
            return String(localized: "timeline.error.invalid_timezone") + ": \(identifier)"
        case .unsupportedVersion(let version):
            return String(localized: "timeline.error.unsupported_version") + ": \(version)"
        case .invalidImportData(let message):
            return String(localized: "timeline.error.invalid_import") + ": \(message)"
        }
    }
}
