import Foundation

struct WeeklyContext: Codable, Sendable {
    let weekStartDate: Date
    let weekEndDate: Date
    let dailyStats: [DailyStatsSummary]
    let completedTasks: [CompletedTaskSummary]
    let staleTasks: [StaleTaskSummary]
    let currentStreak: Int
    let previousWeekCompletionRate: Double

    init(
        weekStartDate: Date,
        dailyStats: [DailyStatsSummary] = [],
        completedTasks: [CompletedTaskSummary] = [],
        staleTasks: [StaleTaskSummary] = [],
        currentStreak: Int = 0,
        previousWeekCompletionRate: Double = 0
    ) {
        self.weekStartDate = weekStartDate
        self.weekEndDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        self.dailyStats = dailyStats
        self.completedTasks = completedTasks
        self.staleTasks = staleTasks
        self.currentStreak = currentStreak
        self.previousWeekCompletionRate = previousWeekCompletionRate
    }

    var totalCompleted: Int {
        dailyStats.reduce(0) { $0 + $1.completedCount }
    }

    var totalSkipped: Int {
        dailyStats.reduce(0) { $0 + $1.skippedCount }
    }

    var totalCreated: Int {
        dailyStats.reduce(0) { $0 + $1.createdCount }
    }

    var averageCompletionRate: Double {
        guard !dailyStats.isEmpty else { return 0 }
        let totalRate = dailyStats.reduce(0.0) { $0 + $1.completionRate }
        return totalRate / Double(dailyStats.count)
    }

    var mostProductiveDay: String? {
        dailyStats.max(by: { $0.completedCount < $1.completedCount })?.dayName
    }

    var mostSkippedDay: String? {
        dailyStats.max(by: { $0.skippedCount < $1.skippedCount })?.dayName
    }

    var topTags: [String] {
        var tagCounts: [String: Int] = [:]
        for task in completedTasks {
            for tag in task.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        return tagCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
}

struct DailyStatsSummary: Codable, Sendable {
    let date: Date
    let dayName: String
    let completedCount: Int
    let skippedCount: Int
    let createdCount: Int
    let completionRate: Double

    init(from stats: DailyStats) {
        self.date = stats.date
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        self.dayName = formatter.string(from: stats.date)
        self.completedCount = stats.completedCount
        self.skippedCount = stats.skippedCount
        self.createdCount = stats.createdCount
        self.completionRate = stats.completionRate
    }
}

struct CompletedTaskSummary: Codable, Sendable {
    let id: String
    let title: String
    let tags: [String]
    let priority: String
    let completedAt: Date
    let daysSinceCreation: Int

    init(from task: TaskItem) {
        self.id = task.id.uuidString
        self.title = task.title
        self.tags = task.tags
        self.priority = task.priority.rawValue
        self.completedAt = task.completedAt ?? Date()
        self.daysSinceCreation = task.daysSinceCreation
    }
}

struct StaleTaskSummary: Codable, Sendable {
    let id: String
    let title: String
    let tags: [String]
    let daysSinceCreation: Int
    let skipCount: Int

    init(from task: TaskItem) {
        self.id = task.id.uuidString
        self.title = task.title
        self.tags = task.tags
        self.daysSinceCreation = task.daysSinceCreation
        self.skipCount = task.skipCount
    }
}

struct WeeklyDigestResponse: Codable, Sendable {
    let summary: String
    let accomplishments: [String]
    let patterns: [String]
    let suggestions: [String]
}
