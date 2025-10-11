//
//  LiquidGlassModifiers.swift
//  PokeZoneBuddy
//
//  Liquid Glass Design System for macOS 26 / iOS 26
//  Implements Apple's new Liquid Glass material design language
//

import SwiftUI

// MARK: - Liquid Glass View Extensions

extension View {
    /// Applies Liquid Glass effect with default styling
    /// Use this for floating UI elements like cards, toolbars, and overlays
    func liquidGlassCard(padding: CGFloat = 20, tintColor: Color? = nil) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            .modifier(LiquidGlassReflectionModifier())
    }

    /// Applies interactive Liquid Glass effect for buttons and controls
    func liquidGlassButton(tintColor: Color = .blue) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(tintColor.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: tintColor.opacity(0.2), radius: 8, x: 0, y: 2)
    }

    /// Applies Liquid Glass effect for event cards with dynamic coloring
    func liquidGlassEventCard(isSelected: Bool = false, isActive: Bool = false, accentColor: Color = .blue) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? accentColor.opacity(0.5) : (isActive ? Color.green.opacity(0.4) : .white.opacity(0.15)),
                        lineWidth: isSelected || isActive ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? accentColor.opacity(0.2) : (isActive ? .green.opacity(0.15) : .black.opacity(0.06)),
                radius: isSelected ? 16 : 12,
                x: 0,
                y: isSelected ? 6 : 4
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
    }

    /// Applies Liquid Glass capsule effect for badges
    func liquidGlassBadge(color: Color = .blue) -> some View {
        self
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    /// Applies Liquid Glass overlay effect with tint
    func liquidGlassOverlay(tint: Color? = nil, intensity: Double = 0.6) -> some View {
        self
            .background(
                ZStack {
                    if let tint = tint {
                        Rectangle()
                            .fill(tint.opacity(intensity * 0.15))
                    }
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }
            )
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.1),
                                .clear,
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
}

// MARK: - Liquid Glass Reflection Modifier

/// Adds a subtle reflection effect to simulate glass refraction
private struct LiquidGlassReflectionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .white.opacity(0.15),
                        .clear,
                        .clear,
                        .white.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
            )
    }
}

// MARK: - Liquid Glass Lensing Effect

/// Applies edge lensing effect characteristic of Liquid Glass
struct LiquidGlassLensingModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.1),
                                .clear,
                                .white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
}

extension View {
    func liquidGlassLensing(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(LiquidGlassLensingModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Liquid Glass Container

/// Container view that coordinates Liquid Glass elements for cohesive blending
struct LiquidGlassContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(.ultraThinMaterial)
    }
}

// MARK: - Animated Liquid Glass

/// Adds fluid animation to Liquid Glass elements
struct AnimatedLiquidGlass: ViewModifier {
    @State private var animationPhase: CGFloat = -200

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .rotationEffect(.degrees(20))
                    .offset(x: animationPhase)
                    .allowsHitTesting(false)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    animationPhase = 300
                }
            }
    }
}

extension View {
    /// Adds animated shimmer effect to Liquid Glass elements
    func liquidGlassAnimated() -> some View {
        self.modifier(AnimatedLiquidGlass())
    }
}

// MARK: - Liquid Glass with Tint

/// Applies tinted Liquid Glass effect
struct TintedLiquidGlass: ViewModifier {
    let tint: Color
    let intensity: Double

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(intensity * 0.2))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(tint.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: tint.opacity(0.2), radius: 12, x: 0, y: 4)
    }
}

extension View {
    /// Applies tinted Liquid Glass effect with custom color and intensity
    func liquidGlassTinted(_ tint: Color, intensity: Double = 0.6) -> some View {
        self.modifier(TintedLiquidGlass(tint: tint, intensity: intensity))
    }
}

// MARK: - Liquid Glass Button Style

struct LiquidGlassButtonStyle: ButtonStyle {
    var tint: Color = .blue
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(prominent ? .white : tint)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    if prominent {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tint.gradient)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        prominent ? .clear : tint.opacity(0.3),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: tint.opacity(configuration.isPressed ? 0.1 : 0.2),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 1 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Liquid Glass Icon Style

/// Enhances SF Symbols with Liquid Glass styling
struct LiquidGlassIconModifier: ViewModifier {
    let color: Color
    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        color,
                        color.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .symbolRenderingMode(.hierarchical)
            .symbolEffect(.pulse, options: .repeating)
    }
}

extension View {
    func liquidGlassIcon(color: Color = .blue, size: CGFloat = 24) -> some View {
        self.modifier(LiquidGlassIconModifier(color: color, size: size))
    }
}

// MARK: - Liquid Glass Floating Card

/// Creates a floating card effect perfect for event cards
struct LiquidGlassFloatingCard: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(isHovered ? 0.4 : 0.2),
                                .clear,
                                .white.opacity(isHovered ? 0.3 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: .black.opacity(isHovered ? 0.12 : 0.08),
                radius: isHovered ? 20 : 12,
                x: 0,
                y: isHovered ? 8 : 4
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func liquidGlassFloating() -> some View {
        self.modifier(LiquidGlassFloatingCard())
    }
}
