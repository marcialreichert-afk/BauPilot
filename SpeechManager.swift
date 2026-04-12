import Foundation
import Combine
import AVFoundation
import Speech

final class SpeechManager: NSObject, ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var microphonePermissionGranted: Bool = false
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override init() {
        super.init()
        requestPermissions()
    }

    func requestPermissions() {
        errorMessage = nil

        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
            }
        }

        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.microphonePermissionGranted = granted
            }
        }
    }

    func startRecording(onUpdate: @escaping (String) -> Void) {
        errorMessage = nil

        if audioEngine.isRunning {
            stopRecording()
        }

        guard let speechRecognizer else {
            errorMessage = NSLocalizedString("speech_not_available_device", comment: "")
            return
        }

        guard speechRecognizer.isAvailable else {
            errorMessage = NSLocalizedString("speech_not_available_now", comment: "")
            return
        }

        guard authorizationStatus == .authorized else {
            errorMessage = NSLocalizedString("speech_not_authorized", comment: "")
            return
        }

        guard microphonePermissionGranted else {
            errorMessage = NSLocalizedString("speech_microphone_not_allowed", comment: "")
            return
        }

        recognizedText = ""
        isRecording = true

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            errorMessage = String(
                format: NSLocalizedString("speech_audio_error", comment: ""),
                error.localizedDescription
            )
            isRecording = false
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            errorMessage = "AudioEngine konnte nicht gestartet werden."
            isRecording = false
            return
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            DispatchQueue.main.async {
                if let result {
                    let text = result.bestTranscription.formattedString
                    self.recognizedText = text
                    onUpdate(text)

                    if result.isFinal && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.errorMessage = NSLocalizedString("speech_no_speech_detected", comment: "")
                    }
                }

                if let error = error as NSError? {
                    let message = error.localizedDescription.lowercased()

                    if message.contains("cancel") {
                        return
                    }

                    if message.contains("no speech detected") {
                        self.errorMessage = "Keine Sprache erkannt."
                        return
                    }

                    self.errorMessage = String(
                        format: NSLocalizedString("speech_recognition_error", comment: ""),
                        error.localizedDescription
                    )
                }
            }
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}
