//
//  PokeZoneBuddyApp.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.25.
//  Version 0.4 - Added NetworkMonitor & BackgroundRefresh (Singleton)
//

import SwiftUI
import SwiftData

@main
struct PokeZoneBuddyApp: App {
    
    // MARK: - SwiftData Container
    @AppStorage(ThemePreference.storageKey) private var themePreferenceRaw = ThemePreference.system.rawValue
    
    /// SwiftData ModelContainer for local persistence
    /// Stores Events, FavoriteCities, and FavoriteEvents locally (no CloudKit)
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Event.self,
            FavoriteCity.self,
            CitySpot.self,
            FavoriteEvent.self,
            SpotlightDetails.self,
            RaidDetails.self,
            CommunityDayDetails.self,
            PokemonInfo.self,
            CommunityDayBonus.self
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
    
    // MARK: - Services (Version 0.4)
    
    /// Network connectivity monitor
    @State private var networkMonitor = NetworkMonitor()
    
    /// Calendar service for EventKit integration (macOS only)
    #if os(macOS)
    @State private var calendarService = CalendarService()
    #endif
    
    private var currentTheme: ThemePreference {
        ThemePreference(rawValue: themePreferenceRaw) ?? .system
    }

    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            MainTabView()
                .environment(networkMonitor)
                .preferredColorScheme(currentTheme.colorScheme)
                .onAppear {
                    setupBackgroundRefresh()
                }
            #else
            MacOSMainView()
                .environment(networkMonitor)
                .environment(calendarService)
                .preferredColorScheme(currentTheme.colorScheme)
                .onAppear {
                    setupBackgroundRefresh()
                }
            #endif
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.hiddenTitleBar)
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
    
    // MARK: - Background Refresh Setup
    
    private func setupBackgroundRefresh() {
        // Configure singleton with network monitor
        BackgroundRefreshService.shared.configure(networkMonitor: networkMonitor)
        
        // Start auto-refresh
        BackgroundRefreshService.shared.startAutoRefresh {
            // Refresh logic will be handled by EventsViewModel
            AppLogger.app.info("Auto-refresh triggered")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Notification to refresh events
    static let refreshEvents = Notification.Name("refreshEvents")
}
