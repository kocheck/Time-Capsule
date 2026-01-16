import Foundation

enum AIProvider: String, Codable, CaseIterable, Identifiable {
    case appleIntelligence
    case ollama
    case disabled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleIntelligence: return "Apple Intelligence"
        case .ollama: return "Ollama (Local)"
        case .disabled: return "Disabled (Rule-based)"
        }
    }

    var description: String {
        switch self {
        case .appleIntelligence: return "Uses on-device AI for private, intelligent suggestions"
        case .ollama: return "Uses local Ollama instance for AI features"
        case .disabled: return "Uses simple rules for task suggestions"
        }
    }
}
