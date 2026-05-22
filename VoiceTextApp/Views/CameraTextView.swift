import SwiftUI
import UIKit

struct CameraTextView: View {
    @StateObject private var ocrVM = OCRViewModel()
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var copyConfirmed = false
    @State private var showSaveNote = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notesStore: NotesStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    imageSection
                    actionButtons
                    resultSection
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationTitle("Scan Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if !ocrVM.recognizedText.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }.fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: $capturedImage)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showSaveNote) {
                SaveNoteView(
                    type: .textScan,
                    content: ocrVM.recognizedText,
                    audioURL: nil
                )
                .environmentObject(notesStore)
            }
            .onChange(of: capturedImage) { _, newImage in
                if let img = newImage {
                    ocrVM.recognizeText(from: img)
                }
            }
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        Group {
            if let image = capturedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.15), radius: 10)
                        .padding(.horizontal)

                    Button(action: {
                        capturedImage = nil
                        ocrVM.recognizedText = ""
                        ocrVM.errorMessage = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, Color.black.opacity(0.55))
                            .padding(8)
                    }
                    .padding(.trailing, 8)
                }
            } else {
                Button(action: { showCamera = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(
                                LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 2, dash: [10, 6])
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(LinearGradient(
                                        colors: [Color.orange.opacity(0.08), Color.red.opacity(0.08)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                            )
                            .frame(height: 240)

                        VStack(spacing: 16) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 58))
                                .foregroundStyle(
                                    LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )

                            VStack(spacing: 4) {
                                Text("Take a photo to scan text").font(.headline)
                                Text("Point your camera at printed or handwritten text")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { showCamera = true }) {
                Label(
                    capturedImage == nil ? "Open Camera" : "Retake Photo",
                    systemImage: capturedImage == nil ? "camera.fill" : "camera.rotate.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(14)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Result Section

    @ViewBuilder
    private var resultSection: some View {
        if ocrVM.isProcessing {
            VStack(spacing: 14) {
                ProgressView().scaleEffect(1.2)
                Text("Scanning text…").foregroundColor(.secondary).font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(36)
            .background(.ultraThinMaterial)
            .cornerRadius(18)
            .padding(.horizontal)
        } else if !ocrVM.recognizedText.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Recognized Text", systemImage: "text.alignleft").font(.headline)
                    Spacer()
                    HStack(spacing: 12) {
                        Button(action: copyText) {
                            Label(
                                copyConfirmed ? "Copied!" : "Copy",
                                systemImage: copyConfirmed ? "checkmark.circle.fill" : "doc.on.doc"
                            )
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(copyConfirmed ? .green : .blue)
                        }

                        Button(action: { showSaveNote = true }) {
                            Label("Save", systemImage: "square.and.arrow.down")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.purple)
                        }
                    }
                }

                Divider()

                Text(ocrVM.recognizedText)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(18)
            .padding(.horizontal)
        } else if let error = ocrVM.errorMessage {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                Text(error).foregroundColor(.secondary).font(.subheadline)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(14)
            .padding(.horizontal)
        }
    }

    private func copyText() {
        UIPasteboard.general.string = ocrVM.recognizedText
        withAnimation { copyConfirmed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copyConfirmed = false }
        }
    }
}

// MARK: - Camera Picker

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(image: $image, dismiss: dismiss) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Binding var image: UIImage?
        let dismiss: DismissAction

        init(image: Binding<UIImage?>, dismiss: DismissAction) {
            _image = image
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            image = info[.originalImage] as? UIImage
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
