import Foundation

final class OllamaService: AIServiceProtocol {
    private let endpoint: URL
    private let model: String
    private let session: URLSession

    init(endpoint: String = "http://localhost:11434", model: String = "llama3.1") {
        // Safely unwrap URL, fallback to localhost if invalid
        guard let url = URL(string: endpoint) else {
            self.endpoint = URL(string: "http://localhost:11434")!
            self.model = model
            
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            self.session = URLSession(configuration: config)
            return
        }
        
        self.endpoint = url
        self.model = model

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    func rankTasks(context: TaskContext) async throws -> TaskRanking {
        guard await isAvailable() else {
            throw AIServiceError.notAvailable
        }

        let prompt = buildRankingPrompt(context: context)
        let response = try await sendRequest(prompt: prompt)
        return try parseRankingResponse(response)
    }

    func generateContextHints(for title: String, description: String?, tags: [String]) async throws -> [String] {
        guard await isAvailable() else {
            throw AIServiceError.notAvailable
        }

        let prompt = """
        Analyze this task and provide 3-5 context keywords for when it should be worked on.

        Title: \(title)
        Description: \(description ?? "None")
        Tags: \(tags.isEmpty ? "None" : tags.joined(separator: ", "))

        Respond with ONLY comma-separated keywords.
        """

        let response = try await sendRequest(prompt: prompt)
        return parseContextHints(response)
    }

    func isAvailable() async -> Bool {
        let url = endpoint.appendingPathComponent("api/tags")

        do {
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Private Methods

    private func sendRequest(prompt: String) async throws -> String {
        let url = endpoint.appendingPathComponent("api/generate")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = OllamaRequest(model: model, prompt: prompt, stream: false)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.networkError(URLError(.badServerResponse))
        }

        let result = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return result.response
    }

    private func buildRankingPrompt(context: TaskContext) -> String {
        // Same prompt structure as AppleIntelligenceService
        let tasksDescription = context.candidateTasks.map { task in
            "- [\(task.id)] \(task.title) (priority: \(task.priority), age: \(task.daysSinceCreation)d, skipped: \(task.skipCount)x)"
        }.joined(separator: "\n")

        return """
        Select the best task to work on now. Time: \(context.currentHour):00 \(context.dayOfWeekName)

        Tasks:
        \(tasksDescription)

        Respond with JSON only: {"topTaskId": "<id>", "reasoning": "<why>"}
        """
    }

    private func parseRankingResponse(_ content: String) throws -> TaskRanking {
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonStart = cleaned.firstIndex(of: "{"),
              let jsonEnd = cleaned.lastIndex(of: "}") else {
            throw AIServiceError.parsingError("No JSON found")
        }

        let jsonString = String(cleaned[jsonStart...jsonEnd])
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIServiceError.parsingError("Invalid JSON data")
        }

        return try JSONDecoder().decode(TaskRanking.self, from: jsonData)
    }

    private func parseContextHints(_ content: String) -> [String] {
        content.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }
}
