import Foundation

struct MarkdownExporter: DataExporter {
    func export(
        tasks: [TaskItem],
        completedTasks: [TaskItem],
        archivedTasks: [TaskItem],
        settings: AppSettings?
    ) async throws -> Data {
        var markdown = "# Time Capsule Export\n\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        markdown += "**Exported:** \(dateFormatter.string(from: Date()))\n\n"
        markdown += "---\n\n"

        // Active Tasks
        if !tasks.isEmpty {
            markdown += "## Active Tasks (\(tasks.count))\n\n"
            for task in tasks.sorted(by: { $0.priority.rawValue > $1.priority.rawValue }) {
                markdown += formatTask(task, dateFormatter: dateFormatter)
            }
            markdown += "\n"
        }

        // Completed Tasks
        if !completedTasks.isEmpty {
            markdown += "## Completed Tasks (\(completedTasks.count))\n\n"
            for task in completedTasks.sorted(by: { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }) {
                markdown += formatTask(task, dateFormatter: dateFormatter, showCompletion: true)
            }
            markdown += "\n"
        }

        // Archived Tasks
        if !archivedTasks.isEmpty {
            markdown += "## Archived Tasks (\(archivedTasks.count))\n\n"
            for task in archivedTasks {
                markdown += formatTask(task, dateFormatter: dateFormatter)
            }
            markdown += "\n"
        }

        // Statistics
        markdown += "---\n\n"
        markdown += "## Statistics\n\n"
        markdown += "- **Total Active Tasks:** \(tasks.count)\n"
        markdown += "- **Total Completed Tasks:** \(completedTasks.count)\n"
        markdown += "- **Total Archived Tasks:** \(archivedTasks.count)\n"

        let allTags = Set((tasks + completedTasks + archivedTasks).flatMap { $0.tags })
        markdown += "- **Unique Tags:** \(allTags.count)\n"

        if !allTags.isEmpty {
            markdown += "\n### Tags Used\n\n"
            markdown += allTags.sorted().map { "- `\($0)`" }.joined(separator: "\n")
            markdown += "\n"
        }

        guard let data = markdown.data(using: .utf8) else {
            throw ExportError.invalidFormat
        }

        return data
    }

    private func formatTask(_ task: TaskItem, dateFormatter: DateFormatter, showCompletion: Bool = false) -> String {
        var output = ""

        // Checkbox
        let checkbox = task.isCompleted ? "[x]" : "[ ]"
        output += "\(checkbox) **\(task.title)**\n"

        // Priority
        let priorityEmoji: String
        switch task.priority {
        case .high: priorityEmoji = "🔴"
        case .normal: priorityEmoji = "🟡"
        case .low: priorityEmoji = "🟢"
        }
        output += "  - Priority: \(priorityEmoji) \(task.priority.rawValue.capitalized)\n"

        // Tags
        if !task.tags.isEmpty {
            output += "  - Tags: \(task.tags.map { "`\($0)`" }.joined(separator: ", "))\n"
        }

        // Description
        if let description = task.taskDescription, !description.isEmpty {
            output += "  - Description: \(description)\n"
        }

        // Created date
        output += "  - Created: \(dateFormatter.string(from: task.createdAt))\n"

        // Completion date
        if showCompletion, let completedAt = task.completedAt {
            output += "  - Completed: \(dateFormatter.string(from: completedAt))\n"
        }

        // Skip count
        if task.skipCount > 0 {
            output += "  - Times skipped: \(task.skipCount)\n"
        }

        // Context hints
        if !task.contextHints.isEmpty {
            output += "  - Context: \(task.contextHints.joined(separator: ", "))\n"
        }

        output += "\n"
        return output
    }
}
