//
//  PokeZoneBuddyApp.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.25.
//

import SwiftUI
import SwiftData

@main
struct PokeZoneBuddyApp: App {
    
    /// SwiftData ModelContainer for local persistence
    /// Stores Events and FavoriteCities locally (no CloudKit)
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Event.self,
            FavoriteCity.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError(String(format: String(localized: "fatal.model_container_creation_failed"), String(describing: error)))
        }
    }()

    var body: some Scene {
        WindowGroup {
            EventsListView()
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // Refresh Command for macOS Menu Bar
            CommandGroup(after: .newItem) {
                Button(String(localized: "menu.refresh_events")) {
                    NotificationCenter.default.post(name: .refreshEvents, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        #endif
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Notification to refresh events
    static let refreshEvents = Notification.Name("refreshEvents")
}
