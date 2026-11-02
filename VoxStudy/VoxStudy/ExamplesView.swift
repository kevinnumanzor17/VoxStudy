import SwiftUI

@MainActor
struct ExamplesView: View {
    @ObservedObject var speechManager: SpeechManager
    @ObservedObject var session: ReaderSession
    let onExample: (StudyExample) -> Void
    let onExamplePDF: () -> Void
    let onOpenReader: () -> Void
    let onSettings: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var palette: AppPalette { AppPalette(colorScheme: colorScheme) }
    private var canLoad: Bool { !speechManager.isActive && !session.isImporting }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AppHeader(onSettings: onSettings)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Textos de ejemplo")
                            .font(.largeTitle.bold())
                            .foregroundStyle(palette.mainText)
                        Text("Elegí uno para probar la lectura y el repaso por párrafos.")
                            .foregroundStyle(palette.secondaryText)
                    }

                    if speechManager.isActive {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tenés una lectura en curso. Detenela desde el Lector para abrir otro ejemplo.")
                                .font(.footnote)
                                .foregroundStyle(palette.secondaryText)
                            Button("Ir al Lector", action: onOpenReader)
                                .foregroundStyle(palette.accent)
                                .frame(minHeight: 44)
                        }
                    }

                    ForEach(StudyExample.all) { example in
                        ExampleCard(example: example, isEnabled: canLoad) {
                            onExample(example)
                        }
                    }

                    Button(action: onExamplePDF) {
                        HStack(spacing: 14) {
                            Image(systemName: "doc.text.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("PDF de ejemplo")
                                    .font(.headline)
                                Text("Probá la extracción con un documento de dos páginas.")
                                    .font(.caption)
                                    .foregroundStyle(palette.secondaryText)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(palette.accent)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canLoad)
                    .opacity(canLoad ? 1 : 0.5)

                    if session.isImporting {
                        ProgressView("Extrayendo texto...")
                            .tint(palette.accent)
                    }

                    Text("Contenido de demostración.")
                        .font(.footnote)
                        .foregroundStyle(palette.secondaryText)
                }
                .padding(24)
            }
        }
    }
}

