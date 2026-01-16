import Foundation
import SwiftData
import OSLog

final class StatsService {
    private let modelContext: ModelContext
    private let logger = Logger.data

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Daily Stats Management

    func getTodayStats() -> DailyStats {
        let todayKey = DailyStats.todayKey()
        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate<DailyStats> { $0.dateKey == todayKey }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            if let stats = results.first {
                return stats
            } else {
                let newStats = DailyStats(date: Date())
                modelContext.insert(newStats)
                try modelContext.save()
                return newStats
            }
        } catch {
            logger.error("Failed to get today's stats: \(error.localizedDescription)")
            let newStats = DailyStats(date: Date())
            modelContext.insert(newStats)
            return newStats
        }
    }

    func incrementCompleted() {
        let stats = getTodayStats()
        stats.incrementCompleted()
        saveContext()
    }

    func incrementSkipped() {
        let stats = getTodayStats()
        stats.incrementSkipped()
        saveContext()
    }

    func incrementCreated() {
        let stats = getTodayStats()
        stats.incrementCreated()
        saveContext()
    }

    func incrementFocusModeTriggered() {
        let stats = getTodayStats()
        stats.incrementFocusModeTriggered()
        saveContext()
    }

    // MARK: - Streak Calculation

    func calculateStreak() -> Int {
        let descriptor = FetchDescriptor<DailyStats>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let allStats = try modelContext.fetch(descriptor)
            var streak = 0
            let calendar = Calendar.current
            var currentDate = calendar.startOfDay(for: Date())

            for stats in allStats {
                if calendar.isDate(stats.date, inSameDayAs: currentDate) {
                    if stats.completedCount > 0 {
                        streak += 1
                        currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                    } else {
                        break
                    }
                } else {
                    // Gap in dates
                    break
                }
            }

            // Update today's streak
            let todayStats = getTodayStats()
            todayStats.streak = streak
            saveContext()

            return streak
        } catch {
            logger.error("Failed to calculate streak: \(error.localizedDescription)")
            return 0
        }
    }

    // MARK: - Historical Stats

    func getStatsForLastDays(_ days: Int) -> [DailyStats] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!

        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate<DailyStats> { stats in
                stats.date >= startDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch historical stats: \(error.localizedDescription)")
            return []
        }
    }

    func getAverageCompletionRate(days: Int = 7) -> Double {
        let stats = getStatsForLastDays(days)
        guard !stats.isEmpty else { return 0 }

        let totalRate = stats.reduce(0.0) { $0 + $1.completionRate }
        return totalRate / Double(stats.count)
    }

    func getTotalCompletedTasks() -> Int {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { $0.isCompleted }
        )

        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            logger.error("Failed to count completed tasks: \(error.localizedDescription)")
            return 0
        }
    }

    // MARK: - Private Helpers

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
        }
    }
}
