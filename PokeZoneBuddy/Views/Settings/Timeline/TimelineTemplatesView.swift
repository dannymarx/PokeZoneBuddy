//
//  TimelineTemplatesView.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-20.
//  Version 1.6.0 - Timeline Templates Management
//

import SwiftUI
import SwiftData

/// View for managing timeline templates
struct TimelineTemplatesView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var timelineService: TimelineService?
    @State private var showCreateTemplate = false
    @State private var showEditTemplate = false
    @State private var templateToEdit: TimelineTemplate?
    @State private var showDeleteConfirmation = false
    @State private var templateToDelete: TimelineTemplate?

    // MARK: - Computed Properties

    private var groupedTemplates: [(String, [TimelineTemplate])] {
        guard let service = timelineService else { return [] }

        let grouped = Dictionary(grouping: service.templates) { $0.eventType }
        return grouped.sorted { $0.key < $1.key }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let service = timelineService {
                if service.isLoading {
                    loadingView
                } else if service.templates.isEmpty {
                    emptyStateView
                } else {
                    listContent
                }
            } else {
                loadingView
            }
        }
        .navigationTitle(String(localized: "settings.timeline.templates"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateTemplate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            setupService()
            loadTemplates()
        }
        .sheet(isPresented: $showCreateTemplate) {
            CreateTemplateView()
        }
        .sheet(isPresented: $showEditTemplate) {
            if let template = templateToEdit {
                CreateTemplateView(templateToEdit: template)
            }
        }
        .confirmationDialog(
            String(localized: "timeline.templates.delete_confirm"),
            isPresented: $showDeleteConfirmation,
            presenting: templateToDelete
        ) { template in
            Button(String(localized: "common.delete"), role: .destructive) {
                deleteTemplate(template)
            }
            Button(String(localized: "common.cancel"), role: .cancel) { }
        } message: { template in
            Text(template.name)
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(String(localized: "loading.generic"))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            VStack(spacing: 8) {
                Text(String(localized: "timeline.templates.no_templates"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(String(localized: "timeline.templates.no_templates_subtitle"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showCreateTemplate = true
            } label: {
                Label(
                    String(localized: "timeline.templates.create"),
                    systemImage: "plus.circle.fill"
                )
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.systemPurple)
                )
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedTemplates, id: \.0) { eventType, templates in
                    Section {
                        VStack(spacing: 12) {
                            ForEach(templates) { template in
                                TemplateRowView(template: template) {
                                    toggleDefaultStatus(template)
                                } onEdit: {
                                    templateToEdit = template
                                    showEditTemplate = true
                                } onDelete: {
                                    templateToDelete = template
                                    showDeleteConfirmation = true
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text(formatEventType(eventType))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            Spacer()

                            Text("\(templates.count)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Actions

    private func setupService() {
        guard timelineService == nil else { return }

        let timelineRepo = TimelineRepository(modelContext: modelContext)
        let cityRepo = CityRepository(modelContext: modelContext)
        timelineService = TimelineService(
            timelineRepository: timelineRepo,
            cityRepository: cityRepo
        )
    }

    private func loadTemplates() {
        guard let service = timelineService else { return }

        Task {
            do {
                try await service.loadTemplates()
            } catch {
                AppLogger.service.error("Failed to load templates: \(error)")
            }
        }
    }

    private func toggleDefaultStatus(_ template: TimelineTemplate) {
        guard let service = timelineService else { return }

        Task {
            do {
                try await service.updateTemplate(
                    template,
                    name: template.name,
                    cityIdentifiers: template.cityIdentifiers,
                    isDefault: !template.isDefault
                )
            } catch {
                AppLogger.service.error("Failed to update template: \(error)")
            }
        }
    }

    private func deleteTemplate(_ template: TimelineTemplate) {
        guard let service = timelineService else { return }

        Task {
            do {
                try await service.deleteTemplate(template)
            } catch {
                AppLogger.service.error("Failed to delete template: \(error)")
            }
        }
    }

    private func formatEventType(_ type: String) -> String {
        return type
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

// MARK: - Template Row View

private struct TemplateRowView: View {
    let template: TimelineTemplate
    let onToggleDefault: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            HStack(spacing: 12) {
                // Icon
                Image(systemName: template.isDefault ? "star.fill" : "square.stack")
                    .font(.system(size: 20))
                    .foregroundStyle(template.isDefault ? Color.systemYellow : Color.systemPurple)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                (template.isDefault ? Color.systemYellow : Color.systemPurple)
                                    .opacity(0.1)
                            )
                    )

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(template.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)

                        if template.isDefault {
                            Text(String(localized: "timeline.templates.default"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.systemYellow)
                                )
                        }
                    }

                    HStack(spacing: 8) {
                        Label(
                            "\(template.cityIdentifiers.count)",
                            systemImage: "location.fill"
                        )
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)

                        Text("•")
                            .foregroundStyle(.quaternary)

                        Text(template.dateModified.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label(
                            String(localized: "timeline.templates.edit"),
                            systemImage: "pencil"
                        )
                    }

                    Button {
                        onToggleDefault()
                    } label: {
                        Label(
                            template.isDefault
                                ? String(localized: "timeline.templates.remove_default")
                                : String(localized: "timeline.templates.set_default"),
                            systemImage: template.isDefault ? "star.slash" : "star.fill"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label(
                            String(localized: "common.delete"),
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.25),
                            (template.isDefault ? Color.systemYellow : Color.systemPurple)
                                .opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: template.isDefault ? 2 : 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TimelineTemplatesView()
            .modelContainer(for: TimelineTemplate.self, inMemory: true)
    }
}
