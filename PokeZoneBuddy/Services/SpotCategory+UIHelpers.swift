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
    var color: Color {
        switch self {
        case .gym:
            return .blue
        case .pokestop:
            return .cyan
        case .meetingPoint:
            return .purple
        case .other:
            return .gray
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
