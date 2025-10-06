//
//  TimeConversionTests.swift
//  PokeZoneBuddyTests
//
//  Created by Refactoring on 06.10.2025.
//

import XCTest
@testable import PokeZoneBuddy

final class TimeConversionTests: XCTestCase {
    
    var timezoneService: TimezoneService!
    
    override func setUp() {
        super.setUp()
        timezoneService = TimezoneService.shared
    }
    
    override func tearDown() {
        timezoneService = nil
        super.tearDown()
    }
    
    // MARK: - Bangkok ↔ Berlin Tests
    
    func testBangkokToBerlinSummer() {
        // Bangkok UTC+7, Berlin UTC+2 (Summer)
        let bangkok = TimeZone(identifier: "Asia/Bangkok")!
        let berlin = TimeZone(identifier: "Europe/Berlin")!
        
        // July 2025 - Summer time in Berlin
        let dateString = "2025-07-15T14:00:00"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        formatter.timeZone = bangkok
        
        let bangkokTime = formatter.date(from: dateString)!
        let berlinTime = timezoneService.convert(date: bangkokTime, from: bangkok, to: berlin)
        
        // Bangkok 14:00 = Berlin 09:00 (5 hours difference in summer)
        let berlinFormatter = DateFormatter()
        berlinFormatter.timeZone = berlin
        berlinFormatter.dateFormat = "HH:mm"
        
        XCTAssertEqual(berlinFormatter.string(from: berlinTime), "09:00")
    }
    
    func testBangkokToBerlinWinter() {
        // Bangkok UTC+7, Berlin UTC+1 (Winter)
        let bangkok = TimeZone(identifier: "Asia/Bangkok")!
        let berlin = TimeZone(identifier: "Europe/Berlin")!
        
        // January 2025 - Winter time in Berlin
        let dateString = "2025-01-15T14:00:00"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        formatter.timeZone = bangkok
        
        let bangkokTime = formatter.date(from: dateString)!
        let berlinTime = timezoneService.convert(date: bangkokTime, from: bangkok, to: berlin)
        
        // Bangkok 14:00 = Berlin 08:00 (6 hours difference in winter)
        let berlinFormatter = DateFormatter()
        berlinFormatter.timeZone = berlin
        berlinFormatter.dateFormat = "HH:mm"
        
        XCTAssertEqual(berlinFormatter.string(from: berlinTime), "08:00")
    }
    
    // MARK: - Tokyo ↔ Berlin Tests
    
    func testTokyoToBerlinSummer() {
        // Tokyo UTC+9, Berlin UTC+2 (Summer)
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let berlin = TimeZone(identifier: "Europe/Berlin")!
        
        // July 2025
        let dateString = "2025-07-15T14:00:00"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        formatter.timeZone = tokyo
        
        let tokyoTime = formatter.date(from: dateString)!
        let berlinTime = timezoneService.convert(date: tokyoTime, from: tokyo, to: berlin)
        
        // Tokyo 14:00 = Berlin 07:00 (7 hours difference in summer)
        let berlinFormatter = DateFormatter()
        berlinFormatter.timeZone = berlin
        berlinFormatter.dateFormat = "HH:mm"
        
        XCTAssertEqual(berlinFormatter.string(from: berlinTime), "07:00")
    }
    
    func testTokyoToBerlinWinter() {
        // Tokyo UTC+9, Berlin UTC+1 (Winter)
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let berlin = TimeZone(identifier: "Europe/Berlin")!
        
        // January 2025
        let dateString = "2025-01-15T14:00:00"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        formatter.timeZone = tokyo
        
        let tokyoTime = formatter.date(from: dateString)!
        let berlinTime = timezoneService.convert(date: tokyoTime, from: tokyo, to: berlin)
        
        // Tokyo 14:00 = Berlin 06:00 (8 hours difference in winter)
        let berlinFormatter = DateFormatter()
        berlinFormatter.timeZone = berlin
        berlinFormatter.dateFormat = "HH:mm"
        
        XCTAssertEqual(berlinFormatter.string(from: berlinTime), "06:00")
    }
    
    // MARK: - DST Boundary Tests
    
    func testDSTTransitionSpringForward() {
        // Test Spring Forward (DST starts) in Berlin
        // 2025-03-30 02:00 → 03:00
        let berlin = TimeZone(identifier: "Europe/Berlin")!
        
        // Before DST
        let beforeDST = DateComponents(calendar: Calendar(identifier: .gregorian),
                                      timeZone: berlin,
                                      year: 2025, month: 3, day: 30, hour: 1, minute: 30)
        
        // After DST (should jump to 3:30)
        let afterDST = DateComponents(calendar: Calendar(identifier: .gregorian),
                                     timeZone: berlin,
                                     year: 2025, month: 3, day: 30, hour: 3, minute: 30)
        
        XCTAssertNotNil(beforeDST.date)
        XCTAssertNotNil(afterDST.date)
        
        // The hour 02:00-02:59 doesn't exist on this day
        let nonExistent = DateComponents(calendar: Calendar(identifier: .gregorian),
                                        timeZone: berlin,
                                        year: 2025, month: 3, day: 30, hour: 2, minute: 30)
        
        // Calendar should adjust to 03:30
        if let adjusted = nonExistent.date {
            let formatter = DateFormatter()
            formatter.timeZone = berlin
            formatter.dateFormat = "HH:mm"
            XCTAssertEqual(formatter.string(from: adjusted), "03:30")
        }
    }
    
