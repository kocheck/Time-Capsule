import Foundation
import OSLog

// MARK: - Diagnostic Report

struct DiagnosticReport: Codable {
    let generatedAt: Date
    let appVersion: String
    let systemInfo: SystemInfo
    let operationHistory: [OperationLog]
    let errorHistory: [ErrorLog]
    let performanceMetrics: PerformanceMetrics

    var formattedReport: String {
        var report = """
        # Time Capsule Diagnostic Report
        Generated: \(generatedAt.formatted())
        App Version: \(appVersion)

        ## System Information
        \(systemInfo.formatted)

        ## Recent Operations (\(operationHistory.count))
        """

        for operation in operationHistory.prefix(20) {
            report += "\n- [\(operation.timestamp.formatted(date: .omitted, time: .standard))] \(operation.operationType): \(operation.status.rawValue)"
            if let duration = operation.durationMs {
                report += " (\(duration)ms)"
            }
        }

        report += """


        ## Recent Errors (\(errorHistory.count))
        """

        for error in errorHistory.prefix(10) {
            report += "\n- [\(error.timestamp.formatted(date: .omitted, time: .standard))] \(error.errorType): \(error.message)"
        }

        report += """


        ## Performance Metrics
        \(performanceMetrics.formatted)
        """

        return report
    }
}

// MARK: - System Info

struct SystemInfo: Codable {
    let osVersion: String
    let deviceModel: String
    let availableMemory: Int64
    let availableDiskSpace: Int64
    let locale: String

    var formatted: String {
        """
        OS: \(osVersion)
        Device: \(deviceModel)
        Available Memory: \(ByteCountFormatter.string(fromByteCount: availableMemory, countStyle: .memory))
        Available Disk Space: \(ByteCountFormatter.string(fromByteCount: availableDiskSpace, countStyle: .file))
        Locale: \(locale)
        """
    }

    static func current() -> SystemInfo {
        let processInfo = ProcessInfo.processInfo

        // Get available disk space
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        var availableDiskSpace: Int64 = 0
        do {
            let values = try homeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            availableDiskSpace = Int64(values.volumeAvailableCapacity ?? 0)
        } catch {
            // Unable to get disk space
        }

        return SystemInfo(
            osVersion: processInfo.operatingSystemVersionString,
            deviceModel: processInfo.hostName,
            availableMemory: Int64(processInfo.physicalMemory),
            availableDiskSpace: availableDiskSpace,
            locale: Locale.current.identifier
        )
    }
}

// MARK: - Operation Log

struct OperationLog: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let operationType: String
    let status: OperationStatus
    let durationMs: Int?
    let details: String?

    enum OperationStatus: String, Codable {
        case started = "Started"
        case completed = "Completed"
        case failed = "Failed"
    }
}

// MARK: - Error Log

struct ErrorLog: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let errorType: String
    let message: String
    let stackTrace: String?
}

// MARK: - Performance Metrics

struct PerformanceMetrics: Codable {
    let totalExports: Int
    let totalImports: Int
    let totalBackups: Int
    let averageExportTimeMs: Int?
    let averageImportTimeMs: Int?
    let averageBackupTimeMs: Int?
    let largestExportSizeBytes: Int64?
    let largestImportSizeBytes: Int64?

    var formatted: String {
        """
        Total Exports: \(totalExports)
        Total Imports: \(totalImports)
        Total Backups: \(totalBackups)
        Average Export Time: \(averageExportTimeMs.map { "\($0)ms" } ?? "N/A")
        Average Import Time: \(averageImportTimeMs.map { "\($0)ms" } ?? "N/A")
        Average Backup Time: \(averageBackupTimeMs.map { "\($0)ms" } ?? "N/A")
        Largest Export: \(largestExportSizeBytes.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? "N/A")
        Largest Import: \(largestImportSizeBytes.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? "N/A")
        """
    }
}
