//
//  EventFilterButton.swift
//  PokeZoneBuddy
//
//  Extracted from EventsListView for better modularity
//

import SwiftUI

/// Event filter options for filtering event lists
enum EventFilter: String, CaseIterable {
    case all = "filter.all"
    case live = "filter.live"
    case upcoming = "filter.upcoming"
    case past = "filter.past"

    var icon: String {
        switch self {
        case .all: return "calendar"
        case .live: return "circle.fill"
        case .upcoming: return "clock.fill"
        case .past: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .blue
        case .live: return .green
        case .upcoming: return .orange
        case .past: return .gray
        }
    }

    var localizedKey: LocalizedStringKey { .init(self.rawValue) }
}

/// Filter button component for event filtering
struct FilterButton: View {
    let filter: EventFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 11, weight: .semibold))

                Text(filter.localizedKey)

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? filter.color : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? filter.color.opacity(0.2) : Color.secondary.opacity(0.15))
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? filter.color.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? filter.color.opacity(0.4) : Color.secondary.opacity(0.2), lineWidth: 1.5)
            )
            .foregroundStyle(isSelected ? filter.color : .secondary)
        }
        .buttonStyle(.plain)
    }
}
