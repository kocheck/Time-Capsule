import Foundation
import CryptoKit

/// Universal Task Format - Time Capsule's open data interchange format
/// Version: 1.0.0
///
/// This format is designed to be:
/// - Human-readable (JSON)
/// - Self-documenting (includes schema)
/// - Forward-compatible (versioned)
/// - Complete (captures all task data)
/// - Interoperable (maps to other tools)

struct UniversalTaskFormat: Codable {
    static let currentVersion = "1.0.0"
    static let formatIdentifier = "com.timecapsule.utf"

    // MARK: - Metadata
    let formatVersion: String
    let formatIdentifier: String
    let exportedAt: Date
    let exportedFrom: ExportSource
    let checksum: String

    // MARK: - Content
    let tasks: [UTFTask]
    let completedTasks: [UTFTask]
    let archivedTasks: [UTFTask]
    let settings: UTFSettings?

    // MARK: - Schema
    let schema: UTFSchema

    init(tasks: [UTFTask], completedTasks: [UTFTask], archivedTasks: [UTFTask], settings: UTFSettings?) throws {
        self.formatVersion = Self.currentVersion
        self.formatIdentifier = Self.formatIdentifier
        self.exportedAt = Date()
        self.exportedFrom = ExportSource(
            appName: "Time Capsule",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            platform: "macOS",
            platformVersion: ProcessInfo.processInfo.operatingSystemVersionString
        )

        self.tasks = tasks
        self.completedTasks = completedTasks
        self.archivedTasks = archivedTasks
        self.settings = settings

        self.schema = UTFSchema.current

        // Calculate checksum
        var tempFormat = UniversalTaskFormat(
            formatVersion: formatVersion,
            formatIdentifier: formatIdentifier,
            exportedAt: exportedAt,
            exportedFrom: exportedFrom,
            checksum: "",
            tasks: tasks,
            completedTasks: completedTasks,
            archivedTasks: archivedTasks,
            settings: settings,
            schema: schema
        )
        self.checksum = try Self.calculateChecksum(&tempFormat)
    }

    private init(
        formatVersion: String,
        formatIdentifier: String,
        exportedAt: Date,
        exportedFrom: ExportSource,
        checksum: String,
        tasks: [UTFTask],
        completedTasks: [UTFTask],
        archivedTasks: [UTFTask],
        settings: UTFSettings?,
        schema: UTFSchema
    ) {
        self.formatVersion = formatVersion
        self.formatIdentifier = formatIdentifier
        self.exportedAt = exportedAt
        self.exportedFrom = exportedFrom
        self.checksum = checksum
        self.tasks = tasks
        self.completedTasks = completedTasks
        self.archivedTasks = archivedTasks
        self.settings = settings
        self.schema = schema
    }

    private static func calculateChecksum(_ format: inout UniversalTaskFormat) throws -> String {
        format.checksum = ""
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(format)
        return SHA256.hash(data: data).hexString
    }
}

// MARK: - Export Source

struct ExportSource: Codable {
    let appName: String
    let appVersion: String
    let platform: String
    let platformVersion: String
}

// MARK: - UTF Task

struct UTFTask: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let tags: [String]
    let priority: String
    let createdAt: Date
    let completedAt: Date?
    let skipCount: Int
    let dailySkipCount: Int
    let lastSkippedAt: Date?
    let lastPresentedAt: Date?
    let isArchived: Bool
    let contextHints: [String]

    // Mapping metadata for import/export
    let sourceSystem: String?
    let sourceId: String?

    init(from task: TaskItem) {
        self.id = task.id.uuidString
        self.title = task.title
        self.description = task.taskDescription
        self.tags = task.tags
        self.priority = task.priority.rawValue
        self.createdAt = task.createdAt
        self.completedAt = task.completedAt
        self.skipCount = task.skipCount
        self.dailySkipCount = task.dailySkipCount
        self.lastSkippedAt = task.lastSkippedAt
        self.lastPresentedAt = task.lastPresentedAt
        self.isArchived = task.isArchived
        self.contextHints = task.contextHints
        self.sourceSystem = "TimeCapsule"
        self.sourceId = task.id.uuidString
    }

    func toTaskItem() -> TaskItem {
        let priority = TaskPriority(rawValue: self.priority) ?? .normal
        let task = TaskItem(
            title: title,
            description: description,
            tags: tags,
            priority: priority
        )
        task.id = UUID(uuidString: id) ?? UUID()
        task.createdAt = createdAt
        task.completedAt = completedAt
        task.skipCount = skipCount
        task.dailySkipCount = dailySkipCount
        task.lastSkippedAt = lastSkippedAt
        task.lastPresentedAt = lastPresentedAt
        task.isArchived = isArchived
        task.contextHints = contextHints
        return task
    }
}

// MARK: - UTF Settings

struct UTFSettings: Codable {
    let aiProvider: String
    let ollamaEndpoint: String
    let ollamaModel: String
    let showBadgeCount: Bool
    let skipThreshold: Int
    let staleTaskDays: Int
    let showDailyNotification: Bool
    let dailyNotificationHour: Int
    let dailyNotificationMinute: Int
    let theme: String

    init(from settings: AppSettings) {
        self.aiProvider = settings.aiProvider.rawValue
        self.ollamaEndpoint = settings.ollamaEndpoint
        self.ollamaModel = settings.ollamaModel
        self.showBadgeCount = settings.showBadgeCount
        self.skipThreshold = settings.skipThreshold
        self.staleTaskDays = settings.staleTaskDays
        self.showDailyNotification = settings.showDailyNotification
        self.dailyNotificationHour = settings.dailyNotificationHour
        self.dailyNotificationMinute = settings.dailyNotificationMinute
        self.theme = settings.theme.rawValue
    }
}

// MARK: - UTF Schema

struct UTFSchema: Codable {
    let version: String
    let entities: [UTFEntitySchema]
    let documentation: String

    static var current: UTFSchema {
        UTFSchema(
            version: UniversalTaskFormat.currentVersion,
            entities: [
                UTFEntitySchema(
                    name: "Task",
                    description: "A task or todo item",
                    fields: [
                        UTFFieldSchema(name: "id", type: "string", required: true, description: "Unique identifier (UUID)"),
                        UTFFieldSchema(name: "title", type: "string", required: true, description: "Task title"),
                        UTFFieldSchema(name: "description", type: "string", required: false, description: "Detailed description"),
                        UTFFieldSchema(name: "tags", type: "[string]", required: false, description: "Categorization tags"),
                        UTFFieldSchema(name: "priority", type: "enum(low,normal,high)", required: true, description: "Task priority"),
                        UTFFieldSchema(name: "createdAt", type: "datetime", required: true, description: "Creation timestamp (ISO 8601)"),
                        UTFFieldSchema(name: "completedAt", type: "datetime", required: false, description: "Completion timestamp"),
                        UTFFieldSchema(name: "skipCount", type: "integer", required: true, description: "Number of times skipped"),
                        UTFFieldSchema(name: "dailySkipCount", type: "integer", required: true, description: "Daily skip count"),
                        UTFFieldSchema(name: "isArchived", type: "boolean", required: true, description: "Archive status"),
                        UTFFieldSchema(name: "contextHints", type: "[string]", required: false, description: "AI-generated context hints")
                    ]
                )
            ],
            documentation: "https://timecapsule.app/docs/data-format"
        )
    }
}

struct UTFEntitySchema: Codable {
    let name: String
    let description: String
    let fields: [UTFFieldSchema]
}

struct UTFFieldSchema: Codable {
    let name: String
    let type: String
    let required: Bool
    let description: String
}

// MARK: - Crypto Extensions

extension Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
