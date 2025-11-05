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

    @ObservationIgnored private let preferencesStore: TipPreferencesStoreProtocol

    // MARK: - Tip Instances

    let plannerTemplateTip = PlannerTemplateTip()
    let eventFiltersTip = EventFiltersTip()
    let timelineExportTip = TimelineExportTip()

    // MARK: - State

    private(set) var tipsEnabled: Bool
    private(set) var lastReset: Date?
    private var isConfigured = false

    // MARK: - Initialization

    init(preferencesStore: TipPreferencesStoreProtocol) {
        self.preferencesStore = preferencesStore

        let preferences = preferencesStore.fetchOrCreate()
        self.tipsEnabled = preferences.isEnabled
        self.lastReset = preferences.lastReset

        configureTipKit()
    }

    // MARK: - Configuration

    private func configureTipKit() {
        guard !isConfigured else { return }

        do {
            try Tips.configure()
            isConfigured = true
            AppLogger.tips.info("TipKit configured")
        } catch {
            AppLogger.tips.error("Failed to configure TipKit: \(error.localizedDescription)")
        }
    }

    // MARK: - Preference Updates

    func setTipsEnabled(_ isEnabled: Bool) async {
        guard tipsEnabled != isEnabled else { return }

        tipsEnabled = isEnabled

        await preferencesStore.update(isEnabled: isEnabled)

        if !isEnabled {
            dismissActiveTips()
        }

        AppLogger.tips.info("Tips enabled set to \(isEnabled)")
    }

    func resetTips() async {
        do {
            try Tips.resetDatastore()
            let resetDate = Date()
            lastReset = resetDate
            await preferencesStore.update(lastReset: .some(resetDate))
            AppLogger.tips.info("Reset TipKit datastore")
        } catch {
            AppLogger.tips.error("Failed to reset TipKit datastore: \(error.localizedDescription)")
        }
    }

    // MARK: - Tip Triggers

    func recordPlanSaved() {
        guard tipsEnabled else { return }
        AppLogger.tips.info("Recorded timeline plan saved donation")
        Task { await PlannerTemplateTip.planSavedEvent.donate() }
    }

    func recordFiltersUsed() {
        guard tipsEnabled else { return }
        AppLogger.tips.info("Recorded events filter usage donation")
        Task { await EventFiltersTip.filtersUsedEvent.donate() }
    }

    func recordTimelineExport() {
        guard tipsEnabled else { return }
        AppLogger.tips.info("Recorded timeline export donation")
        Task { await TimelineExportTip.exportEvent.donate() }
    }

    // MARK: - Scene Handling

    func dismissActiveTips() {
        plannerTemplateTip.invalidate(reason: .tipClosed)
        eventFiltersTip.invalidate(reason: .tipClosed)
        timelineExportTip.invalidate(reason: .tipClosed)
        AppLogger.tips.debug("Dismissed active tips due to scene transition")
    }
}
