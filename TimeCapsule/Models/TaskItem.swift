import Foundation
import SwiftData

@Model
final class TaskItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String?
    var tags: [String]
    var createdAt: Date
    var completedAt: Date?
    var skipCount: Int
    var dailySkipCount: Int
    var lastSkippedAt: Date?
    var lastPresentedAt: Date?
    var isArchived: Bool
    var priority: TaskPriority
    var contextHints: [String]

    init(
        title: String,
        description: String? = nil,
        tags: [String] = [],
        priority: TaskPriority = .normal
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.tags = tags
        self.createdAt = Date()
        self.skipCount = 0
        self.dailySkipCount = 0
        self.isArchived = false
        self.priority = priority
        self.contextHints = []
    }

    // MARK: - Computed Properties

    var isCompleted: Bool { completedAt != nil }

    var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    var isStale: Bool {
        daysSinceCreation >= Constants.staleTaskThresholdDays && !isCompleted
    }

    var wasSkippedToday: Bool {
        guard let lastSkipped = lastSkippedAt else { return false }
        return Calendar.current.isDateInToday(lastSkipped)
    }

    var shouldTriggerFocusMode: Bool {
        wasSkippedToday && dailySkipCount >= Constants.focusModeSkipThreshold
    }

    // MARK: - Methods

    func markCompleted() {
        completedAt = Date()
    }

    func markSkipped() {
        skipCount += 1

        if wasSkippedToday {
            dailySkipCount += 1
        } else {
            dailySkipCount = 1
        }

        lastSkippedAt = Date()
    }

    func markPresented() {
        lastPresentedAt = Date()
    }

    func archive() {
        isArchived = true
    }

    func unarchive() {
        isArchived = false
    }

    func resetDailySkipCount() {
        dailySkipCount = 0
    }
}
