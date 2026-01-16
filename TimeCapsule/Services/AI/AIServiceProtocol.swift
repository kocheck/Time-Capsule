import Foundation

protocol AIServiceProtocol: Sendable {
    func rankTasks(context: TaskContext) async throws -> TaskRanking
    func generateContextHints(for title: String, description: String?, tags: [String]) async throws -> [String]
    func generateWeeklyDigest(context: WeeklyContext) async throws -> WeeklyDigestResponse
    func isAvailable() async -> Bool
}

enum AIServiceError: LocalizedError {
    case notAvailable
    case invalidResponse
    case networkError(Error)
    case parsingError(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "AI service is not available"
        case .invalidResponse:
            return "Received invalid response from AI service"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError(let message):
            return "Failed to parse response: \(message)"
        case .timeout:
            return "AI service request timed out"
        }
    }
}
