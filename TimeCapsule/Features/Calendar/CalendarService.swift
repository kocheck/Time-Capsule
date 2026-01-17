import Foundation
import EventKit

/// Represents a free time gap between events
struct FreeTimeGap: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }

    var durationFormatted: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }

    var isGoodForDeepWork: Bool {
        durationMinutes >= 45
    }

    var isGoodForQuickTask: Bool {
        durationMinutes >= 15 && durationMinutes < 45
    }
}

/// Service for calendar integration (read-only)
@Observable
class CalendarService {
    private let eventStore = EKEventStore()

    var isAuthorized = false
    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    var todayEvents: [EKEvent] = []
    var freeTimeGaps: [FreeTimeGap] = []
    var nextEvent: EKEvent?

    init() {
        checkAuthorization()
    }

    // MARK: - Authorization

    /// Checks current authorization status
    func checkAuthorization() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = authorizationStatus == .fullAccess || authorizationStatus == .authorized
    }

    /// Requests calendar access
    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                isAuthorized = granted
                authorizationStatus = granted ? .fullAccess : .denied
            }
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Event Fetching

    /// Fetches today's events
    func fetchTodayEvents() async {
        guard isAuthorized else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        await MainActor.run {
            todayEvents = events
            calculateFreeTimeGaps(events: events, dayStart: startOfDay, dayEnd: endOfDay)
            updateNextEvent()
        }
    }

    /// Fetches events for a specific date range
    func fetchEvents(from start: Date, to end: Date) async -> [EKEvent] {
        guard isAuthorized else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Free Time Analysis

    /// Calculates gaps between events
    private func calculateFreeTimeGaps(events: [EKEvent], dayStart: Date, dayEnd: Date) {
        var gaps: [FreeTimeGap] = []

        // Define work hours (9 AM to 6 PM)
        let calendar = Calendar.current
        let workStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dayStart)!
        let workEnd = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: dayStart)!

        let now = Date()
        var lastEndTime = max(workStart, now)

        for event in events where !event.isAllDay {
            let eventStart = event.startDate!
            let eventEnd = event.endDate!

            // Only consider events within work hours
            guard eventStart < workEnd && eventEnd > workStart else { continue }

            // If there's a gap before this event
            if eventStart > lastEndTime {
                let gapStart = lastEndTime
                let gapEnd = min(eventStart, workEnd)

                if gapEnd > gapStart {
                    let gap = FreeTimeGap(start: gapStart, end: gapEnd)
                    if gap.durationMinutes >= 10 {  // Minimum 10 min gap
                        gaps.append(gap)
                    }
                }
            }

            lastEndTime = max(lastEndTime, eventEnd)
        }

        // Check for gap at end of day
        if lastEndTime < workEnd {
            let gap = FreeTimeGap(start: lastEndTime, end: workEnd)
            if gap.durationMinutes >= 10 {
                gaps.append(gap)
            }
        }

        freeTimeGaps = gaps
    }

    /// Updates the next upcoming event
    private func updateNextEvent() {
        let now = Date()
        nextEvent = todayEvents.first { $0.startDate > now }
    }

    // MARK: - Availability Helpers

    /// Returns minutes until the next event
    var minutesUntilNextEvent: Int? {
        guard let next = nextEvent else { return nil }
        let interval = next.startDate.timeIntervalSince(Date())
        return max(0, Int(interval / 60))
    }

    /// Returns the current free time gap (if any)
    var currentFreeGap: FreeTimeGap? {
        let now = Date()
        return freeTimeGaps.first { $0.start <= now && $0.end > now }
    }

    /// Checks if now is a good time for deep work
    var isGoodTimeForDeepWork: Bool {
        guard let gap = currentFreeGap else { return false }
        return gap.isGoodForDeepWork
    }

    /// Returns a suggestion based on available time
    var availabilitySuggestion: String {
        if let gap = currentFreeGap {
            if gap.isGoodForDeepWork {
                return "You have \(gap.durationFormatted) free - great for deep work!"
            } else {
                return "You have \(gap.durationFormatted) - good for a quick task"
            }
        } else if let minutes = minutesUntilNextEvent, minutes < 30 {
            return "Meeting in \(minutes) min - maybe tackle something quick"
        } else if todayEvents.isEmpty {
            return "Your calendar is clear today"
        } else {
            return "Currently in a meeting or event"
        }
    }
}
