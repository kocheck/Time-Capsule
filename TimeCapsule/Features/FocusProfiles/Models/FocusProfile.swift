import Foundation
import SwiftData

/// A focus profile that filters tasks based on tags and time
@Model
final class FocusProfile: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var color: String
    var includeTags: [String]
    var excludeTags: [String]
    var scheduleEnabled: Bool
    var scheduleStartHour: Int
    var scheduleEndHour: Int
    var scheduleDays: [Int]  // 1-7 (Sunday = 1)
    var isActive: Bool
    var createdAt: Date

    init(
        name: String,
        icon: String = "person.fill",
        color: String = "blue",
        includeTags: [String] = [],
        excludeTags: [String] = []
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.includeTags = includeTags
        self.excludeTags = excludeTags
        self.scheduleEnabled = false
        self.scheduleStartHour = 9
        self.scheduleEndHour = 17
        self.scheduleDays = [2, 3, 4, 5, 6]  // Mon-Fri
        self.isActive = false
        self.createdAt = Date()
    }

    /// Checks if a task matches this profile's filters
    func matches(_ task: TaskItem) -> Bool {
        // Check exclude tags first
        for tag in excludeTags {
            if task.tags.contains(tag) {
                return false
            }
        }

        // If include tags are specified, task must have at least one
        if !includeTags.isEmpty {
            let hasIncludedTag = task.tags.contains { includeTags.contains($0) }
            if !hasIncludedTag {
                return false
            }
        }

        return true
    }

    /// Checks if this profile should be active based on schedule
    func shouldBeActiveNow() -> Bool {
        guard scheduleEnabled else { return false }

        let now = Date()
        let calendar = Calendar.current

        let currentDayOfWeek = calendar.component(.weekday, from: now)
        let currentHour = calendar.component(.hour, from: now)

        guard scheduleDays.contains(currentDayOfWeek) else { return false }

        return currentHour >= scheduleStartHour && currentHour < scheduleEndHour
    }
}

// MARK: - Default Profiles

extension FocusProfile {
    static func defaultProfiles() -> [FocusProfile] {
        [
            {
                let profile = FocusProfile(name: "Work", icon: "briefcase.fill", color: "blue")
                profile.includeTags = ["work", "project", "meeting"]
                profile.scheduleEnabled = true
                profile.scheduleStartHour = 9
                profile.scheduleEndHour = 17
                profile.scheduleDays = [2, 3, 4, 5, 6]  // Mon-Fri
                return profile
            }(),
            {
                let profile = FocusProfile(name: "Personal", icon: "person.fill", color: "green")
                profile.excludeTags = ["work", "project"]
                profile.scheduleEnabled = true
                profile.scheduleStartHour = 18
                profile.scheduleEndHour = 22
                return profile
            }(),
            {
                let profile = FocusProfile(name: "Deep Work", icon: "brain.head.profile", color: "purple")
                profile.includeTags = ["coding", "writing", "design"]
                profile.excludeTags = ["quick", "admin"]
                return profile
            }()
        ]
    }
}

// MARK: - Profile Colors

extension FocusProfile {
    static let availableColors = [
        "blue", "green", "red", "purple", "orange", "yellow", "pink", "indigo"
    ]

    static let availableIcons = [
        "briefcase.fill", "person.fill", "brain.head.profile",
        "house.fill", "star.fill", "bolt.fill",
        "book.fill", "pencil", "laptopcomputer",
        "moon.fill", "sun.max.fill", "leaf.fill"
    ]
}
