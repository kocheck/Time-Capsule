import Foundation
import CoreSpotlight
import SwiftData

/// Service for Spotlight search integration
@Observable
class SpotlightService {
    private let searchableIndex = CSSearchableIndex.default()
    private let domainIdentifier = "com.timecapsule.tasks"

    var isIndexing = false

    // MARK: - Indexing

    /// Indexes all tasks for Spotlight search
    func indexAllTasks(_ tasks: [TaskItem]) async {
        isIndexing = true
        defer { isIndexing = false }

        // Remove existing items
        try? await searchableIndex.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])

        // Create searchable items
        let items = tasks.map { createSearchableItem(for: $0) }

        // Index in batches
        let batchSize = 100
        for i in stride(from: 0, to: items.count, by: batchSize) {
            let batch = Array(items[i..<min(i + batchSize, items.count)])
            try? await searchableIndex.indexSearchableItems(batch)
        }
    }

    /// Indexes a single task
    func indexTask(_ task: TaskItem) async {
        let item = createSearchableItem(for: task)
        try? await searchableIndex.indexSearchableItems([item])
    }

    /// Removes a task from the index
    func removeTask(_ task: TaskItem) async {
        try? await searchableIndex.deleteSearchableItems(withIdentifiers: [task.id.uuidString])
    }

    /// Updates an existing task in the index
    func updateTask(_ task: TaskItem) async {
        await removeTask(task)
        await indexTask(task)
    }

    // MARK: - Helpers

    private func createSearchableItem(for task: TaskItem) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)

        attributeSet.title = task.title
        attributeSet.contentDescription = task.taskDescription

        // Add tags as keywords
        attributeSet.keywords = task.tags + [
            task.priority.rawValue,
            task.isCompleted ? "completed" : "pending"
        ]

        // Status info
        attributeSet.displayName = task.title
        attributeSet.thumbnailData = nil  // Could add priority icon

        // Additional metadata
        attributeSet.contentCreationDate = task.createdAt
        if let completedAt = task.completedAt {
            attributeSet.contentModificationDate = completedAt
        }

        return CSSearchableItem(
            uniqueIdentifier: task.id.uuidString,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
    }

    /// Handles Spotlight continuation activity
    func handleSpotlightContinuation(_ activity: NSUserActivity) -> UUID? {
        guard activity.activityType == CSSearchableItemActionType,
              let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              let uuid = UUID(uuidString: identifier) else {
            return nil
        }

        return uuid
    }
}
