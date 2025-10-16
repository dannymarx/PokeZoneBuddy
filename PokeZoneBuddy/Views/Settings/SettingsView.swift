//
//  SettingsView.swift
//  PokeZoneBuddy
//
//  Settings view for preferences & cache
//  Version 0.5 - Professional Redesign
//
import SwiftUI
import SwiftData

enum ThemePreference: String, CaseIterable, Identifiable {
    static let storageKey = "settings.themePreference"

    case system
    case light
    case dark

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

/// View for managing general settings and cache data
struct SettingsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Display Mode

    enum DisplayMode {
        case full
        case primaryOnly
        case supplementaryOnly

        var includesPrimarySections: Bool {
            switch self {
            case .full, .primaryOnly:
                return true
            case .supplementaryOnly:
                return false
            }
        }

        var includesSupplementarySections: Bool {
            switch self {
            case .full, .supplementaryOnly:
                return true
            case .primaryOnly:
                return false
            }
        }

        var showsGroupDivider: Bool {
            includesPrimarySections && includesSupplementarySections
        }
    }

    // MARK: - Properties

    private let displayMode: DisplayMode
    private let showsDismissButton: Bool

    // MARK: - Init

    init(displayMode: DisplayMode = .full, showsDismissButton: Bool = true) {
        self.displayMode = displayMode
        self.showsDismissButton = showsDismissButton
    }

    // MARK: - State

    @AppStorage(ThemePreference.storageKey) private var themePreferenceRaw = ThemePreference.system.rawValue
    @State private var eventCount = 0
    @State private var cityCount = 0
    @State private var spotCount = 0
    @State private var favoriteEventCount = 0
    @State private var diskCacheSize = 0
    @State private var showClearConfirmation = false
    @State private var showDeleteOldConfirmation = false
    @State private var showDeleteAllDataConfirmation = false
    @State private var isRefreshing = false
    @State private var navigationPath = NavigationPath()
    @State private var citiesViewModel: CitiesViewModel?

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    if displayMode.includesPrimarySections {
                        primarySectionGroup
                    }

                    if displayMode.showsGroupDivider {
                        Divider()
                            .padding(.vertical, 8)
                    }

                    if displayMode.includesSupplementarySections {
                        supplementarySectionGroup
                    }
                }
                .padding(24)
            }
            .scrollIndicators(.hidden, axes: .vertical)
            .hideScrollIndicatorsCompat()
            .background(Color.appBackground)
            .navigationTitle(String(localized: "settings.title"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
#if os(macOS)
            .toolbar {
                if showsDismissButton {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: "common.done")) {
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                }
            }
#endif
            .navigationDestination(for: String.self) { destination in
                if destination == "notifications" {
                    NotificationSettingsView()
                }
            }
            .onAppear {
                if citiesViewModel == nil {
                    citiesViewModel = CitiesViewModel(modelContext: modelContext)
                }
                updateStats()
            }
            .confirmationDialog(
                String(localized: "cache.confirm.clear_images.title"),
                isPresented: $showClearConfirmation
            ) {
                Button(String(localized: "common.clear"), role: .destructive) {
                    Task {
                        await clearImageCache()
                    }
                }
                Button(String(localized: "common.cancel"), role: .cancel) { }
            } message: {
                Text(String(localized: "cache.confirm.clear_images.message"))
            }
            .confirmationDialog(
                String(localized: "cache.confirm.delete_old.title"),
                isPresented: $showDeleteOldConfirmation
            ) {
                Button(String(localized: "common.delete"), role: .destructive) {
                    deleteOldEvents()
                }
                Button(String(localized: "common.cancel"), role: .cancel) { }
            } message: {
                Text(String(localized: "cache.confirm.delete_old.message"))
            }
            .confirmationDialog(
                "Delete All User Data",
                isPresented: $showDeleteAllDataConfirmation
            ) {
                Button("Delete All Data", role: .destructive) {
                    deleteAllUserData()
                }
                Button(String(localized: "common.cancel"), role: .cancel) { }
            } message: {
                Text("This will permanently delete all your saved cities, spots, and favorite events. This action cannot be undone.")
            }
        }
#if os(macOS)
        .frame(minWidth: 600, minHeight: 500)
