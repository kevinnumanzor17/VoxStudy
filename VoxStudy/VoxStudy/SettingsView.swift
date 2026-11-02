import AVFoundation
import SwiftUI

@MainActor
struct SettingsView: View {
    @ObservedObject var speechManager: SpeechManager
    @Binding var appearanceRawValue: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette(colorScheme: colorScheme)
    }

    private var languageBinding: Binding<String> {
        Binding(
            get: { speechManager.selectedLanguage },
            set: { speechManager.chooseLanguage($0) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Apariencia", selection: $appearanceRawValue) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Apariencia")
                } footer: {
                    Text("Sistema utiliza la apariencia elegida en tu iPhone.")
                }
                .listRowBackground(palette.surface)

                if speechManager.isActive {
                    Section {
                        Label(speechManager.state.rawValue, systemImage: "speaker.wave.2.fill")
                        Button("Detener lectura para ajustar la voz") {
                            speechManager.stop()
                        }
                    } footer: {
                        Text("Podés cambiar la apariencia mientras escuchás.")
                    }
                    .listRowBackground(palette.surface)
                }

                Section {
                    Picker("Leer en", selection: languageBinding) {
                        ForEach(ReadingLanguage.allCases) { language in
                            Text(language.title).tag(language.rawValue)
                        }
                    }
                    .pickerStyle(.menu)

                    if speechManager.availableVoices.isEmpty {
                        Text("No encontramos voces disponibles en este dispositivo.")
                    } else {
                        if speechManager.voicesForSelectedLanguage.isEmpty {
                            Text("No hay una voz disponible para este idioma. Actualizá las voces o revisá las voces instaladas en el iPhone.")
                                .font(.footnote)
                        } else {
                            Picker("Voz", selection: $speechManager.selectedVoiceID) {
                                ForEach(speechManager.voicesForSelectedLanguage, id: \.identifier) { voice in
                                    Text(SpeechManager.voiceName(voice)).tag(voice.identifier)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    Button("Actualizar voces disponibles") {
                        speechManager.refreshVoices()
                    }
                } header: {
                    Text("Idioma de lectura y voz")
                } footer: {
                    Text("El prototipo admite español e inglés. En el Lector, indicá el idioma del texto original. Si es distinto de Leer en, se traducirá antes de escuchar. Las voces dependen del dispositivo.")
                }
                .listRowBackground(palette.surface)
                .disabled(speechManager.isActive)

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Velocidad", systemImage: "speedometer")
                            .font(.headline)
                        Slider(value: $speechManager.rate,
                               in: SpeechManager.rateRange, step: 0.01)
                            .accessibilityLabel("Velocidad de lectura")
                        HStack {
                            Text("Lenta")
                            Spacer()
                            Text("Rápida")
                        }
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                    }
                    .padding(.vertical, 5)

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Tono", systemImage: "waveform")
                            .font(.headline)
                        Slider(value: $speechManager.pitch,
                               in: SpeechManager.pitchRange, step: 0.05)
                            .accessibilityLabel("Tono de la voz")
                        HStack {
                            Text("Grave")
                            Spacer()
                            Text("Agudo")
                        }
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                    }
                    .padding(.vertical, 5)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Volumen", systemImage: "speaker.wave.2")
                                .font(.headline)
                            Spacer()
                            Text("\(Int((speechManager.volume * 100).rounded())) %")
                                .foregroundStyle(palette.secondaryText)
                        }
                        Slider(value: $speechManager.volume, in: 0...1, step: 0.05)
                            .accessibilityLabel("Volumen de la lectura")
                    }
                    .padding(.vertical, 5)

                    Button("Restablecer narración") {
                        speechManager.resetNarration()
                    }
                } header: {
                    Text("Narración")
                } footer: {
                    Text("Los ajustes se guardan automáticamente y se aplican al iniciar una lectura.")
                }
                .listRowBackground(palette.surface)
                .disabled(speechManager.isActive)
            }
            .scrollContentBackground(.hidden)
            .background(palette.background)
            .foregroundStyle(palette.mainText)
            .tint(palette.accent)
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(palette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }
}


