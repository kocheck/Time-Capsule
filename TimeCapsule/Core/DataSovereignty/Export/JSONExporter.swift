import Foundation

/// Exports tasks to JSON format using UniversalTaskFormat
struct JSONExporter {
    private let encoder: JSONEncoder

    init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    /// Exports tasks to JSON data
    func export(tasks: [TaskItem]) throws -> Data {
        let format = UniversalTaskFormat(tasks: tasks)
        return try encoder.encode(format)
    }

    /// Exports tasks to a JSON file at the specified URL
    func exportToFile(tasks: [TaskItem], url: URL) throws {
        let data = try export(tasks: tasks)
        try data.write(to: url, options: .atomic)
    }

    /// Exports tasks and returns the JSON string
    func exportToString(tasks: [TaskItem]) throws -> String {
        let data = try export(tasks: tasks)
        guard let string = String(data: data, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }
        return string
    }
}

enum ExportError: LocalizedError {
    case encodingFailed
    case fileWriteFailed(URL)
    case directoryCreationFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data"
        case .fileWriteFailed(let url):
            return "Failed to write file to \(url.path)"
        case .directoryCreationFailed:
            return "Failed to create export directory"
        }
    }
}