    func testDSTTransitionFallBack() {
        // Test Fall Back (DST ends) in Berlin
        // 2025-10-26 03:00 → 02:00
        let berlin = TimeZone(identifier: "Europe/Berlin")!
        
        let formatter = DateFormatter()
        formatter.timeZone = berlin
        formatter.dateFormat = "HH:mm"
        
        // The hour 02:00-02:59 exists twice on this day
        let ambiguous = DateComponents(calendar: Calendar(identifier: .gregorian),
                                      timeZone: berlin,
                                      year: 2025, month: 10, day: 26, hour: 2, minute: 30)
        
        XCTAssertNotNil(ambiguous.date)
    }
    
    // MARK: - Overnight Events
    
    func testOvernightEventConversion() {
        // Event: Bangkok 23:30 - 00:30 (crosses midnight)
        let bangkok = TimeZone(identifier: "Asia/Bangkok")!
        let berlin = TimeZone(identifier: "Europe/Berlin")!
        
        // January 2025
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        formatter.timeZone = bangkok
        
        let startBangkok = formatter.date(from: "2025-01-15T23:30:00")!
        let endBangkok = formatter.date(from: "2025-01-16T00:30:00")!
        
        let startBerlin = timezoneService.convert(date: startBangkok, from: bangkok, to: berlin)
        let endBerlin = timezoneService.convert(date: endBangkok, from: bangkok, to: berlin)
        
        let berlinFormatter = DateFormatter()
        berlinFormatter.timeZone = berlin
        berlinFormatter.dateFormat = "dd HH:mm"
        
        // Bangkok 15th 23:30 = Berlin 15th 17:30
        XCTAssertEqual(berlinFormatter.string(from: startBerlin), "15 17:30")
        // Bangkok 16th 00:30 = Berlin 15th 18:30
        XCTAssertEqual(berlinFormatter.string(from: endBerlin), "15 18:30")
    }
    
    // MARK: - Range Formatting Tests
    
    func testRangeStringFormatting() {
        let bangkok = TimeZone(identifier: "Asia/Bangkok")!
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        formatter.timeZone = bangkok
        
        let start = formatter.date(from: "2025-07-15T14:00:00")!
        let end = formatter.date(from: "2025-07-15T17:00:00")!
        
        let range = timezoneService.rangeString(start: start, end: end, in: bangkok, includeDate: false)
        
        // Should contain both times
        XCTAssertTrue(range.contains("14:00") || range.contains("2:00"))
        XCTAssertTrue(range.contains("17:00") || range.contains("5:00"))
    }
    
    func testTimeDifference() {
        let bangkok = TimeZone(identifier: "Asia/Bangkok")!  // UTC+7
        let berlin = TimeZone(identifier: "Europe/Berlin")!  // UTC+1 (winter) or UTC+2 (summer)
        
        // Winter: Bangkok is 6 hours ahead
        let winterDate = DateComponents(calendar: Calendar(identifier: .gregorian),
                                       year: 2025, month: 1, day: 15).date!
        let winterDiff = timezoneService.timeDifference(from: bangkok, to: berlin, at: winterDate)
        XCTAssertEqual(winterDiff, -6)
        
        // Summer: Bangkok is 5 hours ahead
        let summerDate = DateComponents(calendar: Calendar(identifier: .gregorian),
                                       year: 2025, month: 7, day: 15).date!
        let summerDiff = timezoneService.timeDifference(from: bangkok, to: berlin, at: summerDate)
        XCTAssertEqual(summerDiff, -5)
    }
    
    // MARK: - Edge Cases
    
    func testSameTimezone() {
        let berlin = TimeZone(identifier: "Europe/Berlin")!
        let now = Date()
        
        let converted = timezoneService.convert(date: now, from: berlin, to: berlin)
        
        // Should be the same
        XCTAssertEqual(
            timezoneService.format(now, style: .dateTime, in: berlin),
            timezoneService.format(converted, style: .dateTime, in: berlin)
        )
    }
    
    func testLeapYear() {
        let berlin = TimeZone(identifier: "Europe/Berlin")!
        
        // 2024 is a leap year
        let leapDay = DateComponents(calendar: Calendar(identifier: .gregorian),
                                    timeZone: berlin,
                                    year: 2024, month: 2, day: 29, hour: 12).date!
        
        let formatted = timezoneService.format(leapDay, style: .date, in: berlin)
        XCTAssertTrue(formatted.contains("29") || formatted.contains("Feb"))
    }
}
