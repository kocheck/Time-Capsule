import Foundation
import SwiftData

/// Detects recurring patterns in task titles
@Observable
class PatternDetector {
    private let modelContext: ModelContext
    private let minimumOccurrences = 3
    private let similarityThreshold = 0.7

    var detectedPatterns: [RecurringPattern] = []
    var pendingSuggestions: [PatternSuggestion] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Pattern Detection

    /// Analyzes completed tasks to find recurring patterns
    func analyzePatterns() async {
        let completedTasks = await fetchCompletedTasks()

        guard completedTasks.count >= minimumOccurrences else { return }

        // Group similar tasks
        var taskGroups: [[TaskItem]] = []

        for task in completedTasks {
            var foundGroup = false

            for i in taskGroups.indices {
                if let representative = taskGroups[i].first,
                   areTitlesSimilar(task.title, representative.title) {
                    taskGroups[i].append(task)
                    foundGroup = true
                    break
                }
            }

            if !foundGroup {
                taskGroups.append([task])
            }
        }

        // Analyze each group for patterns
        var patterns: [RecurringPattern] = []

        for group in taskGroups where group.count >= minimumOccurrences {
            if let pattern = detectPatternInGroup(group) {
                patterns.append(pattern)
            }
        }

        // Save patterns
        await MainActor.run {
            detectedPatterns = patterns
            updateSuggestions()
        }

        // Persist patterns
        for pattern in patterns {
            // Check if pattern already exists
            if !existingPatternMatches(pattern) {
                modelContext.insert(pattern)
            }
        }
        try? modelContext.save()
    }

    /// Detects pattern frequency and confidence for a group of similar tasks
    private func detectPatternInGroup(_ tasks: [TaskItem]) -> RecurringPattern? {
        guard tasks.count >= minimumOccurrences else { return nil }

        let sortedTasks = tasks.sorted { $0.createdAt < $1.createdAt }
        let titlePattern = extractCommonTitle(from: sortedTasks.map(\.title))

        // Calculate intervals between tasks
        var intervals: [Int] = []
        for i in 1..<sortedTasks.count {
            let days = Calendar.current.dateComponents(
                [.day],
                from: sortedTasks[i - 1].createdAt,
                to: sortedTasks[i].createdAt
            ).day ?? 0
            intervals.append(days)
        }

        guard !intervals.isEmpty else { return nil }

        // Determine frequency
        let avgInterval = intervals.reduce(0, +) / intervals.count
        let frequency = determineFrequency(avgInterval: avgInterval)

        // Calculate confidence based on interval consistency
        let variance = calculateVariance(intervals, mean: avgInterval)
        let confidence = max(0, min(1, 1.0 - (variance / Double(avgInterval * avgInterval + 1))))

        // Only accept patterns with reasonable confidence
        guard confidence >= 0.5 else { return nil }

        let pattern = RecurringPattern(
            titlePattern: titlePattern,
            frequency: frequency,
            confidence: confidence,
            occurrenceCount: tasks.count
        )

        // Calculate average day of week for weekly patterns
        if frequency == .weekly {
            let daysOfWeek = sortedTasks.map { Calendar.current.component(.weekday, from: $0.createdAt) }
            pattern.averageDayOfWeek = mostCommon(in: daysOfWeek)
        }

        // Extract common tags
        let allTags = tasks.flatMap(\.tags)
        let tagCounts = Dictionary(grouping: allTags, by: { $0 }).mapValues(\.count)
        pattern.suggestedTags = tagCounts.filter { $0.value >= tasks.count / 2 }.map(\.key)

        // Set last occurrence
        pattern.lastOccurrence = sortedTasks.last?.completedAt ?? sortedTasks.last?.createdAt

        return pattern
    }

    /// Determines frequency based on average interval
    private func determineFrequency(avgInterval: Int) -> PatternFrequency {
        switch avgInterval {
        case 0...2: return .daily
        case 3...10: return .weekly
        case 11...21: return .biweekly
        default: return .monthly
        }
    }

    // MARK: - Suggestions

    /// Updates pending suggestions based on detected patterns
    func updateSuggestions() {
        pendingSuggestions = detectedPatterns
            .filter { $0.shouldSuggestNow && !$0.wasAccepted && !$0.wasDismissed }
            .map { pattern in
                PatternSuggestion(
                    pattern: pattern,
                    suggestedTitle: pattern.titlePattern,
                    suggestedDate: pattern.nextSuggestedDate
                )
            }
    }

    /// Accepts a pattern suggestion and creates the task
    func acceptSuggestion(_ suggestion: PatternSuggestion) -> TaskItem {
        suggestion.pattern.wasAccepted = true
        suggestion.pattern.lastOccurrence = Date()
        try? modelContext.save()

        let task = TaskItem(
            title: suggestion.suggestedTitle,
            tags: suggestion.pattern.suggestedTags
        )

        return task
    }

    /// Dismisses a pattern suggestion
    func dismissSuggestion(_ suggestion: PatternSuggestion, permanently: Bool = false) {
        if permanently {
            suggestion.pattern.wasDismissed = true
        }
        pendingSuggestions.removeAll { $0.id == suggestion.id }
        try? modelContext.save()
    }

    /// Snoozes a suggestion until next occurrence
    func snoozeSuggestion(_ suggestion: PatternSuggestion) {
        pendingSuggestions.removeAll { $0.id == suggestion.id }
        // Pattern will reappear at next scheduled time
    }

    // MARK: - Helpers

    private func fetchCompletedTasks() async -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func areTitlesSimilar(_ title1: String, _ title2: String) -> Bool {
        let normalized1 = normalizeTitle(title1)
        let normalized2 = normalizeTitle(title2)

        // Check for exact match after normalization
        if normalized1 == normalized2 { return true }

        // Check for prefix/suffix match (e.g., "Weekly Report - Jan" vs "Weekly Report - Feb")
        let words1 = Set(normalized1.split(separator: " ").map(String.init))
        let words2 = Set(normalized2.split(separator: " ").map(String.init))

        let intersection = words1.intersection(words2)
        let union = words1.union(words2)

        let similarity = Double(intersection.count) / Double(union.count)
        return similarity >= similarityThreshold
    }

    private func normalizeTitle(_ title: String) -> String {
        var result = title.lowercased()

        // Remove common date/time patterns
        let datePatterns = [
            #"\d{1,2}/\d{1,2}(/\d{2,4})?"#,  // MM/DD or MM/DD/YYYY
            #"\d{4}-\d{2}-\d{2}"#,           // YYYY-MM-DD
            #"(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*"#,
            #"(monday|tuesday|wednesday|thursday|friday|saturday|sunday)"#,
            #"week\s*\d+"#,
            #"q[1-4]"#
        ]

        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: ""
                )
            }
        }

        // Remove extra whitespace
        result = result.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return result
    }

    private func extractCommonTitle(from titles: [String]) -> String {
        guard let first = titles.first else { return "" }
        return normalizeTitle(first).trimmingCharacters(in: .whitespaces).capitalized
    }

    private func calculateVariance(_ values: [Int], mean: Int) -> Double {
        guard !values.isEmpty else { return 0 }
        let squaredDiffs = values.map { pow(Double($0 - mean), 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }

    private func mostCommon<T: Hashable>(in array: [T]) -> T? {
        let counts = Dictionary(grouping: array, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private func existingPatternMatches(_ pattern: RecurringPattern) -> Bool {
        let descriptor = FetchDescriptor<RecurringPattern>(
            predicate: #Predicate<RecurringPattern> { existing in
                existing.titlePattern == pattern.titlePattern
            }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        return !existing.isEmpty
    }
}