#endif
    }

    // MARK: - Section Grouping

    private var primarySectionGroup: some View {
        VStack(spacing: 32) {
            appearanceSection
            notificationsNavigationSection
            statisticsSection
            dataManagementSection
            actionsSection
        }
    }

    @ViewBuilder
    private var supplementarySectionGroup: some View {
        VStack(spacing: 32) {
            creditsSection
            legalSection
            linksSection

            Divider()
                .padding(.vertical, 8)

            appHeaderSection
                .padding(.bottom, 16)
        }
    }



    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Appearance")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }

            VStack(spacing: 12) {
                Picker("", selection: themePreferenceBinding) {
                    ForEach(ThemePreference.allCases) { preference in
                        Text(preference.label)
                            .tag(preference)
                    }
                }
                .pickerStyle(.segmented)

                Text("Choose a display mode or follow the device setting.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                                .systemBlue.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Notifications Navigation Section

    private var notificationsNavigationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Notifications")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }

            NavigationLink(value: "notifications") {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.systemBlue)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.systemBlue.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Event Reminders")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)

                        Text("Get notified before your favorite events")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
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
                                    .systemBlue.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Data Management")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }

            if let viewModel = citiesViewModel {
                ImportExportView(viewModel: viewModel)
            } else {
                Text("Loading...")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "cache.stats.title"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }

            VStack(spacing: 12) {
                StatRow(
                    title: String(localized: "cache.stats.events.title"),
                    value: "\(eventCount)",
                    subtitle: String(localized: "cache.stats.events.subtitle")
                )

                Divider()

                StatRow(
                    title: "Favorite Cities",
                    value: "\(cityCount)",
                    subtitle: "Saved cities with time zones"
                )

                Divider()

                StatRow(
                    title: "Saved Spots",
                    value: "\(spotCount)",
                    subtitle: "Coordinates across all cities"
                )

                Divider()

                StatRow(
                    title: "Favorite Events",
                    value: "\(favoriteEventCount)",
                    subtitle: "Events marked as favorite"
                )

                Divider()

                StatRow(
                    title: String(localized: "cache.stats.disk.title"),
                    value: formatBytes(diskCacheSize),
                    subtitle: String(localized: "cache.stats.disk.subtitle")
                )
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
                                .systemBlue.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "cache.actions.title"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }

            VStack(spacing: 0) {
                ActionRow(
                    title: String(localized: "cache.actions.clear_images.title"),
                    subtitle: String(localized: "cache.actions.clear_images.subtitle"),
                    buttonText: String(localized: "common.clear"),
                    buttonColor: .systemBlue
                ) {
                    showClearConfirmation = true
                }

                Divider()
                    .padding(.leading, 16)

                ActionRow(
                    title: String(localized: "cache.actions.delete_old.title"),
                    subtitle: String(localized: "cache.actions.delete_old.subtitle"),
                    buttonText: String(localized: "common.delete"),
                    buttonColor: .systemOrange
                ) {
                    showDeleteOldConfirmation = true
                }

                Divider()
                    .padding(.leading, 16)

                ActionRow(
                    title: "Delete All User Data",
                    subtitle: "Permanently delete all cities, spots, and favorite events",
                    buttonText: "Delete All",
                    buttonColor: .systemRed
                ) {
                    showDeleteAllDataConfirmation = true
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.quaternary.opacity(0.2))
            )
        }
    }

    // MARK: - App Header

    private var appHeaderSection: some View {
        HStack(spacing: 16) {
            // App Icon (macOS only)
            #if os(macOS)
            if let appIcon = applicationIcon() {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 4)
                    .accessibilityHidden(true)
            }
            #endif

            VStack(alignment: .leading, spacing: 4) {
                Text(appDisplayName())
                    .font(.system(size: 16, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)

                Text("\(L("about.version_prefix", "Version")) \(appVersionString())")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(L("about.tagline", "Pokémon GO event times — in your local time."))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.2))
        )
    }

    // MARK: - Credits Section

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("about.credits.title", "Credits"))
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                CreditRow(
                    title: L("credits.event_data", "Event data (LeekDuck)"),
                    description: "LeekDuck.com",
                    link: Constants.Credits.leekDuckURL
                )

                CreditRow(
                    title: L("credits.api", "Event mirror / API"),
                    description: L("credits.scraper_by", "ScrapedDuck (LeekDuck mirror, with permission)"),
                    link: Constants.Credits.scrapedDuckURL
                )
            }

            Text(L("credits.update_note", "Event data refreshes periodically and may change without notice."))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LSafe("about.legal.title", "Legal"))
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                LegalTextBox(
                    title: LSafe("legal.copyright.title", "Urheberrecht"),
                    text: LSafe(
                        "legal.copyright.text",
                        {
                            let year = Calendar.current.component(.year, from: Date())
                            return """
                            Pokémon GO © 2016–\(year) Niantic, Inc. Pokémon © 1995–\(year) Nintendo / Creatures Inc. / GAME FREAK inc. Alle Rechte vorbehalten.
                            """
                        }(),
                        comment: "Copyright notice with dynamic current year."
                    )
                )

                LegalTextBox(
                    title: LSafe("legal.trademark.title", "Marken"),
                    text: LSafe(
                        "legal.trademark.text",
                        """
                        „Pokémon" und die Namen der Pokémon‑Charaktere sind Marken von Nintendo. Pokémon GO ist ein Produkt von Niantic, Inc. Weitere erwähnte Marken sind Eigentum der jeweiligen Inhaber.
                        """,
                        comment: "Trademark clarification; concise and neutral."
                    )
                )

                LegalTextBox(
                    title: LSafe("legal.disclaimer.title", "Haftungsausschluss"),
                    text: LSafe(
                        "legal.disclaimer.text",
                        """
                        PokeZoneBuddy ist eine inoffizielle, fan‑gemachte App. Es besteht keine Partnerschaft oder Verbindung zu Niantic, The Pokémon Company, Nintendo, Creatures Inc. oder GAME FREAK. Alle Inhalte dienen ausschließlich Informationszwecken.
                        """,
                        comment: "Independence disclaimer."
                    )
                )

                LegalTextBox(
                    title: LSafe("legal.attribution.title", "Attribution & Quellen"),
                    text: LSafe(
                        "legal.attribution.text",
                        """
                        Eventdaten: LeekDuck (leekduck.com). Spiegel/Feed: ScrapedDuck (mit Erlaubnis). Bitte unterstützt die Originalquelle.
                        """,
                        comment: "Required attribution for LeekDuck & ScrapedDuck; concise."
                    )
                )
            }

            Text(LSafe(
                "legal.images_and_names_note",
                "Bildmaterial und Namen zu Pokémon erscheinen hier im Rahmen von Fair‑Use‑ und Markennutzungs‑Hinweisen.")
            )
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.tertiary)
            .padding(.top, 8)
        }
    }

    // MARK: - Links Section

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("about.links.title", "Links"))
                .font(.system(size: 18, weight: .semibold))

            VStack(spacing: 8) {
                LinkButton(
                    title: L("links.website", "Website"),
                    url: "https://dannymarx.github.io/PokeZoneBuddy"
                )

                LinkButton(
                    title: L("links.github", "GitHub"),
                    url: "https://github.com/dannymarx/PokeZoneBuddy"
                )

                LinkButton(
                    title: L("links.license_mit", "License (MIT)"),
                    url: "https://github.com/dannymarx/PokeZoneBuddy/blob/main/LICENSE"
                )
            }
        }
    }

    // MARK: - Actions

    private func updateStats() {
        isRefreshing = true

        let service = CacheManagementService(modelContext: modelContext)
        let stats = service.getCacheSize()

        eventCount = stats.events
        diskCacheSize = stats.imageDisk

        // Count cities
        let cityDescriptor = FetchDescriptor<FavoriteCity>()
        cityCount = (try? modelContext.fetchCount(cityDescriptor)) ?? 0

        // Count spots
        let spotDescriptor = FetchDescriptor<CitySpot>()
        spotCount = (try? modelContext.fetchCount(spotDescriptor)) ?? 0

        // Count favorite events
        let favoriteDescriptor = FetchDescriptor<FavoriteEvent>()
        favoriteEventCount = (try? modelContext.fetchCount(favoriteDescriptor)) ?? 0

        isRefreshing = false
    }

    private func clearImageCache() async {
        let service = CacheManagementService(modelContext: modelContext)
        await service.clearImageCache()
        updateStats()
    }

    private func deleteOldEvents() {
        let service = CacheManagementService(modelContext: modelContext)

        do {
            try service.deleteOldEvents()
            updateStats()
        } catch {
            AppLogger.cache.error("Error deleting old events: \(String(describing: error))")
        }
    }

    private func deleteAllUserData() {
        do {
            // Delete all favorite cities (cascade will delete spots)
            let cityDescriptor = FetchDescriptor<FavoriteCity>()
            let cities = try modelContext.fetch(cityDescriptor)
            for city in cities {
                modelContext.delete(city)
            }

            // Delete all favorite events
            let favoriteDescriptor = FetchDescriptor<FavoriteEvent>()
            let favorites = try modelContext.fetch(favoriteDescriptor)
            for favorite in favorites {
                modelContext.delete(favorite)
            }

            // Delete all spots (in case any orphaned)
            let spotDescriptor = FetchDescriptor<CitySpot>()
            let spots = try modelContext.fetch(spotDescriptor)
            for spot in spots {
                modelContext.delete(spot)
            }

            // Save changes
            try modelContext.save()

            // Update stats
            updateStats()

            AppLogger.cache.info("All user data deleted successfully")
        } catch {
            AppLogger.cache.error("Error deleting user data: \(String(describing: error))")
        }
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private var themePreferenceBinding: Binding<ThemePreference> {
        Binding(
            get: { ThemePreference(rawValue: themePreferenceRaw) ?? .system },
            set: { themePreferenceRaw = $0.rawValue }
        )
    }

    private func L(_ key: String, _ fallback: String, comment: String = "") -> String {
        return NSLocalizedString(key, tableName: nil, bundle: .main, value: fallback, comment: comment)
    }

    private func LSafe(_ key: String, _ fallback: String, comment: String = "") -> String {
        let resolved = NSLocalizedString(key, tableName: nil, bundle: .main, value: fallback, comment: comment)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = resolved.lowercased()
        if resolved.isEmpty || resolved == key || lowered == "title" || lowered == "placeholder" || lowered.contains("todo") {
            return fallback
        }
        return resolved
    }

    private func appDisplayName() -> String {
        let dict = Bundle.main.infoDictionary
        return (dict?["CFBundleDisplayName"] as? String)
            ?? (dict?["CFBundleName"] as? String)
            ?? "PokeZoneBuddy"
    }

    private func appVersionString() -> String {
        let dict = Bundle.main.infoDictionary
        let version = (dict?["CFBundleShortVersionString"] as? String) ?? "0.0"
        let build = (dict?["CFBundleVersion"] as? String) ?? ""
        return build.isEmpty || build == version ? version : "\(version) (\(build))"
    }

    #if os(macOS)
    private func applicationIcon() -> NSImage? {
        return NSImage(named: NSImage.applicationIconName)
    }
    #endif
}

