import Foundation

enum TaskPriority: String, Codable, CaseIterable, Identifiable, Comparable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var sortOrder: Int {
        switch self {
        case .low: return 0
        case .normal: return 1
        case .high: return 2
        }
    }

    var iconName: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .normal: return "minus.circle"
        case .high: return "exclamationmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .low: return "PriorityLow"
        case .normal: return "PriorityNormal"
        case .high: return "PriorityHigh"
        }
    }

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
