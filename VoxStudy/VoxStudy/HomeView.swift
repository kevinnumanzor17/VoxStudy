import SwiftUI

@MainActor
struct HomeView: View {
    @ObservedObject var speechManager: SpeechManager
    @ObservedObject var session: ReaderSession

    let onWrite: () -> Void
    let onImportPDF: () -> Void
    let onOpenReader: () -> Void
    let onShowExamples: () -> Void
    let onExample: (StudyExample) -> Void
    let onSettings: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var palette: AppPalette { AppPalette(colorScheme: colorScheme) }
    private var canLoad: Bool { !speechManager.isActive && !session.isImporting }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    AppHeader(onSettings: onSettings)
                    hero

                    VStack(spacing: 12) {
                        Button(action: onWrite) {
                            Label("Escribir texto", systemImage: "square.and.pencil")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .foregroundStyle(palette.buttonText)
                                .background(palette.accent, in: RoundedRectangle(cornerRadius: 17))
                        }
                        .disabled(session.isImporting)
                        .opacity(session.isImporting ? 0.5 : 1)

                        Button(action: onImportPDF) {
                            Label("Importar PDF", systemImage: "doc.badge.plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .foregroundStyle(palette.accent)
                                .background(palette.surface, in: RoundedRectangle(cornerRadius: 17))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 17)
                                        .stroke(palette.accent.opacity(0.35), lineWidth: 1)
                                }
                        }
                        .disabled(!canLoad)
                        .opacity(canLoad ? 1 : 0.5)
                    }
                    .buttonStyle(.plain)

                    if session.isImporting {
                        ProgressView("Extrayendo texto del PDF...")
                            .tint(palette.accent)
                            .foregroundStyle(palette.secondaryText)
                    }

                    if speechManager.hasDocument {
                        currentReading
                    }

                    HStack {
                        Text("Probá un ejemplo")
                            .font(.title3.bold())
                            .foregroundStyle(palette.mainText)
                        Spacer()
                        Button("Ver todos", action: onShowExamples)
                            .font(.subheadline)
                            .foregroundStyle(palette.accent)
                    }

                    ForEach(Array(StudyExample.all.prefix(2))) { example in
                        ExampleCard(example: example, isEnabled: canLoad) {
                            onExample(example)
                        }
                    }

                    if speechManager.isActive {
                        Text("Para cargar otro documento, detené la lectura desde el Lector.")
                            .font(.footnote)
                            .foregroundStyle(palette.secondaryText)
                    }
                }
                .padding(24)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text("Tus apuntes,\nahora en voz.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(palette.mainText)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Image(systemName: "book.fill")
                    .font(.system(size: 43, weight: .semibold))
                    .foregroundStyle(palette.accent)
                    .padding(.top, 6)
                    .accessibilityHidden(true)
            }
            Text("Leé, escuchá y repasá a tu ritmo.")
                .font(.subheadline)
                .foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [palette.lilac, palette.peach],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private var currentReading: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tu lectura actual", systemImage: "speaker.wave.2")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.accent)
            Text(session.displayTitle)
                .font(.headline)
                .foregroundStyle(palette.mainText)
            Text("\(speechManager.state.rawValue) · Párrafo \(speechManager.currentParagraphIndex + 1) de \(speechManager.paragraphs.count)")
                .font(.caption)
                .foregroundStyle(palette.secondaryText)
            Button("Abrir lector", action: onOpenReader)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.accent)
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

