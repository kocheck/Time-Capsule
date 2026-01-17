import Foundation
import SwiftData

/// Represents an achievement that can be unlocked
@Model
final class Achievement: Identifiable {
    @Attribute(.unique) var id: String
    var name: String
    var achievementDescription: String
    var icon: String
    var category: AchievementCategory
    var requirement: Int
    var isUnlocked: Bool
    var unlockedAt: Date?
    var progress: Int

    init(
        id: String,
        name: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        requirement: Int
    ) {
        self.id = id
        self.name = name
        self.achievementDescription = description
        self.icon = icon
        self.category = category
        self.requirement = requirement
        self.isUnlocked = false
        self.unlockedAt = nil
        self.progress = 0
    }

    var progressPercentage: Double {
        guard requirement > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(requirement))
    }

    func unlock() {
        guard !isUnlocked else { return }
        isUnlocked = true
        unlockedAt = Date()
        progress = requirement
    }

    func updateProgress(_ newProgress: Int) {
        progress = newProgress
        if progress >= requirement {
            unlock()
        }
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case productivity = "Productivity"
    case streaks = "Streaks"
    case milestones = "Milestones"
    case special = "Special"

    var icon: String {
        switch self {
        case .productivity: return "bolt.fill"
        case .streaks: return "flame.fill"
        case .milestones: return "flag.fill"
        case .special: return "star.fill"
        }
    }
}

// MARK: - Default Achievements

extension Achievement {
    static func defaultAchievements() -> [Achievement] {
        [
            // Productivity
            Achievement(id: "task_slayer", name: "Task Slayer", description: "Complete 10 tasks in one day", icon: "bolt.circle.fill", category: .productivity, requirement: 10),
            Achievement(id: "productivity_burst", name: "Productivity Burst", description: "Complete 5 tasks in one hour", icon: "hare.fill", category: .productivity, requirement: 5),
            Achievement(id: "early_bird", name: "Early Bird", description: "Complete a task before 8 AM", icon: "sunrise.fill", category: .productivity, requirement: 1),
            Achievement(id: "night_owl", name: "Night Owl", description: "Complete a task after 10 PM", icon: "moon.stars.fill", category: .productivity, requirement: 1),
            Achievement(id: "no_skip", name: "No Skip Day", description: "Complete all presented tasks without skipping", icon: "checkmark.seal.fill", category: .productivity, requirement: 1),

            // Streaks
            Achievement(id: "streak_3", name: "Getting Started", description: "Maintain a 3-day completion streak", icon: "flame", category: .streaks, requirement: 3),
            Achievement(id: "streak_7", name: "Streak Master", description: "Maintain a 7-day completion streak", icon: "flame.fill", category: .streaks, requirement: 7),
            Achievement(id: "streak_30", name: "Unstoppable", description: "Maintain a 30-day completion streak", icon: "flame.circle.fill", category: .streaks, requirement: 30),
            Achievement(id: "streak_100", name: "Legendary", description: "Maintain a 100-day completion streak", icon: "crown.fill", category: .streaks, requirement: 100),

            // Milestones
            Achievement(id: "first_task", name: "First Step", description: "Complete your first task", icon: "1.circle.fill", category: .milestones, requirement: 1),
            Achievement(id: "tasks_10", name: "Warming Up", description: "Complete 10 total tasks", icon: "10.circle.fill", category: .milestones, requirement: 10),
            Achievement(id: "tasks_50", name: "Getting Serious", description: "Complete 50 total tasks", icon: "50.circle.fill", category: .milestones, requirement: 50),
            Achievement(id: "tasks_100", name: "Centurion", description: "Complete 100 total tasks", icon: "100.circle.fill", category: .milestones, requirement: 100),
            Achievement(id: "tasks_500", name: "Task Champion", description: "Complete 500 total tasks", icon: "star.circle.fill", category: .milestones, requirement: 500),
            Achievement(id: "tasks_1000", name: "Task Legend", description: "Complete 1000 total tasks", icon: "trophy.fill", category: .milestones, requirement: 1000),

            // Special
            Achievement(id: "tag_master", name: "Tag Master", description: "Use 10 different tags", icon: "tag.fill", category: .special, requirement: 10),
            Achievement(id: "pomodoro_pro", name: "Pomodoro Pro", description: "Complete 25 pomodoro sessions", icon: "timer", category: .special, requirement: 25),
            Achievement(id: "zero_inbox", name: "Zero Inbox", description: "Clear all pending tasks", icon: "tray.fill", category: .special, requirement: 1),
        ]
    }
}
