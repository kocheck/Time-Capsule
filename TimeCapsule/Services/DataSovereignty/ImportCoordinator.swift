import Foundation
import SwiftData
import OSLog

actor ImportCoordinator {
    private let logger = Logger.importLogger
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Preview Generation

    func generatePreview(from url: URL, source: ImportSource) async throws -> ImportPreview {
        logger.info("Generating import preview from \(source.rawValue)")

        // Read and parse file
        let data = try Data(contentsOf: url)
        let parser = createParser(for: source)
        let importedTasks = try await parser.parse(data)

        // Calculate date range
        let dates = importedTasks.compactMap { $0.createdAt }
        let dateRange: ClosedRange<Date>? = if let min = dates.min(), let max = dates.max() {
            min...max
        } else {
            nil
        }

        // Gather tags
        let tags = Set(importedTasks.flatMap { $0.tags })

        // Sample tasks
        let sampleTasks = importedTasks.prefix(5).map { ImportedTaskPreview(from: $0) }

        // Detect conflicts
        let conflicts = try await detectConflicts(importedTasks)

        return ImportPreview(
            source: source,
            taskCount: importedTasks.count,
            dateRange: dateRange,
            tags: tags,
            sampleTasks: Array(sampleTasks),
            potentialConflicts: conflicts
        )
    }

    private func detectConflicts(_ importedTasks: [ImportedTask]) async throws -> [ImportConflict] {
        var conflicts: [ImportConflict] = []

        // Fetch existing tasks
        let existingTasks = try modelContext.fetch(FetchDescriptor<TaskItem>())

        for importedTask in importedTasks {
            // Check for duplicate titles
            if let existing = existingTasks.first(where: { $0.title.lowercased() == importedTask.title.lowercased() }) {
                conflicts.append(ImportConflict(
                    importedTask: importedTask,
                    existingTask: existing,
                    conflictType: .duplicateTitle
                ))
            }
        }

        return conflicts
    }

    // MARK: - Import Entry Point

    func importData(
        from url: URL,
        source: ImportSource,
        options: ImportOptions
    ) async throws -> ImportResult {
        // Track operation start
        let startTime = Date()
        let operationId = await DiagnosticService.shared.trackOperationStart(
            "Import (\(source.rawValue))",
            details: "file=\(url.lastPathComponent)"
        )

        logger.info("Starting import from \(source.rawValue)")

        do {
            // Read file
            let data = try Data(contentsOf: url)

            // Parse based on source
            let parser = createParser(for: source)
            let importedTasks = try await parser.parse(data)

            logger.info("Parsed \(importedTasks.count) tasks from import file")

            // Detect conflicts again to get fresh state
            let conflicts = try await detectConflicts(importedTasks)

            // Build conflict lookup by imported task title
            let conflictsByTitle = Dictionary(grouping: conflicts, by: { $0.importedTask.title.lowercased() })

            // Import tasks
            var importedCount = 0
            var skippedCount = 0
            var errors: [ImportError] = []

            for importedTask in importedTasks {
                do {
                    // Check if this task has a conflict
                    if let taskConflicts = conflictsByTitle[importedTask.title.lowercased()],
                       let conflict = taskConflicts.first,
                       let resolution = options.conflictResolutions[conflict.id] {

                        // Apply user's conflict resolution
                        switch resolution {
                        case .keepExisting:
                            // Skip importing, keep existing task
                            logger.debug("Keeping existing task: \(importedTask.title)")
                            skippedCount += 1

                        case .useImported:
                            // Replace existing task with imported one
                            logger.debug("Replacing existing task with imported: \(importedTask.title)")
                            modelContext.delete(conflict.existingTask)
                            let newTask = importedTask.toTaskItem()
                            modelContext.insert(newTask)
                            importedCount += 1

                        case .skip:
                            // Skip both, don't import
                            logger.debug("Skipping conflicted task: \(importedTask.title)")
                            skippedCount += 1
                        }
                    } else {
                        // No conflict, import normally
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

            // Track operation success
            let duration = Int(Date().timeIntervalSince(startTime) * 1000)
            await DiagnosticService.shared.trackOperationComplete(operationId, durationMs: duration)
            await DiagnosticService.shared.updateLargestImportSize(Int64(data.count))

            return ImportResult(
                success: true,
                importedCount: importedCount,
                skippedCount: skippedCount,
                errors: errors
            )
        } catch {
            // Track operation failure
            await DiagnosticService.shared.trackOperationFailed(operationId, error: error)
            throw error
        }
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
