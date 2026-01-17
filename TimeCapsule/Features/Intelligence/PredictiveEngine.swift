import Foundation
import SwiftData

/// Represents a productivity insight derived from completion patterns
struct ProductivityInsight: Identifiable {
    let id = UUID()
    let message: String
    let confidence: Double  // 0.0 to 1.0
    let basedOnSamples: Int
    let tags: [String]
    let suggestedHour: Int?

    var confidenceLabel: String {
        switch confidence {
        case 0.8...: return "High confidence"
        case 0.6..<0.8: return "Medium confidence"
        default: return "Low confidence"
        }
    }
}

/// Analyzes task completion patterns to predict optimal work times
@Observable
class PredictiveEngine {
    private let modelContext: ModelContext
    private let minimumSamplesForInsight = 5

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Recording Completions

    /// Records a task completion for future analysis
    func recordCompletion(_ task: TaskItem) {
        guard task.completedAt != nil else { return }

        let record = CompletionRecord(from: task)
        modelContext.insert(record)
        try? modelContext.save()
    }

    // MARK: - Best Time Analysis

    /// Returns the best hour (0-23) to work on tasks with the given tag
    func bestTimeForTag(_ tag: String) async -> Int? {
        let records = await fetchRecords(forTag: tag)

        guard records.count >= minimumSamplesForInsight else { return nil }

        // Count completions by hour
        var hourCounts: [Int: Int] = [:]
        for record in records {
            hourCounts[record.hourOfDay, default: 0] += 1
        }

        // Find the hour with most completions
        return hourCounts.max(by: { $0.value < $1.value })?.key
    }

