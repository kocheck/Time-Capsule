import Foundation
import SwiftData

/// Records when and how quickly tasks are completed for predictive analysis
@Model
final class CompletionRecord: Identifiable {
    @Attribute(.unique) var id: UUID
    var taskId: UUID
    var tags: [String]
    var completedAt: Date
    var hourOfDay: Int        // 0-23
    var dayOfWeek: Int        // 1-7 (Sunday = 1)
    var timeToComplete: TimeInterval  // seconds from creation to completion

    init(
        taskId: UUID,
        tags: [String],
        completedAt: Date,
        createdAt: Date
    ) {
        self.id = UUID()
        self.taskId = taskId
        self.tags = tags
        self.completedAt = completedAt

        let calendar = Calendar.current
        self.hourOfDay = calendar.component(.hour, from: completedAt)
        self.dayOfWeek = calendar.component(.weekday, from: completedAt)
        self.timeToComplete = completedAt.timeIntervalSince(createdAt)
    }

    /// Creates a record from a completed TaskItem
    convenience init(from task: TaskItem) {
        guard let completedAt = task.completedAt else {
            fatalError("Cannot create CompletionRecord from incomplete task")
        }

        self.init(
            taskId: task.id,
            tags: task.tags,
            completedAt: completedAt,
            createdAt: task.createdAt
        )
    }
}

// MARK: - Time Slot Statistics

/// Statistics for a specific hour of the day
struct TimeSlotStats {
    let hourOfDay: Int
    let completionCount: Int
    let averageCompletionTime: TimeInterval
    let completionRate: Double

    var hourLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hourOfDay, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }

    var isProductiveHour: Bool {
        completionRate > 0.5 && completionCount >= 3
    }
}

/// Statistics for a specific day of the week
struct DayOfWeekStats {
    let dayOfWeek: Int
    let completionCount: Int
    let averageCompletionTime: TimeInterval

    var dayName: String {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[dayOfWeek - 1]
    }

    var shortDayName: String {
        let formatter = DateFormatter()
        return formatter.shortWeekdaySymbols[dayOfWeek - 1]
    }
}
