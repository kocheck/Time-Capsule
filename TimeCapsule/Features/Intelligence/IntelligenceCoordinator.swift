import Foundation
import SwiftData

/// Coordinates all intelligence features for enhanced task suggestions
@Observable
class IntelligenceCoordinator {
    // Services
    private let modelContext: ModelContext
    let predictiveEngine: PredictiveEngine
    let tagAnalytics: TagAnalyticsService
    let patternDetector: PatternDetector
    let calendarService: CalendarService
    let achievementEngine: AchievementEngine
    let focusProfileManager: FocusProfileManager

    // Current state
    var currentSuggestion: TaskSuggestion?
    var pendingPatternSuggestions: [PatternSuggestion] = []
    var availabilityContext: AvailabilityContext?
    var insights: [ProductivityInsight] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.predictiveEngine = PredictiveEngine(modelContext: modelContext)
        self.tagAnalytics = TagAnalyticsService(modelContext: modelContext)
        self.patternDetector = PatternDetector(modelContext: modelContext)
        self.calendarService = CalendarService()
        self.achievementEngine = AchievementEngine(modelContext: modelContext)
        self.focusProfileManager = FocusProfileManager(modelContext: modelContext)
    }

    // MARK: - Task Suggestion

    /// Generates the best task suggestion based on all intelligence signals
    func generateSuggestion(from tasks: [TaskItem]) async -> TaskSuggestion? {
        // Filter by active focus profile
        let filteredTasks = focusProfileManager.filterTasks(tasks)
            .filter { !$0.isCompleted && !$0.isArchived }

        guard !filteredTasks.isEmpty else {
            currentSuggestion = nil
            return nil
        }

        // Update availability context
        if calendarService.isAuthorized {
            await calendarService.fetchTodayEvents()
        }

        availabilityContext = AvailabilityContext(
            freeTimeMinutes: calendarService.currentFreeGap?.durationMinutes,
            isGoodForDeepWork: calendarService.isGoodTimeForDeepWork,
            minutesUntilNextEvent: calendarService.minutesUntilNextEvent
        )

        // Score each task
        var scoredTasks: [(task: TaskItem, score: Double, reasons: [String])] = []

        for task in filteredTasks {
            let (score, reasons) = await calculateTaskScore(task)
            scoredTasks.append((task, score, reasons))
        }

        // Sort by score
        scoredTasks.sort { $0.score > $1.score }

        guard let best = scoredTasks.first else {
            currentSuggestion = nil
            return nil
        }

        let suggestion = TaskSuggestion(
            task: best.task,
            score: best.score,
            reasons: best.reasons,
            alternativeTasks: Array(scoredTasks.dropFirst().prefix(3).map(\.task)),
            availabilityContext: availabilityContext
        )

        currentSuggestion = suggestion
        return suggestion
    }

    /// Calculates a score for a task based on multiple factors
    private func calculateTaskScore(_ task: TaskItem) async -> (score: Double, reasons: [String]) {
        var score: Double = 0.5  // Base score
        var reasons: [String] = []

        // Factor 1: Priority (0-0.2)
        switch task.priority {
        case .high:
            score += 0.2
            reasons.append("High priority")
        case .normal:
            score += 0.1
        case .low:
            score += 0.0
        }

        // Factor 2: Age/Staleness (0-0.15)
        let daysSinceCreation = task.daysSinceCreation
        if daysSinceCreation > 7 {
            score += 0.15
            reasons.append("Overdue by \(daysSinceCreation) days")
        } else if daysSinceCreation > 3 {
            score += 0.1
            reasons.append("Getting old")
        }

        // Factor 3: Skip count penalty (-0.1 to 0)
        if task.skipCount > 3 {
            score -= 0.1  // Penalize frequently skipped tasks
        } else if task.skipCount == 0 {
            score += 0.05
            reasons.append("Never skipped")
        }

        // Factor 4: Time-based prediction (0-0.2)
        let timeScore = await predictiveEngine.shouldSuggestNow(task)
        if timeScore > 0.7 {
            score += 0.2
            reasons.append("Good time for this type of task")
        } else if timeScore > 0.5 {
            score += 0.1
        }

        // Factor 5: Calendar availability (0-0.15)
        if let context = availabilityContext {
            if context.isGoodForDeepWork && task.priority == .high {
                score += 0.15
                reasons.append("You have time for deep work")
            } else if let freeTime = context.freeTimeMinutes {
                if freeTime < 30 && task.priority == .low {
                    score += 0.1
                    reasons.append("Good for a quick task")
                }
            }
        }

        // Factor 6: Focus mode relevance (0-0.1)
        if let profile = focusProfileManager.activeProfile {
            let matchesInclude = !profile.includeTags.isEmpty &&
                task.tags.contains { profile.includeTags.contains($0) }
            if matchesInclude {
                score += 0.1
                reasons.append("Matches focus: \(profile.name)")
            }
        }

        // Normalize score to 0-1
        score = min(1.0, max(0.0, score))

        return (score, reasons)
    }

    // MARK: - Event Handling

    /// Called when a task is completed
    func onTaskCompleted(_ task: TaskItem) async {
        // Record for predictive analysis
        predictiveEngine.recordCompletion(task)

        // Update achievements
        await achievementEngine.onTaskCompleted(task)

        // Reanalyze patterns
        await patternDetector.analyzePatterns()

        // Update insights
        await refreshInsights()
    }

    /// Called when a task is skipped
    func onTaskSkipped(_ task: TaskItem) async {
        // Could adjust future scoring based on skip patterns
    }

    /// Called when a pomodoro session completes
    func onPomodoroCompleted() async {
        await achievementEngine.onPomodoroCompleted()
    }

    // MARK: - Insights

    /// Refreshes all insights
    func refreshInsights() async {
        insights = await predictiveEngine.getInsights()
    }

    /// Gets combined insights from all sources
    func getCombinedInsights() async -> [CombinedInsight] {
        var combined: [CombinedInsight] = []

        // Productivity insights
        let productivityInsights = await predictiveEngine.getInsights()
        for insight in productivityInsights {
            combined.append(CombinedInsight(
                type: .productivity,
                title: insight.message,
                detail: "Based on \(insight.basedOnSamples) completions",
                icon: "chart.line.uptrend.xyaxis",
                color: "blue"
            ))
        }

        // Tag insights
        let problematicTags = await tagAnalytics.getProblematicTags()
        for tagMetric in problematicTags.prefix(3) {
            combined.append(CombinedInsight(
                type: .warning,
                title: "#\(tagMetric.tag) has low completion rate",
                detail: "Only \(tagMetric.completionRateFormatted) completed",
                icon: "exclamationmark.triangle",
                color: "orange"
            ))
        }

        // Pattern suggestions
        for suggestion in patternDetector.pendingSuggestions.prefix(2) {
            combined.append(CombinedInsight(
                type: .pattern,
                title: suggestion.message,
                detail: "\(suggestion.pattern.frequency.displayName) pattern detected",
                icon: "repeat",
                color: "purple"
            ))
        }

        // Achievement progress
        if let nextAchievement = achievementEngine.getNextAchievement() {
            combined.append(CombinedInsight(
                type: .achievement,
                title: "Close to: \(nextAchievement.name)",
                detail: "\(Int(nextAchievement.progressPercentage * 100))% complete",
                icon: nextAchievement.icon,
                color: "yellow"
            ))
        }

        // Calendar insight
        if let gap = calendarService.currentFreeGap {
            combined.append(CombinedInsight(
                type: .calendar,
                title: gap.isGoodForDeepWork ? "Time for deep work" : "Quick task window",
                detail: gap.durationFormatted + " available",
                icon: "calendar",
                color: "green"
            ))
        }

        return combined
    }

    // MARK: - Daily Reset

    /// Call at the start of each day
    func performDailyReset() {
        achievementEngine.resetDailyTracking()
        focusProfileManager.refreshSchedule()
    }
}

// MARK: - Supporting Types

/// A task suggestion with context
struct TaskSuggestion: Identifiable {
    let id = UUID()
    let task: TaskItem
    let score: Double
    let reasons: [String]
    let alternativeTasks: [TaskItem]
    let availabilityContext: AvailabilityContext?

    var scoreLabel: String {
        switch score {
        case 0.8...: return "Highly recommended"
        case 0.6..<0.8: return "Good choice"
        case 0.4..<0.6: return "Reasonable"
        default: return "Consider"
        }
    }
}

/// Current availability context from calendar
struct AvailabilityContext {
    let freeTimeMinutes: Int?
    let isGoodForDeepWork: Bool
    let minutesUntilNextEvent: Int?
}

/// Combined insight from multiple sources
struct CombinedInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let detail: String
    let icon: String
    let color: String

    enum InsightType {
        case productivity
        case warning
        case pattern
        case achievement
        case calendar
    }
}
