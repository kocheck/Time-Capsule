import Testing
import Foundation
import SwiftData
@testable import TimeCapsule

@Suite("Import Functionality Tests")
struct ImportTests {

    @Test("UTF import parses valid format")
    func utfImportParsesValidFormat() async throws {
        // Create valid UTF JSON
        let utfJSON = """
        {
            "formatVersion": "1.0.0",
            "formatIdentifier": "com.timecapsule.utf",
            "exportedAt": "2024-01-15T10:00:00Z",
            "exportedFrom": {
                "appName": "Time Capsule",
                "appVersion": "1.0.0",
                "platform": "macOS",
                "platformVersion": "14.0"
            },
            "checksum": "abc123",
            "tasks": [
                {
                    "id": "12345678-1234-1234-1234-123456789012",
                    "title": "Test Task",
                    "description": "Description",
                    "tags": ["work"],
                    "priority": "high",
                    "createdAt": "2024-01-15T09:00:00Z",
                    "completedAt": null,
                    "skipCount": 0,
                    "dailySkipCount": 0,
                    "lastSkippedAt": null,
                    "lastPresentedAt": null,
                    "isArchived": false,
                    "contextHints": [],
                    "sourceSystem": "TimeCapsule",
                    "sourceId": "12345678-1234-1234-1234-123456789012"
                }
            ],
            "completedTasks": [],
            "archivedTasks": [],
            "settings": null,
            "schema": {
                "version": "1.0.0",
                "entities": [],
                "documentation": "https://timecapsule.app/docs/data-format"
            }
        }
        """.data(using: .utf8)!

        let parser = UTFImportParser()
        let importedTasks = try await parser.parse(utfJSON)

        #expect(importedTasks.count == 1, "Should parse 1 task")
        #expect(importedTasks.first?.title == "Test Task", "Title should match")
        #expect(importedTasks.first?.tags.contains("work") == true, "Should have work tag")
        #expect(importedTasks.first?.priority == .high, "Priority should be high")
    }

    @Test("JSON import handles Time Capsule format")
    func jsonImportHandlesTimeCapsuleFormat() async throws {
        let jsonData = """
        {
            "exportedAt": "2024-01-15T10:00:00Z",
            "appVersion": "1.0.0",
            "tasks": [
                {
                    "id": "12345678-1234-1234-1234-123456789012",
                    "title": "JSON Task",
                    "description": "Test",
                    "tags": ["test"],
                    "priority": "normal",
                    "createdAt": "2024-01-15T09:00:00Z",
                    "completedAt": null,
                    "skipCount": 2,
                    "isArchived": false,
                    "contextHints": ["hint1"]
                }
            ],
            "completedTasks": [],
            "archivedTasks": []
        }
        """.data(using: .utf8)!

        let parser = JSONImportParser()
        let importedTasks = try await parser.parse(jsonData)

        #expect(importedTasks.count == 1, "Should import 1 task")
        #expect(importedTasks.first?.title == "JSON Task", "Title should match")
        #expect(importedTasks.first?.priority == .normal, "Priority should be normal")
    }

    @Test("CSV import parses valid CSV")
    func csvImportParsesValidCSV() async throws {
        let csvData = """
        ID,Title,Description,Tags,Priority,Created At,Completed At,Skip Count,Status
        12345678-1234-1234-1234-123456789012,CSV Task,Test description,work;urgent,high,2024-01-15T10:00:00Z,,0,Active
        87654321-4321-4321-4321-210987654321,Done Task,Another task,personal,low,2024-01-14T10:00:00Z,2024-01-15T10:00:00Z,1,Completed
        """.data(using: .utf8)!

        let parser = CSVImportParser()
        let importedTasks = try await parser.parse(csvData)

        #expect(importedTasks.count == 2, "Should import 2 tasks")
        #expect(importedTasks[0].title == "CSV Task", "First task title should match")
        #expect(importedTasks[0].tags.contains("work"), "Should have work tag")
        #expect(importedTasks[0].tags.contains("urgent"), "Should have urgent tag")
        #expect(importedTasks[1].completedAt != nil, "Second task should be completed")
    }

