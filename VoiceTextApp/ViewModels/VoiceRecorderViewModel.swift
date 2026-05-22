import AVFoundation
import SwiftUI

class VoiceRecorderViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordedURL: URL?
    @Published var uploadedURL: URL?
    @Published var uploadedFileName: String?
    @Published var permissionDenied = false
    @Published var errorMessage: String?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    private var newRecordingURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("voiceMessage.m4a")
    }

    var activePlaybackURL: URL? { uploadedURL ?? recordedURL }

    func requestPermissionAndRecord() {
        let grant: (@escaping (Bool) -> Void) -> Void
        if #available(iOS 17.0, *) {
            grant = AVAudioApplication.requestRecordPermission(completionHandler:)
        } else {
            grant = AVAudioSession.sharedInstance().requestRecordPermission(_:)
        }
        grant { [weak self] granted in
            DispatchQueue.main.async {
                if granted { self?.startRecording() }
                else { self?.permissionDenied = true }
            }
        }
    }

    func startRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: newRecordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            isRecording = true
            recordingDuration = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordingDuration += 0.1
            }
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
        recordedURL = newRecordingURL
        uploadedURL = nil
        uploadedFileName = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    func play() {
        guard let url = activePlaybackURL else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            errorMessage = "Could not play audio: \(error.localizedDescription)"
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
    }

    func deleteRecording() {
        stopPlayback()
        if let url = recordedURL { try? FileManager.default.removeItem(at: url) }
        recordedURL = nil
        uploadedURL = nil
        uploadedFileName = nil
        recordingDuration = 0
    }

    func setUploadedFile(url: URL, name: String) {
        let dest = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: url, to: dest)
        uploadedURL = dest
        uploadedFileName = name
        recordedURL = nil
        recordingDuration = 0
    }

    func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        let d = Int((t * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%02d:%02d.%01d", m, s, d)
    }
}

extension VoiceRecorderViewModel: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag { DispatchQueue.main.async { self.errorMessage = "Recording failed" } }
    }
}

extension VoiceRecorderViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.isPlaying = false }
    }
}
