//
//  TipPreferencesStore.swift
//  PokeZoneBuddy
//
//  Created by Codex on 21.10.25.
//

import Foundation
import SwiftData

// MARK: - Tip Preferences Store Protocol

@MainActor
protocol TipPreferencesStoreProtocol: AnyObject {
    func fetchOrCreate() -> TipPreferences
    func update(isEnabled: Bool?, lastReset: Date??) async
}

extension TipPreferencesStoreProtocol {
    func update(isEnabled: Bool? = nil, lastReset: Date?? = nil) async {
        await update(isEnabled: isEnabled, lastReset: lastReset)
    }
}

// MARK: - Tip Preferences Store Implementation

@MainActor
final class TipPreferencesStore: TipPreferencesStoreProtocol {

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let defaults: UserDefaults

    // MARK: - Cache

    private var cachedPreferences: TipPreferences?

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        defaults: UserDefaults = .standard
    ) {
        self.modelContext = modelContext
        self.defaults = defaults

        defaults.register(defaults: [
            TipService.tipsEnabledDefaultsKey: true
        ])
    }

    // MARK: - Fetching

    func fetchOrCreate() -> TipPreferences {
        if let cachedPreferences {
            return cachedPreferences
        }

        var descriptor = FetchDescriptor<TipPreferences>()
        descriptor.fetchLimit = 1

        if let existing = try? modelContext.fetch(descriptor).first {
            cachedPreferences = existing
            defaults.set(existing.isEnabled, forKey: TipService.tipsEnabledDefaultsKey)
            return existing
        }

        let preferences = TipPreferences()
        modelContext.insert(preferences)
        do {
            try modelContext.save()
            AppLogger.tips.info("Created TipPreferences record")
        } catch {
            AppLogger.tips.error("Failed to save TipPreferences: \(error.localizedDescription)")
        }

        defaults.set(preferences.isEnabled, forKey: TipService.tipsEnabledDefaultsKey)
        cachedPreferences = preferences
        return preferences
    }

    // MARK: - Updates

    func update(isEnabled: Bool?, lastReset: Date??) async {
        let preferences = fetchOrCreate()

        if let isEnabled {
            preferences.isEnabled = isEnabled
            defaults.set(isEnabled, forKey: TipService.tipsEnabledDefaultsKey)
        }

        if let lastReset {
            preferences.lastReset = lastReset
        }

        do {
            try modelContext.save()
            AppLogger.tips.info("Updated TipPreferences (isEnabled: \(preferences.isEnabled))")
        } catch {
            AppLogger.tips.error("Failed to update TipPreferences: \(error.localizedDescription)")
        }

        cachedPreferences = preferences
    }
}
