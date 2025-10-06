# PokeZoneBuddy

**PokeZoneBuddy** is a macOS app that displays Pokémon GO events and automatically converts event times to your favorite cities' local times. Know exactly when you need to be active at home to participate in an event happening in Tokyo, New York, or anywhere else in the world.

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/dannymarx/PokeZoneBuddy/releases)
[![Platform](https://img.shields.io/badge/platform-macOS%2026.0+-lightgrey.svg)](https://github.com/dannymarx/PokeZoneBuddy)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![Swift](https://img.shields.io/badge/swift-5.9+-orange.svg)](https://swift.org)

---

## ✨ Features

### 🌍 Time Zone Magic
- **Favorite Cities**: Track events in cities around the world
- **Smart Conversion**: Automatic conversion to your local timezone
- **Dual Display**: See both event local time and your time
- **Calendar Export**: Add events to macOS Calendar with one click

### 📅 Event Management
- **Live Overview**: Browse all upcoming Pokémon GO events
- **Event Details**: 
  - Featured Pokémon with shiny availability
  - Raid bosses and special research
  - Event bonuses and multipliers
- **Filter & Search**: Find events by type or name instantly
- **Favorites**: Star important events for quick access
- **Live Countdowns**: Real-time timers and progress bars

### 📡 Smart & Offline
- **Offline Mode**: Full functionality without internet
- **Auto-Refresh**: Background updates every 30 minutes
- **Smart Caching**: 50MB memory / 200MB disk cache
- **Cache Management**: View stats and clear storage manually
- **Fast Performance**: Smooth scrolling with 1000+ events

### 🎨 Native Experience
- **macOS Design**: Native SwiftUI with Dark Mode support
- **Accessibility**: VoiceOver, Dynamic Type, semantic labels
- **Multi-language**: English and German
- **Visual Clarity**: Color-coded event types, status badges

---

## 🚀 Installation

### Download
1. Download the latest **[Release](https://github.com/dannymarx/PokeZoneBuddy/releases/latest)**
2. Open the `.dmg` file
3. Drag **PokeZoneBuddy** to your Applications folder
4. Launch and enjoy!

### Build from Source
```bash
git clone https://github.com/dannymarx/PokeZoneBuddy.git
cd PokeZoneBuddy
open PokeZoneBuddy.xcodeproj
```

**Requirements:**
- macOS 26.0+
- Xcode 16.0+
- Swift 5.9+

---

## 📖 How It Works

### Example
**Community Day in Tokyo** runs 14:00–17:00 JST  
→ **You play** 07:00–10:00 in your local time (CEST)

### Data Flow
1. Fetch events from **ScrapedDuck API** (LeekDuck mirror)
2. Cache locally with URLCache (offline-first)
3. Add your favorite cities
4. Events auto-convert to your local timezone
5. Export to Calendar or star as favorite

---

## 📊 Data Source

Event data provided by:
- **[ScrapedDuck](https://github.com/bigfoott/ScrapedDuck)** (MIT License) – API for Pokémon GO event data
- **[LeekDuck.com](https://leekduck.com)** – Original data source (scraped with permission)

Many thanks to the maintainers of these projects!

---

## ⚠️ Legal Notice

**This app is not officially affiliated with Pokémon GO** and is intended to fall under Fair Use doctrine, similar to any other informational site such as a wiki.

Pokémon and its trademarks are ©1995-2025 Nintendo, Creatures, and GAMEFREAK. All images and names owned and trademarked by Nintendo, Niantic, The Pokémon Company, and GAMEFREAK are property of their respective owners.

Event data courtesy of [Leek Duck](https://leekduck.com) via [ScrapedDuck API](https://github.com/bigfoott/ScrapedDuck). All rights reserved by their respective owners.

---

## 🔒 Privacy

- **No tracking**: Zero analytics, telemetry, or crash reporting
- **Local storage**: All data stored on your device with SwiftData
- **No account**: No sign-up, no email, no personal data
- **Minimal permissions**: Calendar write-only access (optional)

[Full Privacy Policy](https://dannymarx.github.io/PokeZoneBuddy/privacy.html)

---

## 🛠 Tech Stack

- **Platform**: macOS 26.0+ (iOS-ready architecture)
- **Framework**: SwiftUI with Observation
- **Architecture**: MVVM with service layer
- **Storage**: SwiftData + URLCache
- **Networking**: URLSession with offline-first caching
- **Testing**: XCTest for unit tests

### Key Services
- `APIService` – Event fetching with 200MB disk cache
- `TimezoneService` – Date/time conversion across zones
- `NetworkMonitor` – NWPathMonitor for connectivity
- `CalendarService` – EventKit integration (macOS)
- `CacheManagementService` – Storage monitoring
- `BackgroundRefreshService` – Auto-updates every 30min

---

## 🧪 Testing

Run tests in Xcode:
```bash
Product → Test  # or ⌘U
```

Test coverage:
- ✅ Timezone conversion (DST, UTC±14, date boundaries)
- ✅ API parsing (optional fields, edge cases)
- ✅ Localization (key existence, placeholder validation)
- ✅ ViewModel logic (offline mode, cache handling)

---

## 📄 License

MIT License – see [LICENSE](./LICENSE) file for details.

Copyright (c) 2025 Danny Hollek

---

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the [Developer Style Guide](./PokeZoneBuddy_developer_style_guide.md)
4. Run tests and format with `swift-format`
5. Submit a pull request

---

## 🔗 Links

- [Website](https://dannymarx.github.io/PokeZoneBuddy)
- [GitHub](https://github.com/dannymarx/PokeZoneBuddy)
- [Issues](https://github.com/dannymarx/PokeZoneBuddy/issues)
- [Privacy Policy](https://dannymarx.github.io/PokeZoneBuddy/privacy.html)

---

##### This app was created 99% by AI and 1% by a human who brought it all together.
