import Foundation

struct UniversalTaskFormatExporter: DataExporter {
    func export(
        tasks: [TaskItem],
        completedTasks: [TaskItem],
        archivedTasks: [TaskItem],
        settings: AppSettings?
    ) async throws -> Data {
        let utfTasks = tasks.map { UTFTask(from: $0) }
        let utfCompletedTasks = completedTasks.map { UTFTask(from: $0) }
        let utfArchivedTasks = archivedTasks.map { UTFTask(from: $0) }
        let utfSettings = settings.map { UTFSettings(from: $0) }

        let format = try UniversalTaskFormat(
            tasks: utfTasks,
            completedTasks: utfCompletedTasks,
            archivedTasks: utfArchivedTasks,
            settings: utfSettings
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        return try encoder.encode(format)
    }
}
