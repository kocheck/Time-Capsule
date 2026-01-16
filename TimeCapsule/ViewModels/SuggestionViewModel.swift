import Foundation
import SwiftData
import Observation

@Observable
final class SuggestionViewModel {
    private let modelContext: ModelContext
    private let contextEngine: ContextEngine
    private let taskViewModel: TaskViewModel

    var suggestedTask: TaskItem?
    var isLoading: Bool = false
    var isFocusMode: Bool = false
    var focusModeTask: TaskItem?
    var error: Error?
    var aiReasoning: String?

    init(modelContext: ModelContext, aiService: AIServiceProtocol) {
        self.modelContext = modelContext
        self.contextEngine = ContextEngine(aiService: aiService)
        self.taskViewModel = TaskViewModel(modelContext: modelContext)
    }

    @MainActor
    func loadSuggestion() async {
        isLoading = true
        error = nil
        aiReasoning = nil

        defer { isLoading = false }

        do {
            // Check for focus mode first
            if let focusTask = focusModeTask, focusTask.shouldTriggerFocusMode {
                isFocusMode = true
                suggestedTask = focusTask
                return
            }

            let pendingTasks = try taskViewModel.fetchPendingTasks()
            let recentlyCompleted = try taskViewModel.fetchRecentlyCompletedTasks(within: 24)

            // Check if any task should trigger focus mode
            if let focusTrigger = pendingTasks.first(where: { $0.shouldTriggerFocusMode }) {
                isFocusMode = true
                focusModeTask = focusTrigger
                suggestedTask = focusTrigger
                return
            }

            isFocusMode = false
            focusModeTask = nil

            let suggestion = await contextEngine.suggestTask(
                from: pendingTasks,
                recentlyCompleted: recentlyCompleted
            )

            suggestedTask = suggestion
            suggestedTask?.markPresented()
            try modelContext.save()

        } catch {
            self.error = error
        }
    }

    @MainActor
    func completeCurrentTask() async {
        guard let task = suggestedTask else { return }

        do {
            try taskViewModel.completeTask(task)

            if isFocusMode && focusModeTask?.id == task.id {
                isFocusMode = false
                focusModeTask = nil
            }

            await loadSuggestion()
        } catch {
            self.error = error
        }
    }

    @MainActor
    func skipCurrentTask() async {
        guard let task = suggestedTask else { return }

        do {
            try taskViewModel.skipTask(task)

            // Check if this triggers focus mode
            if task.shouldTriggerFocusMode {
                isFocusMode = true
                focusModeTask = task
                // Don't load new suggestion - stay on this task
            } else {
                await loadSuggestion()
            }
        } catch {
            self.error = error
        }
    }

    @MainActor
    func archiveCurrentTask() async {
        guard let task = suggestedTask else { return }

        do {
            try taskViewModel.archiveTask(task)

            if isFocusMode && focusModeTask?.id == task.id {
                isFocusMode = false
                focusModeTask = nil
            }

            await loadSuggestion()
        } catch {
            self.error = error
        }
    }

    func updateAIService(_ service: AIServiceProtocol) async {
        await contextEngine.updateAIService(service)
    }
}
