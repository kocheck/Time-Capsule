import Foundation

/// Service for parsing natural language input into structured task data
///
/// Example inputs:
/// - "Remind me to call mom next week when I'm free in the evening"
/// - "Buy groceries tomorrow morning"
/// - "URGENT: Submit tax returns by Friday"
/// - "Schedule dentist appointment sometime this weekend"
final class NaturalLanguageParser {

    // MARK: - Pattern Definitions

    /// Words that indicate the start of a task action (to be removed from title)
    private static let prefixPatterns: [String] = [
        "remind me to",
        "remember to",
        "don't forget to",
        "i need to",
        "i have to",
        "i should",
        "i must",
        "i want to",
        "need to",
        "have to",
        "should",
        "must",
        "want to",
        "gotta",
        "gonna"
    ]

    /// Words indicating high priority
    private static let highPriorityIndicators: [String] = [
        "urgent",
        "asap",
        "immediately",
        "critical",
        "important",
        "priority",
        "emergency",
        "crucial",
        "vital",
        "pressing"
    ]

    /// Words indicating low priority
    private static let lowPriorityIndicators: [String] = [
        "sometime",
        "eventually",
        "whenever",
        "if possible",
        "when i can",
        "when i have time",
        "low priority",
        "not urgent",
        "no rush",
        "maybe"
    ]

    /// Time of day patterns
    private static let timeOfDayPatterns: [String: ParsedTask.TimeOfDay] = [
        "morning": .morning,
        "in the morning": .morning,
        "this morning": .morning,
        "tomorrow morning": .morning,
        "am": .morning,
        "before noon": .morning,
        "early": .morning,

        "afternoon": .afternoon,
        "in the afternoon": .afternoon,
        "this afternoon": .afternoon,
        "midday": .afternoon,
        "lunch": .afternoon,
        "after lunch": .afternoon,

        "evening": .evening,
        "in the evening": .evening,
        "this evening": .evening,
        "tonight": .evening,
        "after work": .evening,
        "after dinner": .evening,
        "pm": .evening,

        "night": .night,
        "at night": .night,
        "late night": .night,
        "before bed": .night,
        "bedtime": .night
    ]

    /// Day context patterns
    private static let dayContextPatterns: [String: ParsedTask.DayContext] = [
        "weekday": .weekday,
        "on a weekday": .weekday,
        "during the week": .weekday,
        "work day": .weekday,
        "workday": .weekday,

        "weekend": .weekend,
        "on the weekend": .weekend,
        "this weekend": .weekend,
        "next weekend": .weekend,
        "saturday or sunday": .weekend,

        "monday": .monday,
        "on monday": .monday,
        "next monday": .monday,
        "this monday": .monday,

        "tuesday": .tuesday,
        "on tuesday": .tuesday,
        "next tuesday": .tuesday,
        "this tuesday": .tuesday,

        "wednesday": .wednesday,
        "on wednesday": .wednesday,
        "next wednesday": .wednesday,
        "this wednesday": .wednesday,

        "thursday": .thursday,
        "on thursday": .thursday,
        "next thursday": .thursday,
        "this thursday": .thursday,

        "friday": .friday,
        "on friday": .friday,
        "next friday": .friday,
        "this friday": .friday,

        "saturday": .saturday,
        "on saturday": .saturday,
        "next saturday": .saturday,
        "this saturday": .saturday,

        "sunday": .sunday,
        "on sunday": .sunday,
        "next sunday": .sunday,
        "this sunday": .sunday
    ]

    /// Relative time patterns
    private static let relativeTimePatterns: [String] = [
        "today",
        "tomorrow",
        "next week",
        "this week",
        "next month",
        "this month",
        "later",
        "soon",
        "in a few days",
        "in a couple days",
        "by end of day",
        "by eod",
        "by end of week",
        "by eow",
        "next year"
    ]

