import SwiftUI
import SwiftData

struct DataPortabilityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: PortabilityTab = .export
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingBackupSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Data Portability")
                    .font(.title2.bold())
                Text("Your data, your control. Export, import, or backup your tasks anytime.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.windowBackgroundColor))

            Divider()

            // Tab Selection
            HStack(spacing: 12) {
                ForEach(PortabilityTab.allCases) { tab in
                    TabButton(
                        title: tab.title,
                        icon: tab.icon,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))

            Divider()

            // Content
            ScrollView {
                Group {
                    switch selectedTab {
                    case .export:
                        ExportTabView(showingSheet: $showingExportSheet)
                    case .import_:
                        ImportTabView(showingSheet: $showingImportSheet)
                    case .backup:
                        BackupTabView(showingSheet: $showingBackupSheet)
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
        .sheet(isPresented: $showingExportSheet) {
            ExportSheetView()
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportSheetView()
        }
        .sheet(isPresented: $showingBackupSheet) {
            BackupSheetView()
        }
    }
}

// MARK: - Portability Tab

enum PortabilityTab: String, CaseIterable, Identifiable {
    case export
    case import_
    case backup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .export: return "Export"
        case .import_: return "Import"
        case .backup: return "Backup"
        }
    }

    var icon: String {
        switch self {
        case .export: return "square.and.arrow.up"
        case .import_: return "square.and.arrow.down"
        case .backup: return "externaldrive"
        }
    }
}

// MARK: - Export Tab

struct ExportTabView: View {
    @Binding var showingSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Your Data")
                .font(.headline)

            Text("Download your tasks in multiple formats for backup, migration, or analysis.")
                .font(.callout)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                FormatCard(
                    icon: "shippingbox",
                    title: "Universal Task Format",
                    description: "Complete export in Time Capsule's open format. Best for backup and migration.",
                    color: .blue
                )

                FormatCard(
                    icon: "curlybraces",
                    title: "JSON",
                    description: "Standard JSON format. Good for developers and data analysis.",
                    color: .purple
                )

                FormatCard(
                    icon: "tablecells",
                    title: "CSV",
                    description: "Spreadsheet-compatible format. Open in Excel, Numbers, or Google Sheets.",
                    color: .green
                )

                FormatCard(
                    icon: "doc.text",
                    title: "Markdown",
                    description: "Human-readable format. Great for documentation or printing.",
                    color: .orange
                )
            }

            Spacer()

            HStack {
                Spacer()
                Button {
                    showingSheet = true
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

// MARK: - Import Tab

struct ImportTabView: View {
    @Binding var showingSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import Data")
                .font(.headline)

            Text("Bring your tasks from other apps or restore from a previous export.")
                .font(.callout)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                SourceCard(
                    icon: "shippingbox",
                    title: "Time Capsule Export",
                    description: "Import from a previous Time Capsule export file.",
                    color: .blue
                )

                SourceCard(
                    icon: "checkmark.circle",
                    title: "Todoist",
                    description: "Migrate from Todoist. Export your data from Todoist settings.",
                    color: .red
                )

                SourceCard(
                    icon: "star.circle",
                    title: "Things 3",
                    description: "Import tasks from Things 3 JSON export.",
                    color: .indigo
                )

                SourceCard(
                    icon: "curlybraces",
                    title: "JSON / CSV",
                    description: "Import from generic JSON or CSV files.",
                    color: .gray
                )
            }

            Spacer()

            HStack {
                Spacer()
                Button {
                    showingSheet = true
                } label: {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

// MARK: - Backup Tab

struct BackupTabView: View {
    @Binding var showingSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Backups")
                .font(.headline)

            Text("Create encrypted backups of all your data for safekeeping.")
                .font(.callout)
                .foregroundStyle(.secondary)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Automatic Protection", systemImage: "shield.checkered")
                        .font(.subheadline.bold())

                    Text("Backups include all tasks, settings, and metadata. Optionally encrypt with a password for maximum security.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Recent Backups", systemImage: "clock")
                    .font(.subheadline.bold())

                Text("No backups yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Spacer()

            HStack {
                Spacer()
                Button {
                    showingSheet = true
                } label: {
                    Label("Create Backup", systemImage: "externaldrive.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

// MARK: - Helper Views

struct FormatCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct SourceCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Sheet Placeholders

struct ExportSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedFormat: ExportFormat = .universalTaskFormat
    @State private var exportOptions = ExportOptions.complete
    @State private var isExporting = false
    @State private var exportError: Error?

    var body: some View {
        VStack(spacing: 20) {
            Text("Export Data")
                .font(.title2.bold())

            Picker("Format", selection: $selectedFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Label(format.rawValue, systemImage: format.icon)
                        .tag(format)
                }
            }
            .pickerStyle(.segmented)

            GroupBox("Options") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Include completed tasks", isOn: $exportOptions.includeCompleted)
                    Toggle("Include archived tasks", isOn: $exportOptions.includeArchived)
                    Toggle("Include settings", isOn: $exportOptions.includeSettings)
                }
                .padding(.vertical, 8)
            }

            if let error = exportError {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Export") {
                    Task { await performExport() }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isExporting)
            }
        }
        .padding()
        .frame(width: 450)
    }

    @MainActor
    private func performExport() async {
        isExporting = true
        defer { isExporting = false }

        do {
            let coordinator = ExportCoordinator(modelContext: modelContext)
            let result = try await coordinator.export(
                format: selectedFormat,
                options: exportOptions,
                destination: nil
            )
            dismiss()
        } catch {
            exportError = error
        }
    }
}

struct ImportSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedSource: ImportSource = .universalTaskFormat
    @State private var selectedFileURL: URL?
    @State private var isImporting = false
    @State private var importResult: ImportResult?
    @State private var importError: Error?
    @State private var showingFilePicker = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Import Data")
                .font(.title2.bold())

            // Source Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Import From")
                    .font(.headline)

                Picker("Source", selection: $selectedSource) {
                    ForEach(ImportSource.allCases) { source in
                        Label(source.rawValue, systemImage: source.icon)
                            .tag(source)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
            }

            // File Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("File")
                    .font(.headline)

                HStack {
                    if let url = selectedFileURL {
                        Text(url.lastPathComponent)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("No file selected")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Choose File...") {
                        showFilePicker()
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Instructions
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedSource.exportInstructions)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Result
            if let result = importResult {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Import Complete", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)

                        Text("Imported: \(result.importedCount) tasks")
                            .font(.caption)

                        if result.skippedCount > 0 {
                            Text("Skipped: \(result.skippedCount) tasks")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if let error = importError {
                GroupBox {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Import") {
                    Task { await performImport() }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selectedFileURL == nil || isImporting)
            }
        }
        .padding()
        .frame(width: 500, height: 500)
    }

    @MainActor
    private func showFilePicker() {
        let panel = NSOpenPanel()
        panel.title = "Select File to Import"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json, .commaSeparatedText]

        if panel.runModal() == .OK {
            selectedFileURL = panel.url
            importResult = nil
            importError = nil
        }
    }

    @MainActor
    private func performImport() async {
        guard let fileURL = selectedFileURL else { return }

        isImporting = true
        importError = nil
        defer { isImporting = false }

        do {
            let coordinator = ImportCoordinator(modelContext: modelContext)
            let result = try await coordinator.importData(
                from: fileURL,
                source: selectedSource,
                options: ImportOptions()
            )
            importResult = result
        } catch {
            importError = error
        }
    }
}

struct BackupSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var backupName = ""
    @State private var useEncryption = false
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isCreatingBackup = false
    @State private var backupResult: Backup?
    @State private var backupError: Error?

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Backup")
                .font(.title2.bold())

            // Backup Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Backup Name")
                    .font(.headline)

                TextField("Optional - auto-generated if empty", text: $backupName)
                    .textFieldStyle(.roundedBorder)
            }

            // Encryption Options
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Encrypt Backup", isOn: $useEncryption)
                    .font(.headline)

                if useEncryption {
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)

                        if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                            Label("Passwords do not match", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Text("Recommended: Use a strong password you'll remember. This cannot be recovered if lost.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Info
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("What's Included", systemImage: "info.circle")
                        .font(.subheadline.bold())

                    Text("• All active tasks\n• All completed tasks\n• All archived tasks\n• App settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Result
            if let backup = backupResult {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Backup Created", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)

                        Text("Name: \(backup.name)")
                            .font(.caption)

                        Text("Size: \(backup.fileSizeFormatted)")
                            .font(.caption)

                        Text("Tasks: \(backup.taskCount)")
                            .font(.caption)

                        if backup.isEncrypted {
                            Label("Encrypted", systemImage: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if let error = backupError {
                GroupBox {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(backupResult != nil ? "Done" : "Create Backup") {
                    if backupResult != nil {
                        dismiss()
                    } else {
                        Task { await createBackup() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isCreatingBackup || (useEncryption && passwordsInvalid))
            }
        }
        .padding()
        .frame(width: 500, height: 550)
    }

    private var passwordsInvalid: Bool {
        password.isEmpty || confirmPassword.isEmpty || password != confirmPassword
    }

    @MainActor
    private func createBackup() async {
        isCreatingBackup = true
        backupError = nil
        defer { isCreatingBackup = false }

        do {
            let exportCoordinator = ExportCoordinator(modelContext: modelContext)
            let backupManager = BackupManager(
                modelContext: modelContext,
                exportCoordinator: exportCoordinator
            )

            let backup = try await backupManager.createBackup(
                name: backupName.isEmpty ? nil : backupName,
                encrypt: useEncryption,
                password: useEncryption ? password : nil
            )

            backupResult = backup

            // Clear sensitive data
            password = ""
            confirmPassword = ""
        } catch {
            backupError = error
        }
    }
}

#Preview {
    DataPortabilityView()
        .modelContainer(PreviewContainer.preview)
}
