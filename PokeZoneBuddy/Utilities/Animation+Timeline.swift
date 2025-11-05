//
//  Animation+Timeline.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-20.
//  Version 1.6.0 - Timeline Animations & Transitions
//

import SwiftUI

// MARK: - Timeline Animations

extension Animation {
    /// Smooth spring animation for timeline interactions
    static var timelineSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0)
    }

    /// Quick bounce animation for buttons
    static var timelineBounce: Animation {
        .spring(response: 0.25, dampingFraction: 0.6, blendDuration: 0)
    }

    /// Gentle fade animation for list items
    static var timelineFade: Animation {
        .easeInOut(duration: 0.2)
    }

    /// Smooth slide animation for sheets
    static var timelineSlide: Animation {
        .easeInOut(duration: 0.3)
    }
}

// MARK: - Success Animation Modifier

struct SuccessAnimationModifier: ViewModifier {
    let isSuccess: Bool

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.0

    func body(content: Content) -> some View {
        content
            .overlay {
                if isSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.green)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .onAppear {
                            withAnimation(.timelineBounce) {
                                scale = 1.0
                                opacity = 1.0
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation(.timelineFade) {
                                    opacity = 0.0
                                }
                            }
                        }
                }
            }
    }
}

extension View {
    /// Shows a success checkmark animation overlay
    func successAnimation(isSuccess: Bool) -> some View {
        modifier(SuccessAnimationModifier(isSuccess: isSuccess))
    }
}

// MARK: - Slide In Transition

struct SlideInTransition: ViewModifier {
    let isVisible: Bool
    let fromEdge: Edge

    func body(content: Content) -> some View {
        content
            .transition(.asymmetric(
                insertion: .move(edge: fromEdge).combined(with: .opacity),
                removal: .opacity
            ))
    }
}

extension View {
    /// Slides in from specified edge with fade
    func slideIn(isVisible: Bool, from edge: Edge = .bottom) -> some View {
        modifier(SlideInTransition(isVisible: isVisible, fromEdge: edge))
    }
}

// MARK: - Card Interaction Animations

struct CardPressAnimation: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.timelineBounce, value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) {
                // Never completes, just tracks press state
            } onPressingChanged: { pressing in
                isPressed = pressing
            }
    }
}

extension View {
    /// Adds subtle press animation to cards
    func cardPress() -> some View {
        modifier(CardPressAnimation())
    }
}

// MARK: - Delete Swipe Animation

struct DeleteSwipeModifier: ViewModifier {
    @Binding var offset: CGFloat
    let onDelete: () -> Void

    @State private var isDeleting = false

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .opacity(isDeleting ? 0 : 1)
            .scaleEffect(isDeleting ? 0.8 : 1.0)
            .animation(.timelineSpring, value: offset)
            .animation(.timelineFade, value: isDeleting)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.width < 0 {
                            offset = gesture.translation.width
                        }
                    }
                    .onEnded { gesture in
                        if gesture.translation.width < -100 {
                            isDeleting = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDelete()
                            }
                        } else {
                            offset = 0
                        }
                    }
            )
    }
}

// MARK: - Counter Animation

struct AnimatedCounter: View {
    let value: Int
    let label: String

    @State private var displayValue: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            Text("\(displayValue)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: Double(displayValue)))
                .animation(.timelineSpring, value: displayValue)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .onAppear {
            // Animate from 0 to value
            withAnimation(.timelineSpring.delay(0.1)) {
                displayValue = value
            }
        }
        .onChange(of: value) { oldValue, newValue in
            withAnimation(.timelineSpring) {
                displayValue = newValue
            }
        }
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    let isActive: Bool

    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        scale = 1.05
                    }
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        scale = 1.05
                    }
                } else {
                    withAnimation(.timelineSpring) {
                        scale = 1.0
                    }
                }
            }
    }
}

extension View {
    /// Adds a gentle pulse animation
    func pulse(isActive: Bool = true) -> some View {
        modifier(PulseModifier(isActive: isActive))
    }
}
