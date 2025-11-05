# Getting Started

New to PokeZoneBuddy? This guide walks you through installation, first launch, and the core setup steps so you can start exploring events and building plans right away.

## Requirements
- **macOS 15 (Sequoia) or later** for the desktop app.
- **iOS 18 or later** for the mobile app (no App Store build yet; run via Xcode).
- Xcode 16+ if you plan to run the iOS simulator build.
- An internet connection is recommended for the initial event sync, but most features continue to work offline once data is cached.

## Install on macOS
1. Download the latest `.dmg` from the [releases page](https://github.com/dannymarx/PokeZoneBuddy/releases/latest).
2. Open the disk image and drag **PokeZoneBuddy** into your Applications folder.
3. Launch the app. Grant notification permission if you plan to use reminders.

## Install on iOS (via Xcode)
1. Clone or download the repository.
2. Open `PokeZoneBuddy.xcodeproj` in Xcode 16 or later.
3. Select the `PokeZoneBuddy` iOS scheme and target your simulator or registered device.
4. Build and run. Approve notification prompts on first launch if you want reminders.

## First Launch Checklist
- **Sync Events:** The Events tab automatically fetches the latest schedule on first load. Pull to refresh anytime.
- **Pin Favourite Cities:** Head to the Cities tab, search for locations, and add the ones you care about. Timezones are resolved automatically.
- **Enable Reminders (Optional):** Allow notifications when prompted so you can schedule event alerts later.
- **Explore the Timeline Planner:** Pick an event, tap into the planner, and add cities to see how timelines line up across regions.

## Staying Up to Date
- Pull-to-refresh on the Events list fetches new data whenever you have a connection.
- Background refresh (macOS and iOS) keeps cached data current every 30 minutes when the app is active or in the background.
- Check the [Timeline Planner](./Timeline-Planner) and [Notifications](./Notifications) pages to learn how reminders and exported plans stay in sync across devices.

Ready for more? Jump to the [Events Hub](./Events-Hub) to learn how to browse and favourite events, or skip ahead to [Tips and FAQ](./Tips-and-FAQ) for quick wins.
