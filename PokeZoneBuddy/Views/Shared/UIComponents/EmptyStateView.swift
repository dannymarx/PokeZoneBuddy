//
//  EmptyStateView.swift
//  PokeZoneBuddy
//
//  Unified empty state component for consistent UX across the app
//

import SwiftUI

/// Unified empty state view with consistent styling
/// Supports optional action button and adapts to platform
struct EmptyStateView: View {

    // MARK: - Properties

    let icon: String
    let title: String
    let subtitle: String
    var action: Action? = nil

    struct Action {
        let title: String
        let systemImage: String?
        let handler: () -> Void

        init(title: String, systemImage: String? = nil, handler: @escaping () -> Void) {
            self.title = title
            self.systemImage = systemImage
            self.handler = handler
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.quaternary)

            // Text Content
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            // Optional Action Button
            if let action = action {
                Button {
                    action.handler()
                } label: {
                    if let systemImage = action.systemImage {
                        Label(action.title, systemImage: systemImage)
                    } else {
                        Text(action.title)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

/// Convenience initializer for placeholder views (no action button)
extension EmptyStateView {
    init(icon: String, title: String, subtitle: String) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = nil
    }
}

// MARK: - Preview

#Preview("No Cities") {
    EmptyStateView(
        icon: "map.circle",
        title: "No Cities Yet",
        subtitle: "Add your favorite cities to track event times in different time zones",
        action: .init(title: "Add City", systemImage: "plus.circle") {
            AppLogger.app.debug("Preview: Add city tapped")
        }
    )
}

#Preview("No Event Selected") {
    EmptyStateView(
        icon: "calendar",
        title: "No Event Selected",
        subtitle: "Select an event from the list to view details"
    )
}

#Preview("No Spots") {
    EmptyStateView(
        icon: "mappin.slash",
        title: "No Spots Yet",
        subtitle: "Add spots to your cities to save important locations"
    )
}
