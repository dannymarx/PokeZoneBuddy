# Changelog

All notable changes to **PokeZoneBuddy** are documented here.
This project follows [Semantic Versioning](https://semver.org/).

---

## [1.6.0] – Unreleased

### Added
- Multi-city timeline plans that save event-specific city selections with rename/update flows plus JSON export/import.
- Timeline templates with per-event-type defaults and dedicated management screens in Settings.
- Planner export tools to capture high-resolution PNG timelines and share them via the new cross-platform share sheet.
- Timeline management hub in Settings with plan/template stats, grouped search, and Files-based plan import.
- Background refresh cleanup that prunes temporary timeline assets and notification images.

### Changed
- Multi-City Planner integrates a gear menu for saving, loading, template application, sharing, and macOS calendar shortcuts.
- Settings reorganized to surface the full timeline toolkit alongside appearance, notifications, and data management.
- Reminder controls expose configurable offsets within the planner and allow macOS users to target a specific city timezone.

### Fixed
- Automatic cleanup now removes stale temporary notification assets after background refresh to prevent cache bloat.

---

## [1.5.0] – 2025-10-20

### Added
- **Multi-City Planner** – Revolutionary new feature for planning sequential event participation across multiple cities.
  - Sequential timeline view showing event times across all favorite cities in chronological order
  - Visual timeline with color-coded city entries and playing time indicators
  - Smart travel gap detection between cities with automatic time calculations
  - Optimal playing strategy suggestions to maximize multi-city participation
  - Integrated directly into event detail views for seamless planning
  - Supports unlimited favorite cities with automatic timezone conversion
- **Enhanced Event Detail View** with integrated Multi-City Planning Tool access
- **New App Logo** with refreshed branding and visual identity

### Changed
- Event detail views now prominently feature the Multi-City Planning Tool for better discoverability
- Improved countdown overlays with better visual hierarchy
- Settings view refinements for better organization and usability
- Window management improvements on macOS for better multi-window workflows

### Fixed
- API service reliability improvements with better error handling
- Notification scheduling edge cases for events spanning multiple days
- Observable pattern refresh issues with event data updates
- Music service state management on macOS

---

## [1.4.0] – 2025-10-13

### Changed
- **City Spots Interface** completely redesigned with enhanced user experience.
  - Improved SpotDetailView with better layout, visual hierarchy, and information display.
  - Enhanced SpotListView with refined filtering, sorting, and spot management capabilities.
  - Updated SpotRowView with modern card-based design and better visual feedback.
  - Redesigned AllSpotsView and AllSpotsContentView for improved navigation and spot discovery.
  - Refined CitiesManagementView and CityTimeRowView for better city management workflow.
  - Enhanced CityDetailView with improved layout and spot integration on macOS.
  - Updated MacOSMainView navigation patterns for better user flow.
- **Localization** expanded with additional strings for improved UI labels and descriptions.
- **UI/UX Polish** across spots-related views with consistent design language and improved accessibility.

---

## [1.3.0] – 2025-10-13

### Added
- **Event Reminders & Local Notifications** system that automatically sends notifications for favorited events.
  - Automatic notification scheduling 30 minutes before event start when favoriting an event.
  - Comprehensive notification management in Settings with permission handling and test functionality.
  - Timezone-aware notifications with automatic rescheduling on timezone changes.
  - Background cleanup of expired and orphaned notifications.
  - Support for multiple reminder offsets (15 min, 30 min, 1 hour, 3 hours, 1 day).
- **Import/Export functionality** for Cities and Spots data.
  - Export all cities and spots to portable JSON format with metadata.
  - Import data with merge or replace options and duplicate detection.
  - Data validation for coordinates, timezones, and spot categories.
  - Progress indicators and detailed import summaries.
  - Compatible across iOS and macOS for easy data transfer.

### Changed
- Background refresh service now includes automatic notification cleanup after each refresh cycle.
- Settings interface enhanced with new sections for Notifications and Import/Export.
- FavoritesManager automatically manages notification lifecycle when favoriting/unfavoriting events.

### Fixed
- Various bug fixes to improve app stability and performance.

---

## [1.2.0] – 2025-10-12

### Added
- **Liquid Glass UI** enhancements with improved visual effects and modern design language throughout the app.
- **iOS Support** with platform-specific layouts, navigation patterns, and optimized views for iPhone and iPad.
- **Enhanced Empty States** across all views to guide users when no data is available with clear calls-to-action.

### Changed
- **Refined Add Spot Workflow** with improved validation, better error handling, and streamlined user experience.
- **SwiftData Architecture** upgraded with optimized queries, better performance, and more reliable persistence.
- **Settings Interface** redesigned for better organization and clearer option presentation.
- **Calendar Export** improved with better date/time handling and error feedback on macOS.
- **Event Detail Views** optimized for iOS with platform-appropriate navigation and layout patterns.
- **Favorite Button** behavior refined for more consistent and predictable interactions.
- **Standard Buttons** and title bars updated across the app for better consistency and accessibility.

### Fixed
- Add Spot workflow validation and submission errors.
- Favorite Events sidebar persistence and state management.
- macOS-specific layout issues in various views.
- Calendar export timing and timezone conversion accuracy.
- Settings view crashes and data synchronization issues.
- City Spots display and editing on iOS platforms.

---

## [1.1.0] – 2025-10-08

### Added
- Introduced **City Spots** so every favorite city can store gyms, PokéStops, meetup points, and custom coordinates with notes, categories, and favorites.
- Added a **Favorite Events** sidebar section that surfaces starred events with thumbnails, times, and one-click navigation to details.
- Built a **coordinate parsing service** that accepts plain GPS pairs, Google/Apple Maps URLs, and DMS formats with live validation and clipboard-friendly exports.

### Changed
- Polished the About view layout with platform-specific padding so it centers cleanly on every device.

### Fixed
- Hid remaining scroll indicators across lists and sidebars to prevent stray scrollbars on macOS.
- Present the About view as a full-screen cover on iOS to eliminate the draggable sheet behavior.

---

## [1.0.0] – 2025-10-06

Initial release of PokeZoneBuddy – Your companion for tracking Pokémon GO events across timezones.

### 🎉 Core Features
- **Event Overview**: Browse upcoming Pokémon GO events with images and live countdowns
- **Favorite Cities**: Track events in cities around the world
- **Smart Time Conversion**: Automatic conversion to your local timezone
- **Event Details**: 
  - Featured Pokémon with shiny status
  - Raid bosses and special research information
  - Event bonuses and multipliers
  - Color-coded event types for quick orientation

### ⭐ Organization & Management
- **Filter & Search**: Filter events by type and search across event names
- **Favorites System**: Mark important events with stars (persisted with SwiftData)
- **Calendar Integration** (macOS): Export events to your macOS calendar with one click
- **Real-time Status**: Live countdown timers and progress bars for active events

### 📡 Performance & Offline
- **Offline Mode**: Full functionality without internet connection
- **Smart Caching**: URLCache with 50MB memory / 200MB disk limits
- **Background Refresh**: Auto-update every 30 minutes
- **Cache Management**: 
  - View storage statistics
  - Clear cache manually
  - Auto-cleanup of events older than 30 days
- **Optimized Performance**: Smooth scrolling with 1000+ events

### 🎨 User Experience
- **Native macOS Design**: SwiftUI with proper spacing, typography, and Dark Mode support
- **Accessibility**: VoiceOver support, Dynamic Type, semantic labels
- **Multi-language Support**: English and German (fully localized)
- **Visual Feedback**: Live status badges, countdown timers, event type colors

### 🔒 Privacy & Data
- **Privacy-First**: All data stored locally with SwiftData (no cloud sync)
- **No Tracking**: No analytics, no crash reporting, no telemetry
- **No Account Required**: Works completely offline after initial data fetch
- **Calendar-Only Permissions**: Write-only access when using calendar export

### 🛠 Technical Highlights
- **Platform**: macOS 26.0+ (iOS-ready architecture)
- **Framework**: 100% SwiftUI with Observation framework
- **Architecture**: MVVM with service layer pattern
- **Data Source**: ScrapedDuck API (LeekDuck mirror)
- **Storage**: SwiftData for favorites, URLCache for API responses
- **Services**:
  - `APIService` – Event data fetching with offline-first caching
  - `TimezoneService` – Timezone conversion and formatting
  - `NetworkMonitor` – Network status tracking with NWPathMonitor
  - `CalendarService` – macOS EventKit integration
  - `CacheManagementService` – Storage monitoring and cleanup
  - `BackgroundRefreshService` – Periodic auto-updates
  - `FavoritesManager` – SwiftData-based favorites persistence

### 📝 Documentation
- Comprehensive developer style guide
- Unit tests for timezone conversion, API parsing, and localization
- Example use cases and architecture documentation

---

## Format

- **Added** – new features  
- **Changed** – changes to existing functionality  
- **Fixed** – bug fixes  
- **Removed** – removed features  
- **Security** – security-related changes
