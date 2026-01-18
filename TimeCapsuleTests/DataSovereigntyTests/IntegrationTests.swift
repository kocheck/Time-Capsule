import XCTest
import SwiftData
@testable import TimeCapsule

@MainActor
final class DataSovereigntyIntegrationTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        // Create in-memory model container for testing
        let schema = Schema([TaskItem.self, AppSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
    }

    // MARK: - Full Export-Import Round Trip Tests

    func testExportImportRoundTrip_UTF() async throws {
        // Given: Generate sample tasks
        let originalTasks = TestDataGenerator.generateDataset(active: 10, completed: 5, highPriority: 3)
        for task in originalTasks {
            modelContext.insert(task)
        }
        try modelContext.save()

        // When: Export to UTF
        let exportCoordinator = ExportCoordinator(modelContext: modelContext)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-export.utf.json")

        let exportResult = try await exportCoordinator.export(
            format: .universalTaskFormat,
            options: .complete,
            destination: tempURL
        )

        // Clear existing tasks
        let allTasks = try modelContext.fetch(FetchDescriptor<TaskItem>())
        for task in allTasks {
            modelContext.delete(task)
        }
        try modelContext.save()

        // Then: Import back
        let importCoordinator = ImportCoordinator(modelContext: modelContext)
        let importResult = try await importCoordinator.importData(
            from: exportResult.destination,
            source: .universalTaskFormat,
            options: ImportOptions()
        )

        // Verify: All tasks restored
        XCTAssertTrue(importResult.success)
        XCTAssertEqual(importResult.importedCount, originalTasks.count)

        let importedTasks = try modelContext.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(importedTasks.count, originalTasks.count)

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testExportImportRoundTrip_JSON() async throws {
        // Given: Generate diverse dataset
        let originalTasks = TestDataGenerator.generateTasks(count: 20)
        for task in originalTasks {
            modelContext.insert(task)
        }
        try modelContext.save()

        // When: Export to JSON
        let exportCoordinator = ExportCoordinator(modelContext: modelContext)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-export.json")

        let exportResult = try await exportCoordinator.export(
            format: .json,
            options: .complete,
            destination: tempURL
        )

        // Clear and re-import
        let allTasks = try modelContext.fetch(FetchDescriptor<TaskItem>())
        for task in allTasks {
            modelContext.delete(task)
        }
        try modelContext.save()

        let importCoordinator = ImportCoordinator(modelContext: modelContext)
        let importResult = try await importCoordinator.importData(
            from: exportResult.destination,
            source: .json,
            options: ImportOptions()
        )

        // Verify
        XCTAssertTrue(importResult.success)
        XCTAssertEqual(importResult.importedCount, originalTasks.count)

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Backup and Restore Tests

    func testCreateAndRestoreBackup() async throws {
        // Given: Create tasks
        let originalTasks = TestDataGenerator.generateDataset(active: 15, completed: 10)
        for task in originalTasks {
            modelContext.insert(task)
        }
        try modelContext.save()

        // When: Create backup
        let exportCoordinator = ExportCoordinator(modelContext: modelContext)
        let backupManager = BackupManager(
            modelContext: modelContext,
            exportCoordinator: exportCoordinator
        )

        let backup = try await backupManager.createBackup(
            name: "Test Backup",
            encrypt: false,
            password: nil
        )

        // Verify backup metadata
        XCTAssertEqual(backup.name, "Test Backup")
        XCTAssertEqual(backup.taskCount, 15)
        XCTAssertEqual(backup.completedTaskCount, 10)
        XCTAssertFalse(backup.isEncrypted)
        XCTAssertTrue(FileManager.default.fileExists(atPath: backup.fileURL.path))

        // Clear all tasks
        let allTasks = try modelContext.fetch(FetchDescriptor<TaskItem>())
        for task in allTasks {
            modelContext.delete(task)
        }
        try modelContext.save()

        // Then: Restore backup
        let restoreResult = try await backupManager.restoreBackup(
            backup,
            password: nil,
            options: RestoreOptions(clearExistingData: false, restoreSettings: false)
        )

        // Verify restoration
        XCTAssertTrue(restoreResult.success)
        XCTAssertEqual(restoreResult.tasksRestored, originalTasks.count)

        let restoredTasks = try modelContext.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(restoredTasks.count, originalTasks.count)

        // Clean up
        try? FileManager.default.removeItem(at: backup.fileURL)
    }

    func testEncryptedBackupRoundTrip() async throws {
        // Given: Create tasks
        let tasks = TestDataGenerator.generateTasks(count: 5)
        for task in tasks {
            modelContext.insert(task)
        }
        try modelContext.save()

        // When: Create encrypted backup
        let exportCoordinator = ExportCoordinator(modelContext: modelContext)
        let backupManager = BackupManager(
            modelContext: modelContext,
            exportCoordinator: exportCoordinator
        )

        let password = "TestPassword123!"
        let backup = try await backupManager.createBackup(
            name: "Encrypted Backup",
            encrypt: true,
            password: password
        )

        // Verify encryption
        XCTAssertTrue(backup.isEncrypted)

        // Clear tasks
        let allTasks = try modelContext.fetch(FetchDescriptor<TaskItem>())
        for task in allTasks {
            modelContext.delete(task)
        }
        try modelContext.save()

        // Then: Restore with correct password
        let restoreResult = try await backupManager.restoreBackup(
            backup,
            password: password,
            options: RestoreOptions(clearExistingData: false, restoreSettings: false)
        )

        // Verify
        XCTAssertTrue(restoreResult.success)
        XCTAssertEqual(restoreResult.tasksRestored, tasks.count)

        // Clean up
        try? FileManager.default.removeItem(at: backup.fileURL)
    }

    // MARK: - Conflict Detection Tests

    func testConflictDetection_DuplicateTitles() async throws {
        // Given: Existing task
        let existingTask = TaskItem(title: "Duplicate Task", description: "Original", tags: [], priority: .medium)
        modelContext.insert(existingTask)
        try modelContext.save()

        // When: Import file with duplicate title
        let importedTask = ImportedTask(
            sourceId: "ext-123",
            sourceSystem: "test",
            title: "Duplicate Task",
            description: "Imported",
            tags: [],
            priority: .high,
            createdAt: Date(),
            completedAt: nil
        )

        let importCoordinator = ImportCoordinator(modelContext: modelContext)

        // Create temporary import file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("conflict-test.json")
        let jsonData = """
        {
            "tasks": [
                {
                    "title": "Duplicate Task",
                    "description": "Imported",
                    "tags": [],
                    "priority": "high"
                }
            ]
        }
        """.data(using: .utf8)!
        try jsonData.write(to: tempURL)

        // Then: Generate preview and check conflicts
        let preview = try await importCoordinator.generatePreview(from: tempURL, source: .json)

        XCTAssertTrue(preview.hasConflicts)
        XCTAssertEqual(preview.potentialConflicts.count, 1)
        XCTAssertEqual(preview.potentialConflicts.first?.conflictType, .duplicateTitle)

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Edge Case Tests

    func testExportImport_EdgeCases() async throws {
        // Given: Edge case tasks
        let edgeCaseTasks = TestDataGenerator.generateEdgeCaseTasks()
        for task in edgeCaseTasks {
            modelContext.insert(task)
        }
        try modelContext.save()

        // When: Export and import
        let exportCoordinator = ExportCoordinator(modelContext: modelContext)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("edge-cases.json")

        let exportResult = try await exportCoordinator.export(
            format: .json,
            options: .complete,
            destination: tempURL
        )

        // Clear and re-import
        let allTasks = try modelContext.fetch(FetchDescriptor<TaskItem>())
        for task in allTasks {
            modelContext.delete(task)
        }
        try modelContext.save()

        let importCoordinator = ImportCoordinator(modelContext: modelContext)
        let importResult = try await importCoordinator.importData(
            from: exportResult.destination,
            source: .json,
            options: ImportOptions()
        )

        // Verify: All edge cases handled correctly
        XCTAssertTrue(importResult.success)
        XCTAssertEqual(importResult.importedCount, edgeCaseTasks.count)

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testImport_EmptyFile() async throws {
        // Given: Empty file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("empty.json")
        let emptyData = "{}".data(using: .utf8)!
        try emptyData.write(to: tempURL)

        // When: Try to import
        let importCoordinator = ImportCoordinator(modelContext: modelContext)

        do {
            _ = try await importCoordinator.importData(
                from: tempURL,
                source: .json,
                options: ImportOptions()
            )
            // Should handle gracefully without crashing
        } catch {
            // Error is acceptable for empty file
        }

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Performance Tests

    func testExportPerformance_LargeDataset() async throws {
        // Given: Large dataset
        let largeTasks = TestDataGenerator.generateLargeDataset(size: .medium)
        for task in largeTasks {
            modelContext.insert(task)
        }
        try modelContext.save()

        // Measure export performance
        let exportCoordinator = ExportCoordinator(modelContext: modelContext)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("large-export.json")

        let startTime = Date()
        _ = try await exportCoordinator.export(
            format: .json,
            options: .complete,
            destination: tempURL
        )
        let duration = Date().timeIntervalSince(startTime)

        // Verify: Export completes in reasonable time (< 5 seconds for 500 tasks)
        XCTAssertLessThan(duration, 5.0, "Export should complete in under 5 seconds")

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testImportPerformance_LargeDataset() async throws {
        // Given: Export large dataset first
        let largeTasks = TestDataGenerator.generateLargeDataset(size: .small)
        for task in largeTasks {
            modelContext.insert(task)
        }
        try modelContext.save()

        let exportCoordinator = ExportCoordinator(modelContext: modelContext)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("large-import.json")
        _ = try await exportCoordinator.export(
            format: .json,
            options: .complete,
            destination: tempURL
        )

        // Clear database
        let allTasks = try modelContext.fetch(FetchDescriptor<TaskItem>())
        for task in allTasks {
            modelContext.delete(task)
        }
        try modelContext.save()

        // Measure import performance
        let importCoordinator = ImportCoordinator(modelContext: modelContext)

        let startTime = Date()
        _ = try await importCoordinator.importData(
            from: tempURL,
            source: .json,
            options: ImportOptions()
        )
        let duration = Date().timeIntervalSince(startTime)

        // Verify: Import completes in reasonable time
        XCTAssertLessThan(duration, 5.0, "Import should complete in under 5 seconds")

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Diagnostic Tracking Tests

    func testDiagnosticTracking_ExportOperation() async throws {
        // Given: Some tasks
        let tasks = TestDataGenerator.generateTasks(count: 5)
        for task in tasks {
            modelContext.insert(task)
        }
        try modelContext.save()

        // When: Perform export (diagnostics tracked automatically)
        let exportCoordinator = ExportCoordinator(modelContext: modelContext)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("diagnostic-test.json")

        _ = try await exportCoordinator.export(
            format: .json,
            options: .complete,
            destination: tempURL
        )

        // Then: Verify diagnostic data was recorded
        let report = await DiagnosticService.shared.generateReport()

        XCTAssertGreaterThan(report.performanceMetrics.totalExports, 0)
        XCTAssertFalse(report.operationHistory.isEmpty)

        // Should have at least one export operation
        let exportOperations = report.operationHistory.filter { $0.operationType.contains("Export") }
        XCTAssertGreaterThan(exportOperations.count, 0)

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
}
