import Foundation

struct TaskRanking: Codable, Sendable {
    let topTaskId: String
    let reasoning: String?
    let confidence: Double?

    init(topTaskId: String, reasoning: String? = nil, confidence: Double? = nil) {
        self.topTaskId = topTaskId
        self.reasoning = reasoning
        self.confidence = confidence
    }
}
