import SwiftUI
import UniformTypeIdentifiers

struct FileUploadView: View {
    @State private var showPicker = false
    @State private var fileName: String?
    @State private var fileSize: String?
    @State private var fileExtension: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                if let name = fileName {
                    fileSelectedView(name: name)
                } else {
                    uploadPromptView
                }

                Spacer()
            }
            .navigationTitle("Upload File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if fileName != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }.fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                GeneralFilePicker(
                    fileName: $fileName,
                    fileSize: $fileSize,
                    fileExtension: $fileExtension
                )
            }
        }
    }

    private func fileSelectedView(name: String) -> some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 130, height: 130)

                Image(systemName: iconName(for: fileExtension ?? ""))
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(spacing: 8) {
                Text(name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let size = fileSize {
                    Text(size)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let ext = fileExtension, !ext.isEmpty {
                    Text(ext.uppercased())
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }

            HStack(spacing: 14) {
                Button(action: { showPicker = true }) {
                    Label("Replace", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }

                Button(action: { fileName = nil; fileSize = nil; fileExtension = nil }) {
                    Label("Remove", systemImage: "trash")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }

    private var uploadPromptView: some View {
        VStack(spacing: 24) {
            Button(action: { showPicker = true }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2, dash: [10, 6])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.green.opacity(0.04))
                        )
                        .frame(height: 220)

                    VStack(spacing: 16) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 54))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .teal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(spacing: 4) {
                            Text("Tap to select a file")
                                .font(.headline)
                            Text("Any file type supported")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Button(action: { showPicker = true }) {
                Label("Browse Files", systemImage: "folder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
        }
    }

    private func iconName(for ext: String) -> String {
        switch ext.lowercased() {
        case "pdf":                          return "doc.richtext.fill"
        case "jpg", "jpeg", "png", "heic":  return "photo.fill"
        case "mp3", "m4a", "wav", "aac":    return "music.note"
        case "mp4", "mov":                   return "video.fill"
        case "txt":                          return "doc.text.fill"
        case "zip", "rar":                   return "archivebox.fill"
        default:                             return "doc.fill"
        }
    }
}

// MARK: - Document Picker

struct GeneralFilePicker: UIViewControllerRepresentable {
    @Binding var fileName: String?
    @Binding var fileSize: String?
    @Binding var fileExtension: String?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(fileName: $fileName, fileSize: $fileSize, fileExtension: $fileExtension, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        @Binding var fileName: String?
        @Binding var fileSize: String?
        @Binding var fileExtension: String?
        let dismiss: DismissAction

        init(
            fileName: Binding<String?>,
            fileSize: Binding<String?>,
            fileExtension: Binding<String?>,
            dismiss: DismissAction
        ) {
            _fileName = fileName
            _fileSize = fileSize
            _fileExtension = fileExtension
            self.dismiss = dismiss
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            fileName = url.lastPathComponent
            fileExtension = url.pathExtension

            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                fileSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }

            dismiss()
        }
    }
}
