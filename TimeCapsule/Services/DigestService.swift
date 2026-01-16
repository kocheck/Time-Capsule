import Foundation
import SwiftData
import OSLog

final class DigestService {
    private let modelContext: ModelContext
    private let statsService: StatsService
    private let aiService: AIServiceProtocol
    private let logger = Logger.data

    init(modelContext: ModelContext, aiService: AIServiceProtocol) {
        self.modelContext = modelContext
        self.statsService = StatsService(modelContext: modelContext)
        self.aiService = aiService
    }

    // MARK: - Digest Retrieval

    func getCurrentWeekDigest() -> WeeklyDigest? {
        let currentWeekKey = WeeklyDigest.currentWeekKey()
        return getDigest(forWeekKey: currentWeekKey)
    }

    func getDigest(forWeekKey weekKey: String) -> WeeklyDigest? {
        let descriptor = FetchDescriptor<WeeklyDigest>(
            predicate: #Predicate<WeeklyDigest> { $0.weekKey == weekKey }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            logger.error("Failed to fetch digest: \(error.localizedDescription)")
            return nil
        }
    }

    func getRecentDigests(limit: Int = 4) -> [WeeklyDigest] {
        let descriptor = FetchDescriptor<WeeklyDigest>(
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )

        do {
            let results = try modelContext.fetch(descriptor)
            return Array(results.prefix(limit))
        } catch {
            logger.error("Failed to fetch recent digests: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Digest Generation

    func generateDigest(forWeekStarting weekStart: Date? = nil) async throws -> WeeklyDigest {
        let startDate = weekStart ?? WeeklyDigest.startOfCurrentWeek()
        let weekKey = WeeklyDigest.formatWeekKey(startDate)

        // Check if digest already exists
        if let existing = getDigest(forWeekKey: weekKey) {
            return existing
        }

        // Build context
        let context = try buildWeeklyContext(forWeekStarting: startDate)

        // Generate digest using AI
        let response = try await aiService.generateWeeklyDigest(context: context)

        // Create and save digest
        let digest = WeeklyDigest(
            weekStartDate: startDate,
            summaryText: response.summary,
            accomplishments: response.accomplishments,
            patternsNoticed: response.patterns,
            suggestionsForImprovement: response.suggestions,
            staleTaskTitles: context.staleTasks.map { $0.title },
            totalCompleted: context.totalCompleted,
            totalSkipped: context.totalSkipped,
            totalCreated: context.totalCreated,
            averageCompletionRate: context.averageCompletionRate,
            streakAtGeneration: context.currentStreak
        )

        modelContext.insert(digest)
        try modelContext.save()

        logger.info("Generated weekly digest for \(weekKey)")
        return digest
    }

    func regenerateDigest(forWeekStarting weekStart: Date? = nil) async throws -> WeeklyDigest {
        let startDate = weekStart ?? WeeklyDigest.startOfCurrentWeek()
        let weekKey = WeeklyDigest.formatWeekKey(startDate)

        // Delete existing digest if present
        if let existing = getDigest(forWeekKey: weekKey) {
            modelContext.delete(existing)
            try modelContext.save()
        }

        return try await generateDigest(forWeekStarting: startDate)
    }

    // MARK: - Context Building

    private func buildWeeklyContext(forWeekStarting weekStart: Date) throws -> WeeklyContext {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart

        // Get daily stats for the week
        let dailyStats = getStatsForWeek(startDate: weekStart, endDate: weekEnd)
            .map { DailyStatsSummary(from: $0) }

        // Get completed tasks for the week
        let completedTasks = try fetchCompletedTasks(from: weekStart, to: weekEnd)
            .map { CompletedTaskSummary(from: $0) }

        // Get stale tasks
        let staleTasks = try fetchStaleTasks()
            .map { StaleTaskSummary(from: $0) }

        // Calculate streak and previous week rate
        let currentStreak = statsService.calculateStreak()
        let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart
        let previousWeekStats = getStatsForWeek(
            startDate: previousWeekStart,
            endDate: calendar.date(byAdding: .day, value: -1, to: weekStart) ?? previousWeekStart
        )
        let previousWeekRate = calculateAverageRate(from: previousWeekStats)

        return WeeklyContext(
            weekStartDate: weekStart,
            dailyStats: dailyStats,
            completedTasks: completedTasks,
            staleTasks: staleTasks,
            currentStreak: currentStreak,
            previousWeekCompletionRate: previousWeekRate
        )
    }

    private func getStatsForWeek(startDate: Date, endDate: Date) -> [DailyStats] {
        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate<DailyStats> { stats in
                stats.date >= startDate && stats.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch weekly stats: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchCompletedTasks(from startDate: Date, to endDate: Date) throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )

        let allCompleted = try modelContext.fetch(descriptor)

        // Filter by date range (SwiftData predicate limitations with optionals)
        return allCompleted.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= startDate && completedAt <= endDate
        }
    }

    private func fetchStaleTasks() throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                !task.isArchived && task.completedAt == nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        let openTasks = try modelContext.fetch(descriptor)
        return openTasks.filter { $0.isStale }
    }

    private func calculateAverageRate(from stats: [DailyStats]) -> Double {
        guard !stats.isEmpty else { return 0 }
        let totalRate = stats.reduce(0.0) { $0 + $1.completionRate }
        return totalRate / Double(stats.count)
    }

    // MARK: - Cleanup

    func cleanupOldDigests(keepLast weeks: Int = 12) {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .weekOfYear, value: -weeks, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<WeeklyDigest>(
            predicate: #Predicate<WeeklyDigest> { digest in
                digest.weekStartDate < cutoffDate
            }
        )

        do {
            let oldDigests = try modelContext.fetch(descriptor)
            for digest in oldDigests {
                modelContext.delete(digest)
            }
            try modelContext.save()
            logger.info("Cleaned up \(oldDigests.count) old digests")
        } catch {
            logger.error("Failed to cleanup old digests: \(error.localizedDescription)")
        }
    }
}
