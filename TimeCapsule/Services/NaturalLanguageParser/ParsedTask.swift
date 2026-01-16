import Foundation

/// Represents the result of parsing natural language input into task components
struct ParsedTask {
    /// The extracted task title/action
    var title: String

    /// Optional additional description extracted from the input
    var description: String?

    /// Tags inferred from the input (e.g., "call", "family", "work")
    var tags: [String]

    /// Context hints for when the task should be done (e.g., "evening", "weekday", "morning")
    var contextHints: [String]

    /// Inferred priority based on urgency indicators
    var priority: TaskPriority

    /// Time-related hints extracted from the input (e.g., "next week", "tomorrow")
    var timeHint: String?

    init(
        title: String,
        description: String? = nil,
        tags: [String] = [],
        contextHints: [String] = [],
        priority: TaskPriority = .normal,
        timeHint: String? = nil
    ) {
        self.title = title
        self.description = description
        self.tags = tags
        self.contextHints = contextHints
        self.priority = priority
        self.timeHint = timeHint
    }
}

// MARK: - Time Context

extension ParsedTask {
    /// Represents time-of-day context extracted from natural language
    enum TimeOfDay: String, CaseIterable {
        case morning
        case afternoon
        case evening
        case night

        var contextHint: String { rawValue }
    }

    /// Represents day-of-week context extracted from natural language
    enum DayContext: String, CaseIterable {
        case weekday
        case weekend
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday
        case sunday

        var contextHint: String { rawValue }
    }
}