    @Test("Todoist import maps priority correctly")
    func todoistImportMapsPriorityCorrectly() async throws {
        let todoistJSON = """
        {
            "projects": [
                {
                    "id": 1,
                    "name": "Work",
                    "items": [
                        {
                            "id": 100,
                            "content": "High priority task",
                            "description": null,
                            "priority": 1,
                            "labels": ["urgent"],
                            "checked": false,
                            "date_added": "2024-01-15T10:00:00Z",
                            "date_completed": null
                        },
                        {
                            "id": 101,
                            "content": "Low priority task",
                            "description": "Details",
                            "priority": 4,
                            "labels": [],
                            "checked": true,
                            "date_added": "2024-01-14T10:00:00Z",
                            "date_completed": "2024-01-15T10:00:00Z"
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let parser = TodoistImportParser()
        let importedTasks = try await parser.parse(todoistJSON)

        #expect(importedTasks.count == 2, "Should import 2 tasks")
        #expect(importedTasks[0].title == "High priority task", "First task title should match")
        #expect(importedTasks[0].priority == .high, "Todoist priority 1 should map to high")
        #expect(importedTasks[1].priority == .low, "Todoist priority 4 should map to low")
        #expect(importedTasks[0].tags.contains("Work"), "Should include project name as tag")
        #expect(importedTasks[1].completedAt != nil, "Checked task should be completed")
    }

    @Test("Things 3 import includes project and area")
    func things3ImportIncludesProjectAndArea() async throws {
        let things3JSON = """
        {
            "items": [
                {
                    "uuid": "ABC-123",
                    "type": "to-do",
                    "title": "Things Task",
                    "notes": "Some notes",
                    "tags": ["coding"],
                    "completed": false,
                    "project": "App Development",
                    "area": "Work",
                    "created": "2024-01-15T10:00:00Z",
                    "completionDate": null
                }
            ]
        }
        """.data(using: .utf8)!

        let parser = Things3ImportParser()
        let importedTasks = try await parser.parse(things3JSON)

        #expect(importedTasks.count == 1, "Should import 1 task")
        #expect(importedTasks.first?.title == "Things Task", "Title should match")
        #expect(importedTasks.first?.description == "Some notes", "Description should match")
        #expect(importedTasks.first?.tags.contains("coding"), "Should have coding tag")
        #expect(importedTasks.first?.tags.contains("App Development"), "Should include project as tag")
        #expect(importedTasks.first?.tags.contains("Work"), "Should include area as tag")
    }

    @Test("Import handles malformed JSON gracefully")
    func importHandlesMalformedJSONGracefully() async throws {
        let malformedJSON = """
        {
            "invalid": "format"
            "missing": "comma"
        }
        """.data(using: .utf8)!

        let parser = JSONImportParser()

        await #expect(throws: Error.self) {
            _ = try await parser.parse(malformedJSON)
        }
    }

    @Test("Import round-trip preserves data")
    func importRoundTripPreservesData() async throws {
        let container = try ModelContainer(for: TaskItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)

        // Create original task
        let originalTask = TaskItem(
            title: "Round Trip Task",
            description: "Test description",
            tags: ["tag1", "tag2"],
            priority: .high
        )
        originalTask.skipCount = 5
        originalTask.contextHints = ["morning", "focused"]

        context.insert(originalTask)
        try context.save()

        // Export
        let exporter = UniversalTaskFormatExporter()
        let exportedData = try await exporter.export(
            tasks: [originalTask],
            completedTasks: [],
            archivedTasks: [],
            settings: nil
        )

        // Import
        let parser = UTFImportParser()
        let importedTasks = try await parser.parse(exportedData)

        #expect(importedTasks.count == 1, "Should import 1 task")

        let importedTask = importedTasks.first!
        #expect(importedTask.title == originalTask.title, "Title should match")
        #expect(importedTask.description == originalTask.taskDescription, "Description should match")
        #expect(importedTask.tags == originalTask.tags, "Tags should match")
        #expect(importedTask.priority == originalTask.priority, "Priority should match")
    }
}
