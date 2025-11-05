# Timeline Planning

## Goals
Help players plan sequential participation across multiple cities or time zones for time-bound events (e.g., Community Days, Raid Hours).

## Core Components

- **TimelineService (`@Observable @MainActor`)**
  - Wraps `TimelineRepository` and `CityRepository`.
  - Loads, saves, updates, and deletes `TimelinePlan` and `TimelineTemplate` records.
  - Handles validation (non-empty names, valid city identifiers, event type checks).
  - Bumps `dateModified` on updates, manages default template uniqueness.
  - Exports plans/templates to `ExportableTimelinePlan` JSON (versioned) and imports with compatibility safeguards.
- **EventTimelineView**
  - Renders sequential timeline by converting each city’s event window into the user’s time zone (`TimezoneService.convertLocalEventTime`).
  - Displays event segments and gaps, summarises total duration vs active playtime.
  - Accepts planner menu actions (save, export).
- **Save Plan Dialog (`SavePlanDialog`)**
  - Captures user-provided plan name and invokes `TimelineService.savePlan`.

## Plans vs Templates

| Aspect | Timeline Plan | Timeline Template |
| ------ | ------------- | ----------------- |
| Scope | Specific event instance (`eventID`) | Event type (`eventType`) |
| Fields | `name`, `eventID`, `eventName`, `eventType`, `[cityIdentifiers]` | `name`, `eventType`, `[cityIdentifiers]`, `isDefault` |
| Use Case | Revisit past selections for the same event | Apply default city set for future events of same type |
| Export | JSON `.pzb` with event metadata | JSON `.pzb` without `eventID`/`eventName` |

## Export & Sharing

- `TimelineImageRenderer` captures timeline view as PNG (Retina-friendly, 1200×800).
- `ShareSheet` exposes share UI with exported data or images.
- `.pzb` files contain version/app metadata and city list; see `data/export-formats.md` for schema.

## Calendar Integration (macOS)

- `CalendarService` provides:
  - `addEventToCalendar` (single city).
  - `addMultiCityEventToCalendar` (multi-city plan).
- Converts between event-local times and user calendar timezone.
- Requires EventKit write-only permission; prompts handled inside service.

## Timeline Import Entry Point (Settings)

### Purpose
Expose a dedicated entry point in the Settings → Timeline Management card that lets power users import exported `.pzb` timeline plans without leaving the management hub. The button now owns the only timeline-plan `fileImporter`, preventing conflicts with the data-management importer.

### Usage Examples
```swift
@State private var showTimelineImportPicker = false

Button {
    showTimelineImportPicker = true
} label: {
    timelineNavigationLabel(
        icon: "square.and.arrow.down",
        title: String(localized: "timeline.import.title"),
        subtitle: String(localized: "timeline.import.subtitle"),
        showChevron: false
    )
}
.buttonStyle(.plain)
.fileImporter(
    isPresented: $showTimelineImportPicker,
    allowedContentTypes: [.json],
    allowsMultipleSelection: false
) { result in
    handleImport(result) // delegates to TimelineService.importPlan
}
```

### Parameters
- `showTimelineImportPicker: Binding<Bool>` – toggles presentation of the Finder/iOS document picker; must remain `false` once dismissal completes.
- `allowedContentTypes: [UTType]` – restricts selection to `.json` since timeline exports use JSON payloads.
- `allowsMultipleSelection: Bool` – keep `false`; timeline importer currently processes one plan at a time.
- `handleImport(_:)` – existing helper that unwraps `Result<[URL], Error>` and passes data to `TimelineService.importPlan(from:)`.

### Return Values
- `fileImporter` provides a `Result<[URL], Error>`; success returns security-scoped URLs for the selected plan, while failure delivers the system error. Side effects include showing a success alert (`timeline.import.success`) or propagating `TimelineError` descriptions.

### Edge Cases
- First invocation can take a couple of seconds while macOS/iOS warms up the file picker; no app code runs during this delay.
- Sandbox environments may require security-scoped access; `TimelineService.importPlan` reads raw data immediately to minimise scope duration.
- Cancelling the picker leaves `showTimelineImportPicker` as `false`; ensure the binding is not reused elsewhere to avoid re-entrancy issues.

### Architectural Context
- Lives inside the **Timeline Management** card in `SettingsView`. The scoped importer ensures the data-management `ImportExportView` can present its own picker independently.
- Continues to rely on `TimelineService` for validation, deduplication, and persistence of imported plans; no business logic moved into the view.
- Complements export paths handled by `TimelinePlansListView` and maintains parity with macOS/iOS navigation shells.

### Change Notes
- **Nov 2025:** Scoped the `.fileImporter` directly to the timeline import button (`showTimelineImportPicker`) to resolve a collision that prevented the cities/spots importer from presenting. No changes to underlying import logic.

## Contextual Guidance (TipKit)

- `TipService` centralises TipKit configuration and exposes three reusable tips:
  - **PlannerTemplateTip** highlights timeline templates after the first (and second) saved plan via the planner menu.
  - **EventFiltersTip** nudges users toward combined search/type filters the first time filters become active.
  - **TimelineExportTip** surfaces export guidance once a user finishes an Import/Export export flow.
- Each tip caps display counts (`Tips.MaxDisplayCount`) and ignores default spacing so the overlay appears immediately after the qualifying action.
- Views record triggers through `TipService.recordPlanSaved()`, `recordFiltersUsed()`, and `recordTimelineExport()`, keeping business logic out of SwiftUI layers.

### Settings & Reset
- Settings → Cache & Actions now hosts a “Show contextual tips” toggle backed by SwiftData (`TipPreferences`) and `@AppStorage` for instant UI updates.
- “Reset tips” clears the TipKit datastore and stamps `TipPreferences.lastReset`, making overlays eligible again; the subtitle shows relative last-reset timing.
- macOS and iOS scene observers dismiss active tips when the window or scene resigns, preventing overlays from lingering across window switches.

## Related Documentation

- `features/events.md` for how the planner appears in the event detail screen.
- `services/services-and-repositories.md` for repository responsibilities.
- `data/export-formats.md` for plan/template JSON structure.
