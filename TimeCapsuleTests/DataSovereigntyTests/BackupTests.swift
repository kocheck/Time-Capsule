import Testing
import Foundation
import SwiftData
@testable import TimeCapsule

@Suite("Backup Functionality Tests")
struct BackupTests {

    @Test("Backup metadata is created correctly")
    func backupMetadataIsCreatedCorrectly() async throws {
        let backup = Backup(
            id: UUID(),
            name: "Test Backup",
            createdAt: Date(),
            fileURL: URL(fileURLWithPath: "/tmp/test.tcbackup"),
            fileSizeBytes: 1024,
            isEncrypted: true,
            taskCount: 10,
            completedTaskCount: 5,
            archivedTaskCount: 2,
            appVersion: "1.0.0"
        )

        #expect(backup.name == "Test Backup", "Name should match")
        #expect(backup.isEncrypted == true, "Should be encrypted")
        #expect(backup.taskCount == 10, "Task count should match")
        #expect(backup.fileSizeFormatted.contains("1"), "File size should be formatted")
        #expect(!backup.ageFormatted.isEmpty, "Age should be formatted")
    }

    @Test("Restore options are configured correctly")
    func restoreOptionsAreConfiguredCorrectly() {
        let standardOptions = RestoreOptions.standard
        #expect(standardOptions.clearExistingData == false, "Standard should not clear data")
        #expect(standardOptions.restoreSettings == false, "Standard should not restore settings")

        let fullOptions = RestoreOptions.fullRestore
        #expect(fullOptions.clearExistingData == true, "Full restore should clear data")
        #expect(fullOptions.restoreSettings == true, "Full restore should restore settings")
    }

    @Test("Backup error descriptions are helpful")
    func backupErrorDescriptionsAreHelpful() {
        let errors: [BackupError] = [
            .passwordRequired,
            .encryptionFailed,
            .decryptionFailed,
            .checksumMismatch,
            .compressionFailed,
            .decompressionFailed,
            .invalidBackupFile
        ]

        for error in errors {
            let description = error.errorDescription
            #expect(description != nil, "Error should have description")
            #expect(!description!.isEmpty, "Description should not be empty")
        }
    }

    @Test("Export models define correct file types")
    func exportModelsDefineCorrectFileTypes() {
        #expect(ExportFormat.universalTaskFormat.fileExtension == "utf.json")
        #expect(ExportFormat.json.fileExtension == "json")
        #expect(ExportFormat.csv.fileExtension == "csv")
        #expect(ExportFormat.markdown.fileExtension == "md")

        #expect(ExportFormat.universalTaskFormat.utType == .json)
        #expect(ExportFormat.csv.utType == .commaSeparatedText)
        #expect(ExportFormat.markdown.utType == .plainText)
    }

    @Test("Export options presets are configured correctly")
    func exportOptionsPresetsAreConfiguredCorrectly() {
        let minimal = ExportOptions.minimal
        #expect(minimal.includeCompleted == false, "Minimal should not include completed")
        #expect(minimal.includeArchived == false, "Minimal should not include archived")
        #expect(minimal.includeSettings == false, "Minimal should not include settings")

        let complete = ExportOptions.complete
        #expect(complete.includeCompleted == true, "Complete should include completed")
        #expect(complete.includeArchived == true, "Complete should include archived")
        #expect(complete.includeSettings == true, "Complete should include settings")
    }

    @Test("Import source descriptions provide guidance")
    func importSourceDescriptionsProvideGuidance() {
        for source in ImportSource.allCases {
            let instructions = source.exportInstructions
            #expect(!instructions.isEmpty, "Source \(source.rawValue) should have instructions")

            switch source {
            case .todoist:
                #expect(instructions.contains("todoist.com"), "Todoist instructions should mention website")
            case .things3:
                #expect(instructions.contains("Export"), "Things 3 should mention export")
            case .reminders:
                #expect(instructions.contains("Reminders"), "Reminders should mention Reminders app")
            default:
                break
            }
        }
    }

    @Test("Import conflict strategies are available")
    func importConflictStrategiesAreAvailable() {
        let strategies = ConflictStrategy.allCases

        #expect(strategies.contains(.keepBoth), "Should have keep both strategy")
        #expect(strategies.contains(.replaceExisting), "Should have replace strategy")
        #expect(strategies.contains(.skipDuplicates), "Should have skip strategy")
    }

    @Test("UTF schema defines task structure")
    func utfSchemaDefinesTaskStructure() {
        let schema = UTFSchema.current

        #expect(schema.version == "1.0.0", "Schema version should be 1.0.0")
        #expect(!schema.entities.isEmpty, "Schema should define entities")

        let taskEntity = schema.entities.first { $0.name == "Task" }
        #expect(taskEntity != nil, "Schema should define Task entity")

        let idField = taskEntity?.fields.first { $0.name == "id" }
        #expect(idField?.required == true, "ID field should be required")

        let titleField = taskEntity?.fields.first { $0.name == "title" }
        #expect(titleField?.required == true, "Title field should be required")
    }

    @Test("UTF task conversion maintains data integrity")
    func utfTaskConversionMaintainsDataIntegrity() {
        // Create original task
        let originalTask = TaskItem(
            title: "Test Task",
            description: "Test description",
            tags: ["work", "urgent"],
            priority: .high
        )
        originalTask.skipCount = 3
        originalTask.dailySkipCount = 1
        originalTask.isArchived = false
        originalTask.contextHints = ["morning"]

        // Convert to UTF
        let utfTask = UTFTask(from: originalTask)

        #expect(utfTask.title == originalTask.title)
        #expect(utfTask.description == originalTask.taskDescription)
        #expect(utfTask.tags == originalTask.tags)
        #expect(utfTask.priority == originalTask.priority.rawValue)
        #expect(utfTask.skipCount == originalTask.skipCount)
        #expect(utfTask.dailySkipCount == originalTask.dailySkipCount)
        #expect(utfTask.contextHints == originalTask.contextHints)

        // Convert back
        let convertedTask = utfTask.toTaskItem()

        #expect(convertedTask.title == originalTask.title)
        #expect(convertedTask.taskDescription == originalTask.taskDescription)
        #expect(convertedTask.tags == originalTask.tags)
        #expect(convertedTask.priority == originalTask.priority)
        #expect(convertedTask.skipCount == originalTask.skipCount)
        #expect(convertedTask.contextHints == originalTask.contextHints)
    }

    @Test("Export manifest tracks metadata")
    func exportManifestTracksMetadata() {
        let manifest = ExportManifest(
            format: .universalTaskFormat,
            exportedAt: Date(),
            taskCount: 10,
            completedTaskCount: 5,
            archivedTaskCount: 2,
            includesSettings: true,
            checksum: "abc123"
        )

        #expect(manifest.taskCount == 10)
        #expect(manifest.completedTaskCount == 5)
        #expect(manifest.archivedTaskCount == 2)
        #expect(manifest.includesSettings == true)
        #expect(manifest.checksum == "abc123")
    }
}
