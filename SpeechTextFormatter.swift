import Foundation

enum SpeechTextFormatter {

    static func format(_ rawText: String) -> String {
        var text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "" }

        text = text.replacingOccurrences(of: "\n", with: " ")
        while text.contains("  ") {
            text = text.replacingOccurrences(of: "  ", with: " ")
        }

        let replacements: [String: String] = [
            "fh": "Fußbodenheizung",
            "heiz.": "Heizung",
            "san.": "Sanitär",
            "elekt.": "Elektro",
            "uv": "Unterverteilung",
            "og": "Obergeschoss",
            "eg": "Erdgeschoss",
            "kg": "Kellergeschoss",
            "whg": "Wohnung"
        ]

        for (short, long) in replacements {
            text = text.replacingOccurrences(
                of: "\\b\(NSRegularExpression.escapedPattern(for: short))\\b",
                with: long,
                options: .regularExpression
            )
        }

        if let first = text.first {
            text = first.uppercased() + text.dropFirst()
        }

        if let last = text.last, ![".", "!", "?"].contains(last) {
            text += "."
        }

        return text
    }

    static func append(existing: String, newText: String) -> String {
        let oldText = existing.trimmingCharacters(in: .whitespacesAndNewlines)
        let newFormatted = format(newText)

        guard !newFormatted.isEmpty else { return oldText }
        guard !oldText.isEmpty else { return newFormatted }

        if oldText.hasSuffix(newFormatted) {
            return oldText
        }

        return oldText + "\n\n" + newFormatted
    }

    static func bullets(_ text: String) -> String {
        let cleaned = format(text)
        guard !cleaned.isEmpty else { return "" }

        let parts = cleaned
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if parts.isEmpty { return cleaned }

        return parts.map { part in
            let final = part.hasSuffix(".") ? part : part + "."
            return "• " + final
        }
        .joined(separator: "\n")
    }
}
