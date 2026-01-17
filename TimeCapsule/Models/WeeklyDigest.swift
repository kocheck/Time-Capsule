import Foundation
import SwiftData

@Model
final class WeeklyDigest: Identifiable {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var weekKey: String // "yyyy-Www" (ISO week)
    var weekStartDate: Date
    var weekEndDate: Date
    var generatedAt: Date

    // Summary content
    var summaryText: String
    var accomplishments: [String]
    var patternsNoticed: [String]
    var suggestionsForImprovement: [String]
    var staleTaskTitles: [String]

    // Stats snapshot
    var totalCompleted: Int
    var totalSkipped: Int
    var totalCreated: Int
    var averageCompletionRate: Double
    var streakAtGeneration: Int

    init(
        weekStartDate: Date,
        summaryText: String = "",
        accomplishments: [String] = [],
        patternsNoticed: [String] = [],
        suggestionsForImprovement: [String] = [],
        staleTaskTitles: [String] = [],
        totalCompleted: Int = 0,
        totalSkipped: Int = 0,
        totalCreated: Int = 0,
        averageCompletionRate: Double = 0,
        streakAtGeneration: Int = 0
    ) {
        let calendar = Calendar(identifier: .iso8601)
        self.id = UUID()
        self.weekKey = Self.formatWeekKey(weekStartDate)
        self.weekStartDate = calendar.startOfDay(for: weekStartDate)
        self.weekEndDate = calendar.date(byAdding: .day, value: 6, to: self.weekStartDate) ?? weekStartDate
        self.generatedAt = Date()
        self.summaryText = summaryText
        self.accomplishments = accomplishments
        self.patternsNoticed = patternsNoticed
        self.suggestionsForImprovement = suggestionsForImprovement
        self.staleTaskTitles = staleTaskTitles
        self.totalCompleted = totalCompleted
        self.totalSkipped = totalSkipped
        self.totalCreated = totalCreated
        self.averageCompletionRate = averageCompletionRate
        self.streakAtGeneration = streakAtGeneration
    }

    static func formatWeekKey(_ date: Date) -> String {
        let calendar = Calendar(identifier: .iso8601)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        return String(format: "%04d-W%02d", year, week)
    }

    static func currentWeekKey() -> String {
        formatWeekKey(Date())
    }

    static func startOfCurrentWeek() -> Date {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
    }

    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: weekStartDate)
        let end = formatter.string(from: weekEndDate)
        return "\(start) - \(end)"
    }

    var isCurrentWeek: Bool {
        weekKey == Self.currentWeekKey()
    }
}
