import Foundation

/// Supported import sources
enum ImportSource: String, CaseIterable, Identifiable {
    case timeCapsule = "Time Capsule Export"
    case todoist = "Todoist"
    case csv = "CSV File"

    var id: String { rawValue }

    var fileExtensions: [String] {
        switch self {
        case .timeCapsule: return ["json"]
        case .todoist: return ["json"]
        case .csv: return ["csv"]
        }
    }

    var description: String {
        switch self {
        case .timeCapsule:
            return "Import from a Time Capsule JSON export"
        case .todoist:
            return "Import tasks from Todoist JSON export"
        case .csv:
            return "Import from a CSV file with headers"
        }
    }
}

/// Result of an import operation
struct ImportResult {
    let imported: Int
    let skipped: Int
    let errors: [String]

    var totalProcessed: Int { imported + skipped + errors.count }

    var isSuccess: Bool { errors.isEmpty }

    var summary: String {
        var parts: [String] = []
        if imported > 0 {
            parts.append("\(imported) imported")
        }
        if skipped > 0 {
            parts.append("\(skipped) skipped")
        }
        if !errors.isEmpty {
            parts.append("\(errors.count) errors")
        }
        return parts.joined(separator: ", ")
    }
}

/// Options for import operations
struct ImportOptions {
    var skipDuplicates: Bool = true
    var defaultTags: [String] = []
    var defaultPriority: TaskPriority? = nil
    var overwriteExisting: Bool = false

    static let `default` = ImportOptions()
}

/// Errors that can occur during import
enum ImportError: LocalizedError {
    case invalidFormat(String)
    case checksumMismatch
    case unsupportedVersion(String)
    case parsingFailed(String)
    case fileReadFailed(URL)
    case emptyFile
    case missingRequiredField(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let details):
            return "Invalid file format: \(details)"
        case .checksumMismatch:
            return "Data integrity check failed - file may be corrupted"
        case .unsupportedVersion(let version):
            return "Unsupported format version: \(version)"
        case .parsingFailed(let details):
            return "Failed to parse file: \(details)"
        case .fileReadFailed(let url):
            return "Could not read file: \(url.lastPathComponent)"
        case .emptyFile:
            return "The file contains no tasks"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        }
    }
}

/// A preview of tasks to be imported
struct ImportPreview {
    let tasks: [TaskItem]
    let source: ImportSource
    let warnings: [String]
    let metadata: ImportMetadata?
}

/// Metadata extracted from import file
struct ImportMetadata {
    let formatVersion: String?
    let exportedAt: Date?
    let originalTaskCount: Int
    let sourceApp: String?
}
