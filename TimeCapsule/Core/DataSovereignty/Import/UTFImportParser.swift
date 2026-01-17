import Foundation

/// Parses Time Capsule's Universal Task Format exports
struct UTFImportParser {
    private let decoder: JSONDecoder

    init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Parses UTF JSON data into TaskItems
    func parse(_ data: Data) throws -> [TaskItem] {
        let format = try decoder.decode(UniversalTaskFormat.self, from: data)

        // Validate checksum
        guard format.validateChecksum() else {
            throw ImportError.checksumMismatch
        }

        // Convert UTFTasks to TaskItems
        return format.tasks.map { $0.toTaskItem() }
    }

    /// Validates the data without fully parsing
    func validate(_ data: Data) throws -> Bool {
        let format = try decoder.decode(UniversalTaskFormat.self, from: data)
        return format.validateChecksum()
    }

    /// Extracts metadata from the export without parsing all tasks
    func extractMetadata(_ data: Data) throws -> ImportMetadata {
        let format = try decoder.decode(UniversalTaskFormat.self, from: data)

        return ImportMetadata(
            formatVersion: format.formatVersion,
            exportedAt: format.exportedAt,
            originalTaskCount: format.tasks.count,
            sourceApp: "Time Capsule v\(format.appVersion)"
        )
    }

    /// Parses and returns the full UniversalTaskFormat for inspection
    func parseFormat(_ data: Data) throws -> UniversalTaskFormat {
        return try decoder.decode(UniversalTaskFormat.self, from: data)
    }
}
