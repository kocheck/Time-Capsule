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
                    case .diagnostics:
                        DiagnosticsTabView()
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
    case diagnostics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .export: return "Export"
        case .import_: return "Import"
        case .backup: return "Backup"
        case .diagnostics: return "Diagnostics"
        }
    }

    var icon: String {
        switch self {
        case .export: return "square.and.arrow.up"
        case .import_: return "square.and.arrow.down"
        case .backup: return "externaldrive"
        case .diagnostics: return "chart.bar.doc.horizontal"
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
    @Environment(\.modelContext) private var modelContext
    @Binding var showingSheet: Bool
    @State private var viewModel: BackupViewModel?
    @State private var showingRestoreSheet = false
    @State private var selectedBackup: Backup?
    @State private var showingDeleteConfirmation = false
    @State private var backupToDelete: Backup?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Backups")
                    .font(.headline)

                Spacer()

                if let viewModel = viewModel, viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Button {
                    Task { await viewModel?.loadBackups() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }

            Text("Create encrypted backups of all your data for safekeeping.")
                .font(.callout)
                .foregroundStyle(.secondary)

            // Backup List
            if let viewModel = viewModel, !viewModel.backups.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.backups) { backup in
                            BackupRow(
                                backup: backup,
                                onRestore: {
                                    selectedBackup = backup
                                    showingRestoreSheet = true
                                },
                                onDelete: {
                                    backupToDelete = backup
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "externaldrive.badge.xmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("No backups yet")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Text("Create your first backup to protect your data")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
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
        .task {
            if viewModel == nil {
                viewModel = BackupViewModel(modelContext: modelContext)
                await viewModel?.loadBackups()
            }
        }
        .sheet(isPresented: $showingRestoreSheet) {
            if let backup = selectedBackup {
                RestoreBackupSheet(backup: backup, onComplete: {
                    Task { await viewModel?.loadBackups() }
                })
            }
        }
        .alert("Delete Backup?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let backup = backupToDelete {
                    Task {
                        try? await viewModel?.deleteBackup(backup)
                    }
                }
            }
        } message: {
            if let backup = backupToDelete {
                Text("Are you sure you want to delete '\(backup.name)'? This cannot be undone.")
            }
        }
    }
}

// MARK: - Backup Row

struct BackupRow: View {
    let backup: Backup
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        GroupBox {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: backup.isEncrypted ? "lock.shield.fill" : "externaldrive.fill")
                    .font(.title2)
                    .foregroundStyle(backup.isEncrypted ? .blue : .secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text(backup.name)
                        .font(.subheadline.bold())

                    HStack(spacing: 8) {
                        Label(backup.ageFormatted, systemImage: "clock")
                        Label(backup.fileSizeFormatted, systemImage: "doc")
                        Label("\(backup.taskCount) tasks", systemImage: "checklist")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if backup.isEncrypted {
                        Label("Encrypted", systemImage: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    Button {
                        onRestore()
                    } label: {
                        Label("Restore", systemImage: "arrow.down.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Restore Backup Sheet

struct RestoreBackupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let backup: Backup
    let onComplete: () -> Void

    @State private var password = ""
    @State private var clearExistingData = false
    @State private var restoreSettings = false
    @State private var isRestoring = false
    @State private var restoreError: Error?
    @State private var restoreResult: RestoreResult?

    var body: some View {
        VStack(spacing: 20) {
            Text("Restore Backup")
                .font(.title2.bold())

            // Backup Info
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "Backup", value: backup.name)
                    InfoRow(label: "Created", value: backup.ageFormatted)
                    InfoRow(label: "Size", value: backup.fileSizeFormatted)
                    InfoRow(label: "Tasks", value: "\(backup.taskCount)")
                }
                .padding(.vertical, 4)
            }

            // Password (if encrypted)
            if backup.isEncrypted {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)

                    SecureField("Enter backup password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    Text("This backup is encrypted. Enter the password you used when creating it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Restore Options
            GroupBox("Restore Options") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Clear existing data first", isOn: $clearExistingData)
                    Toggle("Restore settings", isOn: $restoreSettings)
                }
                .padding(.vertical, 8)
            }

            // Warning
            if clearExistingData {
                GroupBox {
                    Label("Warning: All existing data will be deleted before restoring", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            // Result
            if let result = restoreResult {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Restore Complete", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)

                        Text("Restored: \(result.tasksRestored) tasks")
                            .font(.caption)

                        if result.tasksFailed > 0 {
                            Text("Failed: \(result.tasksFailed) tasks")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if let error = restoreError {
                GroupBox {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(restoreResult != nil ? "Done" : "Restore") {
                    if restoreResult != nil {
                        onComplete()
                        dismiss()
                    } else {
                        Task { await performRestore() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isRestoring || (backup.isEncrypted && password.isEmpty))
            }
        }
        .padding()
        .frame(width: 500, height: 550)
    }

    @MainActor
    private func performRestore() async {
        isRestoring = true
        restoreError = nil
        defer { isRestoring = false }

        do {
            let exportCoordinator = ExportCoordinator(modelContext: modelContext)
            let backupManager = BackupManager(
                modelContext: modelContext,
                exportCoordinator: exportCoordinator
            )

            let options = RestoreOptions(
                clearExistingData: clearExistingData,
                restoreSettings: restoreSettings
            )

            let result = try await backupManager.restoreBackup(
                backup,
                password: backup.isEncrypted ? password : nil,
                options: options
            )

            restoreResult = result
            password = "" // Clear password
        } catch {
            restoreError = error
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
    @State private var exportPreview: ExportPreview?
    @State private var isLoadingPreview = false

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
                        .onChange(of: exportOptions.includeCompleted) { _, _ in
                            Task { await loadPreview() }
                        }
                    Toggle("Include archived tasks", isOn: $exportOptions.includeArchived)
                        .onChange(of: exportOptions.includeArchived) { _, _ in
                            Task { await loadPreview() }
                        }
                    Toggle("Include settings", isOn: $exportOptions.includeSettings)
                        .onChange(of: exportOptions.includeSettings) { _, _ in
                            Task { await loadPreview() }
                        }
                }
                .padding(.vertical, 8)
            }

            // Preview Section
            if isLoadingPreview {
                ProgressView("Loading preview...")
                    .padding()
            } else if let preview = exportPreview {
                ExportPreviewCard(preview: preview)
            }

            if let error = exportError {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Spacer()

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
        .frame(width: 500, height: 600)
        .task {
            await loadPreview()
        }
    }

    @MainActor
    private func loadPreview() async {
        isLoadingPreview = true
        defer { isLoadingPreview = false }

        do {
            let coordinator = ExportCoordinator(modelContext: modelContext)
            exportPreview = try await coordinator.generatePreview(options: exportOptions)
        } catch {
            // Preview is optional, don't show error
        }
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

// MARK: - Export Preview Card

struct ExportPreviewCard: View {
    let preview: ExportPreview

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Preview", systemImage: "eye")
                    .font(.subheadline.bold())

                HStack {
                    StatView(label: "Active", value: "\(preview.activeCount)")
                    StatView(label: "Completed", value: "\(preview.completedCount)")
                    StatView(label: "Archived", value: "\(preview.archivedCount)")
                    StatView(label: "Total", value: "\(preview.totalCount)")
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    InfoRow(label: "Date Range", value: preview.dateRangeFormatted)
                    InfoRow(label: "Estimated Size", value: preview.estimatedSizeFormatted)
                    InfoRow(label: "Tags", value: preview.tagSummary)
                }

                if !preview.sampleTasks.isEmpty {
                    Divider()
                    Text("Sample Tasks")
                        .font(.caption.bold())

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(preview.sampleTasks.prefix(3)) { task in
                            HStack {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.caption)
                                    .foregroundStyle(task.isCompleted ? .green : .secondary)

                                Text(task.title)
                                    .font(.caption)
                                    .lineLimit(1)

                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct StatView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .lineLimit(1)
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
    @State private var importPreview: ImportPreview?
    @State private var isLoadingPreview = false
    @State private var conflictResolutions: [UUID: ConflictResolution] = [:]

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

            // Preview Loading
            if isLoadingPreview {
                ProgressView("Analyzing file...")
                    .padding()
            }

            // Conflict Resolution
            if let preview = importPreview, preview.hasConflicts {
                ConflictResolutionView(
                    conflicts: preview.potentialConflicts,
                    resolutions: $conflictResolutions
                )
            }

            // Preview Summary
            if let preview = importPreview, !preview.hasConflicts {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Ready to Import", systemImage: "checkmark.circle")
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)

                        Text("\(preview.taskCount) tasks found")
                            .font(.caption)

                        if !preview.tags.isEmpty {
                            Text("Tags: \(preview.tags.sorted().prefix(5).joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Instructions (only if no file selected)
            if selectedFileURL == nil {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedSource.exportInstructions)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
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

                Button(importResult != nil ? "Done" : "Import") {
                    if importResult != nil {
                        dismiss()
                    } else {
                        Task { await performImport() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selectedFileURL == nil || isImporting || (importPreview?.hasConflicts == true && !allConflictsResolved))
            }
        }
        .padding()
        .frame(width: 600, height: 650)
    }

    private var allConflictsResolved: Bool {
        guard let preview = importPreview else { return true }
        return preview.potentialConflicts.allSatisfy { conflict in
            conflictResolutions[conflict.id] != nil
        }
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
            Task { await loadPreview() }
        }
    }

    @MainActor
    private func loadPreview() async {
        guard let fileURL = selectedFileURL else { return }

        isLoadingPreview = true
        defer { isLoadingPreview = false }

        do {
            let coordinator = ImportCoordinator(modelContext: modelContext)
            importPreview = try await coordinator.generatePreview(from: fileURL, source: selectedSource)
            conflictResolutions.removeAll()
        } catch {
            importError = error
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
            var options = ImportOptions()
            options.conflictResolutions = conflictResolutions

            let result = try await coordinator.importData(
                from: fileURL,
                source: selectedSource,
                options: options
            )
            importResult = result
        } catch {
            importError = error
        }
    }
}

// MARK: - Conflict Resolution

struct ConflictResolutionView: View {
    let conflicts: [ImportConflict]
    @Binding var resolutions: [UUID: ConflictResolution]

    @State private var applyToAll: ConflictResolution?
    @State private var showingApplyToAll = false

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("\(conflicts.count) Conflicts Found", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)

                    Spacer()

                    Button("Apply to All...") {
                        showingApplyToAll = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Divider()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(conflicts) { conflict in
                            ConflictRow(
                                conflict: conflict,
                                resolution: Binding(
                                    get: { resolutions[conflict.id] },
                                    set: { resolutions[conflict.id] = $0 }
                                )
                            )
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
            .padding(.vertical, 4)
        }
        .alert("Apply to All Conflicts", isPresented: $showingApplyToAll) {
            Button("Keep All Existing") {
                applyResolutionToAll(.keepExisting)
            }
            Button("Use All Imported") {
                applyResolutionToAll(.useImported)
            }
            Button("Skip All") {
                applyResolutionToAll(.skip)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how to resolve all \(conflicts.count) conflicts at once.")
        }
    }

    private func applyResolutionToAll(_ resolution: ConflictResolution) {
        for conflict in conflicts {
            resolutions[conflict.id] = resolution
        }
    }
}

struct ConflictRow: View {
    let conflict: ImportConflict
    @Binding var resolution: ConflictResolution?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Conflict Type
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                Text(conflict.description)
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            // Side-by-side comparison
            HStack(spacing: 12) {
                // Existing Task
                VStack(alignment: .leading, spacing: 4) {
                    Text("Existing")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)

                    Text(conflict.existingTask.title)
                        .font(.caption)
                        .lineLimit(2)

                    if !conflict.existingTask.tags.isEmpty {
                        Text(conflict.existingTask.tags.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)

                // Arrow
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Imported Task
                VStack(alignment: .leading, spacing: 4) {
                    Text("Imported")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)

                    Text(conflict.importedTask.title)
                        .font(.caption)
                        .lineLimit(2)

                    if !conflict.importedTask.tags.isEmpty {
                        Text(conflict.importedTask.tags.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
            }

            // Resolution Picker
            Picker("Resolution", selection: $resolution) {
                Text("Choose action...").tag(nil as ConflictResolution?)
                ForEach([ConflictResolution.keepExisting, .useImported, .skip], id: \.self) { res in
                    Text(res.rawValue).tag(res as ConflictResolution?)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
        }
        .padding(8)
        .background(resolution != nil ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(resolution != nil ? Color.green : Color.orange.opacity(0.3), lineWidth: 1)
        )
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

// MARK: - Diagnostics Tab

struct DiagnosticsTabView: View {
    @State private var diagnosticReport: DiagnosticReport?
    @State private var isLoading = false
    @State private var showingExportSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Diagnostics")
                .font(.headline)

            Text("View performance metrics and diagnostic information for data operations.")
                .font(.callout)
                .foregroundStyle(.secondary)

            if isLoading {
                ProgressView("Loading diagnostics...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let report = diagnosticReport {
                // Performance Metrics
                GroupBox("Performance Metrics") {
                    VStack(alignment: .leading, spacing: 8) {
                        MetricRow(label: "Total Exports", value: "\(report.performanceMetrics.totalExports)")
                        MetricRow(label: "Total Imports", value: "\(report.performanceMetrics.totalImports)")
                        MetricRow(label: "Total Backups", value: "\(report.performanceMetrics.totalBackups)")

                        Divider()

                        MetricRow(
                            label: "Avg Export Time",
                            value: report.performanceMetrics.averageExportTimeMs.map { "\($0)ms" } ?? "N/A"
                        )
                        MetricRow(
                            label: "Avg Import Time",
                            value: report.performanceMetrics.averageImportTimeMs.map { "\($0)ms" } ?? "N/A"
                        )
                        MetricRow(
                            label: "Avg Backup Time",
                            value: report.performanceMetrics.averageBackupTimeMs.map { "\($0)ms" } ?? "N/A"
                        )
                    }
                    .padding(.vertical, 4)
                }

                // Recent Operations
                GroupBox("Recent Operations") {
                    VStack(alignment: .leading, spacing: 6) {
                        if report.operationHistory.isEmpty {
                            Text("No operations yet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(report.operationHistory.prefix(5)) { operation in
                                HStack {
                                    Image(systemName: operation.status == .completed ? "checkmark.circle.fill" : operation.status == .failed ? "xmark.circle.fill" : "circle")
                                        .foregroundStyle(operation.status == .completed ? .green : operation.status == .failed ? .red : .secondary)
                                        .font(.caption)

                                    Text(operation.operationType)
                                        .font(.caption)

                                    Spacer()

                                    if let duration = operation.durationMs {
                                        Text("\(duration)ms")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // System Info
                GroupBox("System Information") {
                    VStack(alignment: .leading, spacing: 6) {
                        MetricRow(label: "OS", value: report.systemInfo.osVersion)
                        MetricRow(
                            label: "Available Memory",
                            value: ByteCountFormatter.string(fromByteCount: report.systemInfo.availableMemory, countStyle: .memory)
                        )
                        MetricRow(
                            label: "Available Disk",
                            value: ByteCountFormatter.string(fromByteCount: report.systemInfo.availableDiskSpace, countStyle: .file)
                        )
                    }
                    .padding(.vertical, 4)
                }

                Spacer()

                // Actions
                HStack(spacing: 12) {
                    Button {
                        Task { await clearDiagnostics() }
                    } label: {
                        Label("Clear Data", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("Export Report", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task {
            await loadDiagnostics()
        }
        .sheet(isPresented: $showingExportSheet) {
            DiagnosticExportSheet(report: diagnosticReport)
        }
    }

    @MainActor
    private func loadDiagnostics() async {
        isLoading = true
        defer { isLoading = false }

        diagnosticReport = await DiagnosticService.shared.generateReport()
    }

    @MainActor
    private func clearDiagnostics() async {
        await DiagnosticService.shared.clearDiagnostics()
        await loadDiagnostics()
    }
}

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
        }
    }
}

struct DiagnosticExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let report: DiagnosticReport?

    @State private var exportFormat: DiagnosticExportFormat = .text
    @State private var isExporting = false
    @State private var exportError: Error?
    @State private var exportSuccess = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Export Diagnostic Report")
                .font(.title2.bold())

            Picker("Format", selection: $exportFormat) {
                Text("Text").tag(DiagnosticExportFormat.text)
                Text("JSON").tag(DiagnosticExportFormat.json)
            }
            .pickerStyle(.segmented)

            if let error = exportError {
                GroupBox {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if exportSuccess {
                GroupBox {
                    Label("Report exported successfully", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(exportSuccess ? "Done" : "Export") {
                    if exportSuccess {
                        dismiss()
                    } else {
                        Task { await performExport() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isExporting)
            }
        }
        .padding()
        .frame(width: 400, height: 250)
    }

    @MainActor
    private func performExport() async {
        guard let report = report else { return }

        isExporting = true
        exportError = nil
        defer { isExporting = false }

        do {
            let panel = NSSavePanel()
            panel.title = "Export Diagnostic Report"
            panel.nameFieldStringValue = "diagnostics-\(Date().formatted(date: .numeric, time: .omitted))"
            panel.allowedContentTypes = [exportFormat == .text ? .plainText : .json]

            if panel.runModal() == .OK, let url = panel.url {
                if exportFormat == .text {
                    try await DiagnosticService.shared.exportDiagnosticsAsText(to: url)
                } else {
                    try await DiagnosticService.shared.exportDiagnostics(to: url)
                }
                exportSuccess = true
            }
        } catch {
            exportError = error
        }
    }
}

enum DiagnosticExportFormat {
    case text
    case json
}

#Preview {
    DataPortabilityView()
        .modelContainer(PreviewContainer.preview)
}
