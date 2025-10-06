import Foundation
import os

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "App"

    static let app = Logger(subsystem: subsystem, category: "App")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let background = Logger(subsystem: subsystem, category: "Background")
    static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")
    static let calendar = Logger(subsystem: subsystem, category: "Calendar")
    static let cache = Logger(subsystem: subsystem, category: "Cache")
}

extension Logger {
    func debug(_ message: String) { self.debug("\(message, privacy: .public)") }
    func info(_ message: String) { self.info("\(message, privacy: .public)") }
    func warn(_ message: String) { self.warning("\(message, privacy: .public)") }
    func error(_ message: String) { self.error("\(message, privacy: .public)") }
}
