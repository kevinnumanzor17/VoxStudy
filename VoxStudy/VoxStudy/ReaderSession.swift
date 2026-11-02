import Combine
import Foundation

@MainActor
final class ReaderSession: ObservableObject {
    @Published var title = ""
    @Published var text = """
    Hola. Soy VoxStudy, tu compañero de lectura.

    Escribí o pegá tus apuntes y escuchalos a tu ritmo.
    """

    @Published private(set) var importedFileName: String?
    @Published private(set) var importedPageCount = 0
    @Published private(set) var skippedPages = 0
    @Published private(set) var isImporting = false
    @Published var showImportError = false
    @Published private(set) var importErrorMessage = ""
    @Published private(set) var readingDescription: String?

    func setReadingContext(source: ReadingLanguage, target: ReadingLanguage) {
        readingDescription = source == target
            ? "Lectura en \(target.title)"
            : "Traducción: \(source.title) → \(target.title)"
    }

    func clearReadingContext() {
        readingDescription = nil
    }

    var displayTitle: String {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanTitle.isEmpty ? "Tu lectura" : cleanTitle
    }

    func clear() {
        title = ""
        text = ""
        clearPDFMetadata()
    }

    func paste(_ pastedText: String) {
        if importedFileName != nil { title = "" }
        text = pastedText
        clearPDFMetadata()
    }

    func loadExample(_ example: StudyExample) {
        title = example.title
        text = example.text
        clearPDFMetadata()
    }

    func importPDF(from url: URL) async -> Bool {
        guard !isImporting else { return false }
        isImporting = true
        defer { isImporting = false }

        do {
            let imported = try await Task.detached(priority: .userInitiated) {
                try PDFImportService.read(from: url)
            }.value

            // No cambiamos el texto actual hasta que la extracción tenga éxito.
            text = imported.text
            title = url.deletingPathExtension().lastPathComponent
            importedFileName = imported.fileName
            importedPageCount = imported.pageCount
            skippedPages = imported.skippedPages
            return true
        } catch {
            presentError(error.localizedDescription)
            return false
        }
    }

    func presentError(_ message: String) {
        importErrorMessage = message
        showImportError = true
    }

    private func clearPDFMetadata() {
        clearReadingContext()
        importedFileName = nil
        importedPageCount = 0
        skippedPages = 0
    }
}


