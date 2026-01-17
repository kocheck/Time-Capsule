import Foundation
import SwiftData

/// Tracks user's level and experience points
@Model
final class UserLevel {
    @Attribute(.unique) var id: UUID
    var currentLevel: Int
    var totalXP: Int
    var tasksCompleted: Int
    var achievementsUnlocked: Int

    init() {
        self.id = UUID()
        self.currentLevel = 1
        self.totalXP = 0
        self.tasksCompleted = 0
        self.achievementsUnlocked = 0
    }

    // MARK: - XP Calculation

    /// XP required to reach the next level
    var xpForNextLevel: Int {
        100 * currentLevel + (currentLevel * currentLevel * 10)
    }

    /// XP earned in current level
    var currentLevelXP: Int {
        totalXP - xpForPreviousLevels
    }

    /// Total XP required for all previous levels
    private var xpForPreviousLevels: Int {
        guard currentLevel > 1 else { return 0 }

        var total = 0
        for level in 1..<currentLevel {
            total += 100 * level + (level * level * 10)
        }
        return total
    }

    /// Progress to next level (0.0 to 1.0)
    var levelProgress: Double {
        Double(currentLevelXP) / Double(xpForNextLevel)
    }

    /// Level title based on current level
    var levelTitle: String {
        switch currentLevel {
        case 1: return "Beginner"
        case 2...5: return "Apprentice"
        case 6...10: return "Journeyman"
        case 11...20: return "Expert"
        case 21...35: return "Master"
        case 36...50: return "Grand Master"
        default: return "Legend"
        }
    }

    // MARK: - XP Rewards

    /// Adds XP and checks for level up
    func addXP(_ amount: Int) -> Bool {
        totalXP += amount

        // Check for level up
        while currentLevelXP >= xpForNextLevel {
            currentLevel += 1
            return true  // Level up occurred
        }

        return false
    }

    /// XP reward for completing a task
    static func xpForTask(priority: TaskPriority, wasSkippedMultipleTimes: Bool) -> Int {
        var base: Int

        switch priority {
        case .high: base = 30
        case .normal: base = 20
        case .low: base = 10
        }

        // Bonus for completing difficult (oft-skipped) tasks
        if wasSkippedMultipleTimes {
            base += 15
        }

        return base
    }

    /// XP reward for unlocking an achievement
    static func xpForAchievement(category: AchievementCategory) -> Int {
        switch category {
        case .special: return 100
        case .milestones: return 50
        case .streaks: return 75
        case .productivity: return 40
        }
    }
}

/// Tracks completion streaks
@Model
final class Streak {
    @Attribute(.unique) var id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletionDate: Date?
    var streakStartDate: Date?

    init() {
        self.id = UUID()
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastCompletionDate = nil
        self.streakStartDate = nil
    }

    /// Records a completion and updates streak
    func recordCompletion() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = lastCompletionDate.map { Calendar.current.startOfDay(for: $0) }

        if let last = lastDate {
            if Calendar.current.isDate(last, inSameDayAs: today) {
                // Same day, no change to streak
                return
            }

            let daysBetween = Calendar.current.dateComponents([.day], from: last, to: today).day ?? 0

            if daysBetween == 1 {
                // Consecutive day, increment streak
                currentStreak += 1
            } else {
                // Streak broken, reset
                currentStreak = 1
                streakStartDate = today
            }
        } else {
            // First completion ever
            currentStreak = 1
            streakStartDate = today
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        lastCompletionDate = Date()
    }

    /// Checks if streak is still active (completed today or yesterday)
    var isActive: Bool {
        guard let last = lastCompletionDate else { return false }

        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = Calendar.current.startOfDay(for: last)

        let daysBetween = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0

        return daysBetween <= 1
    }

    /// Days remaining to maintain streak (0 if already completed today)
    var daysUntilStreakExpires: Int {
        guard let last = lastCompletionDate else { return 0 }

        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = Calendar.current.startOfDay(for: last)

        if Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return 1  // Can miss tomorrow
        }

        return 0  // Must complete today
    }
}
