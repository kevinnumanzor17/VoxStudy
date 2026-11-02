import SwiftUI
import UIKit

@MainActor
struct ReaderView: View {
    @ObservedObject var speechManager: SpeechManager
    @ObservedObject var session: ReaderSession
    @Binding var sourceLanguage: ReadingLanguage
    let onStartReading: () -> Void
    let onSettings: () -> Void
    let onImportPDF: () -> Void
    let onExamplePDF: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isEditing: Bool
    @State private var pasteMessage: String?

    private var palette: AppPalette { AppPalette(colorScheme: colorScheme) }
    private var isTextEmpty: Bool {
        session.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var cannotImport: Bool { speechManager.isActive || session.isImporting }
    private var needsTranslation: Bool { sourceLanguage != speechManager.outputLanguage }

    private var targetLanguageBinding: Binding<ReadingLanguage> {
        Binding(
            get: { speechManager.outputLanguage },
            set: { speechManager.chooseLanguage($0.rawValue) }
        )
    }

    private var playTitle: String {
        switch speechManager.state {
        case .speaking: return "Pausar"
        case .paused: return "Continuar"
        case .ready:
            if speechManager.hasDocument { return "Leer desde aquí" }
            if needsTranslation { return "Traducir y escuchar" }
            return session.importedFileName == nil ? "Escuchar" : "Escuchar PDF"
        case .finished:
            return speechManager.canGoForward ? "Seguir lectura" : "Leer de nuevo"
        }
    }

    private var playIcon: String {
        speechManager.state == .speaking ? "pause.fill" : "play.fill"
    }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            if speechManager.hasDocument {
                guidedReadingLayout
            } else {
                editorLayout
            }
        }
        .safeAreaInset(edge: .bottom) { playbackPanel }
        .onDisappear {
            // Cambiar de pestaña oculta el teclado, pero conserva la narración.
            isEditing = false
        }
    }

    private var editorLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                VStack(alignment: .leading, spacing: 8) {
                        Text("Prepará tu lectura")
                            .font(.title.bold())
                        .foregroundStyle(palette.mainText)
                        Text("Escribí, pegá un texto o importá un PDF.")
                        .foregroundStyle(palette.secondaryText)
                }

                importSection
                documentCard
                languageSection
                editorSection

                if let message = speechManager.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(palette.mainText)
                        .padding()
                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
                }

                Text("Los párrafos sencillos ofrecen mejores resultados. El orden de las tablas o columnas puede variar al extraer el texto.")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryText)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var guidedReadingLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Text(session.displayTitle)
                .font(.title3.bold())
                .foregroundStyle(palette.mainText)
                .lineLimit(1)

            if let fileName = session.importedFileName {
                Label(fileName, systemImage: "doc.text")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
                    .lineLimit(1)
            }

            Text("Párrafo \(speechManager.currentParagraphIndex + 1) de \(speechManager.paragraphs.count)")
                .font(.headline)
                .foregroundStyle(palette.mainText)

            if let description = session.readingDescription {
                Text(description)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.accent)
            }

            ReadingTextView(
                text: speechManager.currentParagraph,
                highlightedRange: speechManager.highlightedRange
            )
            .frame(minHeight: 180, maxHeight: .infinity)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            paragraphControls

            if let message = speechManager.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(palette.mainText)
            }

            Button(needsTranslation ? "Editar original / cambiar idiomas" : "Editar texto / cambiar idiomas") {
                speechManager.resetDocument()
                session.clearReadingContext()
                isEditing = true
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(palette.accent)
            .frame(minHeight: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var paragraphControls: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    speechManager.previousParagraph()
                } label: {
                    Label("Anterior", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .disabled(!speechManager.canGoBackward)

                Button {
                    speechManager.nextParagraph()
                } label: {
                    Label("Siguiente", systemImage: "chevron.right")
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .disabled(!speechManager.canGoForward)
            }
            .buttonStyle(.bordered)
            .tint(palette.accent)

            Button {
                speechManager.repeatParagraph()
            } label: {
                Label("Repetir párrafo", systemImage: "repeat")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Text("Estos botones reproducen un solo párrafo.")
                .font(.caption)
                .foregroundStyle(palette.secondaryText)
        }
    }

    private var header: some View {
        AppHeader {
            isEditing = false
            onSettings()
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Idiomas", systemImage: "globe")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Texto en")
                    .font(.subheadline.weight(.medium))
                Picker("Idioma del texto original", selection: $sourceLanguage) {
                    ForEach(ReadingLanguage.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Leer en")
                    .font(.subheadline.weight(.medium))
                Picker("Idioma de lectura", selection: targetLanguageBinding) {
                    ForEach(ReadingLanguage.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }

            Text(needsTranslation
                 ? "Se traducirá de \(sourceLanguage.title) a \(speechManager.outputLanguage.title) antes de leer. El original se conserva."
                 : "Se leerá el texto original en \(sourceLanguage.title), sin traducir.")
                .font(.footnote)
                .foregroundStyle(palette.secondaryText)

            Text("Indicá el idioma en que está escrito el texto. Usá un solo idioma por documento.")
                .font(.caption)
                .foregroundStyle(palette.secondaryText)
        }
        .foregroundStyle(palette.mainText)
        .padding(16)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 18))
        .disabled(cannotImport)
    }

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isEditing = false
                onImportPDF()
            } label: {
                Label(
                    session.importedFileName == nil ? "Importar PDF" : "Cambiar PDF",
                    systemImage: "doc.badge.plus"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(palette.accent)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(palette.accent.opacity(0.35), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(cannotImport)
            .opacity(cannotImport ? 0.5 : 1)

            Button("Probar PDF de ejemplo") {
                isEditing = false
                onExamplePDF()
            }
            .font(.subheadline)
            .foregroundStyle(palette.accent)
            .frame(minHeight: 44)
            .disabled(cannotImport)

            if session.isImporting {
                ProgressView("Extrayendo texto...")
                    .tint(palette.accent)
                    .foregroundStyle(palette.secondaryText)
            } else {
                Text("Elegí un PDF con texto seleccionable. Su contenido se cargará en el editor.")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryText)
            }
        }
    }

    @ViewBuilder
    private var documentCard: some View {
        if let fileName = session.importedFileName {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.title2)
                        .foregroundStyle(palette.accent)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(fileName)
                            .font(.headline)
                            .lineLimit(2)
                            .foregroundStyle(palette.mainText)
                        Text("\(session.importedPageCount) \(session.importedPageCount == 1 ? "página" : "páginas")")
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)
                    }
                }

                Label("Texto cargado", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.accent)

                if session.skippedPages > 0 {
                    Text("Páginas sin texto extraíble: \(session.skippedPages). Se leerá el contenido encontrado.")
                        .font(.footnote)
                        .foregroundStyle(palette.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Título (opcional)", text: $session.title)
                .foregroundStyle(palette.mainText)
                .padding(14)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
                .disabled(speechManager.isActive || session.isImporting)

            HStack {
                Text(session.importedFileName == nil ? "Tu texto" : "Texto del PDF (editable)")
                    .font(.headline)
                    .foregroundStyle(palette.mainText)

                Spacer()

                Button("Pegar") {
                    if let pasted = UIPasteboard.general.string,
                       !pasted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        speechManager.resetDocument()
                        session.paste(pasted)
                        pasteMessage = nil
                    } else {
                        pasteMessage = "No encontramos texto en el portapapeles."
                    }
                }
                .foregroundStyle(palette.accent)
                .disabled(speechManager.isActive || session.isImporting)

                Button("Limpiar") {
                    speechManager.resetDocument()
                    session.clear()
                    pasteMessage = nil
                }
                .foregroundStyle(palette.accent)
                .disabled(speechManager.isActive || session.isImporting || isTextEmpty)
            }

            TextEditor(text: $session.text)
                .font(.body)
                .foregroundStyle(palette.mainText)
                .scrollContentBackground(.hidden)
                .frame(height: 250)
                .padding(12)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 18))
                .disabled(speechManager.isActive || session.isImporting)
                .focused($isEditing)
                .accessibilityLabel("Texto para escuchar")

            if let pasteMessage {
                Text(pasteMessage)
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryText)
            }

            Text("Dejá una línea en blanco para separar los párrafos.")
                .font(.footnote)
                .foregroundStyle(palette.secondaryText)
        }
    }

    private var playbackPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Label(speechManager.state.rawValue, systemImage: "speaker.wave.2.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.accent)
                Text(speechManager.voiceSummary)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
            }

            HStack(spacing: 12) {
                Button {
                    isEditing = false
                    switch speechManager.state {
                    case .speaking: speechManager.pause()
                    case .paused: speechManager.resume()
                    case .ready, .finished:
                        if speechManager.hasDocument {
                            speechManager.continueReading()
                        } else {
                            onStartReading()
                        }
                    }
                } label: {
                    Label(playTitle, systemImage: playIcon)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .foregroundStyle(palette.buttonText)
                        .background(palette.accent, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(isTextEmpty || session.isImporting)
                .opacity(isTextEmpty || session.isImporting ? 0.5 : 1)

                Button {
                    speechManager.stop()
                } label: {
                    Label("Detener", systemImage: "stop.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .foregroundStyle(palette.accent)
                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(!speechManager.isActive)
                .opacity(speechManager.isActive ? 1 : 0.5)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(palette.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(palette.accent.opacity(0.15))
                .frame(height: 1)
        }
    }

}


