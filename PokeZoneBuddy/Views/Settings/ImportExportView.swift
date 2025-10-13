//
//  ImportExportView.swift
//  PokeZoneBuddy
//
//  Created by Danny Hollek on 13.10.2025.
//

import SwiftUI
import UniformTypeIdentifiers

/// View for importing and exporting app data
struct ImportExportView: View {

    // MARK: - Properties

    let viewModel: CitiesViewModel

    // MARK: - State

    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var showImportPreview = false
    @State private var showImportModeSelection = false
    @State private var showImportResult = false

    @State private var exportDocument: JSONDocument?
    @State private var previewCityCount = 0
    @State private var previewSpotCount = 0
    @State private var selectedFileURL: URL?
    @State private var importResult: ImportExportService.ImportResult?
    @State private var importError: Error?

    @State private var isProcessing = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Export Section
            ActionRow(
                title: "Export Data",
                subtitle: "Save all cities and spots to a JSON file",
                buttonText: "Export",
                buttonColor: .blue
            ) {
                handleExport()
            }

            Divider()
                .padding(.leading, 16)

            // Import Section
            ActionRow(
                title: "Import Data",
                subtitle: "Load cities and spots from a JSON file",
                buttonText: "Import",
                buttonColor: .green
            ) {
                showImportPicker = true
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.2))
        )
        .disabled(isProcessing)
        .fileExporter(
            isPresented: $showExportSheet,
            document: exportDocument,
            contentType: .json,
            defaultFilename: viewModel.generateExportFilename()
        ) { result in
            handleExportResult(result)
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Import Preview", isPresented: $showImportPreview) {
            Button("Cancel", role: .cancel) {
                selectedFileURL = nil
            }
            Button("Merge with Existing") {
                importData(mode: .merge)
            }
            Button("Replace All Data", role: .destructive) {
                showImportModeSelection = true
            }
        } message: {
            Text("Found \(previewCityCount) \(previewCityCount == 1 ? "city" : "cities") with \(previewSpotCount) \(previewSpotCount == 1 ? "spot" : "spots").\n\nMerge: Add new cities, skip duplicates.\nReplace: Delete all existing data first.")
        }
        .confirmationDialog(
            "Confirm Replace",
            isPresented: $showImportModeSelection
        ) {
            Button("Replace All Data", role: .destructive) {
                importData(mode: .replace)
            }
            Button("Cancel", role: .cancel) {
                selectedFileURL = nil
            }
        } message: {
            Text("This will permanently delete all your existing cities and spots before importing. This action cannot be undone.")
        }
        .alert("Import Complete", isPresented: $showImportResult) {
            Button("OK") {
                importResult = nil
                selectedFileURL = nil
            }
        } message: {
            if let result = importResult {
                Text(result.summary)
            } else if let error = importError {
                Text("Import failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Export Handling

    private func handleExport() {
        isProcessing = true

        do {
            let data = try viewModel.exportAllData()
            exportDocument = JSONDocument(data: data)
            showExportSheet = true
        } catch {
            AppLogger.viewModel.error("Export failed: \(String(describing: error))")
            // Could add error alert here if needed
        }

        isProcessing = false
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            AppLogger.viewModel.info("Data exported successfully to \(url.path)")
        case .failure(let error):
            AppLogger.viewModel.error("Export failed: \(String(describing: error))")
        }
    }

    // MARK: - Import Handling

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                AppLogger.viewModel.error("Failed to access file: \(url.path)")
                return
            }

            Task {
                do {
                    let (cities, spots) = try await viewModel.previewImport(from: url)
                    await MainActor.run {
                        previewCityCount = cities
                        previewSpotCount = spots
                        selectedFileURL = url
                        showImportPreview = true
                    }
                } catch {
                    url.stopAccessingSecurityScopedResource()
                    await MainActor.run {
                        importError = error
                        showImportResult = true
                    }
                    AppLogger.viewModel.error("Import preview failed: \(String(describing: error))")
                }
            }

        case .failure(let error):
            AppLogger.viewModel.error("File selection failed: \(String(describing: error))")
        }
    }

    private func importData(mode: ImportExportService.ImportMode) {
        guard let url = selectedFileURL else { return }

        isProcessing = true

        Task {
            do {
                let result = try await viewModel.importData(from: url, mode: mode)
                url.stopAccessingSecurityScopedResource()

                await MainActor.run {
                    importResult = result
                    importError = nil
                    showImportResult = true
                    isProcessing = false
                }

                AppLogger.viewModel.info("Import completed: \(result.summary)")
            } catch {
                url.stopAccessingSecurityScopedResource()

                await MainActor.run {
                    importError = error
                    importResult = nil
                    showImportResult = true
                    isProcessing = false
                }

                AppLogger.viewModel.error("Import failed: \(String(describing: error))")
            }
        }
    }
}

// MARK: - JSON Document

/// Wrapper for Data to enable file export
struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Action Row (Reused from SettingsView style)

private struct ActionRow: View {
    let title: String
    let subtitle: String
    let buttonText: String
    let buttonColor: Color
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                action()
            } label: {
                Text(buttonText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isHovering ? buttonColor.opacity(0.9) : buttonColor)
                    )
                    .shadow(
                        color: buttonColor.opacity(isHovering ? 0.3 : 0.2),
                        radius: isHovering ? 6 : 4,
                        x: 0,
                        y: isHovering ? 3 : 2
                    )
                    .scaleEffect(isHovering ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .padding(16)
    }
}
