# Changelog

All notable changes to **PokeZoneBuddy** are documented here.  
This project follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

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
