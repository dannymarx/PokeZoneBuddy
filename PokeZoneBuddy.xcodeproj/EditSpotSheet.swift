import SwiftUI
import SwiftData

struct EditSpotSheet: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties
    let spot: CitySpot
    let viewModel: CitiesViewModel

    // MARK: - State
    @State private var name: String
    @State private var notes: String
    @State private var category: SpotCategory
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    // MARK: - Init
    init(spot: CitySpot, viewModel: CitiesViewModel) {
        self.spot = spot
        self.viewModel = viewModel
        _name = State(initialValue: spot.name)
        _notes = State(initialValue: spot.notes)
        _category = State(initialValue: spot.category)
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                spotDetailsSection
                coordinatesSection
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Spot")
            .toolbar { toolbarContent }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Sections
    @ViewBuilder
    private var spotDetailsSection: some View {
        Section {
            TextField("Name", text: $name, prompt: Text("e.g., Central Park"))
                .accessibilityLabel("Spot name")
                .textFieldStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $notes)
                    .frame(minHeight: 80, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    .accessibilityLabel("Spot notes")
            }

            Picker("Category", selection: $category) {
                ForEach(SpotCategory.allCases, id: \.self) { category in
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                        Text(category.localizedName)
                    }
                    .tag(category)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Spot category")
        } header: {
            Text("Spot Details")
        }
    }

    @ViewBuilder
    private var coordinatesSection: some View {
        Section {
            LabeledContent("Coordinates") {
                Text(spot.formattedCoordinates)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Button {
                copyCoordinates()
            } label: {
                Label("Copy Coordinates", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        } header: {
            Text("Location")
        }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { save() }
        }
    }

    // MARK: - Actions
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.updateSpot(spot, name: trimmedName, notes: notes, category: category)
        if let error = viewModel.errorMessage {
            errorMessage = error
            showError = true
        } else {
            dismiss()
        }
    }

    private func copyCoordinates() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(spot.formattedCoordinates, forType: .string)
        #else
        UIPasteboard.general.string = spot.formattedCoordinates
        #endif
    }
}

// MARK: - Preview
#Preview("Edit Spot Sheet") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FavoriteCity.self,
        CitySpot.self,
        configurations: config
    )

    let context = container.mainContext

    let mockCity = FavoriteCity(
        name: "Tokyo",
        timeZoneIdentifier: "Asia/Tokyo",
        fullName: "Tokyo, Japan"
    )

    let mockSpot = CitySpot(
        name: "Shibuya Crossing",
        notes: "Famous intersection",
        latitude: 35.661852,
        longitude: 139.700514,
        category: .pokestop,
        isFavorite: true,
        city: mockCity
    )

    context.insert(mockCity)
    context.insert(mockSpot)

    let viewModel = CitiesViewModel(modelContext: context)

    return EditSpotSheet(spot: mockSpot, viewModel: viewModel)
        .modelContainer(container)
}
