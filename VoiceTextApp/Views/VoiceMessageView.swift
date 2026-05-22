import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct VoiceMessageView: View {
    @StateObject private var vm = VoiceRecorderViewModel()
    @State private var selectedTab = 0
    @State private var showAudioPicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $selectedTab) {
                    Text("Record").tag(0)
                    Text("Upload").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    RecordTab(vm: vm)
                } else {
                    UploadAudioTab(vm: vm, showAudioPicker: $showAudioPicker)
                }
            }
            .navigationTitle("Voice Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if vm.activePlaybackURL != nil {
                        Button("Done") { dismiss() }.fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showAudioPicker) {
                AudioFilePicker(vm: vm)
            }
            .alert("Microphone Access Denied", isPresented: $vm.permissionDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enable microphone access in Settings to record voice messages.")
            }
        }
    }
}

// MARK: - Record Tab

struct RecordTab: View {
    @ObservedObject var vm: VoiceRecorderViewModel

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            WaveformView(isAnimating: vm.isRecording)
                .frame(height: 80)
                .padding(.horizontal, 32)

            Text(vm.formatTime(vm.recordingDuration))
                .font(.system(size: 52, weight: .thin, design: .monospaced))
                .foregroundColor(vm.isRecording ? .red : .primary)
                .contentTransition(.numericText())
                .animation(.default, value: vm.recordingDuration)

            Button(action: {
                vm.isRecording ? vm.stopRecording() : vm.requestPermissionAndRecord()
            }) {
                ZStack {
                    Circle()
                        .fill(vm.isRecording ? Color.red : Color.blue)
                        .frame(width: 84, height: 84)
                        .shadow(
                            color: (vm.isRecording ? Color.red : Color.blue).opacity(0.4),
                            radius: 12
                        )

                    if vm.isRecording {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.white)
                            .frame(width: 28, height: 28)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
            }
            .scaleEffect(vm.isRecording ? 1.08 : 1.0)
            .animation(
                vm.isRecording
                    ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                    : .easeInOut(duration: 0.2),
                value: vm.isRecording
            )

            Text(vm.isRecording
                 ? "Tap to stop"
                 : vm.recordedURL != nil ? "Recording saved" : "Tap to record")
                .foregroundColor(.secondary)
                .font(.subheadline)

            if vm.recordedURL != nil && !vm.isRecording {
                playbackControls
            }

            if let err = vm.errorMessage {
                Text(err).foregroundColor(.red).font(.caption).padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }

    private var playbackControls: some View {
        HStack(spacing: 24) {
            Button(action: { vm.isPlaying ? vm.stopPlayback() : vm.play() }) {
                Label(
                    vm.isPlaying ? "Stop" : "Play",
                    systemImage: vm.isPlaying ? "stop.circle.fill" : "play.circle.fill"
                )
                .font(.headline)
            }

            Button(action: vm.deleteRecording) {
                Label("Delete", systemImage: "trash.circle.fill")
                    .font(.headline)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Upload Tab

struct UploadAudioTab: View {
    @ObservedObject var vm: VoiceRecorderViewModel
    @Binding var showAudioPicker: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if let name = vm.uploadedFileName {
                VStack(spacing: 20) {
                    Image(systemName: "waveform")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom)
                        )

                    VStack(spacing: 6) {
                        Text(name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text("Audio file ready")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }

                    HStack(spacing: 20) {
                        Button(action: { vm.isPlaying ? vm.stopPlayback() : vm.play() }) {
                            Label(
                                vm.isPlaying ? "Stop" : "Play",
                                systemImage: vm.isPlaying ? "stop.circle.fill" : "play.circle.fill"
                            )
                            .font(.headline)
                        }

                        Button(action: { vm.deleteRecording() }) {
                            Label("Remove", systemImage: "trash.circle.fill")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                    }

                    Button(action: { showAudioPicker = true }) {
                        Label("Replace File", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 76))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom)
                        )

                    VStack(spacing: 6) {
                        Text("Upload Audio File")
                            .font(.title2.bold())
                        Text("Select an audio file from your device")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: { showAudioPicker = true }) {
                        Label("Choose Audio File", systemImage: "folder")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Waveform

struct WaveformView: View {
    let isAnimating: Bool
    @State private var heights: [CGFloat] = Array(repeating: 4, count: 24)
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<24, id: \.self) { i in
                Capsule()
                    .fill(
                        LinearGradient(colors: [.blue, .purple], startPoint: .bottom, endPoint: .top)
                    )
                    .frame(width: 4, height: heights[i])
                    .animation(.easeInOut(duration: 0.12), value: heights[i])
            }
        }
        .onReceive(timer) { _ in
            guard isAnimating else {
                if heights.first != 4 {
                    heights = Array(repeating: 4, count: 24)
                }
                return
            }
            for i in 0..<heights.count {
                heights[i] = CGFloat.random(in: 4...72)
            }
        }
    }
}

// MARK: - Audio File Picker

struct AudioFilePicker: UIViewControllerRepresentable {
    @ObservedObject var vm: VoiceRecorderViewModel
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(vm: vm, dismiss: dismiss) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let vm: VoiceRecorderViewModel
        let dismiss: DismissAction

        init(vm: VoiceRecorderViewModel, dismiss: DismissAction) {
            self.vm = vm
            self.dismiss = dismiss
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            vm.setUploadedFile(url: url, name: url.lastPathComponent)
            dismiss()
        }
    }
}
