import Foundation

/// Coordinates import operations from various sources
@Observable
class ImportCoordinator {
    private let vault: DataVaultManager
    private let auditLogger: AuditLogger

    private let utfParser = UTFImportParser()
    private let todoistParser = TodoistImportParser()
    private let csvParser = CSVImportParser()

    var previewTasks: [TaskItem] = []
    var importResult: ImportResult?
    var isProcessing = false
    var currentPreview: ImportPreview?
    var lastError: Error?

    init(vault: DataVaultManager, auditLogger: AuditLogger) {
        self.vault = vault
        self.auditLogger = auditLogger
    }

    /// Previews tasks from a file without importing
    @MainActor
    func preview(from url: URL, source: ImportSource) async throws {
        isProcessing = true
        lastError = nil
        previewTasks = []
        currentPreview = nil

        defer { isProcessing = false }

        let data = try Data(contentsOf: url)

        guard !data.isEmpty else {
            throw ImportError.emptyFile
        }

        var tasks: [TaskItem] = []
        var warnings: [String] = []
        var metadata: ImportMetadata? = nil

        switch source {
        case .timeCapsule:
            tasks = try utfParser.parse(data)
            metadata = try? utfParser.extractMetadata(data)

        case .todoist:
            tasks = try todoistParser.parse(data)
            metadata = ImportMetadata(
                formatVersion: nil,
                exportedAt: nil,
                originalTaskCount: tasks.count,
                sourceApp: "Todoist"
            )

        case .csv:
            guard let csvString = String(data: data, encoding: .utf8) else {
                throw ImportError.parsingFailed("Could not read CSV as text")
            }
            tasks = try csvParser.parse(csvString)
        }

        // Check for potential duplicates
        let existingTasks = try await vault.fetchAllTasks()
        let existingTitles = Set(existingTasks.map { $0.title.lowercased() })

        let duplicateCount = tasks.filter { existingTitles.contains($0.title.lowercased()) }.count
        if duplicateCount > 0 {
            warnings.append("\(duplicateCount) task(s) may be duplicates of existing tasks")
        }

        previewTasks = tasks
        currentPreview = ImportPreview(
            tasks: tasks,
            source: source,
            warnings: warnings,
            metadata: metadata
        )
    }

    /// Confirms and performs the import
    @MainActor
    func confirmImport(options: ImportOptions = .default) async throws -> ImportResult {
        guard !previewTasks.isEmpty else {
            throw ImportError.emptyFile
        }

        isProcessing = true
        defer { isProcessing = false }

        var imported = 0
        var skipped = 0
        var errors: [String] = []

        // Get existing tasks for duplicate checking
        let existingTasks = try await vault.fetchAllTasks()
        let existingTitles = Set(existingTasks.map { $0.title.lowercased() })

        for task in previewTasks {
            do {
                // Check for duplicates
                if options.skipDuplicates && existingTitles.contains(task.title.lowercased()) {
                    skipped += 1
                    continue
                }

                // Apply default tags
                if !options.defaultTags.isEmpty {
                    for tag in options.defaultTags {
                        if !task.tags.contains(tag) {
                            task.tags.append(tag)
                        }
                    }
                }

                // Apply default priority if specified
                if let defaultPriority = options.defaultPriority {
                    // Only apply if task has no explicit priority (normal = default)
                    if task.priority == .normal {
                        task.priority = defaultPriority
                    }
                }

                try await vault.createTask(task)
                imported += 1
            } catch {
                errors.append("Failed to import '\(task.title)': \(error.localizedDescription)")
            }
        }

        let result = ImportResult(imported: imported, skipped: skipped, errors: errors)
        importResult = result

        // Log the import
        let sourceName = currentPreview?.source.rawValue ?? "unknown"
        await auditLogger.log(.imported(source: sourceName, taskCount: imported))

        // Clear preview state
        cancelImport()

        return result
    }

    /// Cancels the current import preview
    func cancelImport() {
        previewTasks = []
        currentPreview = nil
    }

    /// Detects the import source based on file content
    func detectSource(from url: URL) -> ImportSource? {
        guard let data = try? Data(contentsOf: url) else { return nil }

        // Try to detect based on content
        if let jsonString = String(data: data, encoding: .utf8) {
            // Check for Time Capsule format markers
            if jsonString.contains("formatVersion") && jsonString.contains("UniversalTaskFormat") ||
               jsonString.contains("\"tasks\"") && jsonString.contains("\"metadata\"") {
                return .timeCapsule
            }

            // Check for Todoist format
            if jsonString.contains("\"items\"") || jsonString.contains("\"content\"") {
                return .todoist
            }
        }

        // Check file extension
        let ext = url.pathExtension.lowercased()
        if ext == "csv" {
            return .csv
        }
        if ext == "json" {
            // Default JSON to Time Capsule
            return .timeCapsule
        }

        return nil
    }
}
