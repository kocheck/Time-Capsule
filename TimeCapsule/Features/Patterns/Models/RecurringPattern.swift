import Foundation
import SwiftData

/// Frequency of a detected pattern
enum PatternFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"

    var dayCount: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        }
    }

    var displayName: String { rawValue }
}

/// A detected recurring task pattern
@Model
final class RecurringPattern: Identifiable {
    @Attribute(.unique) var id: UUID
    var titlePattern: String
    var frequency: PatternFrequency
    var confidence: Double
    var occurrenceCount: Int
    var averageDayOfWeek: Int?  // 1-7, Sunday = 1
    var suggestedTags: [String]
    var lastOccurrence: Date?
    var isActive: Bool
    var wasAccepted: Bool
    var wasDismissed: Bool
    var createdAt: Date

    init(
        titlePattern: String,
        frequency: PatternFrequency,
        confidence: Double,
        occurrenceCount: Int
    ) {
        self.id = UUID()
        self.titlePattern = titlePattern
        self.frequency = frequency
        self.confidence = confidence
        self.occurrenceCount = occurrenceCount
        self.suggestedTags = []
        self.isActive = true
        self.wasAccepted = false
        self.wasDismissed = false
        self.createdAt = Date()
    }

    /// Day name if pattern has a preferred day
    var preferredDayName: String? {
        guard let day = averageDayOfWeek else { return nil }
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[day - 1]
    }

    /// Confidence label
    var confidenceLabel: String {
        switch confidence {
        case 0.8...: return "High"
        case 0.6..<0.8: return "Medium"
        default: return "Low"
        }
    }

    /// Next suggested date based on pattern
    var nextSuggestedDate: Date? {
        guard let last = lastOccurrence else { return nil }

        let calendar = Calendar.current

        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: last)

        case .weekly:
            if let preferredDay = averageDayOfWeek {
                // Find next occurrence of preferred day
                var nextDate = calendar.date(byAdding: .day, value: 1, to: last)!
                while calendar.component(.weekday, from: nextDate) != preferredDay {
                    nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
                }
                return nextDate
            }
            return calendar.date(byAdding: .weekOfYear, value: 1, to: last)

        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: last)

        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: last)
        }
    }

    /// Whether a task should be suggested now
    var shouldSuggestNow: Bool {
        guard isActive, !wasDismissed else { return false }

        guard let nextDate = nextSuggestedDate else {
            // No last occurrence, suggest if it's a new pattern
            return confidence > 0.6
        }

        let now = Date()
        let calendar = Calendar.current

        // Suggest if we're within a day of the next date
        let daysBetween = calendar.dateComponents([.day], from: now, to: nextDate).day ?? 0
        return daysBetween <= 1 && daysBetween >= 0
    }
}

/// A suggestion based on a detected pattern
struct PatternSuggestion: Identifiable {
    let id = UUID()
    let pattern: RecurringPattern
    let suggestedTitle: String
    let suggestedDate: Date?

    var message: String {
        if let day = pattern.preferredDayName {
            return "Create '\(suggestedTitle)' every \(day)?"
        } else {
            return "Create '\(suggestedTitle)' \(pattern.frequency.displayName.lowercased())?"
        }
    }
}
