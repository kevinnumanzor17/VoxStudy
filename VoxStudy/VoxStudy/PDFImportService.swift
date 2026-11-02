import Foundation
import PDFKit

enum PDFImportService {
    typealias Content = (
        fileName: String,
        pageCount: Int,
        text: String,
        skippedPages: Int
    )

    // El PDF se abre y se procesa en la tarea de fondo.
    // Solo devolvemos valores simples; PDFDocument no pasa a la interfaz.
    nonisolated static func read(from url: URL) throws -> Content {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        var coordinationError: NSError?
        var extraction: Result<Content, Error>?
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(
            readingItemAt: url, options: [], error: &coordinationError
        ) { readableURL in
            extraction = Result {
                try extract(from: readableURL, fileName: url.lastPathComponent)
            }
        }

        if let coordinationError {
            throw coordinationError
        }
        guard let extraction else {
            throw NSError(
                domain: "VoxStudy.PDFImport", code: 4,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo acceder al PDF seleccionado."]
            )
        }
        return try extraction.get()
    }

    private nonisolated static func extract(from url: URL, fileName: String) throws -> Content {
        // Los archivos incluidos en la app pueden ser legibles sin acceso adicional.
        guard let document = PDFDocument(url: url) else {
            throw NSError(
                domain: "VoxStudy.PDFImport", code: 1,
                userInfo: [NSLocalizedDescriptionKey:
                    "No se pudo abrir ese PDF. Comprobá que esté descargado y volvé a intentarlo."]
            )
        }

        guard !document.isLocked else {
            throw NSError(
                domain: "VoxStudy.PDFImport", code: 2,
                userInfo: [NSLocalizedDescriptionKey:
                    "El PDF está protegido con contraseña. Elegí un PDF que puedas abrir sin contraseña."]
            )
        }

        var extractedPages: [String] = []
        var skippedPages = 0

        for index in 0..<document.pageCount {
            let pageText = (document.page(at: index)?.string ?? "")
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if pageText.isEmpty {
                skippedPages += 1
            } else {
                extractedPages.append(pageText)
            }
        }

        let text = extractedPages.joined(separator: "\n\n")
        guard !text.isEmpty else {
            throw NSError(
                domain: "VoxStudy.PDFImport", code: 3,
                userInfo: [NSLocalizedDescriptionKey:
                    "No encontramos texto para leer. Elegí un PDF con texto seleccionable. Los escaneos que solo contienen imágenes necesitan reconocimiento de texto."]
            )
        }

        return (
            fileName: fileName,
            pageCount: document.pageCount,
            text: text,
            skippedPages: skippedPages
        )
    }
}

