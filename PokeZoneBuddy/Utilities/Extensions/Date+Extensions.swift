//
//  Date+Extensions.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.2025.
//

import Foundation

extension Date {
    
    /// Prüft ob das Datum heute ist
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Prüft ob das Datum morgen ist
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// Prüft ob das Datum in dieser Woche ist
    var isThisWeek: Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Gibt einen relativen Zeitstring zurück (z.B. "in 2 Stunden", "vor 3 Tagen")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Formatiert das Datum für deutsche Locale
    func formatted(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: self)
    }
    
    /// Gibt nur das Datum ohne Zeit zurück
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Gibt das Datum am Ende des Tages zurück (23:59:59)
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    /// Berechnet die Differenz in Tagen zu einem anderen Datum
    func daysDifference(to date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self.startOfDay, to: date.startOfDay)
        return components.day ?? 0
    }
    
    /// Formatiert das Datum als ISO8601 String
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    
    /// Konvertiert Sekunden in Stunden
    var hours: Double {
        return self / 3600
    }
    
    /// Konvertiert Sekunden in Minuten
    var minutes: Double {
        return self / 60
    }
    
    /// Formatiert die Zeitspanne als String (z.B. "2h 30min")
    var formattedDuration: String {
        let hours = Int(self / 3600)
        let minutes = Int((self.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)min"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)min"
        } else {
            return "< 1min"
        }
    }
}
