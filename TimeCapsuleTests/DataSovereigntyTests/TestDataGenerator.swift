import Foundation
@testable import TimeCapsule

/// Generates realistic test data for data sovereignty tests
struct TestDataGenerator {

    // MARK: - Task Generation

    /// Generates a single task with random but realistic data
    static func generateTask(
        priority: TaskPriority? = nil,
        isCompleted: Bool = false,
        tags: [String]? = nil
    ) -> TaskItem {
        let task = TaskItem(
            title: randomTitle(),
            description: randomDescription(),
            tags: tags ?? randomTags(),
            priority: priority ?? randomPriority()
        )

        task.createdAt = randomPastDate(daysAgo: 30)

        if isCompleted {
            task.isCompleted = true
            task.completedAt = randomPastDate(daysAgo: 15)
        }

        return task
    }

    /// Generates a batch of tasks with varied characteristics
    static func generateTasks(count: Int) -> [TaskItem] {
        (0..<count).map { _ in
            let isCompleted = Bool.random()
            return generateTask(isCompleted: isCompleted)
        }
    }

    /// Generates a dataset with specific distribution
    static func generateDataset(
        active: Int = 10,
        completed: Int = 5,
        highPriority: Int = 3,
        withTags: Bool = true
    ) -> [TaskItem] {
        var tasks: [TaskItem] = []

        // Active tasks
        for _ in 0..<active {
            tasks.append(generateTask(isCompleted: false))
        }

        // Completed tasks
        for _ in 0..<completed {
            tasks.append(generateTask(isCompleted: true))
        }

        // High priority tasks
        for _ in 0..<highPriority {
            tasks.append(generateTask(priority: .high, isCompleted: false))
        }

        return tasks
    }

    /// Generates a large dataset for performance testing
    static func generateLargeDataset(size: DatasetSize = .medium) -> [TaskItem] {
        let count: Int
        switch size {
        case .small:
            count = 50
        case .medium:
            count = 500
        case .large:
            count = 2000
        case .extraLarge:
            count = 10000
        }

        return generateTasks(count: count)
    }

    // MARK: - Edge Case Data

    /// Generates tasks with edge case characteristics
    static func generateEdgeCaseTasks() -> [TaskItem] {
        var tasks: [TaskItem] = []

        // Empty title
        let emptyTitle = TaskItem(title: "", description: "Task with empty title", tags: [], priority: .medium)
        tasks.append(emptyTitle)

        // Very long title
        let longTitle = TaskItem(
            title: String(repeating: "Very long title ", count: 50),
            description: "Task with very long title",
            tags: [],
            priority: .medium
        )
        tasks.append(longTitle)

        // Very long description
        let longDesc = TaskItem(
            title: "Task with long description",
            description: String(repeating: "Lorem ipsum dolor sit amet. ", count: 100),
            tags: [],
            priority: .medium
        )
        tasks.append(longDesc)

        // Many tags
        let manyTags = TaskItem(
            title: "Task with many tags",
            description: "Testing tag handling",
            tags: (1...50).map { "tag\($0)" },
            priority: .medium
        )
        tasks.append(manyTags)

        // Special characters in title
        let specialChars = TaskItem(
            title: "Task with special chars: 你好 🎉 €£¥ <>&\"'",
            description: "Testing Unicode and special characters",
            tags: ["unicode", "special-chars"],
            priority: .medium
        )
        tasks.append(specialChars)

        // Future dates (should not happen in normal usage)
        let futureDate = TaskItem(
            title: "Task with future date",
            description: "Testing date handling",
            tags: [],
            priority: .medium
        )
        futureDate.createdAt = Date().addingTimeInterval(86400 * 30) // 30 days in future
        tasks.append(futureDate)

        return tasks
    }

    // MARK: - Malformed Data

    /// Generates JSON data with various malformations for import testing
    static func generateMalformedJSON() -> [String: Data] {
        var datasets: [String: Data] = [:]

        // Invalid JSON syntax
        datasets["invalid_syntax"] = "{broken json".data(using: .utf8)!

        // Missing required fields
        datasets["missing_fields"] = """
        {
            "tasks": [
                {"description": "No title field"}
            ]
        }
        """.data(using: .utf8)!

        // Wrong data types
        datasets["wrong_types"] = """
        {
            "tasks": [
                {
                    "title": 123,
                    "priority": "not-a-priority",
                    "tags": "should-be-array"
                }
            ]
        }
        """.data(using: .utf8)!

        // Empty document
        datasets["empty"] = Data()

        // Null values
        datasets["null_values"] = """
        {
            "tasks": [
                {
                    "title": null,
                    "description": null,
                    "tags": null
                }
            ]
        }
        """.data(using: .utf8)!

        return datasets
    }

    // MARK: - Helper Data

    private static let sampleTitles = [
        "Review project proposal",
        "Update documentation",
        "Fix critical bug in production",
        "Schedule team meeting",
        "Research new technologies",
        "Write unit tests",
        "Optimize database queries",
        "Deploy to staging environment",
        "Code review for PR #123",
        "Refactor authentication module",
        "Update dependencies",
        "Create API documentation",
        "Design new feature",
        "Analyze performance metrics",
        "Backup production database"
    ]

    private static let sampleDescriptions = [
        "Need to complete this by end of week",
        "This is a high priority item",
        "Follow up with the team about requirements",
        "Make sure to test thoroughly before deploying",
        "Consider performance implications",
        nil,
        "Low priority, can be done later",
        "Blocked by another task",
        "Waiting for client feedback"
    ]

    private static let sampleTags = [
        ["work", "urgent"],
        ["personal"],
        ["project-alpha", "backend"],
        ["frontend", "ui"],
        ["bug", "critical"],
        ["enhancement"],
        ["documentation"],
        ["testing"],
        ["deployment"],
        []
    ]

    private static func randomTitle() -> String {
        sampleTitles.randomElement() ?? "Task \(Int.random(in: 1...1000))"
    }

    private static func randomDescription() -> String? {
        sampleDescriptions.randomElement() ?? nil
    }

    private static func randomTags() -> [String] {
        sampleTags.randomElement() ?? []
    }

    private static func randomPriority() -> TaskPriority {
        TaskPriority.allCases.randomElement() ?? .medium
    }

    private static func randomPastDate(daysAgo: Int) -> Date {
        let randomDays = Int.random(in: 0...daysAgo)
        return Date().addingTimeInterval(-Double(randomDays * 86400))
    }
}

// MARK: - Dataset Size

enum DatasetSize {
    case small      // 50 tasks
    case medium     // 500 tasks
    case large      // 2,000 tasks
    case extraLarge // 10,000 tasks
}
