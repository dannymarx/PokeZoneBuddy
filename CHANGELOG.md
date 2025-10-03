# Changelog

Alle relevanten Änderungen an **PokeZoneBuddy** werden hier dokumentiert.  
Dieses Projekt folgt (noch) keinem strengen [Semantic Versioning](https://semver.org/), aber Versionssprünge orientieren sich grob daran.

---

## [0.2.0] – 2025-10-03
### Added
- **Event-Bilder**: Event-Thumbnails in Listen und Hero-Images in Details
- **Pokemon-Details**: Detaillierte Anzeige von Featured Pokemon, Raid-Bossen und Shinies
  - Spotlight Hours: Featured Pokemon mit Shiny-Status und Bonusse
  - Raid Battles: Raid-Boss-Galerie mit verfügbaren Shinies
  - Community Days: Featured Pokemon, Special Research Status und Bonusse
- **Shiny-Badges**: Auffällige Anzeige welche Pokemon als Shiny verfügbar sind
- **Live-Countdown**: 
  - Live-Timer für laufende Events mit Progress-Bar
  - Countdown für kommende Events
  - Kompakte Badges in Event-Listen
- **Status-Anzeige**: "Läuft jetzt" (grün), "Startet bald" (orange), "Beendet" (grau)
- **Farbcodierte Event-Types**: 
  - Community Day (Grün), Raids (Rot), Spotlight Hour (Gelb)
  - GO Battle League (Lila), Research (Blau), Sonstige (Grau)
- **About-View**: Credits, Copyright-Hinweise und rechtliche Informationen
- **Image-Caching**: Automatisches Caching für bessere Performance

### Changed
- Event-Listen jetzt mit Thumbnails und kompakten Countdowns
- Event-Details mit vollständigem Hero-Image-Header
- Verbesserte visuelle Hierarchie und Scanability

### Technical
- Neuer ImageCacheService für effizientes Image-Management
- Actor-basiertes Caching für Thread-Safety
- Neue Component-Bibliothek für Pokemon-Details
- Cross-Platform Image-Handling (macOS/iOS)

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