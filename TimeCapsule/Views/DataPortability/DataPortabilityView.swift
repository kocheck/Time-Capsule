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

    var body: some View {
        VStack(spacing: 20) {
            Text("Import Data")
                .font(.title2.bold())

            Text("Import functionality will be available in the next update.")
                .foregroundStyle(.secondary)

            Button("OK") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 450)
    }
}

struct BackupSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Backup")
                .font(.title2.bold())

            Text("Backup functionality will be available in the next update.")
                .foregroundStyle(.secondary)

            Button("OK") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 450)
    }
}

#Preview {
    DataPortabilityView()
        .modelContainer(PreviewContainer.preview)
}
