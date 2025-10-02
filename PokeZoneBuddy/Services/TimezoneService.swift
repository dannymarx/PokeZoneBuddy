//
//  TimezoneService.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.2025.
//

import Foundation

/// Service für Timezone-Konvertierungen und Zeit-Formatierungen
final class TimezoneService {
    
    // MARK: - Singleton
    static let shared = TimezoneService()
    private init() {}
    
    // MARK: - Date Formatters
    
    /// Formatter für Datum + Zeit (z.B. "05. Okt 2025, 14:00")
    private lazy var dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    
    /// Formatter nur für Zeit (z.B. "14:00")
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    
    /// Formatter für Datum (z.B. "05. Oktober 2025")
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    
    // MARK: - Timezone Conversion
    
    /// Konvertiert ein Date-Objekt nicht (Date ist immer UTC),
    /// gibt aber das gleiche Date zurück für die Anzeige in einer anderen Timezone
    /// - Parameters:
    ///   - date: Das zu konvertierende Datum
    ///   - timezone: Die Ziel-Timezone
    /// - Returns: Das gleiche Date (Dates sind timezone-agnostic)
    func convertToTimezone(_ date: Date, to timezone: TimeZone) -> Date {
        // Date-Objekte sind immer in UTC, die Timezone wird nur für die Anzeige verwendet
        return date
    }
    
    /// Formatiert ein Datum für eine bestimmte Timezone
    /// - Parameters:
    ///   - date: Das zu formatierende Datum
    ///   - timezone: Die Timezone für die Formatierung
    ///   - includeDate: Ob das Datum mit angezeigt werden soll (default: true)
    /// - Returns: Formatierter String (z.B. "05. Okt 2025, 14:00 JST")
    func formatDateForTimezone(_ date: Date, timezone: TimeZone, includeDate: Bool = true) -> String {
        let formatter = includeDate ? dateTimeFormatter : timeFormatter
        formatter.timeZone = timezone
        
        let timeString = formatter.string(from: date)
        let tzAbbreviation = timezone.abbreviation() ?? timezone.identifier
        
        return "\(timeString) \(tzAbbreviation)"
    }
    
    /// Formatiert nur die Zeit für eine Timezone
    /// - Parameters:
    ///   - date: Das zu formatierende Datum
    ///   - timezone: Die Timezone
    /// - Returns: Nur die Zeit (z.B. "14:00")
    func formatTimeOnly(_ date: Date, timezone: TimeZone) -> String {
        timeFormatter.timeZone = timezone
        return timeFormatter.string(from: date)
    }
    
    /// Formatiert nur das Datum für eine Timezone
    /// - Parameters:
    ///   - date: Das zu formatierende Datum
    ///   - timezone: Die Timezone
    /// - Returns: Nur das Datum (z.B. "05. Oktober 2025")
    func formatDateOnly(_ date: Date, timezone: TimeZone) -> String {
        dateFormatter.timeZone = timezone
        return dateFormatter.string(from: date)
    }
    
    // MARK: - Time Range Formatting
    
    /// Formatiert einen Zeitbereich (Start-Ende) für eine Timezone
    /// - Parameters:
    ///   - startDate: Startzeit
    ///   - endDate: Endzeit
    ///   - timezone: Die Timezone
    ///   - includeDate: Ob das Datum angezeigt werden soll
    /// - Returns: Formatierter Zeitbereich (z.B. "14:00-17:00 JST" oder "05. Okt, 14:00-17:00 JST")
    func formatTimeRange(
        startDate: Date,
        endDate: Date,
        timezone: TimeZone,
        includeDate: Bool = false
    ) -> String {
        timeFormatter.timeZone = timezone
        
        let startTime = timeFormatter.string(from: startDate)
        let endTime = timeFormatter.string(from: endDate)
        let tzAbbreviation = timezone.abbreviation() ?? timezone.identifier
        
        if includeDate {
            dateFormatter.timeZone = timezone
            let dateString = dateFormatter.string(from: startDate)
            return "\(dateString), \(startTime)-\(endTime) \(tzAbbreviation)"
        } else {
            return "\(startTime)-\(endTime) \(tzAbbreviation)"
        }
    }
    
    // MARK: - Comparison Helpers
    
    /// Berechnet die Zeitdifferenz zwischen zwei Timezones in Stunden
    /// - Parameters:
    ///   - fromTimezone: Quell-Timezone
    ///   - toTimezone: Ziel-Timezone
    ///   - date: Referenzdatum (wichtig wegen Sommerzeit)
    /// - Returns: Zeitdifferenz in Stunden (kann negativ sein)
    func timeDifference(
        from fromTimezone: TimeZone,
        to toTimezone: TimeZone,
        at date: Date = Date()
    ) -> Int {
        let fromOffset = fromTimezone.secondsFromGMT(for: date)
        let toOffset = toTimezone.secondsFromGMT(for: date)
        return (toOffset - fromOffset) / 3600
    }
    
    /// Erstellt einen Text der die Zeitdifferenz erklärt
    /// - Parameters:
    ///   - sourceTimezone: Die Timezone der Quelle
    ///   - targetTimezone: Die Timezone des Ziels
    ///   - date: Referenzdatum
    /// - Returns: Beschreibender Text (z.B. "7 Stunden früher als deine Zeit")
    func timeDifferenceDescription(
        from sourceTimezone: TimeZone,
        to targetTimezone: TimeZone,
        at date: Date = Date()
    ) -> String {
        let difference = timeDifference(from: sourceTimezone, to: targetTimezone, at: date)
        
        if difference == 0 {
            return "Gleiche Zeit wie deine Zeit"
        } else if difference > 0 {
            return "\(abs(difference)) Stunden später als deine Zeit"
        } else {
            return "\(abs(difference)) Stunden früher als deine Zeit"
        }
    }
    
    // MARK: - User's Current Timezone
    
    /// Die aktuelle Timezone des Users
    var userTimezone: TimeZone {
        return TimeZone.current
    }
    
    /// Formatiert ein Datum für die User-Timezone
    func formatDateForUser(_ date: Date, includeDate: Bool = true) -> String {
        return formatDateForTimezone(date, timezone: userTimezone, includeDate: includeDate)
    }
}
