//
//  DesignSystem.swift
//  PokeZoneBuddy
//
//  Centralized design system for consistent styling across the app
//

import SwiftUI

/// Centralized design system for consistent styling
enum DesignSystem {

    // MARK: - Colors

    enum Colors {
        /// Event type colors
        static let eventCommunityDay = Color.green
        static let eventRaid = Color.red
        static let eventSpotlight = Color.yellow
        static let eventBattleLeague = Color.purple
        static let eventResearch = Color.blue
        static let eventSeason = Color.orange
        static let eventDefault = Color.gray

        /// Spot category colors (now using SpotCategory.color, kept for reference)
        static let categoryGym = Color.blue
        static let categoryPokestop = Color.cyan
        static let categoryMeetingPoint = Color.purple
        static let categoryOther = Color.gray

        /// Status colors
        static let statusLive = Color.green
        static let statusUpcoming = Color.orange
        static let statusPast = Color.gray

        /// UI accent colors
        static let accentBlue = Color.blue
        static let accentGreen = Color.green
        static let accentYellow = Color.yellow
        static let accentRed = Color.red
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 10
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let pill: CGFloat = 999
    }

    // MARK: - Typography

    enum Typography {
        // Titles
        static func title(_ size: CGFloat = 28, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight)
        }

        static func subtitle(_ size: CGFloat = 18, weight: Font.Weight = .semibold) -> Font {
            .system(size: size, weight: weight)
        }

        // Body text
        static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }

        static func bodyMedium(_ size: CGFloat = 15) -> Font {
            .system(size: size, weight: .medium)
        }

        static func bodySemibold(_ size: CGFloat = 15) -> Font {
            .system(size: size, weight: .semibold)
        }

        // Small text
        static func caption(_ size: CGFloat = 12, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }

        static func captionMedium(_ size: CGFloat = 12) -> Font {
            .system(size: size, weight: .medium)
        }

        static func captionSemibold(_ size: CGFloat = 12) -> Font {
            .system(size: size, weight: .semibold)
        }

        // Tiny text
        static func tiny(_ size: CGFloat = 10, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }
    }

    // MARK: - Shadows

    enum Shadow {
        static func card(color: Color = .black, opacity: Double = 0.1) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color.opacity(opacity), 8, 0, 2)
        }

        static func elevated(color: Color = .black, opacity: Double = 0.15) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color.opacity(opacity), 12, 0, 4)
        }

        static func subtle(color: Color = .black, opacity: Double = 0.05) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color.opacity(opacity), 4, 0, 1)
        }
    }

    // MARK: - Animation

    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Apply standard card styling
    func designSystemCard(cornerRadius: CGFloat = DesignSystem.CornerRadius.lg) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Apply standard shadow
    func designSystemShadow(style: DesignSystem.Shadow.Type = DesignSystem.Shadow.self) -> some View {
        let shadow = style.card()
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    // MARK: - Text Modifiers

    /// Single line truncated text
    func singleLineTruncated() -> some View {
        self
            .lineLimit(1)
            .truncationMode(.tail)
    }

    /// Event title text style
    func eventTitleStyle() -> some View {
        self
            .font(DesignSystem.Typography.bodySemibold(15))
            .foregroundStyle(.primary)
            .singleLineTruncated()
    }

    /// Event subtitle text style
    func eventSubtitleStyle() -> some View {
        self
            .font(DesignSystem.Typography.caption(12))
            .foregroundStyle(.secondary)
            .singleLineTruncated()
    }

    /// Spot name text style
    func spotNameStyle(compact: Bool = false) -> some View {
        self
            .font(DesignSystem.Typography.bodySemibold(compact ? 14 : 15))
            .foregroundStyle(.primary)
            .singleLineTruncated()
    }

    /// Spot notes text style
    func spotNotesStyle(compact: Bool = false) -> some View {
        self
            .font(DesignSystem.Typography.caption(compact ? 11 : 12))
            .foregroundStyle(.secondary)
            .singleLineTruncated()
    }

    /// City name text style
    func cityNameStyle() -> some View {
        self
            .font(DesignSystem.Typography.subtitle(18))
            .foregroundStyle(.primary)
    }

    /// Badge text style
    func badgeTextStyle() -> some View {
        self
            .font(DesignSystem.Typography.captionSemibold(12))
    }

    // MARK: - Badge Modifiers

    /// Standard badge styling
    func standardBadge(color: Color, opacity: Double = 0.15) -> some View {
        self
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                Capsule()
                    .fill(color.opacity(opacity))
            )
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.2), radius: 2, x: 0, y: 1)
    }

    /// Category badge styling (for spots)
    func categoryBadge(color: Color) -> some View {
        standardBadge(color: color)
    }

    // MARK: - Icon Modifiers

    /// Favorite star styling
    func favoriteStarStyle(compact: Bool = false) -> some View {
        self
            .font(.system(size: compact ? 11 : 12))
            .foregroundStyle(.yellow)
            .symbolRenderingMode(.hierarchical)
            .shadow(color: .yellow.opacity(0.3), radius: 2, x: 0, y: 1)
    }

    // MARK: - Layout Modifiers

    /// Standard list row padding
    func standardRowPadding(compact: Bool = false) -> some View {
        self
            .padding(.vertical, compact ? DesignSystem.Spacing.sm : DesignSystem.Spacing.md)
            .padding(.horizontal, compact ? DesignSystem.Spacing.xs : DesignSystem.Spacing.sm)
    }

    /// Standard content padding
    func standardContentPadding() -> some View {
        self.padding(DesignSystem.Spacing.lg)
    }

    /// Standard section spacing
    func standardSectionSpacing() -> some View {
        self.padding(.bottom, DesignSystem.Spacing.md)
    }
}
