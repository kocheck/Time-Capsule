import SwiftUI

/// View for exporting tasks in various formats
struct ExportView: View {
    @Bindable var coordinator: ExportCoordinator

    @State private var selectedFormat: ExportFormat = .json
    @State private var includeCompleted = true
    @State private var includeArchived = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                formatSection
                optionsSection
                exportButton
                successMessage
            }
            .padding()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Export Your Data")
                .font(.title)
                .fontWeight(.bold)

            Text("Download your tasks in a format you can use anywhere.")
                .foregroundStyle(.secondary)
        }
    }

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Format")
                .font(.headline)

            ForEach(ExportFormat.allCases) { format in
                FormatOption(
                    format: format,
                    isSelected: selectedFormat == format,
                    action: { selectedFormat = format }
                )
            }
        }
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)

            Toggle("Include completed tasks", isOn: $includeCompleted)
            Toggle("Include archived tasks", isOn: $includeArchived)
        }
    }

    private var exportButton: some View {
        VStack(spacing: 12) {
            Button(action: performExport) {
                HStack {
                    if coordinator.isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(coordinator.isExporting ? "Exporting..." : "Export My Data")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(coordinator.isExporting)

            Button(action: exportAll) {
                Text("Export All Formats")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(coordinator.isExporting)

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var successMessage: some View {
        if showSuccess, let url = coordinator.lastExportURL {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                VStack(alignment: .leading) {
                    Text("Export successful!")
                        .fontWeight(.medium)
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Show in Finder") {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func performExport() {
        Task {
            do {
                showSuccess = false
                errorMessage = nil

                let options = ExportOptions(
                    includeCompleted: includeCompleted,
                    includeArchived: includeArchived
                )

                _ = try await coordinator.export(format: selectedFormat, options: options)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func exportAll() {
        Task {
            do {
                showSuccess = false
                errorMessage = nil

                let options = ExportOptions(
                    includeCompleted: includeCompleted,
                    includeArchived: includeArchived
                )

                _ = try await coordinator.exportAll(options: options)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Supporting Views

private struct FormatOption: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(format.rawValue)
                        .fontWeight(.medium)

                    Text(format.displayDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
