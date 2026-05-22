import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @State private var showVoiceSheet = false
    @State private var showFileSheet = false
    @State private var showCameraSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    Text("What would you like to do?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    VStack(spacing: 14) {
                        HomeActionCard(
                            icon: "waveform.circle.fill",
                            title: "Voice Message",
                            subtitle: "Record or upload audio",
                            gradient: [.blue, .indigo]
                        ) { showVoiceSheet = true }

                        HomeActionCard(
                            icon: "doc.fill",
                            title: "Upload File",
                            subtitle: "Select any file from your device",
                            gradient: [.green, .teal]
                        ) { showFileSheet = true }

                        HomeActionCard(
                            icon: "camera.fill",
                            title: "Scan Text",
                            subtitle: "Take a photo to transcribe text",
                            gradient: [.orange, .red]
                        ) { showCameraSheet = true }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: NotesView()) {
                        Image(systemName: "note.text")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isLoggedIn = false }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showVoiceSheet) { VoiceMessageView() }
            .sheet(isPresented: $showFileSheet)  { FileUploadView() }
            .sheet(isPresented: $showCameraSheet) { CameraTextView() }
        }
    }
}

struct HomeActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(.background)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
