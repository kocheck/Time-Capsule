import Foundation
import SwiftData
import OSLog

final class DataService {
    private let modelContext: ModelContext
    private let logger = Logger.data

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Settings Management

    func getSettings() -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()

        do {
            let results = try modelContext.fetch(descriptor)
            if let settings = results.first {
                return settings
            } else {
                let newSettings = AppSettings()
                modelContext.insert(newSettings)
                try modelContext.save()
                return newSettings
            }
        } catch {
            logger.error("Failed to fetch settings: \(error.localizedDescription)")
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            return newSettings
        }
    }

    func saveSettings(_ settings: AppSettings) throws {
        try modelContext.save()
    }

    // MARK: - Task Management

    func resetDailySkipCounts() {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { !$0.isCompleted && !$0.isArchived }
        )

        do {
            let tasks = try modelContext.fetch(descriptor)
            for task in tasks {
                task.resetDailySkipCount()
            }
            try modelContext.save()
            logger.info("Reset daily skip counts for \(tasks.count) tasks")
        } catch {
            logger.error("Failed to reset daily skip counts: \(error.localizedDescription)")
        }
    }

    func archiveStaleTasks() {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { !$0.isCompleted && !$0.isArchived }
        )

        do {
            let tasks = try modelContext.fetch(descriptor)
            let staleTasks = tasks.filter { $0.isStale }

            for task in staleTasks {
                task.archive()
            }

            if !staleTasks.isEmpty {
                try modelContext.save()
                logger.info("Archived \(staleTasks.count) stale tasks")
            }
        } catch {
            logger.error("Failed to archive stale tasks: \(error.localizedDescription)")
        }
    }

    func cleanupOldData() {
        cleanupOldStats()
        archiveOldCompletedTasks()
    }

    // MARK: - Private Helpers

    private func cleanupOldStats() {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -Constants.statsHistoryDays, to: Date())!

        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate<DailyStats> { stats in
                stats.date < cutoffDate
            }
        )

        do {
            let oldStats = try modelContext.fetch(descriptor)
            for stats in oldStats {
                modelContext.delete(stats)
            }

            if !oldStats.isEmpty {
                try modelContext.save()
                logger.info("Cleaned up \(oldStats.count) old stats records")
            }
        } catch {
            logger.error("Failed to cleanup old stats: \(error.localizedDescription)")
        }
    }

    private func archiveOldCompletedTasks() {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -Constants.autoArchiveDays, to: Date())!

        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.isCompleted && !task.isArchived && task.completedAt != nil && task.completedAt! < cutoffDate
            }
        )

        do {
            let oldTasks = try modelContext.fetch(descriptor)
            for task in oldTasks {
                task.archive()
            }

            if !oldTasks.isEmpty {
                try modelContext.save()
                logger.info("Auto-archived \(oldTasks.count) old completed tasks")
            }
        } catch {
            logger.error("Failed to archive old tasks: \(error.localizedDescription)")
        }
    }
}
