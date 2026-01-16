import Foundation
import SwiftData

@Model
final class DailyStats: Identifiable {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var dateKey: String
    var date: Date
    var completedCount: Int
    var skippedCount: Int
    var createdCount: Int
    var focusModeTriggeredCount: Int
    var streak: Int

    init(date: Date = Date()) {
        self.id = UUID()
        let startOfDay = Calendar.current.startOfDay(for: date)
        self.dateKey = Self.formatDateKey(startOfDay)
        self.date = startOfDay
        self.completedCount = 0
        self.skippedCount = 0
        self.createdCount = 0
        self.focusModeTriggeredCount = 0
        self.streak = 0
    }

    static func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func todayKey() -> String {
        formatDateKey(Date())
    }

    func incrementCompleted() { completedCount += 1 }
    func incrementSkipped() { skippedCount += 1 }
    func incrementCreated() { createdCount += 1 }
    func incrementFocusModeTriggered() { focusModeTriggeredCount += 1 }

    var completionRate: Double {
        let total = completedCount + skippedCount
        guard total > 0 else { return 0 }
        return Double(completedCount) / Double(total)
    }
}
