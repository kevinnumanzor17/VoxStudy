import Foundation

enum ParagraphParser {
    // Una línea en blanco separa párrafos. Los saltos simples se unen con espacios.
    nonisolated static func parse(_ text: String) -> [String] {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{2029}", with: "\n\n")
            .replacingOccurrences(of: "\u{2028}", with: "\n")

        var paragraphs: [String] = []
        var lines: [String] = []

        for line in normalized.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if !lines.isEmpty {
                    paragraphs.append(lines.joined(separator: " "))
                    lines = []
                }
            } else {
                lines.append(trimmed)
            }
        }

        if !lines.isEmpty {
            paragraphs.append(lines.joined(separator: " "))
        }
        return paragraphs
    }
}

