import Foundation

// MARK: - Export Preview

struct ExportPreview {
    let activeCount: Int
    let completedCount: Int
    let archivedCount: Int
    let totalCount: Int
    let dateRange: ClosedRange<Date>?
    let estimatedSizeBytes: Int
    let tags: Set<String>
    let sampleTasks: [TaskPreview]
    let includesSettings: Bool

    var estimatedSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(estimatedSizeBytes), countStyle: .file)
    }

    var dateRangeFormatted: String {
        guard let range = dateRange else {
            return "No tasks"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        return "\(formatter.string(from: range.lowerBound)) - \(formatter.string(from: range.upperBound))"
    }

    var tagSummary: String {
        if tags.isEmpty {
            return "No tags"
        } else if tags.count <= 3 {
            return tags.sorted().joined(separator: ", ")
        } else {
            let first3 = Array(tags.sorted().prefix(3))
            return "\(first3.joined(separator: ", ")) +\(tags.count - 3) more"
        }
    }
}

// MARK: - Task Preview

struct TaskPreview: Identifiable {
    let id: String
    let title: String
    let tags: [String]
    let priority: String
    let isCompleted: Bool

    init(from task: TaskItem) {
        self.id = task.id.uuidString
        self.title = task.title
        self.tags = task.tags
        self.priority = task.priority.rawValue
        self.isCompleted = task.isCompleted
    }
}

// MARK: - Import Preview

struct ImportPreview {
    let source: ImportSource
    let taskCount: Int
    let dateRange: ClosedRange<Date>?
    let tags: Set<String>
    let sampleTasks: [ImportedTaskPreview]
    let potentialConflicts: [ImportConflict]

    var dateRangeFormatted: String {
        guard let range = dateRange else {
            return "No date information"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        return "\(formatter.string(from: range.lowerBound)) - \(formatter.string(from: range.upperBound))"
    }

    var hasConflicts: Bool {
        !potentialConflicts.isEmpty
    }
}

// MARK: - Imported Task Preview

struct ImportedTaskPreview: Identifiable {
    let id: String
    let title: String
    let tags: [String]
    let sourceSystem: String

    init(from task: ImportedTask) {
        self.id = task.sourceId
        self.title = task.title
        self.tags = task.tags
        self.sourceSystem = task.sourceSystem
    }
}

// MARK: - Import Conflict

struct ImportConflict: Identifiable {
    let id = UUID()
    let importedTask: ImportedTask
    let existingTask: TaskItem
    let conflictType: ConflictType

    enum ConflictType {
        case duplicateTitle
        case sameSourceId
        case similarContent
    }

    var description: String {
        switch conflictType {
        case .duplicateTitle:
            return "Task with same title exists"
        case .sameSourceId:
            return "Task with same ID already imported"
        case .similarContent:
            return "Very similar task exists"
        }
    }
}
