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
                configuredWindows.insert(windowID)
                // Delay configuration to let SwiftUI finish initial layout
                // Use longer delay to ensure all layout passes are complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.configureWindow(window)
                }
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

        // Don't configure if window is currently in a layout pass
        guard !window.inLiveResize else { return }

        print("🪟 Configuring window: \(window.title)")
        print("📏 Before - minSize: \(window.minSize), maxSize: \(window.maxSize)")
        print("🎨 Before - styleMask: \(window.styleMask.rawValue)")
        print("📍 Before - frame: \(window.frame)")
        print("🔒 Before - contentLayoutRect: \(window.contentLayoutRect)")

        // Store the current frame so we can restore it
        let currentFrame = window.frame

        // Batch all configuration to minimize layout passes
        // Use disableScreenUpdatesUntilFlush to prevent intermediate redraws
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        window.disableScreenUpdatesUntilFlush()

        // Set full resizability with complete style mask
        window.styleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
            .fullSizeContentView
        ]

        // Set minimal constraints - just enough for macOS window chrome
        // but small enough to allow effectively free resizing
        window.minSize = NSSize(width: 1, height: 1)
        window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        // Remove content size constraints completely
        window.contentMinSize = NSSize(width: 1, height: 1)
        window.contentMaxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        // Ensure window can be resized and moved freely
        window.isMovable = true
        window.isMovableByWindowBackground = false

        // Disable any automatic positioning that might stick to top
        window.setFrameAutosaveName("")

        // Allow window to be positioned anywhere
        window.collectionBehavior = [.fullScreenPrimary, .managed]

        NSAnimationContext.endGrouping()

        // Restore the frame AFTER all other configuration is complete
        // This minimizes the chance of triggering layout during the frame change
        DispatchQueue.main.async {
            window.setFrame(currentFrame, display: true, animate: false)
        }

        print("✅ After - minSize: \(window.minSize), maxSize: \(window.maxSize)")
        print("✅ After - contentMinSize: \(window.contentMinSize), contentMaxSize: \(window.contentMaxSize)")
        print("✅ After - styleMask: \(window.styleMask.rawValue)")
        print("✅ Window is resizable: \(window.styleMask.contains(.resizable))")
        print("📍 After - frame: \(window.frame)")
    }
}
#endif
