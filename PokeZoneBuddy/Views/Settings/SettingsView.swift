//
//  SettingsView.swift
//  PokeZoneBuddy
//
//  Settings view for preferences & cache
//  Version 0.4 - Modern UI Design
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
    
    var icon: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
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
    @State private var diskCacheSize = 0
    @State private var showClearConfirmation = false
    @State private var showDeleteOldConfirmation = false
    @State private var isRefreshing = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    if displayMode.includesPrimarySections {
                        primarySectionGroup
                    }

                    if displayMode.showsGroupDivider {
                        Divider()
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
            .onAppear {
                updateCacheStats()
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
        }
#if os(macOS)
        .frame(minWidth: 600, minHeight: 500)
#endif
    }
    
    // MARK: - Section Grouping

    private var primarySectionGroup: some View {
        VStack(spacing: 24) {
            appearanceSection
            cacheStatisticsSection
            cacheActionsSection
        }
    }

    @ViewBuilder
    private var supplementarySectionGroup: some View {
        VStack(spacing: 24) {
            if displayMode == .supplementaryOnly {
                Divider()
            }

            creditsSection
            legalSection
            linksSection

            Divider()

            appHeaderSection
                .padding(.bottom, 16)
        }
    }


    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Appearance", systemImage: "paintbrush")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            Picker("", selection: themePreferenceBinding) {
                ForEach(ThemePreference.allCases) { preference in
                    Label {
                        Text(preference.label)
                    } icon: {
                        Image(systemName: preference.icon)
                    }
                    .tag(preference)
                }
            }
            .pickerStyle(.segmented)
            
            Text("Choose a display mode or follow the device setting.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.3))
        )
    }
    
    // MARK: - Cache Statistics Section
    
    private var cacheStatisticsSection: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Label(String(localized: "cache.stats.title"), systemImage: "chart.bar.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.bottom, 16)
            
            // Stats Cards
            VStack(spacing: 12) {
                StatCard(
                    icon: "calendar.badge.clock",
                    iconColor: .blue,
                    title: String(localized: "cache.stats.events.title"),
                    value: "\(eventCount)",
                    subtitle: String(localized: "cache.stats.events.subtitle")
                )
                
                StatCard(
                    icon: "internaldrive",
                    iconColor: .orange,
                    title: String(localized: "cache.stats.disk.title"),
                    value: formatBytes(diskCacheSize),
                    subtitle: String(localized: "cache.stats.disk.subtitle")
                )
            }
        }
    }
    
    // MARK: - Cache Actions Section
    
    private var cacheActionsSection: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Label(String(localized: "cache.actions.title"), systemImage: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.bottom, 16)
            
            // Action Cards
            VStack(spacing: 12) {
                ActionCard(
                    icon: "photo.badge.arrow.down",
                    iconColor: .blue,
                    title: String(localized: "cache.actions.clear_images.title"),
                    subtitle: String(localized: "cache.actions.clear_images.subtitle"),
                    buttonText: String(localized: "common.clear"),
                    buttonColor: .blue
                ) {
                    showClearConfirmation = true
                }
                
                ActionCard(
                    icon: "calendar.badge.minus",
                    iconColor: .red,
                    title: String(localized: "cache.actions.delete_old.title"),
                    subtitle: String(localized: "cache.actions.delete_old.subtitle"),
                    buttonText: String(localized: "common.delete"),
                    buttonColor: .red
                ) {
                    showDeleteOldConfirmation = true
                }
            }
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

                // Localized "Version" prefix with dynamic version string
                Text("\(L("about.version_prefix", "Version")) \(appVersionString())")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                // Tagline
                Text(L("about.tagline", "Pokémon GO event times — in your local time."))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.3))
        )
    }

    // MARK: - Credits Section

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("about.credits.title", "Credits"))
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                CreditRow(
                    icon: "globe",
                    title: L("credits.event_data", "Event data (LeekDuck)"),
                    description: "LeekDuck.com",
                    link: Constants.Credits.leekDuckURL
                )

                CreditRow(
                    icon: "arrow.down.circle",
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
                // Copyright — dynamic years, no duplicate trademark lines here
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

                // Trademarks — keep concise and non-redundant
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

                // Disclaimer — unaffiliated fan project
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

                // Attribution — concise to avoid duplicating the Credits section
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
                    icon: "globe",
                    title: L("links.website", "Website"),
                    url: "https://dannymarx.github.io/PokeZoneBuddy"
                )

                LinkButton(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: L("links.github", "GitHub"),
                    url: "https://github.com/dannymarx/PokeZoneBuddy"
                )

                LinkButton(
                    icon: "doc.text",
                    title: L("links.license_mit", "License (MIT)"),
                    url: "https://github.com/dannymarx/PokeZoneBuddy/blob/main/LICENSE"
                )
            }
        }
    }

    // MARK: - Actions
    
    private func updateCacheStats() {
        isRefreshing = true
        
        let service = CacheManagementService(modelContext: modelContext)
        let stats = service.getCacheSize()
        
        eventCount = stats.events
        diskCacheSize = stats.imageDisk
        
        isRefreshing = false
    }
    
    private func clearImageCache() async {
        let service = CacheManagementService(modelContext: modelContext)
        await service.clearImageCache()
        updateCacheStats()
    }
    
    private func deleteOldEvents() {
        let service = CacheManagementService(modelContext: modelContext)
        
        do {
            try service.deleteOldEvents()
            updateCacheStats()
        } catch {
            AppLogger.cache.error("Error deleting old events: \(String(describing: error))")
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

    /// Localize with a safe fallback so missing/placeholder keys never leak into UI.
    private func L(_ key: String, _ fallback: String, comment: String = "") -> String {
        return NSLocalizedString(key, tableName: nil, bundle: .main, value: fallback, comment: comment)
    }

    /// Safer localization that falls back when the resolved value looks like a placeholder (e.g., "Title" or the key itself).
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

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(iconColor)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Action Card

private struct ActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let buttonText: String
    let buttonColor: Color
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(iconColor)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Action Button
            Button {
                action()
            } label: {
                Text(buttonText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(buttonColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isHovering ? buttonColor.opacity(0.15) : buttonColor.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(buttonColor.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Credit Row

private struct CreditRow: View {
    let icon: String
    let title: String
    let description: String
    let link: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.blue)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))

                if let url = URL(string: link) {
                    Link(description, destination: url)
                        .font(.system(size: 12))
                        .foregroundStyle(.blue)
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
                .fill(.quaternary.opacity(0.3))
        )
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
    let icon: String
    let title: String
    let url: String

    var body: some View {
        if let linkURL = URL(string: url) {
            Link(destination: linkURL) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14))
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
                        .fill(.blue.opacity(0.1))
                )
                .foregroundStyle(.blue)
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
