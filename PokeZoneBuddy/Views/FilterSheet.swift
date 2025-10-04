//
//  FilterSheet.swift
//  PokeZoneBuddy
//
//  Created by Claude on 03.10.2025.
//  Version 0.3 - Advanced Filter Sheet
//

import SwiftUI

struct FilterSheet: View {
    
    // MARK: - Properties
    
    @Bindable var config: FilterConfiguration
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                eventTypesSection
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "filter.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "filter.reset")) {
                        config.reset()
                    }
                    .disabled(!config.isActive)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, idealWidth: 480, minHeight: 500, idealHeight: 600)
    }
    
    // MARK: - Event Types Section
    
    private var eventTypesSection: some View {
        Section {
            ForEach(EventType.allCases) { type in
                Toggle(isOn: Binding(
                    get: { config.selectedTypes.contains(type) },
                    set: { isOn in
                        if isOn {
                            config.selectedTypes.insert(type)
                        } else {
                            config.selectedTypes.remove(type)
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: type.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(colorForType(type))
                            .frame(width: 24)
                        
                        Text(type.displayName)
                            .font(.system(size: 14))
                    }
                }
                .toggleStyle(.checkbox)
            }
        } header: {
            Text(String(localized: "filter.section.event_types"))
        } footer: {
            if config.selectedTypes.isEmpty {
                Text(String(localized: "filter.footer.no_types_selected"))
            } else {
                Text(String(format: String(localized: "filter.footer.types_selected"), config.selectedTypes.count))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func colorForType(_ type: EventType) -> Color {
        switch type.color {
        case "green": return .green
        case "red": return .red
        case "yellow": return .yellow
        case "purple": return .purple
        case "blue": return .blue
        case "orange": return .orange
        case "gray": return .gray
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var config = FilterConfiguration()
    config.selectedTypes = [.communityDay, .raidBattles]
    
    return FilterSheet(config: config)
}
