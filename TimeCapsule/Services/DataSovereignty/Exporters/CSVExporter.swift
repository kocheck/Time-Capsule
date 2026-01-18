import Foundation

struct CSVExporter: DataExporter {
    func export(
        tasks: [TaskItem],
        completedTasks: [TaskItem],
        archivedTasks: [TaskItem],
        settings: AppSettings?
    ) async throws -> Data {
        var csv = "ID,Title,Description,Tags,Priority,Created At,Completed At,Skip Count,Status\n"

        let dateFormatter = ISO8601DateFormatter()

        let allTasks = tasks + completedTasks + archivedTasks

        for task in allTasks {
            let id = task.id.uuidString
            let title = escapeCSV(task.title)
            let description = escapeCSV(task.taskDescription ?? "")
            let tags = escapeCSV(task.tags.joined(separator: ";"))
            let priority = task.priority.rawValue
            let createdAt = dateFormatter.string(from: task.createdAt)
            let completedAt = task.completedAt.map { dateFormatter.string(from: $0) } ?? ""
            let skipCount = String(task.skipCount)
            let status = task.isArchived ? "Archived" : (task.isCompleted ? "Completed" : "Active")

            csv += "\(id),\(title),\(description),\(tags),\(priority),\(createdAt),\(completedAt),\(skipCount),\(status)\n"
        }

        guard let data = csv.data(using: .utf8) else {
            throw ExportError.invalidFormat
        }

        return data
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
