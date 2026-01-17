import Foundation

/// Available export formats
enum ExportFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case csv = "CSV"
    case markdown = "Markdown"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .markdown: return "md"
        }
    }

    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        case .markdown: return "text/markdown"
        }
    }

    var displayDescription: String {
        switch self {
        case .json: return "Universal Task Format (machine-readable)"
        case .csv: return "Spreadsheet compatible"
        case .markdown: return "Human-readable document"
        }
    }
}

/// Options for export operations
struct ExportOptions {
    var includeCompleted: Bool = true
    var includeArchived: Bool = false
    var filterTags: [String]? = nil
    var dateRange: DateRange? = nil
}

/// Coordinates export operations across formats
@Observable
class ExportCoordinator {
    private let vault: DataVaultManager
    private let auditLogger: AuditLogger

    private let jsonExporter = JSONExporter()
    private let csvExporter = CSVExporter()
    private let markdownExporter = MarkdownExporter()

    var isExporting = false
    var lastExportURL: URL?
    var lastError: Error?

    init(vault: DataVaultManager, auditLogger: AuditLogger) {
        self.vault = vault
        self.auditLogger = auditLogger
    }

    /// Exports tasks in the specified format
    @MainActor
    func export(format: ExportFormat, options: ExportOptions = ExportOptions()) async throws -> URL {
        isExporting = true
        lastError = nil

        defer { isExporting = false }

        // Fetch tasks based on options
        let tasks = try await fetchTasksForExport(options: options)

        // Create export directory
        let exportDir = try createExportDirectory()

        // Generate filename
        let dateString = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let filename = "TimeCapsule_Export_\(dateString).\(format.fileExtension)"
        let fileURL = exportDir.appendingPathComponent(filename)

        // Export based on format
        switch format {
        case .json:
            try jsonExporter.exportToFile(tasks: tasks, url: fileURL)
        case .csv:
            try csvExporter.exportToFile(tasks: tasks, url: fileURL)
        case .markdown:
            try markdownExporter.exportToFile(tasks: tasks, url: fileURL)
        }

        // Log the export
        await auditLogger.log(.exported(format: format.rawValue, taskCount: tasks.count))

        lastExportURL = fileURL
        return fileURL
    }

    /// Exports all tasks in all formats to a folder
    @MainActor
    func exportAll(options: ExportOptions = ExportOptions()) async throws -> URL {
        isExporting = true
        lastError = nil

        defer { isExporting = false }

        let tasks = try await fetchTasksForExport(options: options)

        // Create export folder
        let dateString = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let exportDir = try createExportDirectory()
        let bundleDir = exportDir.appendingPathComponent("TimeCapsule_Export_\(dateString)")

        try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)

        // Export in all formats
        for format in ExportFormat.allCases {
            let filename = "tasks.\(format.fileExtension)"
            let fileURL = bundleDir.appendingPathComponent(filename)

            switch format {
            case .json:
                try jsonExporter.exportToFile(tasks: tasks, url: fileURL)
            case .csv:
                try csvExporter.exportToFile(tasks: tasks, url: fileURL)
            case .markdown:
                try markdownExporter.exportToFile(tasks: tasks, url: fileURL)
            }
        }

        // Log the export
        await auditLogger.log(.exported(format: "all", taskCount: tasks.count))

        lastExportURL = bundleDir
        return bundleDir
    }

    /// Returns the export data without writing to file
    func getExportData(format: ExportFormat, options: ExportOptions = ExportOptions()) async throws -> Data {
        let tasks = try await fetchTasksForExport(options: options)

        switch format {
        case .json:
            return try jsonExporter.export(tasks: tasks)
        case .csv:
            let csv = csvExporter.export(tasks: tasks)
            return csv.data(using: .utf8) ?? Data()
        case .markdown:
            let md = markdownExporter.export(tasks: tasks)
            return md.data(using: .utf8) ?? Data()
        }
    }

    // MARK: - Private Helpers

    private func fetchTasksForExport(options: ExportOptions) async throws -> [TaskItem] {
        var tasks = try await vault.fetchAllTasks()

        // Filter by completion status
        if !options.includeCompleted {
            tasks = tasks.filter { !$0.isCompleted }
        }

        if !options.includeArchived {
            tasks = tasks.filter { !$0.isArchived }
        }

        // Filter by tags
        if let filterTags = options.filterTags, !filterTags.isEmpty {
            tasks = tasks.filter { task in
                task.tags.contains { filterTags.contains($0) }
            }
        }

        // Filter by date range
        if let range = options.dateRange {
            tasks = tasks.filter { task in
                task.createdAt >= range.start && task.createdAt <= range.end
            }
        }

        return tasks
    }

    private func createExportDirectory() throws -> URL {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let exportDir = documentsURL.appendingPathComponent("TimeCapsuleExports")

        if !fileManager.fileExists(atPath: exportDir.path) {
            try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
        }

        return exportDir
    }
}
