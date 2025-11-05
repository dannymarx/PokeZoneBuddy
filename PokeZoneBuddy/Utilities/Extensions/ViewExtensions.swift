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
}

// MARK: - Typography Extensions

extension Text {
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
    /// Cross-platform default background color
    static var appBackground: Color {
#if os(macOS)
        Color(nsColor: .windowBackgroundColor)
#else
        Color(uiColor: .systemBackground)
#endif
    }
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

#if os(macOS)
private struct MacScrollIndicatorHider: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ScrollViewConfigurator())
            .onAppear {
                // Configure scrollbars on appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    configureAllScrollbars()
                }
            }
    }

    private func configureAllScrollbars() {
        guard let window = NSApplication.shared.keyWindow else { return }
        window.contentView?.configureScrollbarsInSubviews()
    }
}

private struct ScrollViewConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Avoid layout recursion by scheduling configuration outside the layout cycle
        DispatchQueue.main.async {
            // Only configure if we're not in the middle of a layout pass
            guard nsView.window != nil, nsView.window?.isVisible == true else { return }
            nsView.window?.contentView?.configureScrollbarsInSubviews()
        }
    }
}

private extension NSView {
    func configureScrollbarsInSubviews() {
        // Avoid recursion by checking if we're in a layout pass
        guard !self.inLiveResize else { return }

        // Configure scrollbars for this view if it's a scroll view
        if let scrollView = self as? NSScrollView {
            configureScrollView(scrollView)
        }

        // Check enclosing scroll view
        if let enclosingScroll = self.enclosingScrollView {
            configureScrollView(enclosingScroll)
        }

        // Recursively configure in all subviews
        for subview in subviews {
            subview.configureScrollbarsInSubviews()
        }
    }

    private func configureScrollView(_ scrollView: NSScrollView) {
        // Avoid triggering layout during configuration
        guard !scrollView.inLiveResize else { return }

        // Use overlay style - scrollbars appear only when scrolling or hovering
        scrollView.scrollerStyle = .overlay

        // Enable scrollers so they can appear on demand
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true

        // Overlay style automatically handles show/hide behavior:
        // - Scrollers are hidden by default
        // - Scrollers appear when scrolling
        // - Scrollers appear when hovering over the scroll area
        // - Scrollers fade out after inactivity

        // Flash scrollers outside the layout cycle to avoid recursion
        // Schedule on next run loop to ensure layout is complete
        DispatchQueue.main.async {
            scrollView.flashScrollers()
        }
    }
}

extension View {
    func hideScrollIndicatorsCompat() -> some View {
        self.modifier(MacScrollIndicatorHider())
    }
}
#else
extension View {
    func hideScrollIndicatorsCompat() -> some View {
        self
    }
}
#endif
