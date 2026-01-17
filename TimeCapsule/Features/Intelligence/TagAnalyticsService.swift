import Foundation
import SwiftData

/// Metrics for a specific tag
struct TagMetrics: Identifiable {
    var id: String { tag }

    let tag: String
    let totalCreated: Int
    let totalCompleted: Int
    let completionRate: Double
    let averageTimeToComplete: TimeInterval?
    let skipRate: Double
    let bestHour: Int?
    let completionsByHour: [Int: Int]

    var completionRateFormatted: String {
        "\(Int(completionRate * 100))%"
    }

    var averageTimeFormatted: String? {
        guard let time = averageTimeToComplete else { return nil }
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }

    var bestHourFormatted: String? {
        guard let hour = bestHour else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }

    var skipRateFormatted: String {
        "\(Int(skipRate * 100))%"
    }
}

/// Service for analyzing tag-specific metrics
@Observable
class TagAnalyticsService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Gets metrics for a specific tag
    func getMetrics(for tag: String) async -> TagMetrics {
        let allTasks = await fetchAllTasks()
        let tagTasks = allTasks.filter { $0.tags.contains(tag) }

        return calculateMetrics(for: tag, tasks: tagTasks)
    }

    /// Gets metrics for all tags
    func getAllTagMetrics() async -> [TagMetrics] {
        let allTasks = await fetchAllTasks()

        // Collect all unique tags
        var allTags = Set<String>()
        for task in allTasks {
            allTags.formUnion(task.tags)
        }

        // Calculate metrics for each tag
        return allTags.map { tag in
            let tagTasks = allTasks.filter { $0.tags.contains(tag) }
            return calculateMetrics(for: tag, tasks: tagTasks)
        }.sorted { $0.totalCreated > $1.totalCreated }
    }

    /// Gets metrics for the top N tags by task count
    func getTopTags(limit: Int) async -> [TagMetrics] {
        let allMetrics = await getAllTagMetrics()
        return Array(allMetrics.prefix(limit))
    }

    /// Gets tags that have low completion rates (potential problem areas)
    func getProblematicTags(threshold: Double = 0.3) async -> [TagMetrics] {
        let allMetrics = await getAllTagMetrics()
        return allMetrics.filter { metrics in
            metrics.totalCreated >= 3 && metrics.completionRate < threshold
        }
    }

    /// Gets tags with high skip rates
    func getHighSkipTags(threshold: Double = 0.5) async -> [TagMetrics] {
        let allMetrics = await getAllTagMetrics()
        return allMetrics.filter { metrics in
            metrics.totalCreated >= 3 && metrics.skipRate > threshold
        }
    }

    // MARK: - Private Helpers

    private func fetchAllTasks() async -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchCompletionRecords(forTag tag: String) async -> [CompletionRecord] {
        let descriptor = FetchDescriptor<CompletionRecord>()
        let allRecords = (try? modelContext.fetch(descriptor)) ?? []
        return allRecords.filter { $0.tags.contains(tag) }
    }

    private func calculateMetrics(for tag: String, tasks: [TaskItem]) -> TagMetrics {
        let totalCreated = tasks.count
        let completedTasks = tasks.filter { $0.isCompleted }
        let totalCompleted = completedTasks.count

        let completionRate = totalCreated > 0 ? Double(totalCompleted) / Double(totalCreated) : 0

        // Calculate average time to complete
        let completionTimes = completedTasks.compactMap { task -> TimeInterval? in
            guard let completedAt = task.completedAt else { return nil }
            return completedAt.timeIntervalSince(task.createdAt)
        }

        let averageTime: TimeInterval?
        if !completionTimes.isEmpty {
            averageTime = completionTimes.reduce(0, +) / Double(completionTimes.count)
        } else {
            averageTime = nil
        }

        // Calculate skip rate
        let totalSkips = tasks.reduce(0) { $0 + $1.skipCount }
        let skipRate = totalCreated > 0 ? Double(totalSkips) / Double(totalCreated * 3) : 0  // Normalize by expected max skips

        // Calculate completions by hour
        var completionsByHour: [Int: Int] = [:]
        for task in completedTasks {
            if let completedAt = task.completedAt {
                let hour = Calendar.current.component(.hour, from: completedAt)
                completionsByHour[hour, default: 0] += 1
            }
        }

        // Find best hour
        let bestHour = completionsByHour.max(by: { $0.value < $1.value })?.key

        return TagMetrics(
            tag: tag,
            totalCreated: totalCreated,
            totalCompleted: totalCompleted,
            completionRate: completionRate,
            averageTimeToComplete: averageTime,
            skipRate: min(1.0, skipRate),
            bestHour: bestHour,
            completionsByHour: completionsByHour
        )
    }
}
