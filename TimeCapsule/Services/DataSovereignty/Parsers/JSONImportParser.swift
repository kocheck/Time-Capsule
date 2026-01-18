import Foundation
import OSLog

struct JSONImportParser: ImportParser {
    private let logger = Logger.importLogger

    func parse(_ data: Data) async throws -> [ImportedTask] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try to parse as UTF format first
        if let utfFormat = try? decoder.decode(UniversalTaskFormat.self, from: data) {
            logger.info("Detected Universal Task Format")
            let utfParser = UTFImportParser()
            return try await utfParser.parse(data)
        }

        // Try generic JSON export format
        if let exportData = try? decoder.decode(JSONExportData.self, from: data) {
            logger.info("Detected Time Capsule JSON export format")
            return parseJSONExport(exportData)
        }

        // Try as array of tasks
        if let tasks = try? decoder.decode([JSONTask].self, from: data) {
            logger.info("Detected JSON task array")
            return tasks.map { convertJSONTask($0) }
        }

        throw ImportErrorType.invalidFormat
    }

    private func parseJSONExport(_ exportData: JSONExportData) -> [ImportedTask] {
        var importedTasks: [ImportedTask] = []

        for task in exportData.tasks {
            importedTasks.append(convertJSONTask(task))
        }

        for task in exportData.completedTasks {
            importedTasks.append(convertJSONTask(task))
        }

        for task in exportData.archivedTasks {
            importedTasks.append(convertJSONTask(task))
        }

        return importedTasks
    }

    private func convertJSONTask(_ task: JSONTask) -> ImportedTask {
        let priority = TaskPriority(rawValue: task.priority) ?? .normal
        return ImportedTask(
            sourceId: task.id,
            sourceSystem: "TimeCapsule",
            title: task.title,
            description: task.description,
            tags: task.tags,
            priority: priority,
            createdAt: task.createdAt,
            completedAt: task.completedAt
        )
    }
}

// MARK: - JSON Import Models

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
    let skipCount: Int?
    let isArchived: Bool?
    let contextHints: [String]?
}
