import Foundation

/// Parses Todoist JSON exports
struct TodoistImportParser {
    private let decoder: JSONDecoder

    init() {
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    /// Parses Todoist JSON data into TaskItems
    func parse(_ data: Data) throws -> [TaskItem] {
        // Try parsing as Todoist export format
        let todoistExport = try decoder.decode(TodoistExport.self, from: data)

        return todoistExport.items.map { item in
            convertToTaskItem(item)
        }
    }

    /// Converts a Todoist item to a TaskItem
    private func convertToTaskItem(_ item: TodoistItem) -> TaskItem {
        // Map Todoist priority (1=normal, 2=high, 3=urgent, 4=very urgent)
        // to Time Capsule priority (low, normal, high)
        let priority = mapPriority(item.priority)

        let task = TaskItem(
            title: item.content,
            description: item.description,
            tags: item.labels,
            priority: priority
        )

        // Handle completion status
        if item.checked == 1 || item.isCompleted == true {
            task.markCompleted()
        }

        return task
    }

    /// Maps Todoist priority (1-4, where 4 is highest) to TaskPriority
    private func mapPriority(_ todoistPriority: Int) -> TaskPriority {
        // Todoist: 1 = normal, 2 = medium, 3 = high, 4 = urgent
        // Time Capsule: low, normal, high
        switch todoistPriority {
        case 4, 3:
            return .high
        case 2:
            return .normal
        default:
            return .low
        }
    }
}

// MARK: - Todoist Data Models

/// Root structure of a Todoist export
private struct TodoistExport: Codable {
    let items: [TodoistItem]

    // Handle both "items" and "tasks" keys
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let items = try? container.decode([TodoistItem].self, forKey: .items) {
            self.items = items
        } else if let tasks = try? container.decode([TodoistItem].self, forKey: .tasks) {
            self.items = tasks
        } else {
            self.items = []
        }
    }

    enum CodingKeys: String, CodingKey {
        case items
        case tasks
    }
}

/// A single Todoist task item
private struct TodoistItem: Codable {
    let content: String
    let description: String?
    let priority: Int
    let labels: [String]
    let checked: Int?
    let isCompleted: Bool?
    let dateAdded: String?
    let dateCompleted: String?

    enum CodingKeys: String, CodingKey {
        case content
        case description
        case priority
        case labels
        case checked
        case isCompleted = "is_completed"
        case dateAdded = "date_added"
        case dateCompleted = "date_completed"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        content = try container.decode(String.self, forKey: .content)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        priority = try container.decodeIfPresent(Int.self, forKey: .priority) ?? 1
        labels = try container.decodeIfPresent([String].self, forKey: .labels) ?? []
        checked = try container.decodeIfPresent(Int.self, forKey: .checked)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted)
        dateAdded = try container.decodeIfPresent(String.self, forKey: .dateAdded)
        dateCompleted = try container.decodeIfPresent(String.self, forKey: .dateCompleted)
    }
}
