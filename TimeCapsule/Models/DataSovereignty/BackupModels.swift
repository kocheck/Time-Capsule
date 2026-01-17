import Foundation

// MARK: - Backup Model

struct Backup: Codable, Identifiable {
    let id: UUID
    let name: String
    let createdAt: Date
    let fileURL: URL
    let fileSizeBytes: Int
    let isEncrypted: Bool
    let taskCount: Int
    let completedTaskCount: Int
    let archivedTaskCount: Int
    let appVersion: String

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(fileSizeBytes), countStyle: .file)
    }

    var ageFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Restore Options

struct RestoreOptions {
    var clearExistingData: Bool = false
    var restoreSettings: Bool = false

    static var standard: RestoreOptions {
        RestoreOptions(clearExistingData: false, restoreSettings: false)
    }

    static var fullRestore: RestoreOptions {
        RestoreOptions(clearExistingData: true, restoreSettings: true)
    }
}

// MARK: - Restore Result

struct RestoreResult {
    var tasksRestored: Int = 0
    var tasksFailed: Int = 0
    var settingsRestored: Bool = false

    var totalProcessed: Int {
        tasksRestored + tasksFailed
    }
}

// MARK: - Backup Errors

enum BackupError: LocalizedError {
    case passwordRequired
    case encryptionFailed
    case decryptionFailed
    case checksumMismatch
    case compressionFailed
    case decompressionFailed
    case invalidBackupFile

    var errorDescription: String? {
        switch self {
        case .passwordRequired:
            return "Password required for encrypted backup"
        case .encryptionFailed:
            return "Failed to encrypt backup data"
        case .decryptionFailed:
            return "Failed to decrypt backup - check password"
        case .checksumMismatch:
            return "Backup file is corrupted or tampered"
        case .compressionFailed:
            return "Failed to compress backup data"
        case .decompressionFailed:
            return "Failed to decompress backup data"
        case .invalidBackupFile:
            return "Invalid backup file format"
        }
    }
}
