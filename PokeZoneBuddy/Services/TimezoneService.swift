//
//  TimezoneService.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 01.10.2025.
//

import Foundation

/// Service for timezone conversions and time formatting
final class TimezoneService {
    
    // MARK: - Singleton
    static let shared = TimezoneService()
    private init() {}
    
    // MARK: - Date Formatters
    
    /// Formatter for date + time (e.g. "Oct 05, 2025, 2:00 PM")
    private lazy var dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    /// Formatter for time only (e.g. "2:00 PM")
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    /// Formatter for date only (e.g. "October 5, 2025")
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    // MARK: - Timezone Conversion
    
    /// Does not convert a Date object (Date is always UTC),
    /// but returns the same Date for display in a different timezone
    /// - Parameters:
    ///   - date: The date to convert
    ///   - timezone: The target timezone
    /// - Returns: The same Date (Dates are timezone-agnostic)
    func convertToTimezone(_ date: Date, to timezone: TimeZone) -> Date {
        // Date objects are always in UTC, the timezone is only used for display
        return date
    }
    
    /// Formats a date for a specific timezone
    /// - Parameters:
    ///   - date: The date to format
    ///   - timezone: The timezone for formatting
    ///   - includeDate: Whether to include the date (default: true)
    /// - Returns: Formatted string (e.g. "Oct 05, 2025, 2:00 PM JST")
    func formatDateForTimezone(_ date: Date, timezone: TimeZone, includeDate: Bool = true) -> String {
        let formatter = includeDate ? dateTimeFormatter : timeFormatter
        formatter.timeZone = timezone
        
        let timeString = formatter.string(from: date)
        let tzAbbreviation = timezone.abbreviation() ?? timezone.identifier
        
        return "\(timeString) \(tzAbbreviation)"
    }
    
    /// Formats only the time for a timezone
    /// - Parameters:
    ///   - date: The date to format
    ///   - timezone: The timezone
    /// - Returns: Time only (e.g. "2:00 PM")
    func formatTimeOnly(_ date: Date, timezone: TimeZone) -> String {
        timeFormatter.timeZone = timezone
        return timeFormatter.string(from: date)
    }
    
    /// Formats only the date for a timezone
    /// - Parameters:
    ///   - date: The date to format
    ///   - timezone: The timezone
    /// - Returns: Date only (e.g. "October 5, 2025")
    func formatDateOnly(_ date: Date, timezone: TimeZone) -> String {
        dateFormatter.timeZone = timezone
        return dateFormatter.string(from: date)
    }
    
    // MARK: - Time Range Formatting
    
    /// Formats a time range (start-end) for a timezone
    /// - Parameters:
    ///   - startDate: Start time
    ///   - endDate: End time
    ///   - timezone: The timezone
    ///   - includeDate: Whether to include the date
    /// - Returns: Formatted time range (e.g. "2:00 PM-5:00 PM JST" or "Oct 05, 2:00 PM-5:00 PM JST")
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
    
    /// Calculates the time difference between two timezones in hours
    /// - Parameters:
    ///   - fromTimezone: Source timezone
    ///   - toTimezone: Target timezone
    ///   - date: Reference date (important because of daylight saving)
    /// - Returns: Time difference in hours (can be negative)
    func timeDifference(
        from fromTimezone: TimeZone,
        to toTimezone: TimeZone,
        at date: Date = Date()
    ) -> Int {
        let fromOffset = fromTimezone.secondsFromGMT(for: date)
        let toOffset = toTimezone.secondsFromGMT(for: date)
        return (toOffset - fromOffset) / 3600
    }
    
    /// Creates a text that explains the time difference
    /// - Parameters:
    ///   - sourceTimezone: The source timezone
    ///   - targetTimezone: The target timezone
    ///   - date: Reference date
    /// - Returns: Descriptive text (e.g. "7 hours behind your time")
    func timeDifferenceDescription(
        from sourceTimezone: TimeZone,
        to targetTimezone: TimeZone,
        at date: Date = Date()
    ) -> String {
        let difference = timeDifference(from: sourceTimezone, to: targetTimezone, at: date)
        
        if difference == 0 {
            return String(localized: "time.same_as_yours")
        } else if difference > 0 {
            return String(format: String(localized: "time.hours_ahead"), abs(difference))
        } else {
            return String(format: String(localized: "time.hours_behind"), abs(difference))
        }
    }
    
    // MARK: - User's Current Timezone
    
    /// The current timezone of the user
    var userTimezone: TimeZone {
        return TimeZone.current
    }
    
    /// Formats a date for the user's timezone
    func formatDateForUser(_ date: Date, includeDate: Bool = true) -> String {
        return formatDateForTimezone(date, timezone: userTimezone, includeDate: includeDate)
    }
}

