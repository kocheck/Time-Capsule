import Foundation
import SwiftData

/// Represents a single Pomodoro work session
@Model
final class PomodoroSession: Identifiable {
    @Attribute(.unique) var id: UUID
    var taskId: UUID?
    var taskTitle: String?
    var tags: [String]
    var startedAt: Date
    var endedAt: Date?
    var plannedMinutes: Int
    var wasCompleted: Bool
    var wasInterrupted: Bool

    init(
        taskId: UUID? = nil,
        taskTitle: String? = nil,
        tags: [String] = [],
        plannedMinutes: Int = 25
    ) {
        self.id = UUID()
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.tags = tags
        self.startedAt = Date()
        self.endedAt = nil
        self.plannedMinutes = plannedMinutes
        self.wasCompleted = false
        self.wasInterrupted = false
    }

    /// Duration of the session in seconds (if completed)
    var actualDuration: TimeInterval? {
        guard let endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }

    /// Whether the session is currently active
    var isActive: Bool {
        endedAt == nil
    }

    /// Marks the session as completed
    func markCompleted() {
        endedAt = Date()
        wasCompleted = true
        wasInterrupted = false
    }

    /// Marks the session as interrupted
    func markInterrupted() {
        endedAt = Date()
        wasCompleted = false
        wasInterrupted = true
    }
}

// MARK: - Export Support

extension PomodoroSession {
    /// Converts to exportable format
    func toExportFormat() -> UTFPomodoroSession {
        UTFPomodoroSession(from: self)
    }
}

/// Exportable Pomodoro session format
struct UTFPomodoroSession: Codable {
    let id: String
    let taskId: String?
    let taskTitle: String?
    let tags: [String]
    let startedAt: Date
    let endedAt: Date?
    let plannedMinutes: Int
    let wasCompleted: Bool
    let wasInterrupted: Bool

    init(from session: PomodoroSession) {
        self.id = session.id.uuidString
        self.taskId = session.taskId?.uuidString
        self.taskTitle = session.taskTitle
        self.tags = session.tags
        self.startedAt = session.startedAt
        self.endedAt = session.endedAt
        self.plannedMinutes = session.plannedMinutes
        self.wasCompleted = session.wasCompleted
        self.wasInterrupted = session.wasInterrupted
    }
}