// MARK: - Stat Row

private struct StatRow: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.systemBlue, .systemBlue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Action Row

private struct ActionRow: View {
    let title: String
    let subtitle: String
    let buttonText: String
    let buttonColor: Color
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                action()
            } label: {
                Text(buttonText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isHovering ? buttonColor.opacity(0.9) : buttonColor)
                    )
                    .shadow(
                        color: buttonColor.opacity(isHovering ? 0.3 : 0.2),
                        radius: isHovering ? 6 : 4,
                        x: 0,
                        y: isHovering ? 3 : 2
                    )
                    .scaleEffect(isHovering ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .padding(16)
    }
}

// MARK: - Credit Row

private struct CreditRow: View {
    let title: String
    let description: String
    let link: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))

                if let url = URL(string: link) {
                    Link(description, destination: url)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.systemBlue)
                        .accessibilityLabel(Text(description))
                } else {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Legal Text Box

private struct LegalTextBox: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.quaternary.opacity(0.2))
        )
    }
}

// MARK: - Link Button

private struct LinkButton: View {
    let title: String
    let url: String

    var body: some View {
        if let linkURL = URL(string: url) {
            Link(destination: linkURL) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.systemBlue.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color.systemBlue.opacity(0.15), radius: 4, x: 0, y: 2)
                .foregroundStyle(Color.systemBlue)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(title))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: Event.self, inMemory: true)
}
