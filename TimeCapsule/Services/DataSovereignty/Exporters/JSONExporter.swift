import Foundation

struct JSONExporter: DataExporter {
    func export(
        tasks: [TaskItem],
        completedTasks: [TaskItem],
        archivedTasks: [TaskItem],
        settings: AppSettings?
    ) async throws -> Data {
        let exportData = JSONExportData(
            exportedAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            tasks: tasks.map { JSONTask(from: $0) },
            completedTasks: completedTasks.map { JSONTask(from: $0) },
            archivedTasks: archivedTasks.map { JSONTask(from: $0) }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        return try encoder.encode(exportData)
    }
}

// MARK: - JSON Export Models

private struct JSONExportData: Codable {
    let exportedAt: Date
    let appVersion: String
    let tasks: [JSONTask]
    let completedTasks: [JSONTask]
    let archivedTasks: [JSONTask]
}

private struct JSONTask: Codable {
    let id: String
    let title: String
    let description: String?
    let tags: [String]
    let priority: String
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
        self.createdAt = task.createdAt
        self.completedAt = task.completedAt
        self.skipCount = task.skipCount
        self.isArchived = task.isArchived
        self.contextHints = task.contextHints
    }
}
