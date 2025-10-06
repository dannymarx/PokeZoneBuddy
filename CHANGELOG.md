# Changelog

All notable changes to **PokeZoneBuddy** are documented here.  
This project doesn't strictly follow [Semantic Versioning](https://semver.org/) yet, but version increments are roughly oriented towards it.

---

## [0.4.0] – 2025-10-06
### Added
- **Performance Optimizations**:
  - Optimized SwiftData queries with fetch limits
  - Improved image cache with 50MB memory limit
  - Efficient list scrolling with 1000+ events
  - Memory-aware cache eviction
  
- **Offline Mode**:
  - Full app functionality without internet
  - NWPathMonitor for network status tracking
  - URLCache for automatic API response caching
  - Offline banner when using cached data
  
- **Background Refresh**:
  - Auto-update every 30 minutes
  - Only syncs when network is available
  - Respects constrained network modes
  
- **Cache Management**:
  - View cache statistics (events, memory, disk)
  - Clear image cache manually
  - Delete events older than 30 days
  - Disk space monitoring

### Changed
- Events list with offline status banner
- Pull-to-refresh with force sync option
- Improved memory management throughout app

### Technical
- `NetworkMonitor` service with NWPathMonitor
- `EventsViewModel` for centralized state management
- `BackgroundRefreshService` for auto-updates
- `CacheManagementService` for storage control
- Actor-based `ImageCacheService` with memory limits

---


## [0.3.0] – 2025-10-04
### Added
- **Filter & Sort System**: 
  - Event filtering by event type (Community Day, Raids, Spotlight Hour, etc.)
  - Real-time search across event names
  - Filter badge shows number of active filters
  - Reset function for all filters
- **Favorites System**:
  - Star button to mark important events
  - Persistent storage with SwiftData
  - Bounce animation when favoriting
  - Favorites persist after app restart
- **Calendar Integration** (macOS only):
  - One-click export to macOS calendar via EventKit
  - Automatic timezone conversion for selected city
  - Write-only calendar permission for privacy
  - Error handling for missing permissions

### Changed
- Events list now with filter and search functionality
- Event details with favorite button and calendar export
- Improved toolbar with filter badge

### Technical
- New `FilterConfiguration` model class
- `FavoritesManager` service with SwiftData
- `CalendarService` for EventKit integration
- Write-only calendar access for better privacy
- @Observable instead of ObservableObject (modern Swift Concurrency)

### Platform
- **Important:** Calendar integration only available on macOS
- iOS version does not show calendar button

---

## [0.2.0] – 2025-10-03
### Added
- **Event Images**: Event thumbnails in lists and hero images in details
- **Pokemon Details**: Detailed display of featured Pokemon, raid bosses, and shinies
  - Spotlight Hours: Featured Pokemon with shiny status and bonuses
  - Raid Battles: Raid boss gallery with available shinies
  - Community Days: Featured Pokemon, special research status, and bonuses
- **Shiny Badges**: Eye-catching display of which Pokemon are available as shinies
- **Live Countdown**: 
  - Live timer for active events with progress bar
  - Countdown for upcoming events
  - Compact badges in event lists
- **Status Display**: "Active Now" (green), "Starting Soon" (orange), "Ended" (gray)
- **Color-Coded Event Types**: 
  - Community Day (Green), Raids (Red), Spotlight Hour (Yellow)
  - GO Battle League (Purple), Research (Blue), Other (Gray)
- **About View**: Credits, copyright notices, and legal information
- **Image Caching**: Automatic caching for better performance

### Changed
- Event lists now with thumbnails and compact countdowns
- Event details with full hero image header
- Improved visual hierarchy and scanability

### Technical
- New ImageCacheService for efficient image management
- Actor-based caching for thread safety
- New component library for Pokemon details
- Cross-platform image handling (macOS/iOS)

---

## [0.1.0] – 2025-10-01
### Added
- First working MVP version
- Display of upcoming Pokémon GO events
- Add and save favorite cities
- Automatic conversion of event times to local time
- Persistent storage with **SwiftData** (no CloudKit)
- macOS: Menu bar command to refresh (**⌘R**)
- Multi-platform support (macOS-first, also runs on iOS)

### Known Limitations
- No iCloud synchronization
- No push notifications

---

## Format
- **Added** – new features  
- **Changed** – changes to existing functionality  
- **Fixed** – bug fixes  
- **Removed** – removed features

---
