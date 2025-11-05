//
//  TipPreferences.swift
//  PokeZoneBuddy
//
//  Created by Codex on 21.10.25.
//

import Foundation
import SwiftData

/// Stores user-facing TipKit preferences in SwiftData so settings persist across installations.
@Model
final class TipPreferences {
    @Attribute(.unique) var id: UUID
    var isEnabled: Bool
    var lastReset: Date?

    init(id: UUID = UUID(), isEnabled: Bool = true, lastReset: Date? = nil) {
        self.id = id
        self.isEnabled = isEnabled
        self.lastReset = lastReset
    }
}
