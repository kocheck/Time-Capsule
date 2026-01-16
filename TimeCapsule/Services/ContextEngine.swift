import Foundation
import SwiftData
import OSLog

actor ContextEngine {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ContextEngine")
    private var aiService: AIServiceProtocol

    init(aiService: AIServiceProtocol) {
        self.aiService = aiService
    }

    func updateAIService(_ service: AIServiceProtocol) {
        self.aiService = service
    }

    func suggestTask(from tasks: [TaskItem], recentlyCompleted: [TaskItem] = []) async -> TaskItem? {
        let candidates = tasks.filter { !$0.isCompleted && !$0.isArchived }

        guard !candidates.isEmpty else {
            logger.debug("No candidate tasks available")
            return nil
        }

        // Build context
        let recentTags = Array(Set(recentlyCompleted.flatMap { $0.tags })).prefix(10)
        let recentlySkippedIds = candidates
            .filter { $0.wasSkippedToday }
            .map { $0.id.uuidString }

        let context = TaskContext(
            recentlyCompletedTags: Array(recentTags),
            recentlySkippedTaskIds: recentlySkippedIds,
            candidateTasks: candidates.map { TaskSummary(from: $0) }
        )

        // Try AI ranking first
        do {
            if await aiService.isAvailable() {
                logger.debug("Using AI service for task ranking")
                let ranking = try await aiService.rankTasks(context: context)

                if let selectedTask = candidates.first(where: { $0.id.uuidString == ranking.topTaskId }) {
                    logger.info("AI selected task: \(selectedTask.title) - \(ranking.reasoning ?? "no reason")")
                    return selectedTask
                }
            }
        } catch {
            logger.error("AI ranking failed: \(error.localizedDescription)")
        }

        // Fallback to rule-based selection
        logger.debug("Using rule-based task selection")
        return selectTaskWithRules(from: candidates)
    }

    func generateHints(for task: TaskItem) async -> [String] {
        do {
            return try await aiService.generateContextHints(
                for: task.title,
                description: task.taskDescription,
                tags: task.tags
            )
        } catch {
            logger.error("Failed to generate hints: \(error.localizedDescription)")
            return task.tags
        }
    }

    // MARK: - Rule-Based Selection

    private func selectTaskWithRules(from tasks: [TaskItem]) -> TaskItem? {
        let scored = tasks.map { task -> (TaskItem, Double) in
            var score: Double = 0

            // Priority weight (0-20 points)
            switch task.priority {
            case .high: score += 20
            case .normal: score += 10
            case .low: score += 5
            }

            // Age weight - older tasks get more points (0-15 points)
            let ageScore = min(Double(task.daysSinceCreation) / 2.0, 15.0)
            score += ageScore

            // Skip penalty - frequently skipped tasks get fewer points
            let skipPenalty = min(Double(task.skipCount) * 2.0, 10.0)
            score -= skipPenalty

            // Recent presentation penalty
            if let lastPresented = task.lastPresentedAt {
                let hoursSincePresented = Date().timeIntervalSince(lastPresented) / 3600
                if hoursSincePresented < 1 {
                    score -= 15
                } else if hoursSincePresented < 4 {
                    score -= 5
                }
            }

            // Time-based bonuses
            let hour = Calendar.current.component(.hour, from: Date())

            // Morning (6-12): Prefer high priority
            if hour >= 6 && hour < 12 && task.priority == .high {
                score += 5
            }

            // Afternoon (12-17): Balanced
            // Evening (17-22): Prefer lighter tasks
            if hour >= 17 && hour < 22 && task.priority == .low {
                score += 5
            }

            return (task, score)
        }

        return scored.max(by: { $0.1 < $1.1 })?.0
    }
}
