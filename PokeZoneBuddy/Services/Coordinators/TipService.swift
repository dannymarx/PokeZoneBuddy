//
//  TipService.swift
//  PokeZoneBuddy
//
//  Created by Codex on 21.10.25.
//

import Foundation
import Observation
import TipKit

@MainActor
@Observable
final class TipService {

    // MARK: - Constants

    static let tipsEnabledDefaultsKey = "tipsEnabled"

    // MARK: - Dependencies

    @ObservationIgnored private let store: TipStore
    @ObservationIgnored private let preferencesStore: TipPreferencesStoreProtocol

    // MARK: - State

    private(set) var tipsEnabled: Bool
    private(set) var lastReset: Date?
    private var isConfigured = false

    // MARK: - Initialization

    init(
        store: TipStore = .shared,
        preferencesStore: TipPreferencesStoreProtocol
    ) {
        self.store = store
        self.preferencesStore = preferencesStore

        let preferences = preferencesStore.fetchOrCreate()
        self.tipsEnabled = preferences.isEnabled
        self.lastReset = preferences.lastReset
    }

    // MARK: - Configuration

    func configureIfNeeded(with tips: [any Tip.Type]) async {
        guard !isConfigured else { return }

        do {
            try await store.load()

            if !tips.isEmpty {
                try await store.register(tips: tips)
            }

            try await store.setTipsEnabled(tipsEnabled)

            isConfigured = true
            AppLogger.tips.info("TipKit configured (enabled: \(tipsEnabled))")
        } catch {
            AppLogger.tips.error("Failed to configure TipKit: \(error.localizedDescription)")
        }
    }

    // MARK: - Preference Updates

    func setTipsEnabled(_ isEnabled: Bool) async {
        guard tipsEnabled != isEnabled else { return }

        tipsEnabled = isEnabled

        await preferencesStore.update(isEnabled: isEnabled)

        do {
            try await store.setTipsEnabled(isEnabled)
            AppLogger.tips.info("Updated TipKit enabled state: \(isEnabled)")

            if !isEnabled {
                try await store.invalidateAllTips()
            }
        } catch {
            AppLogger.tips.error("Failed to update TipKit enabled state: \(error.localizedDescription)")
        }
    }

    func resetTips() async {
        do {
            try await store.resetAllTips()
            let resetDate = Date()
            lastReset = resetDate
            await preferencesStore.update(lastReset: .some(resetDate))
            AppLogger.tips.info("Reset all tips")
        } catch {
            AppLogger.tips.error("Failed to reset tips: \(error.localizedDescription)")
        }
    }

    // MARK: - Tip Triggers

    func recordPlanSaved() {}

    func recordFiltersUsed() {}

    func recordTimelineExport() {}

    // MARK: - Scene Handling

    func dismissActiveTips() async {
        do {
            try await store.invalidateAllTips()
        } catch {
            AppLogger.tips.error("Failed to invalidate active tips: \(error.localizedDescription)")
        }
    }
}
