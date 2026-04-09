//
//  PlanDetailView.swift
//  PokéZoneBuddy
//
//  Created by Claude Code on 2025-10-20.
//  Version 1.6.0 - Timeline Plans Management
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Detailed view for a timeline plan with export options
struct PlanDetailView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let plan: TimelinePlan

    // MARK: - State

    @State private var timelineService: TimelineService?
    @State private var cities: [FavoriteCity] = []
    @State private var event: Event?
    @State private var isExportingImage = false
    @State private var isExportingData = false
    @State private var showShareSheet = false
    @State private var shareItem: ShareableItem?
    @State private var errorMessage: String?
    @State private var showSuccessAnimation = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                planHeaderSection

                // Metadata Section
                metadataSection

                // Cities Section
                citiesSection

                // Export Actions
                exportActionsSection
            }
            .padding(20)
        }
        .navigationTitle(plan.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    deletePlan()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .onAppear {
            setupService()
            loadCities()
        }
        .sheet(isPresented: $showShareSheet) {
            if let item = shareItem {
                ShareSheet(item: item)
            }
        }
        .alert(
            String(localized: "common.error"),
            isPresented: .constant(errorMessage != nil),
            presenting: errorMessage
        ) { _ in
            Button(String(localized: "common.ok")) {
                errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
        .successAnimation(isSuccess: showSuccessAnimation)
    }

    // MARK: - Sections

    @ViewBuilder
    private var planHeaderSection: some View {
        if let event {
            VStack(alignment: .leading, spacing: 16) {
                // Event image with countdown overlay
                if let imageURLString = event.imageURL, let imageURL = URL(string: imageURLString) {
                    AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.05))
                                )
                                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                        default:
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.quaternary.opacity(0.4))
                                .aspectRatio(16 / 9, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .overlay {
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                EventCountdownView(event: event)
                                    .frame(width: min(geometry.size.width * 0.6, 420))
                                    .padding(.bottom, 12)
                                    .shadow(color: Color.black.opacity(0.18), radius: 14, y: 6)
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
                            .allowsHitTesting(false)
                        }
                    }
                }

                // Type badge + live badge + favorite button
                HStack {
                    ModernBadge(event.eventType, icon: "tag.fill", color: Color.systemBlue)
                        .liquidGlassBadge(color: Color.systemBlue)

                    if event.isCurrentlyActive {
                        ModernBadge(String(localized: "badge.live_now"), icon: "circle.fill", color: Color.systemGreen)
                            .liquidGlassBadge(color: Color.systemGreen)
                            .liquidGlassAnimated()
                    }

                    Spacer()

                    FavoriteButton(eventID: event.id)
                        .font(.system(size: 24))
                        .symbolRenderingMode(.hierarchical)
                }

                // Event name
                Text(event.displayName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                // Event heading
                if !event.displayHeading.isEmpty {
                    Text(event.displayHeading)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Plan name label
                HStack(spacing: 6) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 11))
                    Text(plan.name)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        } else {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    private var metadataSection: some View {
        VStack(spacing: 12) {
            MetadataRow(
                label: String(localized: "timeline.plan.event_type"),
                value: formatEventType(plan.eventType),
                icon: "calendar"
            )

            Divider()

            MetadataRow(
                label: String(localized: "timeline.plan.cities_count"),
                value: "\(plan.cityIdentifiers.count)",
                icon: "location.fill"
            )

            Divider()

            MetadataRow(
                label: String(localized: "timeline.plan.created"),
                value: plan.dateCreated.formatted(date: .long, time: .omitted),
                icon: "clock"
            )

        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    private var citiesSection: some View {
        Group {
            if cities.isEmpty || event == nil {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else {
                EventTimelineView(
                    event: event!,
                    favoriteCities: cities,
                    plannerMenu: nil
                )
            }
        }
    }

    private var exportActionsSection: some View {
        VStack(spacing: 16) {
            Text(String(localized: "timeline.export.title"))
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ExportButton(
                    title: String(localized: "timeline.plans.export_data"),
                    subtitle: String(localized: "timeline.plans.export_data_subtitle"),
                    icon: "doc.text",
                    isLoading: isExportingData
                ) {
                    exportPlanData()
                }

                ExportButton(
                    title: String(localized: "timeline.plans.export_image"),
                    subtitle: String(localized: "timeline.plans.export_image_subtitle"),
                    icon: "photo",
                    isLoading: isExportingImage,
                    isDisabled: cities.isEmpty
                ) {
                    exportPlanImage()
                }
            }
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

    private func loadCities() {
        Task {
            do {
                let cityRepo = CityRepository(modelContext: modelContext)
                let allCities = try await cityRepo.fetchCities()

                // Filter cities based on plan's identifiers
                let cityMap = Dictionary(
                    uniqueKeysWithValues: allCities.map { ($0.timeZoneIdentifier, $0) }
                )

                var resolvedCities: [FavoriteCity] = []
                for identifier in plan.cityIdentifiers {
                    if let city = cityMap[identifier] {
                        resolvedCities.append(city)
                    }
                }

                await MainActor.run {
                    cities = resolvedCities
                }

                // Also load the event for image export
                try await loadEvent()
            } catch {
                AppLogger.service.error("Failed to load cities: \(error)")
            }
        }
    }

    private func loadEvent() async throws {
        // Fetch the event from the repository
        let eventRepo = EventRepository(modelContext: modelContext)
        if let loadedEvent = try await eventRepo.fetchEvent(id: plan.eventID) {
            await MainActor.run {
                event = loadedEvent
            }
        }
    }

    private func exportPlanData() {
        guard let service = timelineService else { return }

        isExportingData = true

        Task {
            do {
                let data = try await service.exportPlan(plan)

                // Create shareable item with proper filename
                let filename = "\(plan.name).pzb"
                let item = try ShareableItem.temporaryFile(
                    data: data,
                    filename: filename,
                    contentType: .json
                )

                await MainActor.run {
                    shareItem = item
                    showShareSheet = true
                    isExportingData = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = String(localized: "timeline.export.failed")
                    isExportingData = false
                }
                AppLogger.service.error("Failed to export plan: \(error)")
            }
        }
    }

    private func exportPlanImage() {
        guard let event = event, !cities.isEmpty else {
            errorMessage = String(localized: "timeline.error.event_not_loaded")
            return
        }

        isExportingImage = true

        Task {
            do {
                // Determine color scheme from environment
                #if os(iOS)
                let colorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? ColorScheme.dark : .light
                #else
                let colorScheme = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? ColorScheme.dark : .light
                #endif

                // Render the image
                let renderer = TimelineImageRenderer()
                guard let image = await renderer.render(
                    event: event,
                    cities: cities,
                    planName: plan.name,
                    colorScheme: colorScheme
                ) else {
                    throw TimelineImageError.failedToRender
                }

                // Create shareable item
                let filename = "\(plan.name)_Timeline.png"
                #if os(macOS)
                let item = ShareableItem.image(image, filename: filename)
                #else
                let item = ShareableItem.image(image, filename: filename)
                #endif

                await MainActor.run {
                    shareItem = item
                    showShareSheet = true
                    isExportingImage = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = String(localized: "timeline.export.image_failed")
                    isExportingImage = false
                }
                AppLogger.service.error("Failed to export timeline image: \(error)")
            }
        }
    }

    private func deletePlan() {
        guard let service = timelineService else { return }

        Task {
            do {
                try await service.deletePlan(plan)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = String(localized: "timeline.error.delete_failed")
                }
                AppLogger.service.error("Failed to delete plan: \(error)")
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

// MARK: - Supporting Views

private struct MetadataRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}

private struct ExportButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isLoading: Bool
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isDisabled ? Color.secondary : Color.systemBlue)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill((isDisabled ? Color.gray : Color.systemBlue).opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isDisabled ? .tertiary : .primary)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isDisabled ? Color.gray.opacity(0.2) : Color.systemBlue.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PlanDetailView(
            plan: TimelinePlan(
                name: "Asia-Pacific Route",
                eventID: "community-day-march-2025",
                eventName: "Community Day: Bulbasaur",
                eventType: "community-day",
                cityIdentifiers: ["Asia/Tokyo", "Australia/Sydney"]
            )
        )
        .modelContainer(for: TimelinePlan.self, inMemory: true)
    }
}
