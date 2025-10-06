//
//  ViewExtensions.swift
//  PokeZoneBuddy
//
//  Design System Extensions für macOS 26
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Design System Extensions

extension View {
    /// Moderner minimaler Card-Style
    func modernCard(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
            )
    }
    
    /// Glassmorphism Effect für macOS
    func glassCard(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
    }
    
    /// Hover-Effekt für interaktive Elemente
    func hoverEffect() -> some View {
        #if os(iOS)
        self
            .contentShape(Rectangle())
            .hoverEffect(.highlight)
        #else
        self
        #endif
    }
}

// MARK: - Typography Extensions

extension Text {
    /// Große Display-Überschrift
    func displayStyle() -> some View {
        self
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
    }
    
    /// Titel-Stil
    func titleStyle() -> some View {
        self
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
    }
    
    /// Sekundärer Text
    func secondaryStyle() -> some View {
        self
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(.secondary)
    }
    
    /// Caption für kleine Infos
    func captionStyle() -> some View {
        self
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.tertiary)
    }
    
    /// Badge-Stil
    func badgeStyle() -> some View {
        self
            .font(.system(size: 11, weight: .semibold))
            .textCase(.uppercase)
            .kerning(0.5)
    }
}

// MARK: - Color Extensions

extension Color {
    /// Primary Accent Color (Pokemon Red)
    static let pokeRed = Color(red: 0.93, green: 0.26, blue: 0.21)
    
    /// Secondary Accent (Pokemon Blue)
    static let pokeBlue = Color(red: 0.16, green: 0.57, blue: 0.95)
    
    /// Success Green
    static let successGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
    
    /// Warning Orange
    static let warningOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    
#if os(macOS)
    static let subtleBackground = Color(nsColor: .windowBackgroundColor).opacity(0.5)
#else
    static let subtleBackground = Color(uiColor: .secondarySystemBackground).opacity(0.5)
#endif
}

// MARK: - Button Styles

struct ModernButtonStyle: ButtonStyle {
    var color: Color = .accentColor
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.opacity(configuration.isPressed ? 0.15 : 0.08))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Badge View

struct ModernBadge: View {
    let text: String
    let icon: String?
    let color: Color
    
    init(_ text: String, icon: String? = nil, color: Color = .accentColor) {
        self.text = text
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .badgeStyle()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
        .foregroundStyle(color)
    }
}

// MARK: - Section Header Style

struct SectionHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .kerning(0.5)
    }
}

extension View {
    func sectionHeader() -> some View {
        self.modifier(SectionHeaderModifier())
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 400
                        }
                    }
            )
            .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

