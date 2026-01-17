import SwiftUI

/// Shows an overview of stored data and recent activity
struct DataOverviewView: View {
    let vault: DataVaultManager
    let auditLogger: AuditLogger

    @State private var totalTasks = 0
    @State private var completedTasks = 0
    @State private var archivedTasks = 0
    @State private var recentLogs: [AuditLogEntry] = []
    @State private var isLoading = true
    @State private var oldestTaskDate: Date?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    statsSection
                    activitySection
                }
            }
            .padding()
        }
        .task {
            await loadData()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Data Overview")
                .font(.title)
                .fontWeight(.bold)

            Text("Your data stays on your device. You own it completely.")
                .foregroundStyle(.secondary)
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Storage Summary")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(title: "Total Tasks", value: "\(totalTasks)", icon: "list.bullet", color: .blue)
                StatCard(title: "Completed", value: "\(completedTasks)", icon: "checkmark.circle", color: .green)
                StatCard(title: "Archived", value: "\(archivedTasks)", icon: "archivebox", color: .orange)
            }

            if let oldestDate = oldestTaskDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("Oldest task: \(dateFormatter.string(from: oldestDate))")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)

            if recentLogs.isEmpty {
                Text("No recent activity")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(recentLogs) { log in
                    ActivityRow(log: log, dateFormatter: dateFormatter)
                }
            }
        }
    }

    private func loadData() async {
        isLoading = true

        async let counts = loadCounts()
        async let logs = auditLogger.getRecentLogs(limit: 5)
        async let oldest = loadOldestTask()

        let (_, loadedLogs, oldestDate) = await (counts, logs, oldest)

        recentLogs = loadedLogs
        oldestTaskDate = oldestDate
        isLoading = false
    }

    private func loadCounts() async {
        totalTasks = await vault.countTasks()
        completedTasks = await vault.countCompletedTasks()
        archivedTasks = await vault.countArchivedTasks()
    }

    private func loadOldestTask() async -> Date? {
        guard let tasks = try? await vault.fetchAllTasks(),
              let oldest = tasks.min(by: { $0.createdAt < $1.createdAt }) else {
            return nil
        }
        return oldest.createdAt
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ActivityRow: View {
    let log: AuditLogEntry
    let dateFormatter: DateFormatter

    var body: some View {
        HStack {
            Image(systemName: iconForEvent(log.event))
                .foregroundStyle(colorForEvent(log.event))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.details)
                    .font(.subheadline)

                Text(dateFormatter.string(from: log.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func iconForEvent(_ event: String) -> String {
        switch event {
        case "export": return "square.and.arrow.up"
        case "import": return "square.and.arrow.down"
        case "delete": return "trash"
        default: return "circle"
        }
    }

    private func colorForEvent(_ event: String) -> Color {
        switch event {
        case "export": return .blue
        case "import": return .green
        case "delete": return .red
        default: return .secondary
        }
    }
}
