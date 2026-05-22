import SwiftUI
import AVFoundation

struct NoteDetailView: View {
    let note: Note
    @EnvironmentObject var notesStore: NotesStore
    @State private var title: String
    @State private var noteText: String
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @FocusState private var titleFocused: Bool

    init(note: Note) {
        self.note = note
        _title = State(initialValue: note.title)
        _noteText = State(initialValue: note.content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Editable title
            TextField("Title", text: $title, axis: .vertical)
                .font(.title.bold())
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)
                .focused($titleFocused)

            // Date + type badge
            HStack(spacing: 6) {
                Text(note.date, format: .dateTime.month(.wide).day().year())
                Text("·")
                Text(note.type.label)
                    .foregroundStyle(
                        LinearGradient(
                            colors: note.type.gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Divider()

            if note.type == .voice {
                voiceBody
            } else {
                TextEditor(text: $noteText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { saveChanges() }
        .onTapGesture { titleFocused = false }
    }

    // MARK: - Voice body

    private var voiceBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Info row
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .foregroundColor(.secondary)
                    Text(note.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)

                // Play button
                if notesStore.audioURL(for: note) != nil {
                    Button(action: togglePlayback) {
                        Label(
                            isPlaying ? "Stop Playback" : "Play Recording",
                            systemImage: isPlaying ? "stop.circle.fill" : "play.circle.fill"
                        )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: note.type.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                }

                Divider()

                // Editable notes area below the player
                Text("Notes")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                TextEditor(text: $noteText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200)
                    .padding(.horizontal, -4)
            }
            .padding(16)
        }
    }

    // MARK: - Helpers

    private func saveChanges() {
        audioPlayer?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        notesStore.updateTitle(for: note, title: title.isEmpty ? note.title : title)
        notesStore.updateContent(for: note, text: noteText)
    }

    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
            return
        }
        guard let url = notesStore.audioURL(for: note) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true
        } catch {}
    }
}
