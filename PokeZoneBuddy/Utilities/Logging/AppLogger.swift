import Foundation
import os

// MARK: - AppLogger
//
// Centralized logging system for PokeZoneBuddy using Apple's Unified Logging (OSLog)
//
// USAGE STANDARDS:
//
// 1. CHOOSING A CATEGORY:
//    - app:           Application lifecycle, general app events
//    - network:       API calls, network requests, connectivity
//    - background:    Background tasks, app refresh
//    - viewModel:     ViewModel operations, data transformations
//    - service:       Service layer operations (calendar, timeline, etc.)
//    - calendar:      Calendar integration, event scheduling
//    - cache:         Cache operations, storage management
//    - notifications: Notification scheduling and delivery
//
// 2. CHOOSING A LOG LEVEL:
//    - debug():       Detailed diagnostic information (only in DEBUG builds)
//    - info():        Informational messages about normal operations
//    - warn():        Warning conditions that don't prevent operation
//    - error():       Error conditions that need attention
//
// 3. PRIVACY GUIDELINES:
//    - Use standard methods for non-sensitive data (already public)
//    - Use private() methods for sensitive data (user IDs, coordinates, names)
//    - Example: AppLogger.network.infoPrivate("Loading events for user: \(userID)")
//
// 4. MESSAGE FORMATTING STANDARDS:
//    - Start with action verb in past tense for completed actions
//      ✅ "Loaded 15 events from cache"
//      ❌ "Loading events" or "load events"
//
//    - Use present continuous for in-progress operations
//      ✅ "Scheduling notification for event: \(eventID)"
//
//    - Include relevant context (counts, IDs, names)
//      ✅ "Deleted 3 expired notifications"
//      ❌ "Deleted notifications"
//
//    - Keep errors actionable
//      ✅ "Failed to schedule notification: \(error.localizedDescription)"
//      ❌ "Error: \(error)"
//
// 5. DEBUG ONLY LOGS:
//    - Use #if DEBUG wrapper for verbose logging that shouldn't ship
//    - Example:
//      #if DEBUG
//      AppLogger.viewModel.debug("Cache hit for key: \(key)")
//      #endif
//
// 6. STRUCTURED LOGGING HELPERS:
//    - Use logTiming() for performance-sensitive operations
//    - Use logError() for standardized error logging with context
//    - Example: AppLogger.network.logTiming("API fetch") { try await fetchData() }
//
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "App"

    static let app = Logger(subsystem: subsystem, category: "App")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let background = Logger(subsystem: subsystem, category: "Background")
    static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")
    static let service = Logger(subsystem: subsystem, category: "Service")
    static let calendar = Logger(subsystem: subsystem, category: "Calendar")
    static let cache = Logger(subsystem: subsystem, category: "Cache")
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")
}

// MARK: - Logger Extensions

extension Logger {
    // MARK: Public Logging (default privacy level)

    /// Log debug-level message (public) - Only included in DEBUG builds
    func debug(_ message: String) {
        #if DEBUG
        self.debug("\(message, privacy: .public)")
        #endif
    }

    /// Log info-level message (public)
    func info(_ message: String) {
        self.info("\(message, privacy: .public)")
    }

    /// Log warning-level message (public)
    func warn(_ message: String) {
        self.warning("\(message, privacy: .public)")
    }

    /// Log error-level message (public)
    func error(_ message: String) {
        self.error("\(message, privacy: .public)")
    }

    // MARK: Private Logging (sensitive data)

    /// Log debug-level message with private data - Only included in DEBUG builds
    func debugPrivate(_ message: String) {
        #if DEBUG
        self.debug("\(message, privacy: .private)")
        #endif
    }

    /// Log info-level message with private data
    func infoPrivate(_ message: String) {
        self.info("\(message, privacy: .private)")
    }

    /// Log warning-level message with private data
    func warnPrivate(_ message: String) {
        self.warning("\(message, privacy: .private)")
    }

    /// Log error-level message with private data
    func errorPrivate(_ message: String) {
        self.error("\(message, privacy: .private)")
    }

    // MARK: Structured Logging Helpers

    /// Log execution time of an operation
    /// - Parameters:
    ///   - operation: Name of the operation being timed
    ///   - block: The operation to execute and measure
    /// - Returns: Result of the operation
    func logTiming<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            self.debug("⏱️ \(operation) completed in \(String(format: "%.2f", elapsed))ms")
        }
        return try block()
    }

    /// Log execution time of an async operation
    /// - Parameters:
    ///   - operation: Name of the operation being timed
    ///   - block: The async operation to execute and measure
    /// - Returns: Result of the operation
    func logTiming<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            self.debug("⏱️ \(operation) completed in \(String(format: "%.2f", elapsed))ms")
        }
        return try await block()
    }

    /// Log an error with standardized context
    /// - Parameters:
    ///   - operation: What operation failed
    ///   - error: The error that occurred
    ///   - context: Additional context about the failure
    func logError(_ operation: String, error: Error, context: String? = nil) {
        var message = "❌ \(operation) failed: \(error.localizedDescription)"
        if let context = context {
            message += " | Context: \(context)"
        }
        self.error(message)
    }

    /// Log a success with count
    /// - Parameters:
    ///   - operation: What operation succeeded
    ///   - count: Number of items processed
    ///   - itemName: Name of the items (singular form, will be pluralized automatically)
    func logSuccess(_ operation: String, count: Int, itemName: String) {
        let plural = count == 1 ? itemName : "\(itemName)s"
        self.info("✅ \(operation): \(count) \(plural)")
    }
}