    /// Returns the best hour for a specific task based on its tags
    func bestTimeForTask(_ task: TaskItem) async -> Int? {
        guard !task.tags.isEmpty else { return nil }

        // Aggregate best times across all task tags
        var hourScores: [Int: Double] = [:]

        for tag in task.tags {
            let records = await fetchRecords(forTag: tag)
            guard records.count >= minimumSamplesForInsight else { continue }

            for record in records {
                hourScores[record.hourOfDay, default: 0] += 1.0 / Double(records.count)
            }
        }

        guard !hourScores.isEmpty else { return nil }
        return hourScores.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Statistics

    /// Returns statistics for each hour of the day
    func getHourlyStats() async -> [TimeSlotStats] {
        let records = await fetchAllRecords()

        guard !records.isEmpty else { return [] }

        var statsByHour: [Int: (count: Int, totalTime: TimeInterval)] = [:]

        for record in records {
            let current = statsByHour[record.hourOfDay] ?? (0, 0)
            statsByHour[record.hourOfDay] = (current.count + 1, current.totalTime + record.timeToComplete)
        }

        let totalCount = Double(records.count)

        return (0..<24).compactMap { hour in
            guard let data = statsByHour[hour] else {
                return TimeSlotStats(
                    hourOfDay: hour,
                    completionCount: 0,
                    averageCompletionTime: 0,
                    completionRate: 0
                )
            }

            return TimeSlotStats(
                hourOfDay: hour,
                completionCount: data.count,
                averageCompletionTime: data.totalTime / Double(data.count),
                completionRate: Double(data.count) / totalCount
            )
        }
    }

    /// Returns statistics for each day of the week
    func getDayOfWeekStats() async -> [DayOfWeekStats] {
        let records = await fetchAllRecords()

        var statsByDay: [Int: (count: Int, totalTime: TimeInterval)] = [:]

        for record in records {
            let current = statsByDay[record.dayOfWeek] ?? (0, 0)
            statsByDay[record.dayOfWeek] = (current.count + 1, current.totalTime + record.timeToComplete)
        }

        return (1...7).map { day in
            let data = statsByDay[day] ?? (0, 0)
            return DayOfWeekStats(
                dayOfWeek: day,
                completionCount: data.count,
                averageCompletionTime: data.count > 0 ? data.totalTime / Double(data.count) : 0
            )
        }
    }

    // MARK: - Insights

    /// Generates productivity insights from completion data
    func getInsights() async -> [ProductivityInsight] {
        var insights: [ProductivityInsight] = []

        // Get tag-specific insights
        let tagInsights = await getTagInsights()
        insights.append(contentsOf: tagInsights)

        // Get general time-of-day insights
        let timeInsights = await getTimeOfDayInsights()
        insights.append(contentsOf: timeInsights)

        // Sort by confidence
        return insights.sorted { $0.confidence > $1.confidence }
    }

    private func getTagInsights() async -> [ProductivityInsight] {
        var insights: [ProductivityInsight] = []

        // Get all unique tags
        let records = await fetchAllRecords()
        let allTags = Set(records.flatMap { $0.tags })

        for tag in allTags {
            let tagRecords = records.filter { $0.tags.contains(tag) }

            guard tagRecords.count >= minimumSamplesForInsight else { continue }

            // Find best hour for this tag
            var hourCounts: [Int: Int] = [:]
            var hourTimes: [Int: [TimeInterval]] = [:]

            for record in tagRecords {
                hourCounts[record.hourOfDay, default: 0] += 1
                hourTimes[record.hourOfDay, default: []].append(record.timeToComplete)
            }

            guard let bestHour = hourCounts.max(by: { $0.value < $1.value })?.key else { continue }

            let bestHourCount = hourCounts[bestHour] ?? 0
            let concentration = Double(bestHourCount) / Double(tagRecords.count)

            // Only create insight if there's a clear pattern (>30% in one hour)
            guard concentration > 0.3 else { continue }

            // Calculate speed improvement
            let bestHourTimes = hourTimes[bestHour] ?? []
            let otherTimes = hourTimes.filter { $0.key != bestHour }.flatMap { $0.value }

            if !bestHourTimes.isEmpty && !otherTimes.isEmpty {
                let avgBestHour = bestHourTimes.reduce(0, +) / Double(bestHourTimes.count)
                let avgOther = otherTimes.reduce(0, +) / Double(otherTimes.count)

                if avgBestHour < avgOther {
                    let improvement = ((avgOther - avgBestHour) / avgOther) * 100
                    let hourLabel = formatHour(bestHour)

                    insights.append(ProductivityInsight(
                        message: "You complete #\(tag) tasks \(Int(improvement))% faster \(hourLabel)",
                        confidence: min(0.95, concentration + 0.3),
                        basedOnSamples: tagRecords.count,
                        tags: [tag],
                        suggestedHour: bestHour
                    ))
                }
            }
        }

        return insights
    }

    private func getTimeOfDayInsights() async -> [ProductivityInsight] {
        var insights: [ProductivityInsight] = []

        let hourlyStats = await getHourlyStats()
        let totalCompletions = hourlyStats.reduce(0) { $0 + $1.completionCount }

        guard totalCompletions >= minimumSamplesForInsight else { return insights }

        // Find peak productivity hours
        let sortedByCount = hourlyStats.sorted { $0.completionCount > $1.completionCount }
        let topHours = sortedByCount.prefix(3).filter { $0.completionCount > 0 }

        if let peakHour = topHours.first, peakHour.completionCount >= 3 {
            let percentage = (Double(peakHour.completionCount) / Double(totalCompletions)) * 100

            insights.append(ProductivityInsight(
                message: "Your peak productivity is at \(formatHour(peakHour.hourOfDay)) (\(Int(percentage))% of completions)",
                confidence: min(0.9, percentage / 100 + 0.4),
                basedOnSamples: totalCompletions,
                tags: [],
                suggestedHour: peakHour.hourOfDay
            ))
        }

        return insights
    }

    // MARK: - Suggestion Scoring

    /// Returns a score (0-1) for how good the current time is for this task
    func shouldSuggestNow(_ task: TaskItem) async -> Double {
        let currentHour = Calendar.current.component(.hour, from: Date())

        guard !task.tags.isEmpty else { return 0.5 }

        var totalScore: Double = 0
        var tagCount = 0

        for tag in task.tags {
            if let bestHour = await bestTimeForTag(tag) {
                let hourDiff = abs(currentHour - bestHour)
                let normalizedDiff = min(hourDiff, 24 - hourDiff)  // Handle wrap-around
                let score = 1.0 - (Double(normalizedDiff) / 12.0)  // Max 12 hours apart
                totalScore += max(0, score)
                tagCount += 1
            }
        }

        return tagCount > 0 ? totalScore / Double(tagCount) : 0.5
    }

    // MARK: - Private Helpers

    private func fetchAllRecords() async -> [CompletionRecord] {
        let descriptor = FetchDescriptor<CompletionRecord>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchRecords(forTag tag: String) async -> [CompletionRecord] {
        let allRecords = await fetchAllRecords()
        return allRecords.filter { $0.tags.contains(tag) }
    }

    private func formatHour(_ hour: Int) -> String {
        switch hour {
        case 5..<12: return "in the morning"
        case 12..<17: return "in the afternoon"
        case 17..<21: return "in the evening"
        default: return "at night"
        }
    }
}