    /// Context phrases to strip from the title
    private static let contextPhrases: [String] = [
        "when i'm free",
        "when i have time",
        "when possible",
        "if i can",
        "if possible"
    ]

    /// Common action verbs that can become tags
    private static let actionVerbTags: [String: String] = [
        "call": "call",
        "phone": "call",
        "text": "message",
        "message": "message",
        "email": "email",
        "send": "email",
        "buy": "shopping",
        "purchase": "shopping",
        "shop": "shopping",
        "get": "errand",
        "pick up": "errand",
        "pickup": "errand",
        "schedule": "scheduling",
        "book": "scheduling",
        "make appointment": "appointment",
        "appointment": "appointment",
        "meet": "meeting",
        "meeting": "meeting",
        "pay": "finance",
        "submit": "work",
        "finish": "work",
        "complete": "work",
        "write": "writing",
        "read": "reading",
        "study": "learning",
        "learn": "learning",
        "practice": "learning",
        "exercise": "health",
        "workout": "health",
        "run": "health",
        "clean": "home",
        "organize": "home",
        "fix": "maintenance",
        "repair": "maintenance"
    ]

    /// People/relationship tags
    private static let relationshipTags: [String: String] = [
        "mom": "family",
        "dad": "family",
        "mother": "family",
        "father": "family",
        "parent": "family",
        "parents": "family",
        "brother": "family",
        "sister": "family",
        "sibling": "family",
        "grandma": "family",
        "grandpa": "family",
        "grandmother": "family",
        "grandfather": "family",
        "aunt": "family",
        "uncle": "family",
        "cousin": "family",
        "wife": "family",
        "husband": "family",
        "spouse": "family",
        "son": "family",
        "daughter": "family",
        "kid": "family",
        "kids": "family",
        "children": "family",
        "friend": "social",
        "friends": "social",
        "colleague": "work",
        "coworker": "work",
        "boss": "work",
        "manager": "work",
        "client": "work",
        "doctor": "health",
        "dentist": "health",
        "therapist": "health"
    ]

    // MARK: - Public API

    /// Parse natural language input into a structured ParsedTask
    /// - Parameter input: The natural language string to parse
    /// - Returns: A ParsedTask with extracted components
    func parse(_ input: String) -> ParsedTask {
        let lowercased = input.lowercased()
        var workingText = input

        // Extract priority
        let priority = extractPriority(from: lowercased)

        // Extract time of day context hints
        var contextHints: [String] = []
        contextHints.append(contentsOf: extractTimeOfDayHints(from: lowercased))
        contextHints.append(contentsOf: extractDayContextHints(from: lowercased))

        // Extract time hint
        let timeHint = extractTimeHint(from: lowercased)

        // Extract tags
        var tags = Set<String>()
        tags.formUnion(extractActionTags(from: lowercased))
        tags.formUnion(extractRelationshipTags(from: lowercased))

        // Clean the title
        let title = cleanTitle(from: workingText, lowercased: lowercased)

        // Build description from time context if present
        var description: String?
        if let hint = timeHint, !contextHints.isEmpty {
            description = "Scheduled for \(hint), preferably in the \(contextHints.first ?? "")."
        } else if let hint = timeHint {
            description = "Scheduled for \(hint)."
        } else if !contextHints.isEmpty {
            let contextDescription = contextHints.joined(separator: ", ")
            description = "Best time: \(contextDescription)."
        }

        return ParsedTask(
            title: title,
            description: description,
            tags: Array(tags).sorted(),
            contextHints: contextHints,
            priority: priority,
            timeHint: timeHint
        )
    }

    // MARK: - Private Extraction Methods

    private func extractPriority(from text: String) -> TaskPriority {
        // Check for high priority indicators
        for indicator in Self.highPriorityIndicators {
            if text.contains(indicator) {
                return .high
            }
        }

        // Check for low priority indicators
        for indicator in Self.lowPriorityIndicators {
            if text.contains(indicator) {
                return .low
            }
        }

        return .normal
    }

