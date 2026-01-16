import Foundation

enum Constants {
    // MARK: - App Info
    static let appName = "Time Capsule"
    static let bundleIdentifier = "com.timecapsule.app"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // MARK: - UI Configuration
    static let menuBarWidth: CGFloat = 380
    static let menuBarHeight: CGFloat = 520
    static let cornerRadius: CGFloat = 12
    static let spacing: CGFloat = 12
    static let padding: CGFloat = 16

    // MARK: - Task Management
    static let staleTaskThresholdDays = 30
    static let focusModeSkipThreshold = 3
    static let maxRecentTags = 10
    static let maxSuggestedTags = 5

    // MARK: - AI Configuration
    static let aiRequestTimeout: TimeInterval = 30
    static let aiMaxRetries = 3
    static let contextWindowHours = 24

    // MARK: - Notifications
    static let defaultNotificationHour = 9
    static let defaultNotificationMinute = 0
    static let notificationIdentifier = "com.timecapsule.daily-reminder"

    // MARK: - Data
    static let maxCompletedTasksHistory = 100
    static let statsHistoryDays = 90
    static let autoArchiveDays = 60

    // MARK: - Animation
    static let shortAnimationDuration: TimeInterval = 0.2
    static let mediumAnimationDuration: TimeInterval = 0.3
    static let longAnimationDuration: TimeInterval = 0.5

    // MARK: - Keyboard Shortcuts
    static let defaultShortcutKey = 17 // T key
    static let defaultShortcutModifiers: UInt = 1048840 // Cmd + Shift

    // MARK: - URLs
    static let githubURL = URL(string: "https://github.com/timecapsule/timecapsule")!
    static let documentationURL = URL(string: "https://docs.timecapsule.app")!
    static let supportURL = URL(string: "https://support.timecapsule.app")!

    // MARK: - Ollama
    static let defaultOllamaEndpoint = "http://localhost:11434"
    static let defaultOllamaModel = "llama3.1"
    static let ollamaHealthCheckPath = "/api/tags"
    static let ollamaGeneratePath = "/api/generate"
}
