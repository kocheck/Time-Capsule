import Foundation
import SwiftData
import Observation

@Observable
final class SettingsViewModel {
    private let modelContext: ModelContext
    private let dataService: DataService

    var settings: AppSettings
    var isLoading: Bool = false
    var error: Error?
    var saveSuccess: Bool = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataService = DataService(modelContext: modelContext)
        self.settings = dataService.getSettings()
    }

    // MARK: - Settings Management

    @MainActor
    func saveSettings() {
        isLoading = true
        saveSuccess = false
        defer { isLoading = false }

        do {
            try dataService.saveSettings(settings)
            saveSuccess = true
        } catch {
            self.error = error
        }
    }

    @MainActor
    func resetToDefaults() {
        settings = AppSettings()
        saveSettings()
    }

    // MARK: - AI Provider

    func updateAIProvider(_ provider: AIProvider) {
        settings.aiProvider = provider
    }

    func updateOllamaEndpoint(_ endpoint: String) {
        settings.ollamaEndpoint = endpoint
    }

    func updateOllamaModel(_ model: String) {
        settings.ollamaModel = model
    }

    // MARK: - Notifications

    func updateDailyNotification(enabled: Bool, hour: Int, minute: Int) {
        settings.showDailyNotification = enabled
        settings.dailyNotificationHour = hour
        settings.dailyNotificationMinute = minute

        if enabled {
            NotificationService.shared.scheduleDailyNotification(hour: hour, minute: minute)
        } else {
            NotificationService.shared.cancelDailyNotification()
        }
    }

    // MARK: - Badge

    func updateBadgeCount(enabled: Bool) {
        settings.showBadgeCount = enabled

        if !enabled {
            NotificationService.shared.clearBadge()
        }
    }

    // MARK: - Keyboard Shortcut

    func updateKeyboardShortcut(keyCode: Int, modifiers: UInt, callback: @escaping () -> Void) {
        settings.globalShortcutKeyCode = keyCode
        settings.globalShortcutModifiers = modifiers

        let carbonModifiers = KeyboardShortcutService.modifierFlagsToCarbon(modifiers)
        _ = KeyboardShortcutService.shared.registerHotKey(
            keyCode: keyCode,
            modifiers: carbonModifiers,
            callback: callback
        )
    }

    // MARK: - Launch at Login

    func updateLaunchAtLogin(enabled: Bool) {
        settings.launchAtLogin = enabled
        // Note: Actual implementation would use SMLoginItemSetEnabled or ServiceManagement framework
    }

    // MARK: - Theme

    func updateTheme(_ theme: AppTheme) {
        settings.theme = theme
    }

    // MARK: - Task Management

    func updateSkipThreshold(_ threshold: Int) {
        settings.skipThreshold = threshold
    }

    func updateStaleTaskDays(_ days: Int) {
        settings.staleTaskDays = days
    }

    // MARK: - iCloud Sync

    func updateiCloudSync(enabled: Bool) {
        settings.enableiCloudSync = enabled
        // Note: Actual implementation would configure NSPersistentCloudKitContainer
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        saveSettings()
    }

    var hasCompletedOnboarding: Bool {
        settings.hasCompletedOnboarding
    }
}