    private func extractTimeOfDayHints(from text: String) -> [String] {
        var hints: [String] = []

        // Sort by length descending to match longer phrases first
        let sortedPatterns = Self.timeOfDayPatterns.keys.sorted { $0.count > $1.count }

        for pattern in sortedPatterns {
            if text.contains(pattern) {
                if let timeOfDay = Self.timeOfDayPatterns[pattern] {
                    if !hints.contains(timeOfDay.contextHint) {
                        hints.append(timeOfDay.contextHint)
                    }
                }
            }
        }

        return hints
    }

    private func extractDayContextHints(from text: String) -> [String] {
        var hints: [String] = []

        // Sort by length descending to match longer phrases first
        let sortedPatterns = Self.dayContextPatterns.keys.sorted { $0.count > $1.count }

        for pattern in sortedPatterns {
            if text.contains(pattern) {
                if let dayContext = Self.dayContextPatterns[pattern] {
                    if !hints.contains(dayContext.contextHint) {
                        hints.append(dayContext.contextHint)
                    }
                }
            }
        }

        return hints
    }

    private func extractTimeHint(from text: String) -> String? {
        // Sort by length descending to match longer phrases first
        let sortedPatterns = Self.relativeTimePatterns.sorted { $0.count > $1.count }

        for pattern in sortedPatterns {
            if text.contains(pattern) {
                return pattern
            }
        }

        return nil
    }

    private func extractActionTags(from text: String) -> Set<String> {
        var tags = Set<String>()

        // Sort by length descending to match longer phrases first
        let sortedActions = Self.actionVerbTags.keys.sorted { $0.count > $1.count }

        for action in sortedActions {
            if text.contains(action) {
                if let tag = Self.actionVerbTags[action] {
                    tags.insert(tag)
                }
            }
        }

        return tags
    }

    private func extractRelationshipTags(from text: String) -> Set<String> {
        var tags = Set<String>()

        // Use word boundary matching for relationship terms
        let words = text.components(separatedBy: .alphanumerics.inverted)
            .filter { !$0.isEmpty }

        for word in words {
            if let tag = Self.relationshipTags[word] {
                tags.insert(tag)
            }
        }

        return tags
    }

    private func cleanTitle(from original: String, lowercased: String) -> String {
        var result = original

        // Remove prefix patterns (case-insensitive)
        for prefix in Self.prefixPatterns {
            if lowercased.hasPrefix(prefix) {
                result = String(result.dropFirst(prefix.count))
                break
            }
        }

        // Remove priority indicators
        for indicator in Self.highPriorityIndicators + Self.lowPriorityIndicators {
            result = result.replacingOccurrences(
                of: indicator,
                with: "",
                options: .caseInsensitive
            )
        }

        // Remove time of day patterns
        for pattern in Self.timeOfDayPatterns.keys.sorted(by: { $0.count > $1.count }) {
            result = result.replacingOccurrences(
                of: pattern,
                with: "",
                options: .caseInsensitive
            )
        }

        // Remove day context patterns
        for pattern in Self.dayContextPatterns.keys.sorted(by: { $0.count > $1.count }) {
            result = result.replacingOccurrences(
                of: pattern,
                with: "",
                options: .caseInsensitive
            )
        }

        // Remove relative time patterns
        for pattern in Self.relativeTimePatterns.sorted(by: { $0.count > $1.count }) {
            result = result.replacingOccurrences(
                of: pattern,
                with: "",
                options: .caseInsensitive
            )
        }

        // Remove context phrases
        for phrase in Self.contextPhrases {
            result = result.replacingOccurrences(
                of: phrase,
                with: "",
                options: .caseInsensitive
            )
        }

        // Clean up punctuation and whitespace
        result = result
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Capitalize first letter
        if let first = result.first {
            result = first.uppercased() + result.dropFirst()
        }

        return result
    }
}
