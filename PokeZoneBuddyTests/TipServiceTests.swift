import Foundation
import Testing
import TipKit
@testable import PokeZoneBuddy

@MainActor
struct TipServiceTests {

    @MainActor
    final class MockTipPreferencesStore: TipPreferencesStoreProtocol {
        private let storedPreferences: TipPreferences
        private(set) var updatedIsEnabled: Bool?
        private(set) var updatedLastReset: Date??

        init(isEnabled: Bool = true, lastReset: Date? = nil) {
            storedPreferences = TipPreferences(isEnabled: isEnabled, lastReset: lastReset)
        }

        func fetchOrCreate() -> TipPreferences {
            storedPreferences
        }

        func update(isEnabled: Bool?, lastReset: Date??) async {
            if let isEnabled {
                storedPreferences.isEnabled = isEnabled
                updatedIsEnabled = isEnabled
            }
            if let lastReset {
                storedPreferences.lastReset = lastReset
                updatedLastReset = lastReset
            }
        }
    }

    @Test
    func togglingTipsPersistsPreference() async {
        let store = MockTipPreferencesStore(isEnabled: true)
        let service = TipService(preferencesStore: store)

        #expect(service.tipsEnabled)

        await service.setTipsEnabled(false)

        #expect(service.tipsEnabled == false)
        #expect(store.updatedIsEnabled == false)
        #expect(store.fetchOrCreate().isEnabled == false)
    }

    @Test
    func resettingTipsUpdatesTimestamp() async {
        let store = MockTipPreferencesStore(isEnabled: true)
        let service = TipService(preferencesStore: store)

        await service.resetTips()

        #expect(service.lastReset != nil)
        #expect(store.updatedLastReset != nil)

        if let lastReset = service.lastReset {
            let delta = abs(lastReset.timeIntervalSinceNow)
            #expect(delta < 5)
        }
    }
}
