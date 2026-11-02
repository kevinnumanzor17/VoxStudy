import AVFoundation
import Combine
import Foundation

enum SpeechState: String {
    case ready = "Listo para escuchar"
    case speaking = "Leyendo"
    case paused = "En pausa"
    case finished = "Lectura finalizada"
}

@MainActor
final class SpeechManager: NSObject, ObservableObject {
    static let rateRange: ClosedRange<Float> = 0.3...0.65
    static let pitchRange: ClosedRange<Float> = 0.5...2.0

    @Published private(set) var state: SpeechState = .ready
    @Published private(set) var errorMessage: String?
    @Published private(set) var availableVoices: [AVSpeechSynthesisVoice] = []
    @Published private(set) var selectedLanguage = ReadingLanguage.spanish.rawValue
    @Published private(set) var paragraphs: [String] = []
    @Published private(set) var currentParagraphIndex = 0
    @Published private(set) var highlightedRange: NSRange?

    @Published var selectedVoiceID = "" {
        didSet { UserDefaults.standard.set(selectedVoiceID, forKey: "voxstudy.voiceID") }
    }

    @Published var rate = AVSpeechUtteranceDefaultSpeechRate {
        didSet { UserDefaults.standard.set(rate, forKey: "voxstudy.rate") }
    }

    @Published var pitch: Float = 1 {
        didSet { UserDefaults.standard.set(pitch, forKey: "voxstudy.pitch") }
    }

    @Published var volume: Float = 1 {
        didSet { UserDefaults.standard.set(volume, forKey: "voxstudy.volume") }
    }

    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtteranceID: ObjectIdentifier?
    private var documentText = ""
    private var paragraphRanges: [NSRange] = []
    private var speechStartOffset = 0
    private var spokenTextLength = 0
    private var readingSingleParagraph = false

    var hasDocument: Bool { !paragraphs.isEmpty }
    var canGoBackward: Bool { hasDocument && currentParagraphIndex > 0 }
    var canGoForward: Bool { currentParagraphIndex + 1 < paragraphs.count }

    var currentParagraph: String {
        guard paragraphs.indices.contains(currentParagraphIndex) else { return "" }
        return paragraphs[currentParagraphIndex]
    }

    var isActive: Bool {
        state == .speaking || state == .paused
    }

    var outputLanguage: ReadingLanguage {
        ReadingLanguage(rawValue: selectedLanguage) ?? .spanish
    }

    var voicesForSelectedLanguage: [AVSpeechSynthesisVoice] {
        availableVoices.filter {
            ReadingLanguage(voiceLanguageCode: $0.language) == outputLanguage
        }
    }

    var selectedVoice: AVSpeechSynthesisVoice? {
        voicesForSelectedLanguage.first { $0.identifier == selectedVoiceID }
    }

    var voiceSummary: String {
        guard let voice = selectedVoice else { return "Seleccioná una voz en Ajustes." }
        return "\(voice.name) · \(Self.languageName(voice.language))"
    }

    override init() {
        super.init()
        synthesizer.delegate = self

        let defaults = UserDefaults.standard
        let savedLanguage = defaults.string(forKey: "voxstudy.language") ?? "es"
        selectedLanguage = (ReadingLanguage(voiceLanguageCode: savedLanguage) ?? .spanish).rawValue
        selectedVoiceID = defaults.string(forKey: "voxstudy.voiceID") ?? ""
        rate = Self.savedFloat("voxstudy.rate",
                               fallback: AVSpeechUtteranceDefaultSpeechRate,
                               range: Self.rateRange)
        pitch = Self.savedFloat("voxstudy.pitch", fallback: 1, range: Self.pitchRange)
        volume = Self.savedFloat("voxstudy.volume", fallback: 1, range: 0...1)
        refreshVoices()
    }

    static func languageName(_ code: String) -> String {
        Locale(identifier: "es").localizedString(forIdentifier: code) ?? code
    }

    static func voiceName(_ voice: AVSpeechSynthesisVoice) -> String {
        let name = "\(voice.name) · \(languageName(voice.language))"
        switch voice.quality {
        case .default: return name
        case .enhanced: return "\(name) · Mejorada"
        case .premium: return "\(name) · Premium"
        @unknown default: return name
        }
    }

    func refreshVoices() {
        guard !isActive else { return }

        // Solo consultamos al iniciar y cuando la persona solicita actualizar.
        // Filtrar el resultado no corrige los avisos internos del servicio de Apple.
        availableVoices = AVSpeechSynthesisVoice.speechVoices().filter {
            ReadingLanguage(voiceLanguageCode: $0.language) != nil
        }.sorted {
            if $0.language == $1.language {
                return Self.voiceName($0) < Self.voiceName($1)
            }
            return $0.language < $1.language
        }

        chooseLanguage(selectedLanguage)
    }

    func chooseLanguage(_ code: String) {
        guard !isActive, let language = ReadingLanguage(voiceLanguageCode: code) else { return }
        selectedLanguage = language.rawValue
        UserDefaults.standard.set(selectedLanguage, forKey: "voxstudy.language")

        // Al cambiar de idioma, elegimos una voz que pertenezca a ese idioma.
        let candidates = voicesForSelectedLanguage
        if !candidates.contains(where: { $0.identifier == selectedVoiceID }) {
            let preferredLocale = language == .spanish ? "es-MX" : "en-US"
            selectedVoiceID = candidates.first(where: {
                $0.language == preferredLocale && $0.quality == .default
            })?.identifier
                ?? candidates.first(where: { $0.quality == .default })?.identifier
                ?? candidates.first?.identifier
                ?? ""
        }
    }

