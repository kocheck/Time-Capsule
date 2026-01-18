import Foundation
import OSLog

struct TodoistImportParser: ImportParser {
    private let logger = Logger.importLogger

    func parse(_ data: Data) async throws -> [ImportedTask] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let todoistExport = try decoder.decode(TodoistExport.self, from: data)

        var importedTasks: [ImportedTask] = []

        for project in todoistExport.projects {
            for item in project.items {
                let priority = mapTodoistPriority(item.priority)

                let task = ImportedTask(
                    sourceId: String(item.id),
                    sourceSystem: "todoist",
                    title: item.content,
                    description: item.description,
                    tags: item.labels + [project.name],  // Add project as tag
                    priority: priority,
                    createdAt: item.dateAdded,
                    completedAt: item.dateCompleted
                )
                importedTasks.append(task)
            }
        }

        logger.info("Imported \(importedTasks.count) tasks from Todoist")
        return importedTasks
    }

    private func mapTodoistPriority(_ todoistPriority: Int) -> TaskPriority {
        // Todoist: 1 = highest, 4 = lowest (inverted)
        switch todoistPriority {
        case 1: return .high
        case 2, 3: return .normal
        default: return .low
        }
    }
}

// MARK: - Todoist Data Structures

private struct TodoistExport: Codable {
    let projects: [TodoistProject]
}

private struct TodoistProject: Codable {
    let id: Int
    let name: String
    let items: [TodoistItem]
}

private struct TodoistItem: Codable {
    let id: Int
    let content: String
    let description: String?
    let priority: Int
    let labels: [String]
    let checked: Bool
    let dateAdded: Date
    let dateCompleted: Date?

    enum CodingKeys: String, CodingKey {
        case id, content, description, priority, labels, checked
        case dateAdded = "date_added"
        case dateCompleted = "date_completed"
    }
}
