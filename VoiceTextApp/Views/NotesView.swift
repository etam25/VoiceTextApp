import SwiftUI

struct NotesView: View {
    @EnvironmentObject var notesStore: NotesStore

    var body: some View {
        Group {
            if notesStore.notes.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(notesStore.notes) { note in
                        NavigationLink(destination: NoteDetailView(note: note)) {
                            NoteRow(note: note)
                        }
                    }
                    .onDelete { notesStore.delete(at: $0) }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Notes")
        .toolbar { EditButton() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.4))

            Text("No Notes Yet")
                .font(.title2.bold())

            Text("After recording, uploading, or scanning text,\ntap \"Save as Note\" to store it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct NoteRow: View {
    let note: Note

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: note.type.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: note.type.systemImage)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(note.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
