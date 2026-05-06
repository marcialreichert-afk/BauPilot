import Foundation
import Speech
import AVFoundation
import Combine

final class SpeechManager: NSObject, ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?

    private let speechRecognizer: SFSpeechRecognizer? = {
        if let recognizer = SFSpeechRecognizer(locale: Locale.current) {
            return recognizer
        }
        return SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    }()

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.errorMessage = nil
                case .denied:
                    self.errorMessage = "speech.error.permission_denied".localized("Spracherkennung wurde nicht erlaubt.")
                case .restricted:
                    self.errorMessage = "speech.error.restricted".localized("Spracherkennung ist auf diesem Gerät eingeschränkt.")
                case .notDetermined:
                    self.errorMessage = nil
                @unknown default:
                    self.errorMessage = "speech.error.unknown".localized("Unbekannter Fehler bei der Spracherkennung.")
                }
            }
        }

        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            DispatchQueue.main.async {
                if !allowed {
                    self.errorMessage = "speech.error.microphone_denied".localized("Mikrofon-Zugriff wurde nicht erlaubt.")
                }
            }
        }
    }

    func startRecording(onTextChange: @escaping (String) -> Void) {
        stopRecording()
        errorMessage = nil
        recognizedText = ""

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "speech.error.not_available".localized("Spracherkennung ist aktuell nicht verfügbar.")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "speech.error.audio_session_failed".localized("Audio-Sitzung konnte nicht gestartet werden.")
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            errorMessage = "speech.error.recording_failed".localized("Audioaufnahme konnte nicht gestartet werden.")
            return
        }

        isRecording = true

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            DispatchQueue.main.async {
                if let result {
                    self.recognizedText = result.bestTranscription.formattedString
                    onTextChange(self.recognizedText)

                    if result.isFinal {
                        self.stopRecording()
                    }
                }

                if error != nil {
                    self.stopRecording()
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

        recognitionRequest = nil
        recognitionTask = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // ignorieren
        }

        isRecording = false
    }
}
