import Testing
import Foundation
@testable import TimeCapsule

@Suite("TaskItem Tests")
struct TaskItemTests {

    @Test("TaskItem initialization")
    func testInitialization() {
        let task = TaskItem(
            title: "Test Task",
            description: "Test Description",
            tags: ["test", "swift"],
            priority: .high
        )

        #expect(task.title == "Test Task")
        #expect(task.taskDescription == "Test Description")
        #expect(task.tags == ["test", "swift"])
        #expect(task.priority == .high)
        #expect(task.isCompleted == false)
        #expect(task.isArchived == false)
        #expect(task.skipCount == 0)
        #expect(task.dailySkipCount == 0)
    }

    @Test("TaskItem completion")
    func testCompletion() {
        let task = TaskItem(title: "Test Task")
        #expect(task.isCompleted == false)

        task.markCompleted()
        #expect(task.isCompleted == true)
        #expect(task.completedAt != nil)
    }

    @Test("TaskItem skip tracking")
    func testSkipTracking() {
        let task = TaskItem(title: "Test Task")

        task.markSkipped()
        #expect(task.skipCount == 1)
        #expect(task.dailySkipCount == 1)
        #expect(task.wasSkippedToday == true)

        task.markSkipped()
        #expect(task.skipCount == 2)
        #expect(task.dailySkipCount == 2)
    }

    @Test("TaskItem archive")
    func testArchive() {
        let task = TaskItem(title: "Test Task")
        #expect(task.isArchived == false)

        task.archive()
        #expect(task.isArchived == true)

        task.unarchive()
        #expect(task.isArchived == false)
    }

    @Test("TaskItem age calculation")
    func testAgeCalculation() {
        let task = TaskItem(title: "Test Task")
        #expect(task.daysSinceCreation == 0)
    }
}
