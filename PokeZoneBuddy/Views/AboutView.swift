//
//  AboutView.swift
//  PokeZoneBuddy
//
//  About & Credits Screen
//  Version 0.2
//


import SwiftUI
import Foundation

// MARK: - Localization & App Info Helpers

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

/// App display name, falling back gracefully.
private func appDisplayName() -> String {
    let dict = Bundle.main.infoDictionary
    return (dict?["CFBundleDisplayName"] as? String)
        ?? (dict?["CFBundleName"] as? String)
        ?? "PokeZoneBuddy"
}

/// Human‑readable version string: "1.0 (1)" if build differs, otherwise just "1.0".
private func appVersionString() -> String {
    let dict = Bundle.main.infoDictionary
    let version = (dict?["CFBundleShortVersionString"] as? String) ?? "0.0"
    let build = (dict?["CFBundleVersion"] as? String) ?? ""
    return build.isEmpty || build == version ? version : "\(version) (\(build))"
}

/// Best‑effort app icon for macOS; returns nil on iOS.
#if os(macOS)
private func applicationIcon() -> NSImage? {
    // Use the system application icon name to reliably fetch the app icon.
    return NSImage(named: NSImage.applicationIconName)
}
#endif

/// About-View mit App-Informationen und Credits
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Close Button

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Label(L("about.close", "Close"), systemImage: "xmark.circle.fill")
                .labelStyle(.iconOnly)
                .font(.system(size: 18, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .padding(8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L("about.close", "Close")))
        .keyboardShortcut(.cancelAction)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // App Icon & Info
                appHeaderSection

                Divider()

                // Credits Section
                creditsSection

                Divider()

                // Legal Section
                legalSection

                Divider()

                // Links
                linksSection

                Spacer(minLength: 40)
            }
            .padding(40)
            .frame(maxWidth: 600)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.windowBackground)
        .overlay(alignment: .topTrailing) { closeButton }
        #if os(macOS)
        .frame(width: 600, height: 700)
        #endif
    }

    // MARK: - App Header

    private var appHeaderSection: some View {
        VStack(spacing: 16) {
            // App Icon (macOS only)
            #if os(macOS)
            if let appIcon = applicationIcon() {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 8)
                    .accessibilityHidden(true)
            }
            #endif

            VStack(spacing: 8) {
                Text(appDisplayName())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .accessibilityAddTraits(.isHeader)

                // Localized "Version" prefix with dynamic version string
                Text("\(L("about.version_prefix", "Version")) \(appVersionString())")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                // Tagline
                Text(L("about.tagline", "Pokémon GO event times — in your local time."))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
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
                        „Pokémon“ und die Namen der Pokémon‑Charaktere sind Marken von Nintendo. Pokémon GO ist ein Produkt von Niantic, Inc. Weitere erwähnte Marken sind Eigentum der jeweiligen Inhaber.
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
}

// MARK: - Supporting Views

/// Credit Row mit Link
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

/// Legal Text Box
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

/// Link Button
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
    AboutView()
}
