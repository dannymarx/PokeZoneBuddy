//
//  StatefulRefreshButton.swift
//  PokeZoneBuddy
//
//  Refresh button with integrated loading/success/error feedback
//

import SwiftUI

/// Refresh button with visual state feedback
struct StatefulRefreshButton: View {

    // MARK: - Properties

    let onRefresh: () async -> Void
    let refreshState: RefreshState
    let isDisabled: Bool

    // MARK: - State

    @State private var isAnimating = false
    @State private var showCheckmark = false
    @State private var showError = false

    // MARK: - Body

    var body: some View {
        Button {
            Task {
                await onRefresh()
            }
        } label: {
            ZStack {
                // Loading state
                if refreshState == .loading {
                    ProgressView()
                        .controlSize(.small)
                        .transition(.opacity)
                }
                // Success state
                else if refreshState == .success && showCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
                // Error state
                else if refreshState == .error && showError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.red)
                        .transition(.scale.combined(with: .opacity))
                }
                // Idle state
                else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDisabled ? .tertiary : .secondary)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .transition(.opacity)
                }
            }
            .frame(width: 20, height: 20)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: refreshState)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || refreshState == .loading)
        .help(helpText)
        .onChange(of: refreshState) { _, newState in
            handleStateChange(newState)
        }
    }

    // MARK: - Helper Methods

    private var helpText: String {
        switch refreshState {
        case .idle:
            return String(localized: "events.refresh.help", defaultValue: "Refresh events")
        case .loading:
            return String(localized: "events.refreshing", defaultValue: "Refreshing...")
        case .success:
            return String(localized: "events.refresh.success", defaultValue: "Updated successfully")
        case .error:
            return String(localized: "events.refresh.error", defaultValue: "Update failed")
        }
    }

    private func handleStateChange(_ state: RefreshState) {
        switch state {
        case .idle:
            showCheckmark = false
            showError = false
            isAnimating = false

        case .loading:
            showCheckmark = false
            showError = false
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                isAnimating = true
            }

        case .success:
            isAnimating = false
            showCheckmark = true
            // Auto-hide checkmark after 2 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation {
                    showCheckmark = false
                }
            }

        case .error:
            isAnimating = false
            showError = true
            // Auto-hide error after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation {
                    showError = false
                }
            }
        }
    }
}

/// Refresh state enum
enum RefreshState: Equatable {
    case idle
    case loading
    case success
    case error
}

// MARK: - iOS Toolbar Button Variant

struct StatefulRefreshToolbarButton: View {
    let onRefresh: () async -> Void
    let refreshState: RefreshState
    let isDisabled: Bool

    @State private var showCheckmark = false
    @State private var showError = false
    @State private var eventCount: Int?

    var body: some View {
        Button {
            Task {
                await onRefresh()
            }
        } label: {
            HStack(spacing: 6) {
                if refreshState == .loading {
                    ProgressView()
                        .controlSize(.small)
                } else if refreshState == .success && showCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    if let count = eventCount {
                        Text("\(count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if refreshState == .error && showError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                } else {
                    Label(String(localized: "events.refresh.help"), systemImage: "arrow.clockwise")
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: refreshState)
        }
        .disabled(isDisabled || refreshState == .loading)
        .onChange(of: refreshState) { _, newState in
            handleStateChange(newState)
        }
    }

    private func handleStateChange(_ state: RefreshState) {
        switch state {
        case .idle:
            showCheckmark = false
            showError = false
            eventCount = nil

        case .loading:
            showCheckmark = false
            showError = false

        case .success:
            showCheckmark = true
            // Auto-hide after 2.5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                withAnimation {
                    showCheckmark = false
                }
            }

        case .error:
            showError = true
            // Auto-hide after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation {
                    showError = false
                }
            }
        }
    }

    func setEventCount(_ count: Int) {
        eventCount = count
    }
}

// MARK: - Preview

#Preview("Idle") {
    StatefulRefreshButton(
        onRefresh: { },
        refreshState: .idle,
        isDisabled: false
    )
    .padding()
}

#Preview("Loading") {
    StatefulRefreshButton(
        onRefresh: { },
        refreshState: .loading,
        isDisabled: false
    )
    .padding()
}

#Preview("alert.success.title") {
    StatefulRefreshButton(
        onRefresh: { },
        refreshState: .success,
        isDisabled: false
    )
    .padding()
}

#Preview("alert.error.title") {
    StatefulRefreshButton(
        onRefresh: { },
        refreshState: .error,
        isDisabled: false
    )
    .padding()
}
