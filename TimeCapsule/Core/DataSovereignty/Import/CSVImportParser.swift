import Foundation

/// Parses CSV files into TaskItems
/// Expected columns: title, description, tags (semicolon-separated), priority, status
struct CSVImportParser {

    /// Parses a CSV string into TaskItems
    func parse(_ csvString: String, hasHeader: Bool = true) throws -> [TaskItem] {
        let lines = csvString.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard !lines.isEmpty else {
            throw ImportError.emptyFile
        }

        var startIndex = 0
        var columnMap: [String: Int] = [:]

        if hasHeader {
            let headerLine = lines[0]
            let headers = parseCSVLine(headerLine).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

            for (index, header) in headers.enumerated() {
                columnMap[header] = index
            }

            startIndex = 1
        } else {
            // Default column order: title, description, tags, priority, status
            columnMap = ["title": 0, "description": 1, "tags": 2, "priority": 3, "status": 4]
        }

        // Verify required column exists
        guard columnMap["title"] != nil else {
            throw ImportError.missingRequiredField("title")
        }

        var tasks: [TaskItem] = []

        for lineIndex in startIndex..<lines.count {
            let line = lines[lineIndex]
            let values = parseCSVLine(line)

            guard !values.isEmpty else { continue }

            if let task = try? parseRow(values: values, columnMap: columnMap) {
                tasks.append(task)
            }
        }

        return tasks
    }

    /// Parses a single CSV row into a TaskItem
    private func parseRow(values: [String], columnMap: [String: Int]) throws -> TaskItem {
        func getValue(_ key: String) -> String? {
            guard let index = columnMap[key], index < values.count else { return nil }
            let value = values[index].trimmingCharacters(in: .whitespaces)
            return value.isEmpty ? nil : value
        }

        guard let title = getValue("title"), !title.isEmpty else {
            throw ImportError.missingRequiredField("title")
        }

        let description = getValue("description")

        // Parse tags (semicolon-separated)
        let tagsString = getValue("tags") ?? ""
        let tags = tagsString.components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Parse priority
        let priorityString = getValue("priority")?.lowercased() ?? "normal"
        let priority = parsePriority(priorityString)

        // Parse status
        let statusString = getValue("status")?.lowercased() ?? "pending"

        let task = TaskItem(
            title: title,
            description: description,
            tags: tags,
            priority: priority
        )

        // Handle completion status
        if statusString == "completed" || statusString == "done" || statusString == "complete" {
            task.markCompleted()
        } else if statusString == "archived" {
            task.archive()
        }

        return task
    }

    /// Parses a CSV line handling quoted values
    private func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                values.append(currentValue)
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }

        values.append(currentValue)
        return values
    }

    /// Parses a priority string to TaskPriority
    private func parsePriority(_ string: String) -> TaskPriority {
        switch string.lowercased() {
        case "high", "urgent", "3", "p1":
            return .high
        case "low", "1", "p3":
            return .low
        default:
            return .normal
        }
    }
}
