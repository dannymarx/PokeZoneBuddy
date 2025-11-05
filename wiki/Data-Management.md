# Data Management

PokeZoneBuddy makes it easy to safeguard your event plans, favourite cities, and raid spots. Use these tools to export backups, share data with friends, or restore everything on a new device.

## Cities and Spots Export
- Open **Settings → Import & Export**.
- Tap **Export Cities & Spots** to generate a JSON file that contains every saved city and spot, including notes, categories, and favourite flags.
- The app names exports `PokeZoneBuddy_Export_<YYYY-MM-DD>.json` and shares them via the system share sheet (AirDrop, Files, email, etc.).
- Keep exports in a safe place so you can restore them later or share coordinates with teammates.

## Import Cities and Spots
- From the same Import & Export screen, choose **Import**.
- Select your export JSON and pick a mode:
  - **Merge:** Adds new cities and spots while leaving existing data untouched.
  - **Replace:** Clears current cities and spots before importing the file.
- The app validates coordinates, timezones, and duplicates to prevent corrupt data.
- After import, you’ll see a summary with counts of imported and skipped entries.

## Timeline Plan Bundles (`.pzb`)
- Timeline plans and templates export as versioned `.pzb` files (JSON under the hood).
- Export from the planner menu or the Timeline Plans/ Templates lists in Settings.
- Share the `.pzb` file with friends; they can import it using the Timeline Import button in Settings.
- Imports check app version compatibility, city lists, and event metadata before saving.

## Restoring After Reinstall
- Reinstall the app, then import your latest cities/spots JSON and any timeline `.pzb` files.
- Re-run the Events sync and re-enable notifications if needed.

## Tips for Safe Sharing
- Review exported files before sharing to confirm there’s no personal information in your notes.
- Use Merge mode when collaborating so multiple teammates can contribute new cities without overwriting each other.

Curious about automation and calendar workflows? Explore [Shortcuts and Integrations](./Shortcuts-and-Integrations) next.
