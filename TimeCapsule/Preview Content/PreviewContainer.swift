import Foundation
import SwiftData

@MainActor
struct PreviewContainer {
    let container: ModelContainer

    init() {
        let schema = Schema([
            TaskItem.self,
            DailyStats.self,
            AppSettings.self
        ])

        let config = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            container = try ModelContainer(for: schema, configurations: config)

            // Add sample data
            addSampleData()
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }

    private func addSampleData() {
        let context = container.mainContext

        // Sample tasks
        let task1 = TaskItem(
            title: "Review pull requests",
            description: "Check and review pending PRs on GitHub",
            tags: ["work", "code-review"],
            priority: .high
        )

        let task2 = TaskItem(
            title: "Buy groceries",
            description: "Get milk, eggs, bread, and vegetables",
            tags: ["personal", "shopping"],
            priority: .normal
        )

        let task3 = TaskItem(
            title: "Call dentist",
            description: "Schedule regular checkup appointment",
            tags: ["health", "phone-call"],
            priority: .low
        )

        task3.markSkipped()
        task3.markSkipped()

        context.insert(task1)
        context.insert(task2)
        context.insert(task3)

        // Sample stats
        let todayStats = DailyStats(date: Date())
        todayStats.completedCount = 3
        todayStats.skippedCount = 1
        todayStats.createdCount = 5
        todayStats.streak = 7

        context.insert(todayStats)

        // Sample settings
        let settings = AppSettings()
        context.insert(settings)

        try? context.save()
    }
}
