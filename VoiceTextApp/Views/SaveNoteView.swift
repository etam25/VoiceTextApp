import SwiftUI

struct SaveNoteView: View {
    let type: Note.NoteType
    let content: String
    let audioURL: URL?

    @EnvironmentObject var notesStore: NotesStore
    @State private var title = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                // Type badge
                HStack(spacing: 8) {
                    Image(systemName: type.systemImage)
                        .foregroundStyle(
                            LinearGradient(
                                colors: type.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(type.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Title field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    TextField(suggestedTitle, text: $title)
                        .font(.headline)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }

                // Content preview
                VStack(alignment: .leading, spacing: 6) {
                    Text("Preview")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(content.isEmpty ? "No content" : content)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Save Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        notesStore.save(
                            title: title.isEmpty ? suggestedTitle : title,
                            type: type,
                            content: content,
                            audioURL: audioURL
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var suggestedTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return "\(type.label) – \(f.string(from: Date()))"
    }
}
