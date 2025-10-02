# Changelog

Alle relevanten Änderungen an **PokeZoneBuddy** werden hier dokumentiert.  
Dieses Projekt folgt (noch) keinem strengen [Semantic Versioning](https://semver.org/), aber Versionssprünge orientieren sich grob daran.

---

## [0.1.0] – 2025-10-01
### Added
- Erste lauffähige MVP-Version
- Anzeige kommender Pokémon GO Events
- Favorisierte Städte hinzufügen und speichern
- Automatische Umrechnung der Eventzeiten in die lokale Zeit
- Persistente Speicherung mit **SwiftData** (kein CloudKit)
- macOS: Menüleisten-Befehl zum Aktualisieren (**⌘R**)
- Multiplattform-Unterstützung (macOS-first, lauffähig auch auf iOS)

### Known Limitations
- Keine iCloud-Synchronisation
- Keine Push Notifications
- Kein Kalender-Export (ICS)
- Nur deutsche UI-Sprache

---

## Format
- **Added** – neue Features  
- **Changed** – Änderungen an bestehender Funktionalität  
- **Fixed** – Bugs und Fehlerbehebungen  
- **Removed** – entfernte Features