import Foundation
import SwiftData
import Observation

@Observable
final class DigestViewModel {
    private let modelContext: ModelContext
    private let digestService: DigestService

    var currentDigest: WeeklyDigest?
    var recentDigests: [WeeklyDigest] = []
    var isLoading: Bool = false
    var isGenerating: Bool = false
    var error: Error?

    init(modelContext: ModelContext, aiService: AIServiceProtocol) {
        self.modelContext = modelContext
        self.digestService = DigestService(modelContext: modelContext, aiService: aiService)
    }

    // MARK: - Loading

    @MainActor
    func loadDigest() {
        isLoading = true
        defer { isLoading = false }

        currentDigest = digestService.getCurrentWeekDigest()
        recentDigests = digestService.getRecentDigests(limit: 4)
    }

    // MARK: - Generation

    @MainActor
    func generateDigest() async {
        isGenerating = true
        error = nil

        do {
            currentDigest = try await digestService.generateDigest()
            recentDigests = digestService.getRecentDigests(limit: 4)
        } catch {
            self.error = error
        }

        isGenerating = false
    }

    @MainActor
    func regenerateDigest() async {
        isGenerating = true
        error = nil

        do {
            currentDigest = try await digestService.regenerateDigest()
            recentDigests = digestService.getRecentDigests(limit: 4)
        } catch {
            self.error = error
        }

        isGenerating = false
    }

    // MARK: - Computed Properties

    var hasDigest: Bool {
        currentDigest != nil
    }

    var digestDateRange: String {
        currentDigest?.formattedDateRange ?? "This Week"
    }

    var summaryText: String {
        currentDigest?.summaryText ?? ""
    }

    var accomplishments: [String] {
        currentDigest?.accomplishments ?? []
    }

    var patterns: [String] {
        currentDigest?.patternsNoticed ?? []
    }

    var suggestions: [String] {
        currentDigest?.suggestionsForImprovement ?? []
    }

    var staleTasks: [String] {
        currentDigest?.staleTaskTitles ?? []
    }

    var weeklyStats: (completed: Int, skipped: Int, created: Int, rate: Double) {
        guard let digest = currentDigest else {
            return (0, 0, 0, 0)
        }
        return (
            digest.totalCompleted,
            digest.totalSkipped,
            digest.totalCreated,
            digest.averageCompletionRate
        )
    }

    var formattedCompletionRate: String {
        String(format: "%.0f%%", weeklyStats.rate * 100)
    }

    var errorMessage: String? {
        error?.localizedDescription
    }
}
