//
//  ShareSheet.swift
//  PokeZoneBuddy
//
//  Created by Claude Code on 2025-10-20.
//  Version 1.6.0 - Share Sheet Utilities
//

import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - Share Item

/// Items that can be shared via the share sheet
enum ShareableItem {
    case file(URL, filename: String? = nil)
    case text(String)
    #if os(macOS)
    case image(NSImage, filename: String? = nil)
    #else
    case image(UIImage, filename: String? = nil)
    #endif
}

// MARK: - Share Sheet View

/// Cross-platform share sheet view
struct ShareSheet: View {
    let items: [ShareableItem]
    @Environment(\.dismiss) private var dismiss

    init(item: ShareableItem) {
        self.items = [item]
    }

    init(items: [ShareableItem]) {
        self.items = items
    }

    var body: some View {
#if os(iOS)
        iOSShareSheet(items: items)
            .ignoresSafeArea()
#else
        macOSShareView(items: items)
            .frame(minWidth: 400, minHeight: 200)
#endif
    }
}

// MARK: - iOS Implementation

#if os(iOS)
private struct iOSShareSheet: UIViewControllerRepresentable {
    let items: [ShareableItem]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityItems: [Any] = items.compactMap { item in
            switch item {
            case .file(let url, _):
                return url
            case .text(let text):
                return text
            case .image(let image, _):
                return image
            }
        }

        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // Set completion handler to dismiss
        controller.completionWithItemsHandler = { _, _, _, _ in
            dismiss()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - macOS Implementation

#if os(macOS)
private struct macOSShareView: View {
    let items: [ShareableItem]
    @Environment(\.dismiss) private var dismiss

    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.systemBlue)

                Text(String(localized: "share.title"))
                    .font(.system(size: 20, weight: .semibold))
            }

            Divider()

            // Share options
            VStack(spacing: 12) {
                Button {
                    saveToFile()
                } label: {
                    HStack {
                        Image(systemName: "folder")
                        Text(String(localized: "share.save_to_file"))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.systemBlue.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.systemBlue, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if sharingServicesAvailable {
                    Button {
                        shareViaServices()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text(String(localized: "share.share_via"))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            Spacer()

            // Cancel button
            Button(String(localized: "common.cancel")) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(24)
        .alert(
            String(localized: "common.error"),
            isPresented: .constant(errorMessage != nil),
            presenting: errorMessage
        ) { _ in
            Button(String(localized: "common.ok")) {
                errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }

    private var sharingServicesAvailable: Bool {
        // Check if we have items that can be shared via NSSharingService
        !items.isEmpty
    }

    private func saveToFile() {
        guard let firstItem = items.first else { return }

        let panel = NSSavePanel()

        // Configure panel based on item type
        switch firstItem {
        case .file(let url, let filename):
            panel.nameFieldStringValue = filename ?? url.lastPathComponent
            // Try to get content type from file extension
            if let contentType = UTType(filenameExtension: url.pathExtension) {
                panel.allowedContentTypes = [contentType]
            }

        case .text:
            panel.nameFieldStringValue = "export.txt"
            panel.allowedContentTypes = [.plainText]

        case .image(_, let filename):
            panel.nameFieldStringValue = filename ?? "image.png"
            panel.allowedContentTypes = [.png]
        }

        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        panel.begin { response in
            guard response == .OK, let saveURL = panel.url else { return }

            do {
                try saveItem(firstItem, to: saveURL)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func saveItem(_ item: ShareableItem, to url: URL) throws {
        switch item {
        case .file(let sourceURL, _):
            // Copy file to destination
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            try FileManager.default.copyItem(at: sourceURL, to: url)

        case .text(let text):
            // Write text to file
            try text.write(to: url, atomically: true, encoding: .utf8)

        case .image(let image, _):
            // Save image as PNG
            if let tiffData = image.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                try pngData.write(to: url)
            } else {
                throw ShareError.imageConversionFailed
            }
        }
    }

    private func shareViaServices() {
        guard let firstItem = items.first else { return }

        let sharingItems: [Any] = switch firstItem {
        case .file(let url, _):
            [url]
        case .text(let text):
            [text]
        case .image(let image, _):
            [image]
        }

        let picker = NSSharingServicePicker(items: sharingItems)

        // Get the current window to show the picker
        if let window = NSApp.keyWindow,
           let contentView = window.contentView {
            picker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        }

        dismiss()
    }
}
#endif

// MARK: - Share Error

enum ShareError: LocalizedError {
    case imageConversionFailed
    case fileNotFound
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return String(localized: "share.error.image_conversion")
        case .fileNotFound:
            return String(localized: "share.error.file_not_found")
        case .saveFailed:
            return String(localized: "share.error.save_failed")
        }
    }
}

// MARK: - File Helper

extension ShareableItem {
    /// Helper to create a temporary file from data
    static func temporaryFile(
        data: Data,
        filename: String,
        contentType: UTType = .json
    ) throws -> ShareableItem {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        // Write data to temp file
        try data.write(to: fileURL)

        return .file(fileURL, filename: filename)
    }

    /// Helper to get suggested filename
    var suggestedFilename: String? {
        switch self {
        case .file(_, let filename):
            return filename
        case .image(_, let filename):
            return filename
        case .text:
            return nil
        }
    }
}

// MARK: - Preview

#Preview("File Share") {
    ShareSheet(item: .text("Hello World"))
}
