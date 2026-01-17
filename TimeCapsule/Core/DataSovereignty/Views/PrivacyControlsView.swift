import SwiftUI

/// View for privacy controls and data deletion options
struct PrivacyControlsView: View {
    let vault: DataVaultManager
    let auditLogger: AuditLogger

    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var tagToDelete = ""
    @State private var deleteConfirmText = ""
    @State private var showDeleteConfirmation = false
    @State private var showAuditLog = false
    @State private var isDeleting = false
    @State private var deleteResult: DeleteResult?
    @State private var auditLogs: [AuditLogEntry] = []

    private let requiredDeleteText = "DELETE ALL MY DATA"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                deleteByDateSection
                deleteByTagSection
                deleteAllSection
                auditLogSection
            }
            .padding()
        }
        .sheet(isPresented: $showAuditLog) {
            AuditLogSheet(logs: auditLogs, onDismiss: { showAuditLog = false })
        }
        .task {
            auditLogs = await auditLogger.getAllLogs()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Privacy Controls")
                .font(.title)
                .fontWeight(.bold)

            Text("Manage and delete your data. All operations are logged.")
                .foregroundStyle(.secondary)
        }
    }

    private var deleteByDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delete by Date Range")
                .font(.headline)

            HStack {
                DatePicker("From", selection: $startDate, displayedComponents: .date)
                DatePicker("To", selection: $endDate, displayedComponents: .date)
            }

            Button(role: .destructive) {
                Task { await deleteByDateRange() }
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Tasks in Range")
                }
            }
            .disabled(isDeleting)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var deleteByTagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delete by Tag")
                .font(.headline)

            HStack {
                TextField("Enter tag name", text: $tagToDelete)
                    .textFieldStyle(.roundedBorder)

                Button(role: .destructive) {
                    Task { await deleteByTag() }
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(tagToDelete.isEmpty || isDeleting)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var deleteAllSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Danger Zone")
                    .font(.headline)
                    .foregroundStyle(.red)
            }

            Text("This will permanently delete ALL your tasks. This action cannot be undone.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Type '\(requiredDeleteText)' to confirm:")
                .font(.caption)

            TextField("Confirmation", text: $deleteConfirmText)
                .textFieldStyle(.roundedBorder)

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete All My Data")
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(deleteConfirmText != requiredDeleteText || isDeleting)
            .alert("Final Confirmation", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    Task { await deleteAll() }
                }
            } message: {
                Text("This will permanently delete all \(vault.countTasks()) tasks. Are you absolutely sure?")
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }

    private var auditLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Audit Log")
                    .font(.headline)

                Spacer()

                Button("View All") {
                    Task {
                        auditLogs = await auditLogger.getAllLogs()
                        showAuditLog = true
                    }
                }
            }

            Text("All data operations are recorded for your review.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let result = deleteResult {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text(result.message)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private func deleteByDateRange() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            let range = DateRange(start: startDate, end: endDate)
            let count = try await vault.deleteTasksInRange(range)
            await auditLogger.log(.deleted(scope: "date range", count: count))
            deleteResult = DeleteResult(message: "Deleted \(count) tasks from date range")
            auditLogs = await auditLogger.getAllLogs()
        } catch {
            deleteResult = DeleteResult(message: "Error: \(error.localizedDescription)")
        }
    }

    private func deleteByTag() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            let tag = tagToDelete
            let count = try await vault.deleteTasksWithTag(tag)
            await auditLogger.log(.deleted(scope: "tag: \(tag)", count: count))
            deleteResult = DeleteResult(message: "Deleted \(count) tasks with tag '\(tag)'")
            tagToDelete = ""
            auditLogs = await auditLogger.getAllLogs()
        } catch {
            deleteResult = DeleteResult(message: "Error: \(error.localizedDescription)")
        }
    }

    private func deleteAll() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            let allTasks = try await vault.fetchAllTasks()
            var count = 0
            for task in allTasks {
                try await vault.deleteTask(task)
                count += 1
            }
            await auditLogger.log(.deleted(scope: "all data", count: count))
            deleteResult = DeleteResult(message: "Deleted all \(count) tasks")
            deleteConfirmText = ""
            auditLogs = await auditLogger.getAllLogs()
        } catch {
            deleteResult = DeleteResult(message: "Error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

private struct DeleteResult {
    let message: String
}

// MARK: - Audit Log Sheet

private struct AuditLogSheet: View {
    let logs: [AuditLogEntry]
    let onDismiss: () -> Void

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationStack {
            List(logs) { log in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: iconFor(log.event))
                            .foregroundStyle(colorFor(log.event))
                        Text(log.event.capitalized)
                            .fontWeight(.medium)
                    }

                    Text(log.details)
                        .font(.subheadline)

                    Text(dateFormatter.string(from: log.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Audit Log")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }

    private func iconFor(_ event: String) -> String {
        switch event {
        case "export": return "square.and.arrow.up"
        case "import": return "square.and.arrow.down"
        case "delete": return "trash"
        default: return "circle"
        }
    }

    private func colorFor(_ event: String) -> Color {
        switch event {
        case "export": return .blue
        case "import": return .green
        case "delete": return .red
        default: return .secondary
        }
    }
}
