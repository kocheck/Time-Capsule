import Foundation

// MARK: - Import Source

enum ImportSource: String, CaseIterable, Identifiable {
    case universalTaskFormat = "Time Capsule Export"
    case json = "JSON File"
    case csv = "CSV File"
    case todoist = "Todoist"
    case things3 = "Things 3"
    case reminders = "Apple Reminders"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .universalTaskFormat: return "shippingbox"
        case .json: return "curlybraces"
        case .csv: return "tablecells"
        case .todoist: return "checkmark.circle"
        case .things3: return "star.circle"
        case .reminders: return "list.bullet"
        }
    }

    var exportInstructions: String {
        switch self {
        case .todoist:
            return """
            To export from Todoist:
            1. Go to todoist.com/settings/general
            2. Scroll to "Export"
            3. Click "Export as template"
            4. Save the JSON file
            """
        case .things3:
            return """
            To export from Things 3:
            1. Select the tasks you want to export
            2. Go to File → Export as JSON
            3. Save the file
            """
        case .reminders:
            return """
            Time Capsule can import directly from Apple Reminders.
            Click "Connect to Reminders" and grant permission.
            """
        default:
            return "Select your export file to begin import."
        }
    }
}

// MARK: - Import Options

struct ImportOptions {
    var conflictStrategy: ConflictStrategy
    var preserveIds: Bool

    init(conflictStrategy: ConflictStrategy = .keepBoth, preserveIds: Bool = false) {
        self.conflictStrategy = conflictStrategy
        self.preserveIds = preserveIds
    }
}

enum ConflictStrategy: String, CaseIterable {
    case keepBoth = "Keep Both"
    case replaceExisting = "Replace Existing"
    case skipDuplicates = "Skip Duplicates"
}

// MARK: - Import Result

struct ImportResult {
    let success: Bool
    let importedCount: Int
    let skippedCount: Int
    let errors: [ImportError]

    init(success: Bool, importedCount: Int, skippedCount: Int, errors: [ImportError] = []) {
        self.success = success
        self.importedCount = importedCount
        self.skippedCount = skippedCount
        self.errors = errors
    }
}

struct ImportError: Identifiable {
    let id = UUID()
    let taskTitle: String
    let errorMessage: String
}

// MARK: - Import Parser Protocol

protocol ImportParser {
    func parse(_ data: Data) async throws -> [ImportedTask]
}

// MARK: - Imported Task

struct ImportedTask {
    let sourceId: String
    let sourceSystem: String
    let title: String
    let description: String?
    let tags: [String]
    let priority: TaskPriority
    let createdAt: Date
    let completedAt: Date?

    func toTaskItem() -> TaskItem {
        let task = TaskItem(
            title: title,
            description: description,
            tags: tags,
            priority: priority
        )
        task.createdAt = createdAt
        task.completedAt = completedAt
        return task
    }
}
