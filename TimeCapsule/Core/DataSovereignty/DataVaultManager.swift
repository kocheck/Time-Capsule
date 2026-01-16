import Foundation
import SwiftData

/// A date range for bulk operations
struct DateRange {
    let start: Date
    let end: Date

    /// Creates a date range from start to end (inclusive)
    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

/// Actor-based data access layer for thread-safe task management.
/// Ensures user data ownership by providing controlled access to all task operations.
actor DataVaultManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Tasks CRUD

    /// Fetches all tasks from the data store
    func fetchAllTasks() async throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches only pending (not completed, not archived) tasks
    func fetchPendingTasks() async throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.completedAt == nil && !task.isArchived
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches only completed tasks
    func fetchCompletedTasks() async throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Creates a new task in the data store
    func createTask(_ task: TaskItem) async throws {
        modelContext.insert(task)
        try modelContext.safeSave()
    }

    /// Updates an existing task (saves any pending changes)
    func updateTask(_ task: TaskItem) async throws {
        try modelContext.safeSave()
    }

    /// Deletes a task from the data store
    func deleteTask(_ task: TaskItem) async throws {
        modelContext.delete(task)
        try modelContext.safeSave()
    }

    // MARK: - Counts (for privacy dashboard)

    /// Returns the total count of all tasks
    func countTasks() -> Int {
        let descriptor = FetchDescriptor<TaskItem>()
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            return 0
        }
    }

    /// Returns the count of completed tasks
    func countCompletedTasks() -> Int {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.completedAt != nil
            }
        )
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            return 0
        }
    }

    /// Returns the count of archived tasks
    func countArchivedTasks() -> Int {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.isArchived
            }
        )
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            return 0
        }
    }

    // MARK: - Bulk Operations

    /// Deletes all tasks created within the specified date range
    /// - Parameter range: The date range (inclusive) for task creation dates
    /// - Returns: The number of tasks deleted
    @discardableResult
    func deleteTasksInRange(_ range: DateRange) async throws -> Int {
        let startDate = range.start
        let endDate = range.end

        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.createdAt >= startDate && task.createdAt <= endDate
            }
        )

        let tasksToDelete = try modelContext.fetch(descriptor)
        let count = tasksToDelete.count

        for task in tasksToDelete {
            modelContext.delete(task)
        }

        try modelContext.safeSave()
        return count
    }

    /// Deletes all tasks containing the specified tag
    /// - Parameter tag: The tag to match
    /// - Returns: The number of tasks deleted
    @discardableResult
    func deleteTasksWithTag(_ tag: String) async throws -> Int {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                task.tags.contains(tag)
            }
        )

        let tasksToDelete = try modelContext.fetch(descriptor)
        let count = tasksToDelete.count

        for task in tasksToDelete {
            modelContext.delete(task)
        }

        try modelContext.safeSave()
        return count
    }
}
