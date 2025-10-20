//
//  TimelinePlansListView.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-20.
//  Version 1.6.0 - Timeline Plans Management
//

import SwiftUI
import SwiftData

/// View for managing saved timeline plans
struct TimelinePlansListView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var timelineService: TimelineService?
    @State private var searchText = ""
    @State private var selectedPlan: TimelinePlan?
    @State private var showDeleteConfirmation = false
    @State private var planToDelete: TimelinePlan?

    // MARK: - Computed Properties

    private var filteredPlans: [TimelinePlan] {
        guard let service = timelineService else { return [] }

        if searchText.isEmpty {
            return service.plans
        }

        return service.plans.filter { plan in
            plan.name.localizedCaseInsensitiveContains(searchText) ||
            plan.eventName.localizedCaseInsensitiveContains(searchText) ||
            plan.eventType.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedPlans: [(String, [TimelinePlan])] {
        let grouped = Dictionary(grouping: filteredPlans) { $0.eventType }
        return grouped.sorted { $0.key < $1.key }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let service = timelineService {
                if service.isLoading {
                    loadingView
                } else if service.plans.isEmpty {
                    emptyStateView
                } else {
                    listContent
                }
            } else {
                loadingView
            }
        }
        .navigationTitle(String(localized: "settings.timeline.my_plans"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .searchable(
            text: $searchText,
            prompt: String(localized: "timeline.plans.search_placeholder")
        )
        .onAppear {
            setupService()
        }
        .confirmationDialog(
            String(localized: "timeline.plans.delete_confirm"),
            isPresented: $showDeleteConfirmation,
            presenting: planToDelete
        ) { plan in
            Button(String(localized: "common.delete"), role: .destructive) {
                deletePlan(plan)
            }
            Button(String(localized: "common.cancel"), role: .cancel) { }
        } message: { plan in
            Text(plan.name)
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
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            VStack(spacing: 8) {
                Text(String(localized: "timeline.plans.no_plans"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(String(localized: "timeline.plans.no_plans_subtitle"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedPlans, id: \.0) { eventType, plans in
                    Section {
                        VStack(spacing: 12) {
                            ForEach(plans) { plan in
                                NavigationLink {
                                    PlanDetailView(plan: plan)
                                } label: {
                                    PlanRowView(plan: plan)
                                }
                                .buttonStyle(.plain)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                                .contextMenu {
                                    Button(role: .destructive) {
                                        planToDelete = plan
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label(
                                            String(localized: "common.delete"),
                                            systemImage: "trash"
                                        )
                                    }
                                }
                            }
                        }
                        .animation(.timelineSpring, value: plans)
                    } header: {
                        HStack {
                            Text(formatEventType(eventType))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            Spacer()

                            Text("\(plans.count)")
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
        let service = TimelineService(
            timelineRepository: timelineRepo,
            cityRepository: cityRepo
        )

        timelineService = service

        Task {
            do {
                // Load all plans using the service
                try await service.loadAllPlans()
            } catch {
                AppLogger.service.error("Failed to load all plans: \(error)")
            }
        }
    }

    private func deletePlan(_ plan: TimelinePlan) {
        guard let service = timelineService else { return }

        Task {
            do {
                try await service.deletePlan(plan)
            } catch {
                AppLogger.service.error("Failed to delete plan: \(error)")
            }
        }
    }

    private func formatEventType(_ type: String) -> String {
        // Convert event-type-slug to Event Type Title
        return type
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

// MARK: - Plan Row View

private struct PlanRowView: View {
    let plan: TimelinePlan

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "map")
                .font(.system(size: 20))
                .foregroundStyle(Color.systemPurple)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.systemPurple.opacity(0.1))
                )

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(plan.eventName)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Label(
                        "\(plan.cityIdentifiers.count)",
                        systemImage: "location.fill"
                    )
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)

                    Text("•")
                        .foregroundStyle(.quaternary)

                    Text(plan.dateModified.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
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
                            .systemPurple.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TimelinePlansListView()
            .modelContainer(for: TimelinePlan.self, inMemory: true)
    }
}
