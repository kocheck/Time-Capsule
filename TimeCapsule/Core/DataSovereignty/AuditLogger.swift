import Foundation

/// Events that can be logged for audit purposes
enum AuditEvent {
    case exported(format: String, taskCount: Int)
    case imported(source: String, taskCount: Int)
    case deleted(scope: String, count: Int)

    var eventType: String {
        switch self {
        case .exported: return "export"
        case .imported: return "import"
        case .deleted: return "delete"
        }
    }

    var description: String {
        switch self {
        case .exported(let format, let count):
            return "Exported \(count) tasks in \(format) format"
        case .imported(let source, let count):
            return "Imported \(count) tasks from \(source)"
        case .deleted(let scope, let count):
            return "Deleted \(count) tasks (\(scope))"
        }
    }
}

/// A single audit log entry recording a data operation
struct AuditLogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let event: String
    let details: String

    init(id: UUID = UUID(), timestamp: Date = Date(), event: String, details: String) {
        self.id = id
        self.timestamp = timestamp
        self.event = event
        self.details = details
    }

    init(from auditEvent: AuditEvent) {
        self.id = UUID()
        self.timestamp = Date()
        self.event = auditEvent.eventType
        self.details = auditEvent.description
    }
}

/// Actor-based audit logger for tracking data operations.
/// Persists logs to UserDefaults for simplicity.
actor AuditLogger {
    private let userDefaultsKey = "com.timecapsule.auditLogs"
    private let maxLogEntries = 1000

    private var logs: [AuditLogEntry] = []

    init() {
        loadLogs()
    }

    /// Logs an audit event
    func log(_ event: AuditEvent) async {
        let entry = AuditLogEntry(from: event)
        logs.insert(entry, at: 0)

        // Trim to max entries
        if logs.count > maxLogEntries {
            logs = Array(logs.prefix(maxLogEntries))
        }

        saveLogs()
    }

    /// Returns recent log entries up to the specified limit
    func getRecentLogs(limit: Int) async -> [AuditLogEntry] {
        return Array(logs.prefix(limit))
    }

    /// Returns all log entries
    func getAllLogs() async -> [AuditLogEntry] {
        return logs
    }

    /// Clears all audit logs
    func clearLogs() async {
        logs = []
        saveLogs()
    }

    /// Returns the total count of log entries
    func logCount() async -> Int {
        return logs.count
    }

    // MARK: - Persistence

    private func loadLogs() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }

        do {
            logs = try JSONDecoder().decode([AuditLogEntry].self, from: data)
        } catch {
            logs = []
        }
    }

    private func saveLogs() {
        do {
            let data = try JSONEncoder().encode(logs)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            // Silent failure for logging - don't disrupt main operations
        }
    }
}
