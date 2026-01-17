import Foundation

enum AIServiceFactory {
    static func create(for provider: AIProvider, settings: AppSettings) -> AIServiceProtocol {
        switch provider {
        case .appleIntelligence:
            return AppleIntelligenceService()
        case .ollama:
            return OllamaService(
                endpoint: settings.ollamaEndpoint,
                model: settings.ollamaModel
            )
        case .disabled:
            return DisabledAIService()
        }
    }
}

// Fallback when AI is disabled
final class DisabledAIService: AIServiceProtocol {
    func rankTasks(context: TaskContext) async throws -> TaskRanking {
        // Just return the first task
        guard let first = context.candidateTasks.first else {
            throw AIServiceError.invalidResponse
        }
        return TaskRanking(topTaskId: first.id, reasoning: "Rule-based selection")
    }

    func generateContextHints(for title: String, description: String?, tags: [String]) async throws -> [String] {
        // Return tags as hints
        return tags
    }

    func generateWeeklyDigest(context: WeeklyContext) async throws -> WeeklyDigestResponse {
        // Generate a rule-based summary
        let summary = generateRuleBasedSummary(context: context)
        let accomplishments = generateRuleBasedAccomplishments(context: context)
        let patterns = generateRuleBasedPatterns(context: context)
        let suggestions = generateRuleBasedSuggestions(context: context)

        return WeeklyDigestResponse(
            summary: summary,
            accomplishments: accomplishments,
            patterns: patterns,
            suggestions: suggestions
        )
    }

    func isAvailable() async -> Bool {
        return true
    }

    // MARK: - Rule-based digest generation

    private func generateRuleBasedSummary(context: WeeklyContext) -> String {
        let completionTrend: String
        if context.averageCompletionRate > context.previousWeekCompletionRate {
            completionTrend = "Your completion rate improved compared to last week."
        } else if context.averageCompletionRate < context.previousWeekCompletionRate {
            completionTrend = "Your completion rate was lower than last week."
        } else {
            completionTrend = "Your completion rate remained consistent."
        }

        let streakNote = context.currentStreak > 0
            ? "You're on a \(context.currentStreak)-day streak!"
            : "Start a new streak by completing a task today."

        return "You completed \(context.totalCompleted) tasks this week with a " +
            "\(String(format: "%.0f%%", context.averageCompletionRate * 100)) completion rate. " +
            completionTrend + " " + streakNote
    }

    private func generateRuleBasedAccomplishments(context: WeeklyContext) -> [String] {
        var accomplishments: [String] = []

        if context.totalCompleted > 0 {
            accomplishments.append("Completed \(context.totalCompleted) task\(context.totalCompleted == 1 ? "" : "s") this week")
        }

        if context.currentStreak >= 7 {
            accomplishments.append("Maintained a \(context.currentStreak)-day productivity streak")
        } else if context.currentStreak >= 3 {
            accomplishments.append("Built a \(context.currentStreak)-day streak")
        }

        if context.averageCompletionRate > context.previousWeekCompletionRate && context.previousWeekCompletionRate > 0 {
            let improvement = (context.averageCompletionRate - context.previousWeekCompletionRate) * 100
            accomplishments.append("Improved completion rate by \(String(format: "%.0f", improvement)) percentage points")
        }

        if let bestDay = context.mostProductiveDay, context.totalCompleted > 0 {
            accomplishments.append("\(bestDay) was your most productive day")
        }

        if !context.topTags.isEmpty {
            accomplishments.append("Made progress on: \(context.topTags.prefix(3).joined(separator: ", "))")
        }

        return accomplishments.isEmpty ? ["You're getting started - keep going!"] : accomplishments
    }

    private func generateRuleBasedPatterns(context: WeeklyContext) -> [String] {
        var patterns: [String] = []

        if let bestDay = context.mostProductiveDay {
            patterns.append("You tend to be most productive on \(bestDay)s")
        }

        if context.totalSkipped > context.totalCompleted && context.totalSkipped > 0 {
            patterns.append("More tasks skipped than completed - consider breaking tasks into smaller pieces")
        }

        if context.averageCompletionRate >= 0.8 {
            patterns.append("High completion rate indicates good task sizing")
        } else if context.averageCompletionRate < 0.5 && context.totalCompleted + context.totalSkipped > 0 {
            patterns.append("Lower completion rate may indicate tasks need to be more specific")
        }

        return patterns.isEmpty ? ["Keep tracking to discover your productivity patterns"] : patterns
    }

    private func generateRuleBasedSuggestions(context: WeeklyContext) -> [String] {
        var suggestions: [String] = []

        if !context.staleTasks.isEmpty {
            let staleCount = context.staleTasks.count
            suggestions.append("Review \(staleCount) stale task\(staleCount == 1 ? "" : "s") that may need archiving or updating")
        }

        if context.totalSkipped > context.totalCompleted * 2 {
            suggestions.append("Try breaking down frequently skipped tasks into smaller, actionable items")
        }

        if context.currentStreak == 0 {
            suggestions.append("Complete one task today to start building a new streak")
        }

        if context.averageCompletionRate < 0.5 && context.totalCompleted > 0 {
            suggestions.append("Focus on 1-2 high-priority tasks per day rather than many tasks")
        }

        if context.totalCreated > context.totalCompleted * 2 {
            suggestions.append("You're adding tasks faster than completing them - consider prioritizing existing tasks")
        }

        return suggestions.isEmpty ? ["Keep up the great work!"] : suggestions
    }
}
