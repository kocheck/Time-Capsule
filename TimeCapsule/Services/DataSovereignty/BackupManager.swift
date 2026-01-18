import Foundation
import Compression
import CryptoKit
import OSLog
import SwiftData

actor BackupManager {
    private let logger = Logger.backup
    private let modelContext: ModelContext
    private let exportCoordinator: ExportCoordinator

    private let backupDirectory: URL
    private let maxBackups: Int = 10

    init(modelContext: ModelContext, exportCoordinator: ExportCoordinator) {
        self.modelContext = modelContext
        self.exportCoordinator = exportCoordinator

        // Store backups in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.backupDirectory = appSupport.appendingPathComponent("TimeCapsule/Backups", isDirectory: true)

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Create Backup

    func createBackup(
        name: String? = nil,
        encrypt: Bool = false,
        password: String? = nil
    ) async throws -> Backup {
        // Track operation start
        let startTime = Date()
        let operationId = await DiagnosticService.shared.trackOperationStart(
            "Create Backup",
            details: "encrypted=\(encrypt)"
        )

        let backupId = UUID()
        let timestamp = Date()
        let backupName = name ?? "Backup \(timestamp.formatted(date: .abbreviated, time: .shortened))"

        logger.info("Creating backup: \(backupName)")

        do {
            // Fetch task counts first
            let activeTasks = try await fetchActiveTasks()
            let completedTasks = try await fetchCompletedTasks()
            let archivedTasks = try await fetchArchivedTasks()

            // Create temporary file for export
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(backupId.uuidString).utf.json")

            // Export all data to temporary location
            let exportResult = try await exportCoordinator.export(
                format: .universalTaskFormat,
                options: .complete,
                destination: tempURL
            )

            // Read exported data
            let exportedData = try Data(contentsOf: exportResult.destination)

            // Compress
            let compressedData = try compress(exportedData)

            // Encrypt if requested
            let finalData: Data
            let isEncrypted: Bool

            if encrypt {
                guard let password = password else {
                    throw BackupError.passwordRequired
                }
                finalData = try encryptData(compressedData, password: password)
                isEncrypted = true
            } else {
                finalData = compressedData
                isEncrypted = false
            }

            // Create backup file
            let backupFileName = "\(backupId.uuidString).tcbackup"
            let backupURL = backupDirectory.appendingPathComponent(backupFileName)
            try finalData.write(to: backupURL)

            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempURL)

            // Create backup metadata
            let backup = Backup(
                id: backupId,
                name: backupName,
                createdAt: timestamp,
                fileURL: backupURL,
                fileSizeBytes: finalData.count,
                isEncrypted: isEncrypted,
                taskCount: activeTasks.count,
                completedTaskCount: completedTasks.count,
                archivedTaskCount: archivedTasks.count,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            )

            // Save backup metadata
            try await saveBackupMetadata(backup)

            // Cleanup old backups
            try await cleanupOldBackups()

            logger.info("Backup created successfully: \(backup.fileSizeFormatted)")

            // Track operation success
            let duration = Int(Date().timeIntervalSince(startTime) * 1000)
            await DiagnosticService.shared.trackOperationComplete(operationId, durationMs: duration)

            return backup
        } catch {
            // Track operation failure
            await DiagnosticService.shared.trackOperationFailed(operationId, error: error)
            throw error
        }
    }

    // MARK: - Restore Backup

    func restoreBackup(
        _ backup: Backup,
        password: String? = nil,
        options: RestoreOptions
    ) async throws -> RestoreResult {
        logger.info("Restoring backup: \(backup.name)")

        // Read backup file
        let backupData = try Data(contentsOf: backup.fileURL)

        // Decrypt if needed
        let decryptedData: Data
        if backup.isEncrypted {
            guard let password = password else {
                throw BackupError.passwordRequired
            }
            decryptedData = try decryptData(backupData, password: password)
        } else {
            decryptedData = backupData
        }

        // Decompress
        let decompressedData = try decompress(decryptedData, originalSize: backup.fileSizeBytes * 10)

        // Parse UTF format
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let format = try decoder.decode(UniversalTaskFormat.self, from: decompressedData)

        // Clear existing data if requested
        if options.clearExistingData {
            logger.warning("Clearing existing data before restore")
            try await clearAllTasks()
        }

        // Restore data
        var result = RestoreResult()

        // Restore active tasks
        for utfTask in format.tasks {
            do {
                let task = utfTask.toTaskItem()
                modelContext.insert(task)
                result.tasksRestored += 1
            } catch {
                logger.error("Failed to restore task: \(utfTask.title)")
                result.tasksFailed += 1
            }
        }

        // Restore completed tasks
        for utfTask in format.completedTasks {
            do {
                let task = utfTask.toTaskItem()
                modelContext.insert(task)
                result.tasksRestored += 1
            } catch {
                logger.error("Failed to restore task: \(utfTask.title)")
                result.tasksFailed += 1
            }
        }

        // Restore archived tasks
        for utfTask in format.archivedTasks {
            do {
                let task = utfTask.toTaskItem()
                modelContext.insert(task)
                result.tasksRestored += 1
            } catch {
                logger.error("Failed to restore task: \(utfTask.title)")
                result.tasksFailed += 1
            }
        }

        // Save changes
        try modelContext.save()

        logger.info("Restore completed: \(result.tasksRestored) tasks restored")

        return result
    }

    // MARK: - List Backups

    func listBackups() async throws -> [Backup] {
        let metadataURL = backupDirectory.appendingPathComponent("backups.json")

        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            return []
        }

        let data = try Data(contentsOf: metadataURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backups = try decoder.decode([Backup].self, from: data)

        // Filter to only existing files
        return backups.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
    }

    func deleteBackup(_ backup: Backup) async throws {
        try FileManager.default.removeItem(at: backup.fileURL)

        var backups = try await listBackups()
        backups.removeAll { $0.id == backup.id }
        try await saveBackupList(backups)

        logger.info("Backup deleted: \(backup.name)")
    }

    // MARK: - Encryption

    private func encryptData(_ data: Data, password: String) throws -> Data {
        let key = SymmetricKey(data: SHA256.hash(data: Data(password.utf8)))
        let sealedBox = try AES.GCM.seal(data, using: key)

        guard let combined = sealedBox.combined else {
            throw BackupError.encryptionFailed
        }

        return combined
    }

    private func decryptData(_ data: Data, password: String) throws -> Data {
        let key = SymmetricKey(data: SHA256.hash(data: Data(password.utf8)))
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw BackupError.decryptionFailed
        }
    }

    // MARK: - Compression

    private func compress(_ data: Data) throws -> Data {
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        defer { destinationBuffer.deallocate() }

        let compressedSize = data.withUnsafeBytes { sourceBuffer in
            compression_encode_buffer(
                destinationBuffer,
                data.count,
                sourceBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self),
                data.count,
                nil,
                COMPRESSION_LZFSE
            )
        }

        guard compressedSize > 0 else {
            throw BackupError.compressionFailed
        }

        return Data(bytes: destinationBuffer, count: compressedSize)
    }

    private func decompress(_ data: Data, originalSize: Int) throws -> Data {
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: originalSize)
        defer { destinationBuffer.deallocate() }

        let decompressedSize = data.withUnsafeBytes { sourceBuffer in
            compression_decode_buffer(
                destinationBuffer,
                originalSize,
                sourceBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self),
                data.count,
                nil,
                COMPRESSION_LZFSE
            )
        }

        guard decompressedSize > 0 else {
            throw BackupError.decompressionFailed
        }

        return Data(bytes: destinationBuffer, count: decompressedSize)
    }

    // MARK: - Helper Functions

    private func fetchActiveTasks() async throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { !$0.isCompleted && !$0.isArchived }
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchCompletedTasks() async throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { $0.isCompleted && !$0.isArchived }
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchArchivedTasks() async throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { $0.isArchived }
        )
        return try modelContext.fetch(descriptor)
    }

    private func clearAllTasks() async throws {
        try modelContext.delete(model: TaskItem.self)
        try modelContext.save()
    }

    private func saveBackupMetadata(_ backup: Backup) async throws {
        var backups = try await listBackups()
        backups.append(backup)
        try await saveBackupList(backups)
    }

    private func saveBackupList(_ backups: [Backup]) async throws {
        let metadataURL = backupDirectory.appendingPathComponent("backups.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backups)
        try data.write(to: metadataURL, options: .atomic)
    }

    private func cleanupOldBackups() async throws {
        var backups = try await listBackups()
        guard backups.count > maxBackups else { return }

        // Sort by creation date
        backups.sort { $0.createdAt < $1.createdAt }

        // Delete oldest backups
        let toDelete = backups.prefix(backups.count - maxBackups)
        for backup in toDelete {
            try? FileManager.default.removeItem(at: backup.fileURL)
            logger.info("Deleted old backup: \(backup.name)")
        }

        // Update metadata
        let remaining = Array(backups.suffix(maxBackups))
        try await saveBackupList(remaining)
    }
}
