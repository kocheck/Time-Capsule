import Foundation

struct TaskContext: Codable, Sendable {
    let currentHour: Int
    let currentMinute: Int
    let dayOfWeek: Int
    let dayOfWeekName: String
    let isWeekend: Bool
    let recentlyCompletedTags: [String]
    let recentlySkippedTaskIds: [String]
    let candidateTasks: [TaskSummary]

    init(
        date: Date = Date(),
        recentlyCompletedTags: [String] = [],
        recentlySkippedTaskIds: [String] = [],
        candidateTasks: [TaskSummary] = []
    ) {
        let calendar = Calendar.current
        self.currentHour = calendar.component(.hour, from: date)
        self.currentMinute = calendar.component(.minute, from: date)
        self.dayOfWeek = calendar.component(.weekday, from: date)

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        self.dayOfWeekName = formatter.string(from: date)

        self.isWeekend = self.dayOfWeek == 1 || self.dayOfWeek == 7
        self.recentlyCompletedTags = recentlyCompletedTags
        self.recentlySkippedTaskIds = recentlySkippedTaskIds
        self.candidateTasks = candidateTasks
    }
}

struct TaskSummary: Codable, Sendable, Identifiable {
    let id: String
    let title: String
    let tags: [String]
    let priority: String
    let daysSinceCreation: Int
    let skipCount: Int
    let contextHints: [String]

    init(from task: TaskItem) {
        self.id = task.id.uuidString
        self.title = task.title
        self.tags = task.tags
        self.priority = task.priority.rawValue
        self.daysSinceCreation = task.daysSinceCreation
        self.skipCount = task.skipCount
        self.contextHints = task.contextHints
    }
}
