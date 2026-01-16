import Foundation
import UserNotifications
import OSLog

final class NotificationService {
    static let shared = NotificationService()
    private let logger = Logger.service

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        logger.info("Notification authorization: \(granted)")
        return granted
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Daily Notification

    func scheduleDailyNotification(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()

        // Remove existing daily notifications
        center.removePendingNotificationRequests(withIdentifiers: [Constants.notificationIdentifier])

        // Create new notification
        let content = UNMutableNotificationContent()
        content.title = "Time Capsule"
        content.body = "Ready to tackle your tasks today?"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Constants.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                self?.logger.info("Scheduled daily notification for \(hour):\(minute)")
            }
        }
    }

    func cancelDailyNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Constants.notificationIdentifier])
        logger.info("Cancelled daily notification")
    }

    // MARK: - Badge

    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to update badge: \(error.localizedDescription)")
            }
        }
    }

    func clearBadge() {
        updateBadgeCount(0)
    }

    // MARK: - One-time Notifications

    func sendNotification(title: String, body: String, delay: TimeInterval = 0) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = delay > 0 ?
            UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) :
            nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
}
