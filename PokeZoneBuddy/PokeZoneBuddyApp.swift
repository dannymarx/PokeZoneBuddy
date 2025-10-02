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
    
    /// SwiftData ModelContainer für lokale Persistierung
    /// Speichert Events und FavoriteCities lokal (kein CloudKit)
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
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
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
            // Refresh Command für macOS Menu Bar
            CommandGroup(after: .newItem) {
                Button("Events aktualisieren") {
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
    /// Notification zum Aktualisieren der Events
    static let refreshEvents = Notification.Name("refreshEvents")
}
