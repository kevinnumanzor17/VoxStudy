import SwiftUI
import Translation

struct ReadingTranslationRequest: Identifiable {
    let id = UUID()
    let originalText: String
    let source: ReadingLanguage
    let target: ReadingLanguage
}

private enum ReadingTranslationError: LocalizedError {
    case unsupported
    case incompleteResult

    nonisolated var errorDescription: String? {
        switch self {
        case .unsupported:
            return "La traducción entre español e inglés no está disponible en este dispositivo."
        case .incompleteResult:
            return "No se recibió una traducción completa. Intentá nuevamente."
        }
    }
}

@MainActor
struct TranslationReadingSheet: View {
    let request: ReadingTranslationRequest
    let onComplete: (String) -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var hasStarted = false
    @State private var wasCancelled = false
    @State private var errorMessage: String?
    @State private var status = "Preparando la traducción…"

    private var palette: AppPalette { AppPalette(colorScheme: colorScheme) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 22) {
                Label("\(request.source.title) → \(request.target.title)",
                      systemImage: "globe")
                    .font(.title2.bold())
                    .foregroundStyle(palette.accent)

                if let errorMessage {
                    Label("No se pudo traducir", systemImage: "exclamationmark.circle")
                        .font(.headline)
                    Text(errorMessage)
                    Text("Tu texto original se conserva. Podés volver e intentar de nuevo.")
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryText)
                } else {
                    ProgressView(status)
                        .tint(palette.accent)
                    Text("La primera vez, el iPhone puede pedirte descargar los idiomas. Al terminar, comenzará la lectura del texto traducido.")
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryText)
                }

                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(palette.background)
            .foregroundStyle(palette.mainText)
            .navigationTitle("Traducir y escuchar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(errorMessage == nil ? "Cancelar" : "Volver") {
                        wasCancelled = true
                        onCancel()
                    }
                }
            }
        }
        .tint(palette.accent)
        .interactiveDismissDisabled()
        .onDisappear { wasCancelled = true }
        .translationTask(source: request.source.localeLanguage,
                         target: request.target.localeLanguage) { translationSession in
            await translate(using: translationSession)
        }
    }

    private func translate(using translationSession: TranslationSession) async {
        guard !hasStarted, !wasCancelled else { return }
        hasStarted = true

        do {
            let availability = LanguageAvailability()
            let state = await availability.status(
                from: request.source.localeLanguage, to: request.target.localeLanguage
            )
            try Task.checkCancellation()
            guard !wasCancelled else { return }
            guard state != .unsupported else { throw ReadingTranslationError.unsupported }

            status = state == .installed
                ? "Traduciendo el contenido…" : "Preparando los idiomas y traduciendo…"

            // La API devuelve las respuestas en el mismo orden de las solicitudes.
            // Cada solicitud es un párrafo, para conservar la navegación y el repaso.
            let paragraphs = ParagraphParser.parse(request.originalText)
            let requests = paragraphs.map { TranslationSession.Request(sourceText: $0) }
            let responses = try await translationSession.translations(from: requests)

            try Task.checkCancellation()
            guard !wasCancelled else { return }
            let translated = responses.map { $0.targetText.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard !translated.isEmpty, translated.count == paragraphs.count,
                  translated.allSatisfy({ !$0.isEmpty }) else {
                throw ReadingTranslationError.incompleteResult
            }

            // El editor conserva el original. Únicamente el lector recibe la traducción.
            onComplete(translated.joined(separator: "\n\n"))
        } catch is CancellationError {
            if !wasCancelled { onCancel() }
        } catch {
            guard !wasCancelled, !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}
