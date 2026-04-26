import Foundation

enum SpeechTextFormatter {
    static func format(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    static func append(existing: String, newText: String) -> String {
        let lhs = format(existing)
        let rhs = format(newText)

        if lhs.isEmpty { return rhs }
        if rhs.isEmpty { return lhs }
        return lhs + "\n" + rhs
    }

    static func bullets(_ text: String) -> String {
        let lines = format(text)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return "" }
        return lines.map { "• \($0)" }.joined(separator: "\n")
    }
}
