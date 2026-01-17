import Foundation

/// URL Scheme: timecapsule://
/// Actions:
///   timecapsule://add?title=Task&tags=work,urgent&priority=high
///   timecapsule://show?id=uuid
///   timecapsule://complete?id=uuid
///   timecapsule://search?query=text

/// Actions that can be triggered via URL scheme
enum URLSchemeAction {
    case addTask(title: String, tags: [String], priority: TaskPriority?, description: String?)
    case showTask(id: UUID)
    case completeTask(id: UUID)
    case search(query: String)
    case showApp

    static func parse(_ url: URL) -> URLSchemeAction? {
        guard url.scheme == "timecapsule" else { return nil }

        let host = url.host
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        func param(_ name: String) -> String? {
            queryItems.first { $0.name == name }?.value
        }

        switch host {
        case "add":
            guard let title = param("title"), !title.isEmpty else { return nil }

            let tags = param("tags")?.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty } ?? []

            let priority: TaskPriority? = {
                guard let p = param("priority")?.lowercased() else { return nil }
                return TaskPriority(rawValue: p)
            }()

            let description = param("description")

            return .addTask(title: title, tags: tags, priority: priority, description: description)

        case "show":
            guard let idString = param("id"), let id = UUID(uuidString: idString) else { return nil }
            return .showTask(id: id)

        case "complete":
            guard let idString = param("id"), let id = UUID(uuidString: idString) else { return nil }
            return .completeTask(id: id)

        case "search":
            guard let query = param("query") else { return nil }
            return .search(query: query)

        default:
            return .showApp
        }
    }

    /// Creates a URL for adding a task
    static func addTaskURL(title: String, tags: [String] = [], priority: TaskPriority? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "timecapsule"
        components.host = "add"

        var queryItems = [URLQueryItem(name: "title", value: title)]

        if !tags.isEmpty {
            queryItems.append(URLQueryItem(name: "tags", value: tags.joined(separator: ",")))
        }

        if let priority {
            queryItems.append(URLQueryItem(name: "priority", value: priority.rawValue))
        }

        components.queryItems = queryItems

        return components.url
    }

    /// Creates a URL for showing a task
    static func showTaskURL(id: UUID) -> URL? {
        var components = URLComponents()
        components.scheme = "timecapsule"
        components.host = "show"
        components.queryItems = [URLQueryItem(name: "id", value: id.uuidString)]
        return components.url
    }
}

/// Handles URL scheme actions
@Observable
class URLSchemeHandler {
    var pendingAction: URLSchemeAction?
    var showQuickAddSheet = false
    var quickAddTitle = ""
    var quickAddTags: [String] = []
    var quickAddPriority: TaskPriority = .normal

    /// Handles an incoming URL
    func handle(_ url: URL) -> Bool {
        guard let action = URLSchemeAction.parse(url) else {
            return false
        }

        pendingAction = action

        switch action {
        case .addTask(let title, let tags, let priority, _):
            quickAddTitle = title
            quickAddTags = tags
            quickAddPriority = priority ?? .normal
            showQuickAddSheet = true

        case .showTask, .completeTask, .search, .showApp:
            // These will be handled by the app delegate or view
            break
        }

        return true
    }

    /// Clears the pending action
    func clearPendingAction() {
        pendingAction = nil
        quickAddTitle = ""
        quickAddTags = []
        quickAddPriority = .normal
    }
}
