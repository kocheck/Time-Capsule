import Foundation

/// Time Capsule's open data format - fully documented, versioned
struct UniversalTaskFormat: Codable {
    static let version = "1.0.0"

    let formatVersion: String
    let exportedAt: Date
    let appVersion: String
    let checksum: String

    let tasks: [UTFTask]
    let metadata: UTFMetadata

    init(tasks: [TaskItem], appVersion: String = "1.0.0") {
        self.formatVersion = Self.version
        self.exportedAt = Date()
        self.appVersion = appVersion
        self.tasks = tasks.map { UTFTask(from: $0) }
        self.metadata = UTFMetadata(from: tasks)

        // Calculate checksum from task data
        self.checksum = Self.calculateChecksum(tasks: self.tasks)
    }

    /// Validates the checksum against the task data
    func validateChecksum() -> Bool {
        let calculated = Self.calculateChecksum(tasks: tasks)
        return calculated == checksum
    }

    private static func calculateChecksum(tasks: [UTFTask]) -> String {
        let taskData = tasks.map { "\($0.id)|\($0.title)|\($0.createdAt.timeIntervalSince1970)" }
        let combined = taskData.joined(separator: ";")
        // Simple hash for demo - in production use CryptoKit
        var hash = 0
        for char in combined.unicodeScalars {
            hash = hash &* 31 &+ Int(char.value)
        }
        return String(format: "%08x", abs(hash))
    }
}

/// A task in Universal Task Format
struct UTFTask: Codable {
    let id: String
    let title: String
    let description: String?
    let tags: [String]
    let priority: String
    let status: String
    let createdAt: Date
    let completedAt: Date?
    let skipCount: Int
    let isArchived: Bool
    let contextHints: [String]

    init(from task: TaskItem) {
        self.id = task.id.uuidString
        self.title = task.title
        self.description = task.taskDescription
        self.tags = task.tags
        self.priority = task.priority.rawValue
        self.status = task.isCompleted ? "completed" : (task.isArchived ? "archived" : "pending")
        self.createdAt = task.createdAt
        self.completedAt = task.completedAt
        self.skipCount = task.skipCount
        self.isArchived = task.isArchived
        self.contextHints = task.contextHints
    }

    /// Converts back to a TaskItem
    func toTaskItem() -> TaskItem {
        let priority = TaskPriority(rawValue: self.priority) ?? .normal
        let task = TaskItem(
            title: title,
            description: description,
            tags: tags,
            priority: priority
        )

        // Note: We can't set the UUID directly on SwiftData models after creation
        // In a real import, we'd need to handle ID mapping differently

        if status == "completed", let completedDate = completedAt {
            task.completedAt = completedDate
        }

        if isArchived {
            task.archive()
        }

        return task
    }
}

/// Metadata about the exported tasks
struct UTFMetadata: Codable {
    let totalTasks: Int
    let completedTasks: Int
    let archivedTasks: Int
    let pendingTasks: Int
    let tagCounts: [String: Int]
    let oldestTask: Date?
    let newestTask: Date?

    init(from tasks: [TaskItem]) {
        self.totalTasks = tasks.count
        self.completedTasks = tasks.filter { $0.isCompleted }.count
        self.archivedTasks = tasks.filter { $0.isArchived }.count
        self.pendingTasks = tasks.filter { !$0.isCompleted && !$0.isArchived }.count

        var tagCounts: [String: Int] = [:]
        for task in tasks {
            for tag in task.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        self.tagCounts = tagCounts

        self.oldestTask = tasks.map(\.createdAt).min()
        self.newestTask = tasks.map(\.createdAt).max()
    }
}
