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
    @ObservedObject var controller: ImportExportController
    let onImportTapped: () -> Void

    // MARK: - State

    @State private var showExportSheet = false
    @State private var exportDocument: JSONDocument?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Export Section
            ActionRow(
                title: "Export Data",
                subtitle: "Save all cities and spots to a JSON file",
                buttonText: "Export",
                buttonColor: .systemBlue
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
                buttonColor: .systemGreen
            ) {
                onImportTapped()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.2))
        )
        .disabled(controller.isProcessing)
        .fileExporter(
            isPresented: $showExportSheet,
            document: exportDocument,
            contentType: .json,
            defaultFilename: viewModel.generateExportFilename()
        ) { result in
            handleExportResult(result)
        }
        .alert(
            String(localized: "import.preview.title"),
            isPresented: Binding(
                get: { controller.showImportPreview },
                set: { controller.showImportPreview = $0 }
            )
        ) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                controller.cancelImportPreview()
            }
            Button(String(localized: "import.merge_with_existing")) {
                controller.importData(mode: .merge)
            }
            Button(String(localized: "import.replace_all_data"), role: .destructive) {
                controller.showImportModeSelection = true
            }
        } message: {
            Text(String(localized: "import.preview.message"))
        }
        .confirmationDialog(
            String(localized: "import.confirm_replace"),
            isPresented: Binding(
                get: { controller.showImportModeSelection },
                set: { controller.showImportModeSelection = $0 }
            )
        ) {
            Button(String(localized: "import.replace_all_data"), role: .destructive) {
                controller.importData(mode: .replace)
            }
            Button(String(localized: "common.cancel"), role: .cancel) {
                controller.cancelImportPreview()
            }
        } message: {
            Text(String(localized: "import.replace_warning.message"))
        }
        .alert(
            String(localized: "import.complete.title"),
            isPresented: Binding(
                get: { controller.showImportResult },
                set: { controller.showImportResult = $0 }
            )
        ) {
            Button(String(localized: "common.ok")) {
                controller.dismissResult()
            }
        } message: {
            if let result = controller.importResult {
                Text(result.summary)
            } else if controller.importError != nil {
                Text(String(localized: "import.failed.message"))
            }
        }
    }

    // MARK: - Export Handling

    private func handleExport() {
        controller.isProcessing = true

        do {
            let data = try viewModel.exportAllData()
            exportDocument = JSONDocument(data: data)
            showExportSheet = true
        } catch {
            AppLogger.viewModel.error("Export failed: \(String(describing: error))")
            // Could add error alert here if needed
        }

        controller.isProcessing = false
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            AppLogger.viewModel.info("Data exported successfully to \(url.path)")
        case .failure(let error):
            AppLogger.viewModel.error("Export failed: \(String(describing: error))")
        }
    }
}

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

// MARK: - Controller

final class ImportExportController: ObservableObject {
    @Published var isProcessing = false
    @Published var showImportPreview = false
    @Published var showImportModeSelection = false
    @Published var showImportResult = false
    @Published var previewCityCount = 0
    @Published var previewSpotCount = 0
    @Published var importResult: ImportExportService.ImportResult?
    @Published var importError: Error?

    private let viewModel: CitiesViewModel
    private var selectedFileURL: URL?
    private var selectedFileHasSecurityScope = false

    init(viewModel: CitiesViewModel) {
        self.viewModel = viewModel
    }

    func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            releaseSelectedFileAccess()
            guard let url = urls.first else { return }

            let hasSecurityScope = url.startAccessingSecurityScopedResource()
            if !hasSecurityScope {
                AppLogger.viewModel.warn("Proceeding without security-scoped access for \(url.path)")
            }

            Task {
                do {
                    let (cities, spots) = try await viewModel.previewImport(from: url)
                    await MainActor.run {
                        previewCityCount = cities
                        previewSpotCount = spots
                        selectedFileURL = url
                        selectedFileHasSecurityScope = hasSecurityScope
                        importError = nil
                        showImportPreview = true
                    }
                } catch {
                    if hasSecurityScope {
                        url.stopAccessingSecurityScopedResource()
                    }

                    await MainActor.run {
                        selectedFileHasSecurityScope = false
                        selectedFileURL = nil
                        importError = error
                        showImportResult = true
                    }

                    AppLogger.viewModel.error("Import preview failed: \(String(describing: error))")
                }
            }

        case .failure(let error):
            releaseSelectedFileAccess()
            AppLogger.viewModel.error("File selection failed: \(String(describing: error))")
        }
    }

    func importData(mode: ImportExportService.ImportMode) {
        guard let url = selectedFileURL else { return }
        let hasSecurityScope = selectedFileHasSecurityScope

        isProcessing = true

        Task {
            do {
                let result = try await viewModel.importData(from: url, mode: mode)

                if hasSecurityScope {
                    url.stopAccessingSecurityScopedResource()
                }

                await MainActor.run {
                    importResult = result
                    importError = nil
                    showImportResult = true
                    showImportPreview = false
                    showImportModeSelection = false
                    isProcessing = false
                    selectedFileHasSecurityScope = false
                    selectedFileURL = nil
                }

                AppLogger.viewModel.info("Import completed: \(result.summary)")
            } catch {
                if hasSecurityScope {
                    url.stopAccessingSecurityScopedResource()
                }

                await MainActor.run {
                    importError = error
                    importResult = nil
                    showImportResult = true
                    showImportPreview = false
                    showImportModeSelection = false
                    isProcessing = false
                    selectedFileHasSecurityScope = false
                    selectedFileURL = nil
                }

                AppLogger.viewModel.error("Import failed: \(String(describing: error))")
            }
        }
    }

    func cancelImportPreview() {
        releaseSelectedFileAccess()
        showImportPreview = false
        showImportModeSelection = false
    }

    func dismissResult() {
        showImportResult = false
        importResult = nil
        importError = nil
        releaseSelectedFileAccess()
    }

    private func releaseSelectedFileAccess() {
        if selectedFileHasSecurityScope, let url = selectedFileURL {
            url.stopAccessingSecurityScopedResource()
        }

        selectedFileHasSecurityScope = false
        selectedFileURL = nil
    }
}

// MARK: - Container

struct ImportExportContainer: View {
    let viewModel: CitiesViewModel

    @StateObject private var controller: ImportExportController
    @State private var showImportPicker = false

    init(viewModel: CitiesViewModel) {
        self.viewModel = viewModel
        _controller = StateObject(wrappedValue: ImportExportController(viewModel: viewModel))
    }

    var body: some View {
        ImportExportView(
            viewModel: viewModel,
            controller: controller,
            onImportTapped: { showImportPicker = true }
        )
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            controller.handleFileSelection(result)
        }
    }
}
