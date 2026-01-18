import Foundation
import SwiftData
import OSLog
import AppKit
import CryptoKit

actor ExportCoordinator {
    private let logger = Logger.export
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Preview Generation

    func generatePreview(options: ExportOptions) async throws -> ExportPreview {
        logger.info("Generating export preview")

        // Fetch data based on options
        let tasks = try await fetchActiveTasks()
        let completedTasks = options.includeCompleted ? try await fetchCompletedTasks() : []
        let archivedTasks = options.includeArchived ? try await fetchArchivedTasks() : []

        let allTasks = tasks + completedTasks + archivedTasks

        // Calculate date range
        let dates = allTasks.map { $0.createdAt }
        let dateRange: ClosedRange<Date>? = if let min = dates.min(), let max = dates.max() {
            min...max
        } else {
            nil
        }

        // Gather tags
        let tags = Set(allTasks.flatMap { $0.tags })

        // Sample tasks
        let sampleTasks = tasks.prefix(5).map { TaskPreview(from: $0) }

        // Estimate size (rough approximation)
        let avgTaskSize = 500 // bytes per task
        let estimatedSize = allTasks.count * avgTaskSize

        return ExportPreview(
            activeCount: tasks.count,
            completedCount: completedTasks.count,
            archivedCount: archivedTasks.count,
            totalCount: allTasks.count,
            dateRange: dateRange,
            estimatedSizeBytes: estimatedSize,
            tags: tags,
            sampleTasks: Array(sampleTasks),
            includesSettings: options.includeSettings
        )
    }

    // MARK: - Main Export Functions

    func export(
        format: ExportFormat,
        options: ExportOptions,
        destination: URL? = nil
    ) async throws -> ExportResult {
        // Track operation start
        let startTime = Date()
        let operationId = await DiagnosticService.shared.trackOperationStart(
            "Export (\(format.rawValue))",
            details: "includeCompleted=\(options.includeCompleted), includeArchived=\(options.includeArchived)"
        )

        logger.info("Starting export: format=\(format.rawValue)")

        do {
            // Fetch data based on options
            let tasks = try await fetchActiveTasks()
            let completedTasks = options.includeCompleted ? try await fetchCompletedTasks() : []
            let archivedTasks = options.includeArchived ? try await fetchArchivedTasks() : []
            let settings = options.includeSettings ? try await fetchSettings() : nil

            // Create export based on format
            let exporter = createExporter(for: format)
            let data = try await exporter.export(
                tasks: tasks,
                completedTasks: completedTasks,
                archivedTasks: archivedTasks,
                settings: settings
            )

            // Generate manifest
            let manifest = ExportManifest(
                format: format,
                exportedAt: Date(),
                taskCount: tasks.count,
                completedTaskCount: completedTasks.count,
                archivedTaskCount: archivedTasks.count,
                includesSettings: options.includeSettings,
                checksum: SHA256.hash(data: data).hexString
            )

            // Determine destination
            let finalDestination: URL
            if let destination = destination {
                finalDestination = destination
            } else {
                finalDestination = try await promptForSaveLocation(
                    suggestedName: generateFileName(format: format),
                    fileType: format.utType
                )
            }

            // Write data
            try data.write(to: finalDestination, options: .atomic)

            // Write manifest alongside (for JSON exports)
            if format == .json || format == .universalTaskFormat {
                let manifestURL = finalDestination.deletingPathExtension()
                    .appendingPathExtension("manifest.json")
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601
                let manifestData = try encoder.encode(manifest)
                try manifestData.write(to: manifestURL, options: .atomic)
            }

            logger.info("Export completed: \(finalDestination.path)")

            // Track operation success
            let duration = Int(Date().timeIntervalSince(startTime) * 1000)
            await DiagnosticService.shared.trackOperationComplete(operationId, durationMs: duration)
            await DiagnosticService.shared.updateLargestExportSize(Int64(data.count))

            return ExportResult(
                success: true,
                destination: finalDestination,
                manifest: manifest,
                exportedAt: Date()
            )
        } catch {
            // Track operation failure
            await DiagnosticService.shared.trackOperationFailed(operationId, error: error)
            throw error
        }
    }

    // MARK: - Format-Specific Exporters

    private func createExporter(for format: ExportFormat) -> any DataExporter {
        switch format {
        case .universalTaskFormat:
            return UniversalTaskFormatExporter()
        case .json:
            return JSONExporter()
        case .csv:
            return CSVExporter()
        case .markdown:
            return MarkdownExporter()
        }
    }

    // MARK: - Data Fetching

    private func fetchActiveTasks() async throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { !$0.isCompleted && !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchCompletedTasks() async throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { $0.isCompleted && !$0.isArchived },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchArchivedTasks() async throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { $0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchSettings() async throws -> AppSettings? {
        let descriptor = FetchDescriptor<AppSettings>()
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Helper Functions

    private func generateFileName(format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        return "TimeCapsule-Export-\(timestamp).\(format.fileExtension)"
    }

    @MainActor
    private func promptForSaveLocation(suggestedName: String, fileType: UTType) async throws -> URL {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Time Capsule Data"
        savePanel.message = "Choose where to save your exported data"
        savePanel.nameFieldStringValue = suggestedName
        savePanel.allowedContentTypes = [fileType]
        savePanel.canCreateDirectories = true

        let response = await savePanel.begin()
        guard response == .OK, let url = savePanel.url else {
            throw ExportError.userCancelled
        }

        return url
    }
}

// MARK: - Export Errors

enum ExportError: LocalizedError {
    case userCancelled
    case noDataToExport
    case invalidFormat
    case encodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Export cancelled by user"
        case .noDataToExport:
            return "No data available to export"
        case .invalidFormat:
            return "Invalid export format specified"
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        }
    }
}
