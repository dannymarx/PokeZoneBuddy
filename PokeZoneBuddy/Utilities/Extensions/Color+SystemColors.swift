//
//  Color+SystemColors.swift
//  PokeZoneBuddy
//
//  System color extensions for automatic light/dark mode support
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    // MARK: - System Colors

    /// System colors that automatically adapt to light and dark modes

    // MARK: Standard Colors
    static var systemRed: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemRed)
        #elseif canImport(AppKit)
        Color(nsColor: .systemRed)
        #else
        .red
        #endif
    }

    static var systemGreen: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGreen)
        #elseif canImport(AppKit)
        Color(nsColor: .systemGreen)
        #else
        .green
        #endif
    }

    static var systemBlue: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBlue)
        #elseif canImport(AppKit)
        Color(nsColor: .systemBlue)
        #else
        .blue
        #endif
    }

    static var systemOrange: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemOrange)
        #elseif canImport(AppKit)
        Color(nsColor: .systemOrange)
        #else
        .orange
        #endif
    }

    static var systemYellow: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemYellow)
        #elseif canImport(AppKit)
        Color(nsColor: .systemYellow)
        #else
        .yellow
        #endif
    }

    static var systemPink: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemPink)
        #elseif canImport(AppKit)
        Color(nsColor: .systemPink)
        #else
        .pink
        #endif
    }

    static var systemPurple: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemPurple)
        #elseif canImport(AppKit)
        Color(nsColor: .systemPurple)
        #else
        .purple
        #endif
    }

    static var systemTeal: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemTeal)
        #elseif canImport(AppKit)
        Color(nsColor: .systemTeal)
        #else
        .teal
        #endif
    }

    static var systemIndigo: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemIndigo)
        #elseif canImport(AppKit)
        Color(nsColor: .systemIndigo)
        #else
        .indigo
        #endif
    }

    static var systemCyan: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemCyan)
        #elseif canImport(AppKit)
        Color(nsColor: .systemCyan)
        #else
        .cyan
        #endif
    }

    static var systemBrown: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBrown)
        #elseif canImport(AppKit)
        Color(nsColor: .systemBrown)
        #else
        .brown
        #endif
    }

    static var systemMint: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemMint)
        #elseif canImport(AppKit)
        Color(nsColor: .systemMint)
        #else
        .mint
        #endif
    }

    // MARK: Gray Colors
    static var systemGray: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGray)
        #elseif canImport(AppKit)
        Color(nsColor: .systemGray)
        #else
        .gray
        #endif
    }

    static var systemGray2: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGray2)
        #elseif canImport(AppKit)
        Color(nsColor: .systemGray)
        #else
        .gray
        #endif
    }

    static var systemGray3: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGray3)
        #elseif canImport(AppKit)
        Color(nsColor: .systemGray)
        #else
        .gray
        #endif
    }

    static var systemGray4: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGray4)
        #elseif canImport(AppKit)
        Color(nsColor: .systemGray)
        #else
        .gray
        #endif
    }

    static var systemGray5: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGray5)
        #elseif canImport(AppKit)
        Color(nsColor: .systemGray)
        #else
        .gray
        #endif
    }

    static var systemGray6: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGray6)
        #elseif canImport(AppKit)
        Color(nsColor: .systemGray)
        #else
        .gray
        #endif
    }

    // MARK: - Background Colors

    /// Primary background color - uses the system's base background
    static var systemBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(white: 1.0)
        #endif
    }

    /// Secondary background color - slightly different from primary for layering
    static var secondarySystemBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(white: 0.95)
        #endif
    }

    /// Tertiary background color - for even more depth
    static var tertiarySystemBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .tertiarySystemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(white: 0.90)
        #endif
    }

    // MARK: Grouped Background Colors

    /// Primary grouped background color
    static var systemGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(white: 0.95)
        #endif
    }

    /// Secondary grouped background color
    static var secondarySystemGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(white: 1.0)
        #endif
    }

    /// Tertiary grouped background color
    static var tertiarySystemGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .tertiarySystemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(white: 0.95)
        #endif
    }

    // MARK: - Fill Colors

    /// Primary fill color for UI elements
    static var systemFill: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemFill)
        #elseif canImport(AppKit)
        Color(nsColor: .controlColor)
        #else
        Color(white: 0.85, opacity: 0.5)
        #endif
    }

    /// Secondary fill color
    static var secondarySystemFill: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemFill)
        #elseif canImport(AppKit)
        Color(nsColor: .controlColor)
        #else
        Color(white: 0.85, opacity: 0.4)
        #endif
    }

    /// Tertiary fill color
    static var tertiarySystemFill: Color {
        #if canImport(UIKit)
        Color(uiColor: .tertiarySystemFill)
        #elseif canImport(AppKit)
        Color(nsColor: .controlColor)
        #else
        Color(white: 0.85, opacity: 0.3)
        #endif
    }

    /// Quaternary fill color
    static var quaternarySystemFill: Color {
        #if canImport(UIKit)
        Color(uiColor: .quaternarySystemFill)
        #elseif canImport(AppKit)
        Color(nsColor: .controlColor)
        #else
        Color(white: 0.85, opacity: 0.2)
        #endif
    }

    // MARK: - Separator Colors

    /// Standard separator color
    static var separator: Color {
        #if canImport(UIKit)
        Color(uiColor: .separator)
        #elseif canImport(AppKit)
        Color(nsColor: .separatorColor)
        #else
        Color(white: 0.8, opacity: 0.6)
        #endif
    }

    /// Opaque separator color
    static var opaqueSeparator: Color {
        #if canImport(UIKit)
        Color(uiColor: .opaqueSeparator)
        #elseif canImport(AppKit)
        Color(nsColor: .separatorColor)
        #else
        Color(white: 0.8)
        #endif
    }

    // MARK: - Link Color

    /// Standard link color
    static var link: Color {
        #if canImport(UIKit)
        Color(uiColor: .link)
        #elseif canImport(AppKit)
        Color(nsColor: .linkColor)
        #else
        .blue
        #endif
    }
}
