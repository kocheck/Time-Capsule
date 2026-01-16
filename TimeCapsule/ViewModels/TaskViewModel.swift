import Foundation
import SwiftData
import Observation

@Observable
final class TaskViewModel {
    private let modelContext: ModelContext
    private let statsService: StatsService

    var isLoading: Bool = false
    var error: Error?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.statsService = StatsService(modelContext: modelContext)
    }

    // MARK: - CRUD Operations

    func createTask(
        title: String,
        description: String? = nil,
        tags: [String] = [],
        priority: TaskPriority = .normal,
        contextHints: [String] = []
    ) throws {
        let task = TaskItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tags.map { $0.lowercased().trimmingCharacters(in: .whitespaces) },
            priority: priority
        )
        task.contextHints = contextHints.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        modelContext.insert(task)
        try modelContext.save()

        statsService.incrementCreated()
    }

    /// Create a task from a parsed natural language input
    func createTask(from parsedTask: ParsedTask) throws {
        try createTask(
            title: parsedTask.title,
            description: parsedTask.description,
            tags: parsedTask.tags,
            priority: parsedTask.priority,
            contextHints: parsedTask.contextHints
        )
    }

    func completeTask(_ task: TaskItem) throws {
        task.markCompleted()
        try modelContext.save()

        statsService.incrementCompleted()
    }

    func skipTask(_ task: TaskItem) throws {
        task.markSkipped()
        try modelContext.save()

        statsService.incrementSkipped()

        if task.shouldTriggerFocusMode {
            statsService.incrementFocusModeTriggered()
        }
    }

    func archiveTask(_ task: TaskItem) throws {
        task.archive()
        try modelContext.save()
    }

    func deleteTask(_ task: TaskItem) throws {
        modelContext.delete(task)
        try modelContext.save()
    }

    func updateTask(_ task: TaskItem, title: String, description: String?, tags: [String], priority: TaskPriority) throws {
        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.taskDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        task.tags = tags.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        task.priority = priority

        try modelContext.save()
    }

    // MARK: - Queries

    func fetchPendingTasks() throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { !$0.isCompleted && !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCompletedTasks(limit: Int = 50) throws -> [TaskItem] {
        var descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { $0.isCompleted },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func fetchRecentlyCompletedTasks(within hours: Int = 24) throws -> [TaskItem] {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.isCompleted && task.completedAt != nil && task.completedAt! > cutoff
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAllTags() throws -> [String] {
        let descriptor = FetchDescriptor<TaskItem>()
        let tasks = try modelContext.fetch(descriptor)
        return Array(Set(tasks.flatMap { $0.tags })).sorted()
    }

    func fetchStaleTasks() throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { !$0.isCompleted && !$0.isArchived }
        )
        let tasks = try modelContext.fetch(descriptor)
        return tasks.filter { $0.isStale }
    }
}
