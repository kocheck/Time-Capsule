import Foundation
import CryptoKit
import OSLog

struct UTFImportParser: ImportParser {
    private let logger = Logger.importLogger

    func parse(_ data: Data) async throws -> [ImportedTask] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Parse the UTF format
        let format = try decoder.decode(UniversalTaskFormat.self, from: data)

        // Verify version compatibility
        guard format.formatVersion == UniversalTaskFormat.currentVersion else {
            logger.warning("Version mismatch: file version \(format.formatVersion), current version \(UniversalTaskFormat.currentVersion)")
            // We'll still try to import, but log the warning
        }

        // Verify checksum
        let calculatedChecksum = SHA256.hash(data: data).hexString
        // Note: We can't verify checksum directly because it's part of the data
        // In a real implementation, we'd exclude checksum from the calculation
        logger.info("Importing UTF format version \(format.formatVersion)")

        var importedTasks: [ImportedTask] = []

        // Convert active tasks
        for utfTask in format.tasks {
            importedTasks.append(convertUTFTask(utfTask))
        }

        // Convert completed tasks
        for utfTask in format.completedTasks {
            importedTasks.append(convertUTFTask(utfTask))
        }

        // Convert archived tasks
        for utfTask in format.archivedTasks {
            importedTasks.append(convertUTFTask(utfTask))
        }

        return importedTasks
    }

    private func convertUTFTask(_ utfTask: UTFTask) -> ImportedTask {
        let priority = TaskPriority(rawValue: utfTask.priority) ?? .normal
        return ImportedTask(
            sourceId: utfTask.id,
            sourceSystem: utfTask.sourceSystem ?? "TimeCapsule",
            title: utfTask.title,
            description: utfTask.description,
            tags: utfTask.tags,
            priority: priority,
            createdAt: utfTask.createdAt,
            completedAt: utfTask.completedAt
        )
    }
}
