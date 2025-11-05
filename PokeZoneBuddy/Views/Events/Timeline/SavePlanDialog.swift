//
//  SavePlanDialog.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-20.
//  Version 1.6.0 - Multi-City Timeline Plans & Templates
//

import SwiftUI

struct SavePlanDialog: View {
    let event: Event
    let cityIdentifiers: [String]
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var planName: String = ""
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
#if os(macOS)
        macOSDialog
#else
        iOSDialog
#endif
    }

#if os(macOS)
    private var macOSDialog: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(String(localized: "timeline.plans.save"))
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            formContent
                .padding(.horizontal, 12)
                .padding(.top, 8)

            Divider()

            HStack {
                Spacer()
                Button(String(localized: "common.cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(String(localized: "common.save")) {
                    savePlan()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(minWidth: 420, idealWidth: 460)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .ignoresSafeArea()
        }
        .onAppear {
            planName = suggestedName
            isNameFieldFocused = true
        }
    }
#else
    private var iOSDialog: some View {
        NavigationStack {
            formContent
                .navigationTitle(String(localized: "timeline.plans.save"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "common.cancel")) {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: "common.save")) {
                            savePlan()
                        }
                        .disabled(planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            planName = suggestedName
            isNameFieldFocused = true
        }
    }
#endif

    private var formContent: some View {
        Form {
            Section {
                TextField(
                    String(localized: "timeline.plans.name_placeholder"),
                    text: $planName
                )
                .focused($isNameFieldFocused)
                .onSubmit(savePlan)

                Text(suggestedName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        planName = suggestedName
                    }
            } header: {
                Text(String(localized: "timeline.plans.dialog.header"))
            } footer: {
                Text(String(localized: "timeline.plans.dialog.footer"))
            }

            Section {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text(event.name)
                        .font(.subheadline)
                }

                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.secondary)
                    Text("\(cityIdentifiers.count) \(cityIdentifiers.count == 1 ? String(localized: "timeline.plans.city") : String(localized: "timeline.plans.cities"))")
                        .font(.subheadline)
                }
            } header: {
                Text(String(localized: "timeline.plans.dialog.details"))
            }
        }
    }

    // MARK: - Helper Methods

    private var suggestedName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let eventTypeFormatted = event.eventType
            .replacingOccurrences(of: "-", with: " ")
            .capitalized

        return "\(eventTypeFormatted) - \(dateFormatter.string(from: event.startTime))"
    }

    private func savePlan() {
        let trimmedName = planName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        onSave(trimmedName)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    SavePlanDialog(
        event: Event(
            id: "test-event",
            name: "Community Day: Bulbasaur",
            eventType: "community-day",
            heading: "Community Day",
            link: nil,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600 * 3),
            isGlobalTime: false,
            imageURL: nil,
            hasSpawns: true,
            hasFieldResearchTasks: true
        ),
        cityIdentifiers: ["Asia/Tokyo", "America/New_York", "Europe/London"],
        onSave: { name in
            AppLogger.service.debug("Preview: Saving plan: \(name)")
        }
    )
}
