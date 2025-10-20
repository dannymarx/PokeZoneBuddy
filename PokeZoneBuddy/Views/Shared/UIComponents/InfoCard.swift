//
//  InfoCard.swift
//  PokeZoneBuddy
//
//  Reusable card component for displaying information with icon, title, and value
//

import SwiftUI

/// A card component displaying titled information with an icon and prominent value
struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .symbolRenderingMode(.hierarchical)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)
            }

            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.25),
                            color.opacity(0.15),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 16) {
        InfoCard(
            icon: "clock.fill",
            title: "Duration",
            value: "3 hours",
            color: Color.systemBlue
        )
        InfoCard(
            icon: "calendar",
            title: "Date",
            value: "Oct 16, 2025",
            color: Color.systemGreen
        )
    }
    .padding()
}
