import Foundation
import UniformTypeIdentifiers

// MARK: - Export Format

enum ExportFormat: String, CaseIterable, Identifiable {
    case universalTaskFormat = "Universal Task Format"
    case json = "JSON"
    case csv = "CSV"
    case markdown = "Markdown"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .universalTaskFormat: return "utf.json"
        case .json: return "json"
        case .csv: return "csv"
        case .markdown: return "md"
        }
    }

    var utType: UTType {
        switch self {
        case .universalTaskFormat, .json: return .json
        case .csv: return .commaSeparatedText
        case .markdown: return .plainText
        }
    }

    var description: String {
        switch self {
        case .universalTaskFormat:
            return "Complete export in Time Capsule's open format. Best for backup and migration."
        case .json:
            return "Standard JSON format. Good for developers and data analysis."
        case .csv:
            return "Spreadsheet-compatible format. Open in Excel, Numbers, or Google Sheets."
        case .markdown:
            return "Human-readable format. Great for documentation or printing."
        }
    }

    var icon: String {
        switch self {
        case .universalTaskFormat: return "shippingbox"
        case .json: return "curlybraces"
        case .csv: return "tablecells"
        case .markdown: return "doc.text"
        }
    }
}

// MARK: - Export Options

struct ExportOptions: Codable {
    var includeCompleted: Bool
    var includeArchived: Bool
    var includeSettings: Bool

    static var minimal: ExportOptions {
        ExportOptions(
            includeCompleted: false,
            includeArchived: false,
            includeSettings: false
        )
    }

    static var complete: ExportOptions {
        ExportOptions(
            includeCompleted: true,
            includeArchived: true,
            includeSettings: true
        )
    }
}

// MARK: - Export Result

struct ExportResult {
    let success: Bool
    let destination: URL
    let manifest: ExportManifest
    let exportedAt: Date
}

// MARK: - Export Manifest

struct ExportManifest: Codable {
    let format: String
    let exportedAt: Date
    let taskCount: Int
    let completedTaskCount: Int
    let archivedTaskCount: Int
    let includesSettings: Bool
    let checksum: String

    init(
        format: ExportFormat,
        exportedAt: Date,
        taskCount: Int,
        completedTaskCount: Int,
        archivedTaskCount: Int,
        includesSettings: Bool,
        checksum: String
    ) {
        self.format = format.rawValue
        self.exportedAt = exportedAt
        self.taskCount = taskCount
        self.completedTaskCount = completedTaskCount
        self.archivedTaskCount = archivedTaskCount
        self.includesSettings = includesSettings
        self.checksum = checksum
    }
}

// MARK: - Data Exporter Protocol

protocol DataExporter {
    func export(tasks: [TaskItem], completedTasks: [TaskItem], archivedTasks: [TaskItem], settings: AppSettings?) async throws -> Data
}
