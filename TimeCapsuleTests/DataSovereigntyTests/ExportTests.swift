import Testing
import Foundation
import SwiftData
@testable import TimeCapsule

@Suite("Export Functionality Tests")
struct ExportTests {

    @Test("Universal Task Format export creates valid format")
    func utfExportCreatesValidFormat() async throws {
        // Setup
        let container = try ModelContainer(for: TaskItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)

        // Create test tasks
        let task1 = TaskItem(title: "Test Task 1", description: "Description 1", tags: ["work"], priority: .high)
        let task2 = TaskItem(title: "Test Task 2", description: nil, tags: ["personal", "urgent"], priority: .normal)
        task2.completedAt = Date()

        context.insert(task1)
        context.insert(task2)
        try context.save()

        // Create exporter
        let exporter = UniversalTaskFormatExporter()
        let data = try await exporter.export(
            tasks: [task1],
            completedTasks: [task2],
            archivedTasks: [],
            settings: nil
        )

        // Verify output
        #expect(data.count > 0, "Export data should not be empty")

        // Parse back
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let format = try decoder.decode(UniversalTaskFormat.self, from: data)

        #expect(format.formatVersion == "1.0.0", "Format version should be 1.0.0")
        #expect(format.formatIdentifier == "com.timecapsule.utf", "Format identifier should match")
        #expect(format.tasks.count == 1, "Should have 1 active task")
        #expect(format.completedTasks.count == 1, "Should have 1 completed task")
        #expect(format.tasks.first?.title == "Test Task 1", "Task title should match")
        #expect(format.tasks.first?.tags.contains("work") == true, "Task should have work tag")
    }

    @Test("JSON export includes all task fields")
    func jsonExportIncludesAllFields() async throws {
        let container = try ModelContainer(for: TaskItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)

        let task = TaskItem(
            title: "Complete Task",
            description: "A detailed description",
            tags: ["work", "important"],
            priority: .high
        )
        task.skipCount = 3
        task.contextHints = ["morning", "focused"]

        context.insert(task)
        try context.save()

        let exporter = JSONExporter()
        let data = try await exporter.export(
            tasks: [task],
            completedTasks: [],
            archivedTasks: [],
            settings: nil
        )

        #expect(data.count > 0, "JSON export should not be empty")

        // Verify it's valid JSON
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json != nil, "Should be valid JSON")

        let tasks = json?["tasks"] as? [[String: Any]]
        #expect(tasks?.count == 1, "Should have 1 task")

        let exportedTask = tasks?.first
        #expect(exportedTask?["title"] as? String == "Complete Task", "Title should match")
        #expect(exportedTask?["description"] as? String == "A detailed description", "Description should match")
        #expect((exportedTask?["tags"] as? [String])?.count == 2, "Should have 2 tags")
        #expect(exportedTask?["priority"] as? String == "high", "Priority should match")
        #expect(exportedTask?["skipCount"] as? Int == 3, "Skip count should match")
    }

    @Test("CSV export creates proper format")
    func csvExportCreatesProperFormat() async throws {
        let container = try ModelContainer(for: TaskItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)

        let task = TaskItem(title: "CSV Task", description: "Test description", tags: ["tag1", "tag2"], priority: .normal)
        context.insert(task)
        try context.save()

        let exporter = CSVExporter()
        let data = try await exporter.export(
            tasks: [task],
            completedTasks: [],
            archivedTasks: [],
            settings: nil
        )

        let csvString = String(data: data, encoding: .utf8)
        #expect(csvString != nil, "CSV should be valid UTF-8")

        let lines = csvString?.components(separatedBy: .newlines) ?? []
        #expect(lines.count >= 2, "Should have header and at least one data row")
        #expect(lines[0].contains("Title"), "Header should contain Title")
        #expect(lines[0].contains("Tags"), "Header should contain Tags")
        #expect(lines[1].contains("CSV Task"), "Data should contain task title")
    }

    @Test("Markdown export creates readable format")
    func markdownExportCreatesReadableFormat() async throws {
        let container = try ModelContainer(for: TaskItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)

        let task1 = TaskItem(title: "Task 1", tags: ["work"], priority: .high)
        let task2 = TaskItem(title: "Task 2", tags: ["personal"], priority: .low)
        task2.completedAt = Date()

        context.insert(task1)
        context.insert(task2)
        try context.save()

        let exporter = MarkdownExporter()
        let data = try await exporter.export(
            tasks: [task1],
            completedTasks: [task2],
            archivedTasks: [],
            settings: nil
        )

        let markdown = String(data: data, encoding: .utf8)
        #expect(markdown != nil, "Markdown should be valid UTF-8")
        #expect(markdown?.contains("# Time Capsule Export") == true, "Should have title")
        #expect(markdown?.contains("## Active Tasks") == true, "Should have active tasks section")
        #expect(markdown?.contains("## Completed Tasks") == true, "Should have completed tasks section")
        #expect(markdown?.contains("Task 1") == true, "Should contain task 1")
        #expect(markdown?.contains("Task 2") == true, "Should contain task 2")
        #expect(markdown?.contains("[x]") == true, "Should have checkbox for completed task")
    }

    @Test("Export handles empty task list")
    func exportHandlesEmptyTaskList() async throws {
        let exporter = JSONExporter()
        let data = try await exporter.export(
            tasks: [],
            completedTasks: [],
            archivedTasks: [],
            settings: nil
        )

        #expect(data.count > 0, "Export should work with empty task list")

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let tasks = json?["tasks"] as? [[String: Any]]
        #expect(tasks?.count == 0, "Should have 0 tasks")
    }

    @Test("Export preserves task relationships")
    func exportPreservesTaskRelationships() async throws {
        let container = try ModelContainer(for: TaskItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)

        let task = TaskItem(title: "Parent Task", tags: ["project"], priority: .high)
        task.contextHints = ["context1", "context2"]

        context.insert(task)
        try context.save()

        let exporter = UniversalTaskFormatExporter()
        let data = try await exporter.export(
            tasks: [task],
            completedTasks: [],
            archivedTasks: [],
            settings: nil
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let format = try decoder.decode(UniversalTaskFormat.self, from: data)

        let exportedTask = format.tasks.first
        #expect(exportedTask?.contextHints.count == 2, "Should preserve context hints")
        #expect(exportedTask?.contextHints.contains("context1") == true, "Should contain context1")
    }
}
