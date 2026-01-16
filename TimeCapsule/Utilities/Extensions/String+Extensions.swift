import Foundation

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isBlank: Bool {
        trimmed.isEmpty
    }

    var isNotBlank: Bool {
        !isBlank
    }

    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + dropFirst()
    }

    var isValidTag: Bool {
        let trimmed = self.trimmed
        return trimmed.count >= 1 && trimmed.count <= 30 && !trimmed.contains(where: \.isNewline)
    }

    func truncated(to length: Int, trailing: String = "...") -> String {
        if count > length {
            return prefix(length) + trailing
        }
        return self
    }
}
