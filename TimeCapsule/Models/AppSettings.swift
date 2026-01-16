import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var aiProvider: AIProvider
    var ollamaEndpoint: String
    var ollamaModel: String
    var globalShortcutKeyCode: Int
    var globalShortcutModifiers: UInt
    var showBadgeCount: Bool
    var enableiCloudSync: Bool
    var skipThreshold: Int
    var staleTaskDays: Int
    var launchAtLogin: Bool
    var showDailyNotification: Bool
    var dailyNotificationHour: Int
    var dailyNotificationMinute: Int
    var hasCompletedOnboarding: Bool
    var theme: AppTheme

    init() {
        self.id = UUID()
        self.aiProvider = .appleIntelligence
        self.ollamaEndpoint = "http://localhost:11434"
        self.ollamaModel = "llama3.1"
        self.globalShortcutKeyCode = 17 // T key
        self.globalShortcutModifiers = 1048840 // Cmd + Shift
        self.showBadgeCount = true
        self.enableiCloudSync = false
        self.skipThreshold = 3
        self.staleTaskDays = 30
        self.launchAtLogin = false
        self.showDailyNotification = true
        self.dailyNotificationHour = 9
        self.dailyNotificationMinute = 0
        self.hasCompletedOnboarding = false
        self.theme = .system
    }
}
