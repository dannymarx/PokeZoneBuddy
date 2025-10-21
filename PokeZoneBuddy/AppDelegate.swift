//
//  AppDelegate.swift
//  PokeZoneBuddy
//
//  Handles window configuration for macOS
//

#if os(macOS)
import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var configuredWindows = Set<String>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure all windows immediately
        configureWindows()

        // Observe window creation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        configureWindows()
    }

    private func configureWindows() {
        for window in NSApplication.shared.windows {
            let windowID = "\(ObjectIdentifier(window).hashValue)"
            // Only configure each window once
            if !configuredWindows.contains(windowID) {
                // Delay configuration to let SwiftUI finish initial layout
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.configureWindow(window)
                }
                configuredWindows.insert(windowID)
            }
        }
    }

    private func configureWindow(_ window: NSWindow) {
        // Only adjust primary SwiftUI application windows
        guard window.className.contains("SwiftUI") else { return }

        // Sheets/modal panels should keep the default macOS behaviour
        if window.sheetParent != nil || window is NSPanel || window.level != .normal {
            return
        }

        #if DEBUG
        AppLogger.app.debug("Configuring window: \(window.title)")
        #endif

        // Set full resizability with complete style mask
        window.styleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
            .fullSizeContentView
        ]

        // Store the current frame so we can restore it
        let currentFrame = window.frame

        // Set minimal constraints - just enough for macOS window chrome
        // but small enough to allow effectively free resizing
        window.minSize = NSSize(width: 1, height: 1)
        window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        // Remove content size constraints completely
        window.contentMinSize = NSSize(width: 1, height: 1)
        window.contentMaxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        // Restore the frame
        window.setFrame(currentFrame, display: true)

        // Ensure window can be resized and moved freely
        window.isMovable = true
        window.isMovableByWindowBackground = false

        // Disable any automatic positioning that might stick to top
        window.setFrameAutosaveName("")

        // Allow window to be positioned anywhere
        window.collectionBehavior = [.fullScreenPrimary, .managed]

        #if DEBUG
        AppLogger.app.debug("Window configured with resizability enabled")
        #endif
    }
}
#endif
