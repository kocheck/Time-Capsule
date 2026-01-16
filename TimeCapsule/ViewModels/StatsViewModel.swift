import Foundation
import SwiftData
import Observation

@Observable
final class StatsViewModel {
    private let modelContext: ModelContext
    private let statsService: StatsService

    var todayStats: DailyStats?
    var currentStreak: Int = 0
    var weeklyStats: [DailyStats] = []
    var averageCompletionRate: Double = 0
    var totalCompleted: Int = 0
    var isLoading: Bool = false
    var error: Error?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.statsService = StatsService(modelContext: modelContext)
    }

    @MainActor
    func loadStats() {
        isLoading = true
        defer { isLoading = false }

        todayStats = statsService.getTodayStats()
        currentStreak = statsService.calculateStreak()
        weeklyStats = statsService.getStatsForLastDays(7)
        averageCompletionRate = statsService.getAverageCompletionRate(days: 7)
        totalCompleted = statsService.getTotalCompletedTasks()
    }

    @MainActor
    func refreshStats() {
        loadStats()
    }

    // MARK: - Computed Properties

    var todayCompletionRate: Double {
        todayStats?.completionRate ?? 0
    }

    var todayCompletedCount: Int {
        todayStats?.completedCount ?? 0
    }

    var todaySkippedCount: Int {
        todayStats?.skippedCount ?? 0
    }

    var todayCreatedCount: Int {
        todayStats?.createdCount ?? 0
    }

    var todayFocusModeCount: Int {
        todayStats?.focusModeTriggeredCount ?? 0
    }

    var formattedStreak: String {
        if currentStreak == 0 {
            return "No streak"
        } else if currentStreak == 1 {
            return "1 day streak"
        } else {
            return "\(currentStreak) day streak"
        }
    }

    var formattedCompletionRate: String {
        String(format: "%.0f%%", averageCompletionRate * 100)
    }

    // MARK: - Historical Data

    func getStatsForDate(_ date: Date) -> DailyStats? {
        let dateKey = DailyStats.formatDateKey(date)
        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate<DailyStats> { $0.dateKey == dateKey }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch let fetchError {
            error = fetchError
            return nil
        }
    }

    func getCompletionRateForLast(_ days: Int) -> [Double] {
        let stats = statsService.getStatsForLastDays(days)
        return stats.reversed().map { $0.completionRate }
    }
}
