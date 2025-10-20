//
//  SpotCategory+UIHelpers.swift
//  PokeZoneBuddy
//
//  Created by Assistant on 06.10.2025.
//

import SwiftUI

// Centralized UI helpers for SpotCategory presentation.
extension SpotCategory {
    /// Color associated with the category for consistent UI styling.
    /// Uses system colors for automatic light/dark mode adaptation.
    var color: Color {
        switch self {
        case .gym:
            return .systemBlue
        case .pokestop:
            return .systemCyan
        case .meetingPoint:
            return .systemPurple
        case .other:
            return .systemGray
        }
    }

    /// A standard label showing the category icon and localized name.
    @ViewBuilder
    var label: some View {
        HStack(spacing: 6) {
            Image(systemName: self.icon)
                .foregroundStyle(self.color)
            Text(self.localizedName)
        }
    }
}
