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
    
    /// Serial queue to synchronize access to DateFormatter (not thread-safe)
    private let formatterQueue = DispatchQueue(label: "TimezoneService.formatter")
    
    // MARK: - Date Formatters
    
    /// Formatter for date + time (e.g. "Oct 05, 2025, 2:00 PM")
    private lazy var dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()
    
    /// Formatter for time only (e.g. "2:00 PM")
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()
    
    /// Formatter for date only (e.g. "October 5, 2025")
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()
    
    enum FormatStyle { case date, time, dateTime }

    /// Unified format helper that respects the current Locale and a provided timezone
    func format(_ date: Date, style: FormatStyle, in timeZone: TimeZone) -> String {
        return formatterQueue.sync {
            let formatter: DateFormatter
            switch style {
            case .date:
                formatter = dateFormatter
            case .time:
                formatter = timeFormatter
            case .dateTime:
                formatter = dateTimeFormatter
            }
            formatter.timeZone = timeZone
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Timezone Conversion
    
    /// Converts a date from a source timezone to a target timezone by adjusting components
    /// - Parameters:
    ///   - date: The original date
    ///   - fromTZ: Source timezone
    ///   - toTZ: Target timezone
    /// - Returns: Converted date
    func convert(date: Date, from fromTZ: TimeZone, to toTZ: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = fromTZ
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)
        var targetCal = Calendar(identifier: .gregorian)
        targetCal.timeZone = toTZ
        return targetCal.date(from: comps) ?? date
    }
    
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
        return formatterQueue.sync {
            let formatter = includeDate ? dateTimeFormatter : timeFormatter
            formatter.timeZone = timezone
            let timeString = formatter.string(from: date)
            let tzAbbreviation = timezone.abbreviation() ?? timezone.identifier
            return "\(timeString) \(tzAbbreviation)"
        }
    }
    
    /// Formats only the time for a timezone
    /// - Parameters:
    ///   - date: The date to format
    ///   - timezone: The timezone
    /// - Returns: Time only (e.g. "2:00 PM")
    func formatTimeOnly(_ date: Date, timezone: TimeZone) -> String {
        return formatterQueue.sync {
            timeFormatter.timeZone = timezone
            return timeFormatter.string(from: date)
        }
    }
    
    /// Formats only the date for a timezone
    /// - Parameters:
    ///   - date: The date to format
    ///   - timezone: The timezone
    /// - Returns: Date only (e.g. "October 5, 2025")
    func formatDateOnly(_ date: Date, timezone: TimeZone) -> String {
        return formatterQueue.sync {
            dateFormatter.timeZone = timezone
            return dateFormatter.string(from: date)
        }
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
        let startTime = format(startDate, style: .time, in: timezone)
        let endTime = format(endDate, style: .time, in: timezone)
        let tzAbbreviation = timezone.abbreviation() ?? timezone.identifier
        if includeDate {
            let dateString = format(startDate, style: .date, in: timezone)
            return "\(dateString), \(startTime)-\(endTime) \(tzAbbreviation)"
        } else {
            return "\(startTime)-\(endTime) \(tzAbbreviation)"
        }
    }
    
    /// Returns a compact range string like "14:00–17:00" or including date when needed
    func rangeString(start: Date, end: Date, in tz: TimeZone, includeDate: Bool = false) -> String {
        let startStr = format(start, style: .time, in: tz)
        let endStr = format(end, style: .time, in: tz)
        if includeDate {
            let dateStr = format(start, style: .date, in: tz)
            return "\(dateStr) \(startStr)–\(endStr)"
        }
        return "\(startStr)–\(endStr)"
    }
    
    /// Formats a time range for events, considering if they are global or local time
    /// - Parameters:
    ///   - startDate: Start time (stored as UTC)
    ///   - endDate: End time (stored as UTC)
    ///   - timezone: The target timezone
    ///   - isGlobalTime: If true, convert timezone. If false, show same time everywhere
    ///   - includeDate: Whether to include the date
    /// - Returns: Formatted time range
    func formatEventTimeRange(
        startDate: Date,
        endDate: Date,
        timezone: TimeZone,
        isGlobalTime: Bool,
        includeDate: Bool = false
    ) -> String {
        if isGlobalTime {
            // Global event: Convert to target timezone
            return formatTimeRange(
                startDate: startDate,
                endDate: endDate,
                timezone: timezone,
                includeDate: includeDate
            )
        } else {
            // Local event: Show same time everywhere (no timezone conversion)
            return formatterQueue.sync {
                let utc = TimeZone(secondsFromGMT: 0) ?? .gmt
                timeFormatter.timeZone = utc
                let startTime = timeFormatter.string(from: startDate)
                let endTime = timeFormatter.string(from: endDate)
                let tzAbbreviation = timezone.abbreviation() ?? timezone.identifier
                if includeDate {
                    dateFormatter.timeZone = utc
                    let dateString = dateFormatter.string(from: startDate)
                    return "\(dateString), \(startTime)-\(endTime) \(tzAbbreviation)"
                } else {
                    return "\(startTime)-\(endTime) \(tzAbbreviation)"
                }
            }
        }
    }
    
    /// Converts local event time from one timezone to another
    /// For events that happen at the same "wall clock time" everywhere (e.g., 14:00 local time)
    /// - Parameters:
    ///   - date: The UTC date representing the local time components
    ///   - fromTimezone: The timezone where the event happens (e.g., Tokyo)
    ///   - toTimezone: The user's timezone (e.g., Berlin)
    /// - Returns: The date adjusted to show when to play in user's timezone
    func convertLocalEventTime(_ date: Date, from fromTimezone: TimeZone, to toTimezone: TimeZone) -> Date {
        // Extract time components from UTC date
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let components = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        // Interpret these components as being in the city's timezone
        var cityCalendar = Calendar(identifier: .gregorian)
        cityCalendar.timeZone = fromTimezone
        guard let cityDate = cityCalendar.date(from: components) else { return date }
        
        // This cityDate is now the absolute time when the event happens in the city
        // Return it as-is - when formatted with user's timezone, it will show the correct time
        return cityDate
    }
    
    /// Formats a time range for local events, showing the converted time in user's timezone
    /// - Parameters:
    ///   - startDate: Start time (UTC components represent local time)
    ///   - endDate: End time (UTC components represent local time)
    ///   - cityTimezone: The timezone where the event happens
    ///   - userTimezone: The user's timezone
    ///   - includeDate: Whether to include the date
    /// - Returns: Formatted time range in user's timezone
    func formatLocalEventInUserTime(
        startDate: Date,
        endDate: Date,
        cityTimezone: TimeZone,
        userTimezone: TimeZone,
        includeDate: Bool = false
    ) -> String {
        // Convert the local event times to absolute times
        let absoluteStart = convertLocalEventTime(startDate, from: cityTimezone, to: userTimezone)
        let absoluteEnd = convertLocalEventTime(endDate, from: cityTimezone, to: userTimezone)
        
        // Format with user's timezone
        return formatTimeRange(
            startDate: absoluteStart,
            endDate: absoluteEnd,
            timezone: userTimezone,
            includeDate: includeDate
        )
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

