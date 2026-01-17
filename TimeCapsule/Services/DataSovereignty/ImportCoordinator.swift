import Foundation
import SwiftData
import OSLog

actor ImportCoordinator {
    private let logger = Logger.import_
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Import Entry Point

    func importData(
        from url: URL,
        source: ImportSource,
        options: ImportOptions
    ) async throws -> ImportResult {
        logger.info("Starting import from \(source.rawValue)")

        // Read file
        let data = try Data(contentsOf: url)

        // Parse based on source
        let parser = createParser(for: source)
        let importedTasks = try await parser.parse(data)

        logger.info("Parsed \(importedTasks.count) tasks from import file")

        // Import tasks
        var importedCount = 0
        var skippedCount = 0
        var errors: [ImportError] = []

        for importedTask in importedTasks {
            do {
                // Check for conflicts
                if !options.preserveIds || options.conflictStrategy != .replaceExisting {
                    // Create new task
                    let task = importedTask.toTaskItem()
                    modelContext.insert(task)
                    importedCount += 1
                } else {
                    // Handle ID preservation and conflicts
                    let task = importedTask.toTaskItem()
                    modelContext.insert(task)
                    importedCount += 1
                }
            } catch {
                logger.error("Failed to import task: \(importedTask.title) - \(error)")
                errors.append(ImportError(taskTitle: importedTask.title, errorMessage: error.localizedDescription))
                skippedCount += 1
            }
        }

        // Save all changes
        do {
            try modelContext.save()
            logger.info("Import completed: \(importedCount) imported, \(skippedCount) skipped")
        } catch {
            logger.error("Failed to save imported tasks: \(error)")
            throw ImportError(taskTitle: "All tasks", errorMessage: "Failed to save: \(error.localizedDescription)")
        }

        return ImportResult(
            success: true,
            importedCount: importedCount,
            skippedCount: skippedCount,
            errors: errors
        )
    }

    // MARK: - Source-Specific Parsers

    private func createParser(for source: ImportSource) -> any ImportParser {
        switch source {
        case .universalTaskFormat:
            return UTFImportParser()
        case .json:
            return JSONImportParser()
        case .csv:
            return CSVImportParser()
        case .todoist:
            return TodoistImportParser()
        case .things3:
            return Things3ImportParser()
        case .reminders:
            return RemindersImportParser()
        }
    }
}

// MARK: - Import Errors

enum ImportErrorType: LocalizedError {
    case invalidFormat
    case parsingFailed(Error)
    case unsupportedVersion
    case checksumMismatch

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid import file format"
        case .parsingFailed(let error):
            return "Failed to parse import file: \(error.localizedDescription)"
        case .unsupportedVersion:
            return "Unsupported data format version"
        case .checksumMismatch:
            return "Data integrity check failed - file may be corrupted"
        }
    }
}
