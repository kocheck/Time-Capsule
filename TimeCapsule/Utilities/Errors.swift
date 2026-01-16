import Foundation

enum AppError: LocalizedError {
    case dataModelError(String)
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case invalidInput(String)
    case serviceUnavailable(String)
    case configurationError(String)

    var errorDescription: String? {
        switch self {
        case .dataModelError(let message):
            return "Data model error: \(message)"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .serviceUnavailable(let message):
            return "Service unavailable: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
}
