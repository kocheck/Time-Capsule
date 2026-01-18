import Foundation
import OSLog

struct CSVImportParser: ImportParser {
    private let logger = Logger.importLogger

    func parse(_ data: Data) async throws -> [ImportedTask] {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ImportErrorType.invalidFormat
        }

        let lines = csvString.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw ImportErrorType.invalidFormat
        }

        // Skip header row
        let dataLines = lines.dropFirst().filter { !$0.isEmpty }

        var importedTasks: [ImportedTask] = []
        let dateFormatter = ISO8601DateFormatter()

        for line in dataLines {
            let fields = parseCSVLine(line)
            guard fields.count >= 9 else { continue }

            let id = fields[0]
            let title = fields[1]
            let description = fields[2].isEmpty ? nil : fields[2]
            let tags = fields[3].split(separator: ";").map { String($0) }
            let priority = TaskPriority(rawValue: fields[4]) ?? .normal
            let createdAt = dateFormatter.date(from: fields[5]) ?? Date()
            let completedAt = fields[6].isEmpty ? nil : dateFormatter.date(from: fields[6])

            let task = ImportedTask(
                sourceId: id,
                sourceSystem: "CSV",
                title: title,
                description: description,
                tags: tags,
                priority: priority,
                createdAt: createdAt,
                completedAt: completedAt
            )
            importedTasks.append(task)
        }

        logger.info("Parsed \(importedTasks.count) tasks from CSV")
        return importedTasks
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        fields.append(currentField)

        return fields.map { $0.replacingOccurrences(of: "\"\"", with: "\"") }
    }
}
