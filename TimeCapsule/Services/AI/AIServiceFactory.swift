import Foundation

enum AIServiceFactory {
    static func create(for provider: AIProvider, settings: AppSettings) -> AIServiceProtocol {
        switch provider {
        case .appleIntelligence:
            return AppleIntelligenceService()
        case .ollama:
            return OllamaService(
                endpoint: settings.ollamaEndpoint,
                model: settings.ollamaModel
            )
        case .disabled:
            return DisabledAIService()
        }
    }
}

// Fallback when AI is disabled
final class DisabledAIService: AIServiceProtocol {
    func rankTasks(context: TaskContext) async throws -> TaskRanking {
        // Just return the first task
        guard let first = context.candidateTasks.first else {
            throw AIServiceError.invalidResponse
        }
        return TaskRanking(topTaskId: first.id, reasoning: "Rule-based selection")
    }

    func generateContextHints(for title: String, description: String?, tags: [String]) async throws -> [String] {
        // Return tags as hints
        return tags
    }

    func isAvailable() async -> Bool {
        return true
    }
}
