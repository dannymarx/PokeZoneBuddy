# Events Hub

The Events hub is the heart of PokeZoneBuddy. It keeps you informed about current, upcoming, and recent Pokémon GO events with rich detail cards, filters, and reminders.

## Browsing Events
- **Events Tab (iOS) / Events Sidebar (macOS):** Access the list from the main navigation. Entries are grouped into Active, Upcoming, and Past.
- **Countdown Timers:** Each card shows a live countdown until the event starts or ends, along with badges for highlights like spawns, raids, or special research.
- **Pull to Refresh:** Swipe down (iOS) or use the toolbar refresh button (macOS) to fetch the latest data at any time.
- **Offline Friendly:** Previously fetched events remain available without a connection. You will see an offline badge when the network is unavailable.

## Filtering and Search
- Tap the **Filter** button to choose which event types appear (Community Day, Spotlight Hour, Raid, and more).
- Use the search bar to match keywords across event names, headings, and types.
- Filter combinations are remembered so you can keep the event stream tailored to your playstyle.

## Event Detail View
Selecting an event opens a detail sheet or panel tailored to your platform:
- **Hero Header:** High-resolution artwork, status badge, and time window in both local and event timezones.
- **Highlights:** See featured Pokémon, raid bosses, bonuses, and any special research steps. Items update automatically when new data arrives.
- **Timeline Planner:** Jump directly into multi-city planning (see [Timeline Planner](./Timeline-Planner.md)).
- **Sharing:** Export the event timeline as an image or share details via the system share sheet.

## Favourites and Reminders
- Use the star icon to mark an event as a favourite. Favourites sync across your devices via SwiftData.
- Toggle reminder offsets (15 minutes to 1 day) to queue local notifications. You can pick which city’s timezone drives the alert on macOS.
- Head over to [Notifications](./Notifications.md) for deeper control over permissions, test reminders, and calendar exports.

## Background Updates
- PokeZoneBuddy checks for fresh event data in the background every 30 minutes when the network allows it.
- Background refresh also clears expired reminders and temporary images so your device stays tidy.

Next steps: learn how to turn event schedules into multi-city strategies with the [Timeline Planner](./Timeline-Planner.md).

