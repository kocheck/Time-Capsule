import Foundation

enum MenuTab: String, CaseIterable, Identifiable {
    case sendOff
    case suggestion
    case progress
    case settings

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sendOff: return "Send Off"
        case .suggestion: return "Suggestion"
        case .progress: return "Progress"
        case .settings: return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .sendOff: return "plus.circle.fill"
        case .suggestion: return "lightbulb.fill"
        case .progress: return "chart.bar.fill"
        case .settings: return "gear"
        }
    }
}
