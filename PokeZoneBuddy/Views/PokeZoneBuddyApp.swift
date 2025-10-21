//
//  PokeZoneBuddyApp.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.25.
//  Version 0.4 - Added NetworkMonitor & BackgroundRefresh (Singleton)
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct PokeZoneBuddyApp: App {

    // MARK: - App Delegate (macOS)

    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    // MARK: - Initialization

    init() {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    // MARK: - SwiftData Container

    /// SwiftData ModelContainer for local persistence
    /// Stores Events, FavoriteCities, FavoriteEvents, Timeline Plans & Templates locally (no CloudKit)
    /// Nested models (SpotlightDetails, RaidDetails, etc.) are automatically discovered via @Relationship
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Event.self,
            FavoriteCity.self,
            CitySpot.self,
            FavoriteEvent.self,
            ReminderPreferences.self,
            TimelinePlan.self,
            TimelineTemplate.self
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

    /// Timeline service for plan and template management (v1.6.0)
    @State private var timelineService: TimelineService!

    /// Theme preference with proper reactive binding
    @AppStorage(ThemePreference.storageKey) private var themePreferenceRaw = ThemePreference.system.rawValue

    private var currentTheme: ColorScheme? {
        (ThemePreference(rawValue: themePreferenceRaw) ?? .system).colorScheme
    }

    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            MainTabView()
                .environment(networkMonitor)
                .environment(timelineService)
                .preferredColorScheme(currentTheme)
                .onAppear {
                    setupServices()
                    setupBackgroundRefresh()
                }
            #else
            MacOSMainView()
                .environment(networkMonitor)
                .environment(calendarService)
                .environment(timelineService)
                .preferredColorScheme(currentTheme)
                .onAppear {
                    setupServices()
                    setupBackgroundRefresh()
                }
            #endif
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .defaultSize(width: 1200, height: 700)
        .windowStyle(.automatic)
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
    
    // MARK: - Service Setup

    private func setupServices() {
        // Initialize TimelineService with repositories
        let modelContext = sharedModelContainer.mainContext
        let timelineRepository = TimelineRepository(modelContext: modelContext)
        let cityRepository = CityRepository(modelContext: modelContext)
        timelineService = TimelineService(
            timelineRepository: timelineRepository,
            cityRepository: cityRepository
        )
        AppLogger.app.info("Timeline service initialized")
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
