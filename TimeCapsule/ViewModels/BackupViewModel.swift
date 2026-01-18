import Foundation
import SwiftData
import OSLog

@Observable
@MainActor
final class BackupViewModel {
    private let modelContext: ModelContext
    private let logger = Logger.backup

    var backups: [Backup] = []
    var isLoading = false
    var error: Error?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadBackups() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let exportCoordinator = ExportCoordinator(modelContext: modelContext)
            let backupManager = BackupManager(
                modelContext: modelContext,
                exportCoordinator: exportCoordinator
            )

            backups = try await backupManager.listBackups()
            logger.info("Loaded \(self.backups.count) backups")
        } catch {
            logger.error("Failed to load backups: \(error)")
            self.error = error
        }
    }

    func deleteBackup(_ backup: Backup) async throws {
        let exportCoordinator = ExportCoordinator(modelContext: modelContext)
        let backupManager = BackupManager(
            modelContext: modelContext,
            exportCoordinator: exportCoordinator
        )

        try await backupManager.deleteBackup(backup)
        await loadBackups()
    }

    func verifyBackup(_ backup: Backup) async -> Bool {
        // Check if file exists and is readable
        guard FileManager.default.fileExists(atPath: backup.fileURL.path) else {
            return false
        }

        guard FileManager.default.isReadableFile(atPath: backup.fileURL.path) else {
            return false
        }

        // Verify file size matches
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: backup.fileURL.path)
            guard let fileSize = attributes[.size] as? Int else {
                return false
            }

            return fileSize == backup.fileSizeBytes
        } catch {
            return false
        }
    }

    func exportBackup(_ backup: Backup, to destination: URL) async throws {
        try FileManager.default.copyItem(at: backup.fileURL, to: destination)
    }
}
