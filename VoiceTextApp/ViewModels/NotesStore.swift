import Foundation
import Combine
import SwiftUI

class NotesStore: ObservableObject {
    @Published var notes: [Note] = []

    private var documentsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var saveURL: URL {
        documentsDir.appendingPathComponent("savedNotes.json")
    }

    init() { load() }

    func save(title: String, type: Note.NoteType, content: String, audioURL: URL? = nil) {
        var audioFileName: String? = nil

        if let url = audioURL {
            let newName = UUID().uuidString + "." + url.pathExtension
            let dest = documentsDir.appendingPathComponent(newName)
            try? FileManager.default.copyItem(at: url, to: dest)
            audioFileName = newName
        }

        let note = Note(
            id: UUID(),
            title: title,
            date: Date(),
            type: type,
            content: content,
            audioFileName: audioFileName
        )
        notes.insert(note, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            if let fileName = notes[index].audioFileName {
                try? FileManager.default.removeItem(at: documentsDir.appendingPathComponent(fileName))
            }
        }
        notes.remove(atOffsets: offsets)
        persist()
    }

    func updateContent(for note: Note, text: String) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].content = text
        persist()
    }

    func updateTitle(for note: Note, title: String) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].title = title
        persist()
    }

    func audioURL(for note: Note) -> URL? {
        guard let fileName = note.audioFileName else { return nil }
        return documentsDir.appendingPathComponent(fileName)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(notes) {
            try? data.write(to: saveURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([Note].self, from: data) else { return }
        notes = decoded
    }
}
