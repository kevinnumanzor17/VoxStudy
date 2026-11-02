import Foundation

enum ReadingLanguage: String, CaseIterable, Identifiable, Hashable, Sendable {
    case spanish = "es"
    case english = "en"

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "Inglés"
        }
    }

    nonisolated var localeLanguage: Locale.Language {
        Locale.Language(identifier: rawValue)
    }

    nonisolated init?(voiceLanguageCode: String) {
        let base = voiceLanguageCode
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-").first.map(String.init) ?? ""
        self.init(rawValue: base)
    }
}
