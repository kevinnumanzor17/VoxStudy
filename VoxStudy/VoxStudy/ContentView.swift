//
//  ContentView.swift
//  VoxStudy
//
//  Created by Usuario invitado on 31/10/26.
//

import SwiftUI
import UniformTypeIdentifiers

private enum AppTab: Hashable {
    case home
    case reader
    case examples
}

@MainActor
struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var session = ReaderSession()
    @State private var selectedTab: AppTab = .home
    @State private var showSettings = false
    @State private var showPDFImporter = false
    @State private var translationRequest: ReadingTranslationRequest?

    @AppStorage("voxstudy.appearance") private var appearanceRawValue = AppAppearance.system.rawValue
    @AppStorage("voxstudy.sourceLanguage") private var sourceLanguageRawValue = ReadingLanguage.spanish.rawValue
    @Environment(\.colorScheme) private var colorScheme

    private var appearance: AppAppearance {
        AppAppearance(rawValue: appearanceRawValue) ?? .system
    }

    private var sourceLanguage: ReadingLanguage {
        ReadingLanguage(rawValue: sourceLanguageRawValue) ?? .spanish
    }

    private var sourceLanguageBinding: Binding<ReadingLanguage> {
        Binding(get: { sourceLanguage }, set: { sourceLanguageRawValue = $0.rawValue })
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Inicio", systemImage: "house", value: AppTab.home) {
                HomeView(
                    speechManager: speechManager, session: session,
                    onWrite: openEditor,
                    onImportPDF: { showPDFImporter = true },
                    onOpenReader: { selectedTab = .reader },
                    onShowExamples: { selectedTab = .examples },
                    onExample: openExample,
                    onSettings: { showSettings = true }
                )
            }

            Tab("Lector", systemImage: "book", value: AppTab.reader) {
                ReaderView(
                    speechManager: speechManager, session: session,
                    sourceLanguage: sourceLanguageBinding,
                    onStartReading: startReading,
                    onSettings: { showSettings = true },
                    onImportPDF: { showPDFImporter = true },
                    onExamplePDF: openExamplePDF
                )
            }

            Tab("Ejemplos", systemImage: "lightbulb", value: AppTab.examples) {
                ExamplesView(
                    speechManager: speechManager, session: session,
                    onExample: openExample,
                    onExamplePDF: openExamplePDF,
                    onOpenReader: { selectedTab = .reader },
                    onSettings: { showSettings = true }
                )
            }
        }
        .tint(AppPalette(colorScheme: colorScheme).accent)
        .toolbarBackground(AppPalette(colorScheme: colorScheme).background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .preferredColorScheme(appearance.colorScheme)
        .sheet(isPresented: $showSettings) {
            SettingsView(speechManager: speechManager, appearanceRawValue: $appearanceRawValue)
                .preferredColorScheme(appearance.colorScheme)
        }
        .sheet(item: $translationRequest) { request in
            TranslationReadingSheet(request: request) { translatedText in
                // Una traducción cancelada o de otro documento nunca inicia audio.
                guard translationRequest?.id == request.id,
                      session.text == request.originalText,
                      sourceLanguage == request.source,
                      speechManager.outputLanguage == request.target else { return }
                translationRequest = nil
                session.setReadingContext(source: request.source, target: request.target)
                speechManager.speak(translatedText)
            } onCancel: {
                if translationRequest?.id == request.id { translationRequest = nil }
            }
            .preferredColorScheme(appearance.colorScheme)
        }
        .fileImporter(isPresented: $showPDFImporter, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url): importPDF(url)
            case .failure(let error): session.presentError(error.localizedDescription)
            }
        }
        .alert("Aviso de VoxStudy", isPresented: $session.showImportError) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(session.importErrorMessage)
        }
        .onChange(of: sourceLanguageRawValue) { _, _ in
            clearPreparedReading()
        }
        .onChange(of: speechManager.selectedLanguage) { _, _ in
            clearPreparedReading()
        }
        .onDisappear {
            translationRequest = nil
            speechManager.stop()
        }
    }

    private func startReading() {
        guard !speechManager.isActive, !session.isImporting,
              translationRequest == nil,
              !session.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        guard speechManager.selectedVoice != nil else {
            session.presentError("No encontramos una voz en \(speechManager.outputLanguage.title). Abrí Ajustes y tocá Actualizar voces disponibles.")
            return
        }

        let target = speechManager.outputLanguage
        if sourceLanguage == target {
            session.setReadingContext(source: sourceLanguage, target: target)
            speechManager.speak(session.text)
        } else {
            #if targetEnvironment(simulator)
            session.presentError("La traducción de Apple necesita un iPhone físico. En el simulador podés probar la lectura eligiendo el mismo idioma en Texto en y Leer en. El original se conserva.")
            #else
            translationRequest = ReadingTranslationRequest(
                originalText: session.text, source: sourceLanguage, target: target
            )
            #endif
        }
    }

    private func clearPreparedReading() {
        // Los selectores están bloqueados mientras se lee o está en pausa.
        guard !speechManager.isActive else { return }
        translationRequest = nil
        speechManager.resetDocument()
        session.clearReadingContext()
    }

    private func openEditor() {
        guard !session.isImporting else { return }
        speechManager.resetDocument()
        session.clearReadingContext()
        selectedTab = .reader
    }

    private func openExample(_ example: StudyExample) {
        guard !speechManager.isActive, !session.isImporting else { return }
        speechManager.resetDocument()
        session.loadExample(example)
        sourceLanguageRawValue = example.language.rawValue
        selectedTab = .reader
    }

    private func openExamplePDF() {
        guard let url = Bundle.main.url(forResource: "VoxStudy_Prueba", withExtension: "pdf") else {
            session.presentError("No encontramos el PDF de ejemplo. Revisá que VoxStudy_Prueba.pdf esté incluido en el destino VoxStudy.")
            return
        }
        importPDF(url, knownLanguage: .spanish)
    }

    private func importPDF(_ url: URL, knownLanguage: ReadingLanguage? = nil) {
        guard !speechManager.isActive, !session.isImporting else { return }
        Task { @MainActor in
            if await session.importPDF(from: url) {
                speechManager.resetDocument()
                session.clearReadingContext()
                if let knownLanguage { sourceLanguageRawValue = knownLanguage.rawValue }
                selectedTab = .reader
            }
        }
    }
}

#Preview {
    ContentView()
}

