import Foundation
import SwiftData

/// Event fired when an achievement is unlocked
struct AchievementUnlockEvent {
    let achievement: Achievement
    let xpAwarded: Int
    let leveledUp: Bool
    let newLevel: Int?
}

/// Manages achievements, XP, and streaks
@Observable
class AchievementEngine {
    private let modelContext: ModelContext

    var achievements: [Achievement] = []
    var userLevel: UserLevel?
    var streak: Streak?
    var recentUnlocks: [AchievementUnlockEvent] = []

    // Stats for achievement checking
    private var todayCompletions: Int = 0
    private var hourlyCompletions: [Date: Int] = [:]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadData()
        }
    }

    // MARK: - Data Loading

    func loadData() async {
        // Load achievements
        let achievementDescriptor = FetchDescriptor<Achievement>()
        achievements = (try? modelContext.fetch(achievementDescriptor)) ?? []

        // Create default achievements if none exist
        if achievements.isEmpty {
            for achievement in Achievement.defaultAchievements() {
                modelContext.insert(achievement)
            }
            try? modelContext.save()
            achievements = (try? modelContext.fetch(achievementDescriptor)) ?? []
        }

        // Load user level
        let levelDescriptor = FetchDescriptor<UserLevel>()
        if let level = try? modelContext.fetch(levelDescriptor).first {
            userLevel = level
        } else {
            let newLevel = UserLevel()
            modelContext.insert(newLevel)
            try? modelContext.save()
            userLevel = newLevel
        }

        // Load streak
        let streakDescriptor = FetchDescriptor<Streak>()
        if let existingStreak = try? modelContext.fetch(streakDescriptor).first {
            streak = existingStreak
        } else {
            let newStreak = Streak()
            modelContext.insert(newStreak)
            try? modelContext.save()
            streak = newStreak
        }
    }

    // MARK: - Event Handling

    /// Called when a task is completed
    func onTaskCompleted(_ task: TaskItem) async {
        guard let level = userLevel, let streak = streak else { return }

        // Update streak
        streak.recordCompletion()

        // Track daily completions
        todayCompletions += 1

        // Track hourly completions
        let hourKey = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: Date()), minute: 0, second: 0, of: Date())!
        hourlyCompletions[hourKey, default: 0] += 1

        // Award XP
        let xp = UserLevel.xpForTask(
            priority: task.priority,
            wasSkippedMultipleTimes: task.skipCount > 2
        )
        let leveledUp = level.addXP(xp)
        level.tasksCompleted += 1

        // Check achievements
        await checkAchievements(task: task, leveledUp: leveledUp)

        try? modelContext.save()
    }

    /// Called when a pomodoro session is completed
    func onPomodoroCompleted() async {
        // Update pomodoro achievement progress
        if let pomodoroAchievement = achievements.first(where: { $0.id == "pomodoro_pro" }) {
            pomodoroAchievement.updateProgress(pomodoroAchievement.progress + 1)

            if pomodoroAchievement.isUnlocked {
                await handleUnlock(pomodoroAchievement)
            }
        }

        try? modelContext.save()
    }

    // MARK: - Achievement Checking

    private func checkAchievements(task: TaskItem, leveledUp: Bool) async {
        guard let level = userLevel, let streak = streak else { return }

        // Milestone achievements
        checkMilestoneAchievement("first_task", currentValue: level.tasksCompleted)
        checkMilestoneAchievement("tasks_10", currentValue: level.tasksCompleted)
        checkMilestoneAchievement("tasks_50", currentValue: level.tasksCompleted)
        checkMilestoneAchievement("tasks_100", currentValue: level.tasksCompleted)
        checkMilestoneAchievement("tasks_500", currentValue: level.tasksCompleted)
        checkMilestoneAchievement("tasks_1000", currentValue: level.tasksCompleted)

        // Streak achievements
        checkMilestoneAchievement("streak_3", currentValue: streak.currentStreak)
        checkMilestoneAchievement("streak_7", currentValue: streak.currentStreak)
        checkMilestoneAchievement("streak_30", currentValue: streak.currentStreak)
        checkMilestoneAchievement("streak_100", currentValue: streak.currentStreak)

        // Daily productivity achievements
        checkMilestoneAchievement("task_slayer", currentValue: todayCompletions)

        // Hourly productivity
        let currentHourKey = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: Date()), minute: 0, second: 0, of: Date())!
        let hourlyCount = hourlyCompletions[currentHourKey] ?? 0
        checkMilestoneAchievement("productivity_burst", currentValue: hourlyCount)

        // Time-based achievements
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 8 {
            checkMilestoneAchievement("early_bird", currentValue: 1)
        }
        if hour >= 22 {
            checkMilestoneAchievement("night_owl", currentValue: 1)
        }

        // Tag master
        let allTags = await fetchAllUniqueTags()
        checkMilestoneAchievement("tag_master", currentValue: allTags.count)

        try? modelContext.save()
    }

    private func checkMilestoneAchievement(_ id: String, currentValue: Int) {
        guard let achievement = achievements.first(where: { $0.id == id && !$0.isUnlocked }) else { return }

        achievement.updateProgress(currentValue)

        if achievement.isUnlocked {
            Task {
                await handleUnlock(achievement)
            }
        }
    }

    private func handleUnlock(_ achievement: Achievement) async {
        guard let level = userLevel else { return }

        let xp = UserLevel.xpForAchievement(category: achievement.category)
        let leveledUp = level.addXP(xp)
        level.achievementsUnlocked += 1

        let event = AchievementUnlockEvent(
            achievement: achievement,
            xpAwarded: xp,
            leveledUp: leveledUp,
            newLevel: leveledUp ? level.currentLevel : nil
        )

        await MainActor.run {
            recentUnlocks.append(event)
        }

        try? modelContext.save()
    }

    // MARK: - Queries

    func getUnlockedAchievements() -> [Achievement] {
        achievements.filter { $0.isUnlocked }
    }

    func getLockedAchievements() -> [Achievement] {
        achievements.filter { !$0.isUnlocked }
    }

    func getAchievements(for category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }

    func getNextAchievement() -> Achievement? {
        achievements
            .filter { !$0.isUnlocked && $0.progress > 0 }
            .max(by: { $0.progressPercentage < $1.progressPercentage })
    }

    private func fetchAllUniqueTags() async -> Set<String> {
        let descriptor = FetchDescriptor<TaskItem>()
        let tasks = (try? modelContext.fetch(descriptor)) ?? []
        return Set(tasks.flatMap { $0.tags })
    }

    /// Clears recent unlock notifications
    func clearRecentUnlocks() {
        recentUnlocks = []
    }

    /// Resets daily tracking (call at midnight)
    func resetDailyTracking() {
        todayCompletions = 0
        hourlyCompletions = [:]
    }
}
