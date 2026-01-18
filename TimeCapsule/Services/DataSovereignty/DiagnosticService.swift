import Foundation
import OSLog

actor DiagnosticService {
    static let shared = DiagnosticService()

    private let logger = Logger.audit
    private let userDefaults = UserDefaults.standard
    private let operationHistoryKey = "diagnostics.operationHistory"
    private let errorHistoryKey = "diagnostics.errorHistory"
    private let metricsKey = "diagnostics.metrics"

    private var operationHistory: [OperationLog] = []
    private var errorHistory: [ErrorLog] = []
    private var metrics: PerformanceMetrics

    private init() {
        // Load persisted data
        self.metrics = Self.loadMetrics()
        self.operationHistory = Self.loadOperationHistory()
        self.errorHistory = Self.loadErrorHistory()
    }

    // MARK: - Operation Tracking

    func trackOperationStart(_ type: String, details: String? = nil) -> UUID {
        let id = UUID()
        let log = OperationLog(
            id: id,
            timestamp: Date(),
            operationType: type,
            status: .started,
            durationMs: nil,
            details: details
        )

        operationHistory.insert(log, at: 0)
        trimOperationHistory()
        persistOperationHistory()

        logger.info("Operation started: \(type)")
        return id
    }

    func trackOperationComplete(_ id: UUID, durationMs: Int) {
        guard let index = operationHistory.firstIndex(where: { $0.id == id }) else { return }

        let startLog = operationHistory[index]
        let completeLog = OperationLog(
            id: id,
            timestamp: Date(),
            operationType: startLog.operationType,
            status: .completed,
            durationMs: durationMs,
            details: startLog.details
        )

        operationHistory[index] = completeLog
        updateMetrics(for: startLog.operationType, durationMs: durationMs)
        persistOperationHistory()
        persistMetrics()

        logger.info("Operation completed: \(startLog.operationType) in \(durationMs)ms")
    }

    func trackOperationFailed(_ id: UUID, error: Error) {
        guard let index = operationHistory.firstIndex(where: { $0.id == id }) else { return }

        let startLog = operationHistory[index]
        let failLog = OperationLog(
            id: id,
            timestamp: Date(),
            operationType: startLog.operationType,
            status: .failed,
            durationMs: nil,
            details: error.localizedDescription
        )

        operationHistory[index] = failLog
        logError(type: startLog.operationType, message: error.localizedDescription)
        persistOperationHistory()

        logger.error("Operation failed: \(startLog.operationType) - \(error)")
    }

    // MARK: - Error Logging

    func logError(type: String, message: String, stackTrace: String? = nil) {
        let error = ErrorLog(
            id: UUID(),
            timestamp: Date(),
            errorType: type,
            message: message,
            stackTrace: stackTrace
        )

        errorHistory.insert(error, at: 0)
        trimErrorHistory()
        persistErrorHistory()

        logger.error("Error logged: \(type) - \(message)")
    }

    // MARK: - Metrics

    private func updateMetrics(for operationType: String, durationMs: Int) {
        var updatedMetrics = metrics

        switch operationType.lowercased() {
        case let type where type.contains("export"):
            updatedMetrics.totalExports += 1
            if let avg = updatedMetrics.averageExportTimeMs {
                updatedMetrics.averageExportTimeMs = (avg + durationMs) / 2
            } else {
                updatedMetrics.averageExportTimeMs = durationMs
            }

        case let type where type.contains("import"):
            updatedMetrics.totalImports += 1
            if let avg = updatedMetrics.averageImportTimeMs {
                updatedMetrics.averageImportTimeMs = (avg + durationMs) / 2
            } else {
                updatedMetrics.averageImportTimeMs = durationMs
            }

        case let type where type.contains("backup"):
            updatedMetrics.totalBackups += 1
            if let avg = updatedMetrics.averageBackupTimeMs {
                updatedMetrics.averageBackupTimeMs = (avg + durationMs) / 2
            } else {
                updatedMetrics.averageBackupTimeMs = durationMs
            }

        default:
            break
        }

        metrics = updatedMetrics
    }

    func updateLargestExportSize(_ sizeBytes: Int64) {
        if let current = metrics.largestExportSizeBytes {
            if sizeBytes > current {
                var updated = metrics
                updated.largestExportSizeBytes = sizeBytes
                metrics = updated
                persistMetrics()
            }
        } else {
            var updated = metrics
            updated.largestExportSizeBytes = sizeBytes
            metrics = updated
            persistMetrics()
        }
    }

    func updateLargestImportSize(_ sizeBytes: Int64) {
        if let current = metrics.largestImportSizeBytes {
            if sizeBytes > current {
                var updated = metrics
                updated.largestImportSizeBytes = sizeBytes
                metrics = updated
                persistMetrics()
            }
        } else {
            var updated = metrics
            updated.largestImportSizeBytes = sizeBytes
            metrics = updated
            persistMetrics()
        }
    }

    // MARK: - Report Generation

    func generateReport() -> DiagnosticReport {
        DiagnosticReport(
            generatedAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            systemInfo: SystemInfo.current(),
            operationHistory: Array(operationHistory.prefix(50)),
            errorHistory: Array(errorHistory.prefix(20)),
            performanceMetrics: metrics
        )
    }

    func exportDiagnostics(to url: URL) throws {
        let report = generateReport()
        let jsonData = try JSONEncoder().encode(report)
        try jsonData.write(to: url)

        logger.info("Diagnostics exported to \(url.path)")
    }

    func exportDiagnosticsAsText(to url: URL) throws {
        let report = generateReport()
        let text = report.formattedReport
        try text.write(to: url, atomically: true, encoding: .utf8)

        logger.info("Diagnostics exported as text to \(url.path)")
    }

    // MARK: - Persistence

    private func trimOperationHistory() {
        if operationHistory.count > 100 {
            operationHistory = Array(operationHistory.prefix(100))
        }
    }

    private func trimErrorHistory() {
        if errorHistory.count > 50 {
            errorHistory = Array(errorHistory.prefix(50))
        }
    }

    private func persistOperationHistory() {
        if let data = try? JSONEncoder().encode(operationHistory) {
            userDefaults.set(data, forKey: operationHistoryKey)
        }
    }

    private func persistErrorHistory() {
        if let data = try? JSONEncoder().encode(errorHistory) {
            userDefaults.set(data, forKey: errorHistoryKey)
        }
    }

    private func persistMetrics() {
        if let data = try? JSONEncoder().encode(metrics) {
            userDefaults.set(data, forKey: metricsKey)
        }
    }

    private static func loadOperationHistory() -> [OperationLog] {
        guard let data = UserDefaults.standard.data(forKey: "diagnostics.operationHistory"),
              let history = try? JSONDecoder().decode([OperationLog].self, from: data) else {
            return []
        }
        return history
    }

    private static func loadErrorHistory() -> [ErrorLog] {
        guard let data = UserDefaults.standard.data(forKey: "diagnostics.errorHistory"),
              let history = try? JSONDecoder().decode([ErrorLog].self, from: data) else {
            return []
        }
        return history
    }

    private static func loadMetrics() -> PerformanceMetrics {
        guard let data = UserDefaults.standard.data(forKey: "diagnostics.metrics"),
              let metrics = try? JSONDecoder().decode(PerformanceMetrics.self, from: data) else {
            return PerformanceMetrics(
                totalExports: 0,
                totalImports: 0,
                totalBackups: 0,
                averageExportTimeMs: nil,
                averageImportTimeMs: nil,
                averageBackupTimeMs: nil,
                largestExportSizeBytes: nil,
                largestImportSizeBytes: nil
            )
        }
        return metrics
    }

    // MARK: - Data Management

    func clearDiagnostics() {
        operationHistory = []
        errorHistory = []
        metrics = PerformanceMetrics(
            totalExports: 0,
            totalImports: 0,
            totalBackups: 0,
            averageExportTimeMs: nil,
            averageImportTimeMs: nil,
            averageBackupTimeMs: nil,
            largestExportSizeBytes: nil,
            largestImportSizeBytes: nil
        )

        userDefaults.removeObject(forKey: operationHistoryKey)
        userDefaults.removeObject(forKey: errorHistoryKey)
        userDefaults.removeObject(forKey: metricsKey)

        logger.info("Diagnostics cleared")
    }
}
