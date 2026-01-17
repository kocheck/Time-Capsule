import Foundation

/// Exports tasks to CSV format
struct CSVExporter {
    private let dateFormatter: ISO8601DateFormatter

    init() {
        dateFormatter = ISO8601DateFormatter()
    }

    /// Exports tasks to CSV string
    func export(tasks: [TaskItem]) -> String {
        var lines: [String] = []

        // Header row
        let headers = [
            "id",
            "title",
            "description",
            "tags",
            "priority",
            "status",
            "created_at",
            "completed_at",
            "skip_count",
            "is_archived"
        ]
        lines.append(headers.joined(separator: ","))

        // Data rows
        for task in tasks {
            let status = task.isCompleted ? "completed" : (task.isArchived ? "archived" : "pending")
            let completedAt = task.completedAt.map { dateFormatter.string(from: $0) } ?? ""

            let row = [
                task.id.uuidString,
                escapeCSV(task.title),
                escapeCSV(task.taskDescription ?? ""),
                escapeCSV(task.tags.joined(separator: ";")),
                task.priority.rawValue,
                status,
                dateFormatter.string(from: task.createdAt),
                completedAt,
                String(task.skipCount),
                task.isArchived ? "true" : "false"
            ]
            lines.append(row.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    /// Exports tasks to a CSV file at the specified URL
    func exportToFile(tasks: [TaskItem], url: URL) throws {
        let csv = export(tasks: tasks)
        try csv.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Escapes a value for CSV format
    private func escapeCSV(_ value: String) -> String {
        // If value contains comma, quote, or newline, wrap in quotes and escape quotes
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}
