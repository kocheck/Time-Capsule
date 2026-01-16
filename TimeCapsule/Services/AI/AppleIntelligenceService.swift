import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

final class AppleIntelligenceService: AIServiceProtocol {

    func rankTasks(context: TaskContext) async throws -> TaskRanking {
        guard await isAvailable() else {
            throw AIServiceError.notAvailable
        }

        #if canImport(FoundationModels)
        let session = LanguageModelSession()
        let prompt = buildRankingPrompt(context: context)

        let response = try await session.respond(to: prompt)
        return try parseRankingResponse(response.content)
        #else
        throw AIServiceError.notAvailable
        #endif
    }

    func generateContextHints(for title: String, description: String?, tags: [String]) async throws -> [String] {
        guard await isAvailable() else {
            throw AIServiceError.notAvailable
        }

        #if canImport(FoundationModels)
        let session = LanguageModelSession()
        let prompt = """
        Analyze this task and provide 3-5 context keywords that describe when this task would be most appropriate to work on. Consider time of day, day of week, mood, energy level, or related activities.

        Task Title: \(title)
        Description: \(description ?? "None")
        Tags: \(tags.isEmpty ? "None" : tags.joined(separator: ", "))

        Respond with ONLY comma-separated keywords, nothing else.
        Example: morning, high-energy, creative, quiet-time, weekend
        """

        let response = try await session.respond(to: prompt)
        return parseContextHints(response.content)
        #else
        throw AIServiceError.notAvailable
        #endif
    }

    func generateWeeklyDigest(context: WeeklyContext) async throws -> WeeklyDigestResponse {
        guard await isAvailable() else {
            throw AIServiceError.notAvailable
        }

        #if canImport(FoundationModels)
        let session = LanguageModelSession()
        let prompt = buildDigestPrompt(context: context)

        let response = try await session.respond(to: prompt)
        return try parseDigestResponse(response.content)
        #else
        throw AIServiceError.notAvailable
        #endif
    }

    func isAvailable() async -> Bool {
        #if canImport(FoundationModels)
        return LanguageModelSession.isAvailable
        #else
        return false
        #endif
    }

    // MARK: - Private Methods

    private func buildRankingPrompt(context: TaskContext) -> String {
        let tasksDescription = context.candidateTasks.map { task in
            """
            - ID: \(task.id)
              Title: \(task.title)
              Tags: \(task.tags.isEmpty ? "none" : task.tags.joined(separator: ", "))
              Priority: \(task.priority)
              Age: \(task.daysSinceCreation) days
              Skipped: \(task.skipCount) times
              Context hints: \(task.contextHints.isEmpty ? "none" : task.contextHints.joined(separator: ", "))
            """
        }.joined(separator: "\n")

        return """
        You are a task prioritization assistant. Select the single most appropriate task for the user to work on right now based on the context.

        CURRENT CONTEXT:
        - Time: \(context.currentHour):\(String(format: "%02d", context.currentMinute))
        - Day: \(context.dayOfWeekName)\(context.isWeekend ? " (weekend)" : "")
        - Recently completed tags: \(context.recentlyCompletedTags.isEmpty ? "none" : context.recentlyCompletedTags.joined(separator: ", "))

        CANDIDATE TASKS:
        \(tasksDescription)

        SELECTION CRITERIA:
        1. High priority tasks should generally be preferred
        2. Older tasks (higher age) need attention
        3. Frequently skipped tasks may not be suitable right now
        4. Consider time of day and context hints
        5. Build momentum by suggesting related tasks to recently completed ones

        Respond with ONLY valid JSON in this exact format:
        {"topTaskId": "<id>", "reasoning": "<brief explanation>", "confidence": <0.0-1.0>}
        """
    }

    private func parseRankingResponse(_ content: String) throws -> TaskRanking {
        // Extract JSON from response
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonStart = cleaned.firstIndex(of: "{"),
              let jsonEnd = cleaned.lastIndex(of: "}") else {
            throw AIServiceError.parsingError("No JSON found in response")
        }

        let jsonString = String(cleaned[jsonStart...jsonEnd])
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIServiceError.parsingError("Failed to convert to data")
        }

        return try JSONDecoder().decode(TaskRanking.self, from: jsonData)
    }

    private func parseContextHints(_ content: String) -> [String] {
        content
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }

    private func buildDigestPrompt(context: WeeklyContext) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let weekRange = "\(formatter.string(from: context.weekStartDate)) - \(formatter.string(from: context.weekEndDate))"

        let dailyBreakdown = context.dailyStats.map { stat in
            "\(stat.dayName): \(stat.completedCount) completed, \(stat.skippedCount) skipped"
        }.joined(separator: "\n")

        let completedTasksList = context.completedTasks.prefix(10).map { task in
            "- \(task.title) [\(task.tags.joined(separator: ", "))]"
        }.joined(separator: "\n")

        let staleTasksList = context.staleTasks.map { task in
            "- \(task.title) (created \(task.daysSinceCreation) days ago, skipped \(task.skipCount) times)"
        }.joined(separator: "\n")

        return """
        You are a productivity coach analyzing a user's weekly task management data. Generate a supportive and insightful weekly digest.

        WEEK: \(weekRange)

        DAILY BREAKDOWN:
        \(dailyBreakdown.isEmpty ? "No activity recorded" : dailyBreakdown)

        WEEKLY STATS:
        - Total Completed: \(context.totalCompleted)
        - Total Skipped: \(context.totalSkipped)
        - Total Created: \(context.totalCreated)
        - Completion Rate: \(String(format: "%.0f%%", context.averageCompletionRate * 100))
        - Current Streak: \(context.currentStreak) days
        - Previous Week Rate: \(String(format: "%.0f%%", context.previousWeekCompletionRate * 100))

        COMPLETED TASKS THIS WEEK:
        \(completedTasksList.isEmpty ? "No tasks completed" : completedTasksList)

        STALE TASKS NEEDING ATTENTION:
        \(staleTasksList.isEmpty ? "No stale tasks" : staleTasksList)

        TOP TAGS THIS WEEK: \(context.topTags.isEmpty ? "None" : context.topTags.joined(separator: ", "))

        Generate a weekly digest with:
        1. A brief summary paragraph (2-3 sentences) highlighting the week
        2. 2-4 specific accomplishments to celebrate
        3. 1-3 patterns you noticed (productivity trends, time preferences, etc.)
        4. 1-3 actionable suggestions for improvement

        Respond with ONLY valid JSON in this exact format:
        {
            "summary": "<2-3 sentence overview>",
            "accomplishments": ["<accomplishment 1>", "<accomplishment 2>"],
            "patterns": ["<pattern 1>", "<pattern 2>"],
            "suggestions": ["<suggestion 1>", "<suggestion 2>"]
        }
        """
    }

    private func parseDigestResponse(_ content: String) throws -> WeeklyDigestResponse {
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonStart = cleaned.firstIndex(of: "{"),
              let jsonEnd = cleaned.lastIndex(of: "}") else {
            throw AIServiceError.parsingError("No JSON found in digest response")
        }

        let jsonString = String(cleaned[jsonStart...jsonEnd])
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIServiceError.parsingError("Failed to convert digest to data")
        }

        return try JSONDecoder().decode(WeeklyDigestResponse.self, from: jsonData)
    }
}
