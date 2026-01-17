import Foundation
import SwiftData

/// User preferences for Pomodoro timer
@Model
final class PomodoroSettings {
    @Attribute(.unique) var id: UUID

    /// Duration of a work session in minutes
    var workMinutes: Int

    /// Duration of a short break in minutes
    var shortBreakMinutes: Int

    /// Duration of a long break in minutes
    var longBreakMinutes: Int

    /// Number of work sessions before a long break
    var sessionsUntilLongBreak: Int

    /// Whether to automatically start breaks
    var autoStartBreaks: Bool

    /// Whether to automatically start the next work session after a break
    var autoStartWork: Bool

    /// Whether to play a sound when timer completes
    var playSound: Bool

    /// Whether to show a notification when timer completes
    var showNotification: Bool

    /// Sound name to play (system sound identifier)
    var soundName: String

    init() {
        self.id = UUID()
        self.workMinutes = 25
        self.shortBreakMinutes = 5
        self.longBreakMinutes = 15
        self.sessionsUntilLongBreak = 4
        self.autoStartBreaks = false
        self.autoStartWork = false
        self.playSound = true
        self.showNotification = true
        self.soundName = "Glass"
    }

    /// Returns the default settings
    static var defaults: PomodoroSettings {
        PomodoroSettings()
    }
}

// MARK: - Computed Properties

extension PomodoroSettings {
    /// Work duration in seconds
    var workSeconds: Int {
        workMinutes * 60
    }

    /// Short break duration in seconds
    var shortBreakSeconds: Int {
        shortBreakMinutes * 60
    }

    /// Long break duration in seconds
    var longBreakSeconds: Int {
        longBreakMinutes * 60
    }
}
