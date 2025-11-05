# PokeZoneBuddy

**PokeZoneBuddy** is a SwiftUI companion for macOS and iOS that keeps every Pokémon GO event and travel-ready timezone plan at your fingertips. Convert event schedules for Tokyo, New York, Berlin, or anywhere else without manual math and keep reusable timelines synced across devices.

[![Version](https://img.shields.io/badge/version-1.6.0-blue.svg)](https://github.com/dannymarx/PokeZoneBuddy/releases)
[![Platform](https://img.shields.io/badge/platform-macOS%2026.0+%20%7C%20iOS%2026.0+-lightgrey.svg)](https://github.com/dannymarx/PokeZoneBuddy)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![Swift](https://img.shields.io/badge/swift-5.9+-orange.svg)](https://swift.org)

---

## ✨ Feature Highlights

### 🗺️ Multi-City Planner
- **Sequential Timeline**: Visualize event windows across every selected city with smart travel gap detection
- **Reusable Plans**: Save, rename, and reload multi-city strategies per event without rebuilding from scratch
- **Templates & Defaults**: Apply reusable templates (with per-event-type defaults) to bootstrap new plans instantly
- **Sharing Toolkit**: Export timelines as high-resolution PNG images or JSON bundles and share them via the cross-platform share sheet
- **macOS Shortcuts**: Send cities straight to Calendar or target notifications to a chosen timezone right from the planner

### 📚 Timeline Library
- **Plan Management**: Dedicated settings hub to browse, search, edit, and delete saved plans grouped by event type
- **Template Studio**: Create reusable city templates, toggle defaults, and refine city selections over time
- **Import Ready**: Pull in teammate plans through the Files picker and apply them immediately to the current event
- **Quick Stats**: Live counters for plan and template totals keep your timeline library tidy

### 🌍 Time Zone Toolkit
- **Favorite Cities**: Track home bases and travel destinations with automatic timezone conversion and localized formatting
- **Global vs Local**: Handle global events gracefully while still converting local window events to your preferred timezone
- **Calendar Export**: macOS users can push any city’s window directly to the native Calendar app with one click

### 📅 Event Management
- **Live Feed**: Browse upcoming Pokémon GO events with countdowns, filters, and fast search
- **Deep Details**: Dive into featured Pokémon, raid bosses, bonuses, research, and more for every event
- **Favorites Hub**: Star critical events for quick access—SwiftData keeps selections synced safely offline
- **Offline First**: Aggressive caching and background refresh keep event data available even without a connection

### 📍 City Spots
- **Local Intel**: Save gyms, PokéStops, meetup points, or custom coordinates per city with rich notes and categories
- **Quick Actions**: Favorite important spots, sort intelligently, and copy/share coordinates in a tap
- **Import/Export**: Move your entire city + spot library across devices via JSON backups

### 🔔 Smart Notifications
- **Automatic Reminders**: Favoriting an event schedules reminders automatically
- **Custom Offsets**: Choose notification lead times from 15 minutes up to 1 day
- **Timezone Targeting**: On macOS select which city’s local time should drive the reminder
- **Background Cleanup**: Expired reminders and temporary notification images are pruned automatically

### 🎨 Native Experience
- **Universal SwiftUI**: Tailored layouts for macOS (multi-window) and iOS (tab navigation)
- **Theme Control**: Switch between system, light, and dark appearances at any time
- **Polished & Accessible**: English and German localization, VoiceOver-friendly components, and modern animations

### 🛠 Technical Highlights
- **SwiftData Everywhere**: Events, favorites, cities, spots, timeline plans, and templates share a rock-solid data store
- **Resilient Networking**: ScrapedDuck API integration with offline caching, background refresh, and request deduplication
- **Service Architecture**: Dedicated services for timelines, import/export, notifications, EventKit, network monitoring, and more

---

## 🚀 Installation

### macOS
1. Download the latest **[Release](https://github.com/dannymarx/PokeZoneBuddy/releases/latest)**
2. Open the `.dmg` file
3. Drag **PokeZoneBuddy** to your Applications folder
4. Launch and enjoy!

### iOS
- Open `PokeZoneBuddy.xcodeproj` with Xcode 16 or newer
- Select the iOS scheme and run on a simulator or development device (no App Store build yet)

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

## 📄 License

MIT License – see [LICENSE](./LICENSE) file for details.

Copyright (c) 2025 Danny Hollek


---

##### This app was created 99% by AI and 1% by a human who brought it all together.
