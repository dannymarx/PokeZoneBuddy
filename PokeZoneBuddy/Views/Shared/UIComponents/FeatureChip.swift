//
//  FeatureChip.swift
//  PokeZoneBuddy
//
//  Reusable badge/chip component for displaying features with icon
//

import SwiftUI

/// A compact chip component displaying an icon and text with a colored background
struct FeatureChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
        .foregroundStyle(color)
    }
}

#Preview {
    VStack(spacing: 12) {
        FeatureChip(icon: "star.fill", text: "Featured", color: Color.systemYellow)
        FeatureChip(icon: "location.fill", text: "Spawns", color: Color.systemGreen)
        FeatureChip(icon: "gift.fill", text: "Bonus", color: Color.systemBlue)
    }
    .padding()
}