    func resetNarration() {
        guard !isActive else { return }
        rate = AVSpeechUtteranceDefaultSpeechRate
        pitch = 1
        volume = 1
    }

    func speak(_ text: String) {
        guard !isActive else { return }
        let parts = ParagraphParser.parse(text)
        guard !parts.isEmpty else { return }

        resetDocument()
        paragraphs = parts
        documentText = parts.joined(separator: "\n\n")

        // AVSpeechSynthesizer y UITextView trabajan con rangos UTF-16.
        var offset = 0
        paragraphRanges = parts.map { paragraph in
            let length = (paragraph as NSString).length
            let range = NSRange(location: offset, length: length)
            offset += length + 2
            return range
        }

        beginSpeech(at: 0, singleParagraph: false)
    }

    func continueReading() {
        guard hasDocument, !isActive else { return }
        let index: Int
        if state == .finished {
            index = canGoForward ? currentParagraphIndex + 1 : 0
        } else {
            index = currentParagraphIndex
        }
        beginSpeech(at: index, singleParagraph: false)
    }

    func repeatParagraph() {
        guard hasDocument else { return }
        beginSpeech(at: currentParagraphIndex, singleParagraph: true)
    }

    func previousParagraph() {
        guard canGoBackward else { return }
        beginSpeech(at: currentParagraphIndex - 1, singleParagraph: true)
    }

    func nextParagraph() {
        guard canGoForward else { return }
        beginSpeech(at: currentParagraphIndex + 1, singleParagraph: true)
    }

    private func beginSpeech(at index: Int, singleParagraph: Bool) {
        guard paragraphs.indices.contains(index) else { return }

        // Invalidamos primero la lectura anterior para ignorar sus eventos pendientes.
        currentUtteranceID = nil
        synthesizer.stopSpeaking(at: .immediate)
        highlightedRange = nil
        state = .ready
        errorMessage = nil
        guard let voice = selectedVoice else {
            errorMessage = "No encontramos una voz en \(outputLanguage.title). Abrí Ajustes y tocá Actualizar voces disponibles."
            deactivateAudioSession()
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            errorMessage = "No se pudo activar el audio. Intentá reproducir nuevamente."
            deactivateAudioSession()
            return
        }

        currentParagraphIndex = index
        speechStartOffset = paragraphRanges[index].location
        readingSingleParagraph = singleParagraph

        let spokenText = singleParagraph
            ? paragraphs[index]
            : (documentText as NSString).substring(from: speechStartOffset)
        spokenTextLength = (spokenText as NSString).length

        let utterance = AVSpeechUtterance(string: spokenText)
        utterance.voice = voice
        utterance.rate = min(max(rate, Self.rateRange.lowerBound), Self.rateRange.upperBound)
        utterance.pitchMultiplier = min(max(pitch, 0.5), 2)
        utterance.volume = min(max(volume, 0), 1)
        currentUtteranceID = ObjectIdentifier(utterance)
        state = .speaking
        synthesizer.speak(utterance)
    }

    private func updateHighlight(_ range: NSRange, for identifier: ObjectIdentifier) {
        guard currentUtteranceID == identifier, state == .speaking,
              range.location != NSNotFound, range.length > 0,
              range.location <= spokenTextLength,
              range.length <= spokenTextLength - range.location else { return }

        let documentRange = NSRange(
            location: speechStartOffset + range.location,
            length: range.length
        )
        guard let index = paragraphRanges.firstIndex(where: {
            NSLocationInRange(documentRange.location, $0)
        }) else { return }

        let intersection = NSIntersectionRange(documentRange, paragraphRanges[index])
        guard intersection.length > 0 else { return }
        currentParagraphIndex = index
        highlightedRange = NSRange(
            location: intersection.location - paragraphRanges[index].location,
            length: intersection.length
        )
    }

    func pause() {
        guard state == .speaking else { return }
        if synthesizer.pauseSpeaking(at: .immediate) {
            state = .paused
        }
    }

    func resume() {
        guard state == .paused else { return }
        if synthesizer.continueSpeaking() {
            state = .speaking
        }
    }

    func stop() {
        currentUtteranceID = nil
        synthesizer.stopSpeaking(at: .immediate)
        highlightedRange = nil
        state = .ready
        deactivateAudioSession()
    }

    func resetDocument() {
        stop()
        paragraphs = []
        paragraphRanges = []
        documentText = ""
        currentParagraphIndex = 0
        errorMessage = nil
    }

    private func finish(_ identifier: ObjectIdentifier, cancelled: Bool) {
        guard currentUtteranceID == identifier else { return }
        currentUtteranceID = nil
        highlightedRange = nil
        if !cancelled && !readingSingleParagraph {
            currentParagraphIndex = max(0, paragraphs.count - 1)
        }
        state = cancelled ? .ready : .finished
        deactivateAudioSession()
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation
        )
    }

    private static func savedFloat(
        _ key: String, fallback: Float, range: ClosedRange<Float>
    ) -> Float {
        guard let number = UserDefaults.standard.object(forKey: key) as? NSNumber,
              number.floatValue.isFinite else { return fallback }
        return min(max(number.floatValue, range.lowerBound), range.upperBound)
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        let identifier = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            self?.updateHighlight(characterRange, for: identifier)
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        let identifier = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            self?.finish(identifier, cancelled: false)
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        let identifier = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            self?.finish(identifier, cancelled: true)
        }
    }
}



