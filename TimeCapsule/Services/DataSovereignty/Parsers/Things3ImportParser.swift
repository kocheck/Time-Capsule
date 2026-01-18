import Foundation
import OSLog

struct Things3ImportParser: ImportParser {
    private let logger = Logger.importLogger

    func parse(_ data: Data) async throws -> [ImportedTask] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let things3Export = try decoder.decode(Things3Export.self, from: data)

        var importedTasks: [ImportedTask] = []

        for item in things3Export.items {
            guard item.type == "to-do" else { continue }

            var tags = item.tags
            if let project = item.project {
                tags.append(project)
            }
            if let area = item.area {
                tags.append(area)
            }

            let task = ImportedTask(
                sourceId: item.uuid,
                sourceSystem: "things3",
                title: item.title,
                description: item.notes,
                tags: tags,
                priority: .normal,  // Things 3 doesn't have explicit priorities
                createdAt: item.createdDate ?? Date(),
                completedAt: item.completed ? (item.completionDate ?? Date()) : nil
            )
            importedTasks.append(task)
        }

        logger.info("Imported \(importedTasks.count) tasks from Things 3")
        return importedTasks
    }
}

// MARK: - Things 3 Data Structures

private struct Things3Export: Codable {
    let items: [Things3Item]
}

private struct Things3Item: Codable {
    let uuid: String
    let type: String
    let title: String
    let notes: String?
    let tags: [String]
    let completed: Bool
    let project: String?
    let area: String?
    let createdDate: Date?
    let completionDate: Date?

    enum CodingKeys: String, CodingKey {
        case uuid, type, title, notes, tags, completed, project, area
        case createdDate = "created"
        case completionDate = "completed"
    }
}
