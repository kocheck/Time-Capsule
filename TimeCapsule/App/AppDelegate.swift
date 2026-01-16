import Cocoa
import SwiftUI
import UserNotifications
import OSLog

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private let logger = Logger.app

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Time Capsule launched")

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Hide from Dock (optional - menu bar app)
        // NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Time Capsule terminating")
        KeyboardShortcutService.shared.unregisterHotKey()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        logger.info("Notification received: \(response.notification.request.identifier)")

        // Handle notification actions here if needed
        // For example, open the app when notification is tapped

        completionHandler()
    }
}
