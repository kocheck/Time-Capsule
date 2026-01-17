import Foundation

/// Exports tasks to Markdown format for human readability
struct MarkdownExporter {
    private let dateFormatter: DateFormatter

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
    }

    /// Exports tasks to Markdown string
    func export(tasks: [TaskItem]) -> String {
        var lines: [String] = []

        // Header
        lines.append("# Time Capsule Export")
        lines.append("")
        lines.append("Exported: \(dateFormatter.string(from: Date()))")
        lines.append("")

        // Summary
        let completed = tasks.filter { $0.isCompleted }.count
        let pending = tasks.filter { !$0.isCompleted && !$0.isArchived }.count
        let archived = tasks.filter { $0.isArchived }.count

        lines.append("## Summary")
        lines.append("")
        lines.append("- **Total Tasks**: \(tasks.count)")
        lines.append("- **Pending**: \(pending)")
        lines.append("- **Completed**: \(completed)")
        lines.append("- **Archived**: \(archived)")
        lines.append("")

        // Pending tasks
        let pendingTasks = tasks.filter { !$0.isCompleted && !$0.isArchived }
        if !pendingTasks.isEmpty {
            lines.append("## Pending Tasks")
            lines.append("")
            for task in pendingTasks.sorted(by: { $0.priority > $1.priority }) {
                lines.append(formatTask(task))
            }
            lines.append("")
        }

        // Completed tasks
        let completedTasks = tasks.filter { $0.isCompleted }
        if !completedTasks.isEmpty {
            lines.append("## Completed Tasks")
            lines.append("")
            for task in completedTasks.sorted(by: { ($0.completedAt ?? Date()) > ($1.completedAt ?? Date()) }) {
                lines.append(formatTask(task))
            }
            lines.append("")
        }

        // Archived tasks
        let archivedTasks = tasks.filter { $0.isArchived && !$0.isCompleted }
        if !archivedTasks.isEmpty {
            lines.append("## Archived Tasks")
            lines.append("")
            for task in archivedTasks {
                lines.append(formatTask(task))
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    /// Exports tasks to a Markdown file at the specified URL
    func exportToFile(tasks: [TaskItem], url: URL) throws {
        let markdown = export(tasks: tasks)
        try markdown.write(to: url, atomically: true, encoding: .utf8)
    }

    private func formatTask(_ task: TaskItem) -> String {
        var lines: [String] = []

        // Checkbox with title
        let checkbox = task.isCompleted ? "[x]" : "[ ]"
        let priorityBadge = task.priority == .high ? " **[HIGH]**" : (task.priority == .low ? " *[low]*" : "")
        lines.append("- \(checkbox) \(task.title)\(priorityBadge)")

        // Description
        if let description = task.taskDescription, !description.isEmpty {
            lines.append("  > \(description)")
        }

        // Tags
        if !task.tags.isEmpty {
            let tagString = task.tags.map { "#\($0)" }.joined(separator: " ")
            lines.append("  - Tags: \(tagString)")
        }

        // Dates
        lines.append("  - Created: \(dateFormatter.string(from: task.createdAt))")
        if let completedAt = task.completedAt {
            lines.append("  - Completed: \(dateFormatter.string(from: completedAt))")
        }

        // Skip count if notable
        if task.skipCount > 0 {
            lines.append("  - Skipped: \(task.skipCount) times")
        }

        return lines.joined(separator: "\n")
    }
}
