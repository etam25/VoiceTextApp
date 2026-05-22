import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 76))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("VoiceText")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Your all-in-one media companion")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.65))
                }

                VStack(spacing: 14) {
                    inputField(
                        icon: "envelope.fill",
                        placeholder: "Email",
                        text: $email,
                        field: .email,
                        isSecure: false
                    )
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                    inputField(
                        icon: "lock.fill",
                        placeholder: "Password",
                        text: $password,
                        field: .password,
                        isSecure: true
                    )

                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red.opacity(0.9))
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }

                    Button(action: login) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 28)

                Spacer()

                Text("Demo: any non-empty email & password")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.bottom, 20)
            }
        }
    }

    @ViewBuilder
    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        isSecure: Bool
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: text)
                    .foregroundColor(.white)
                    .focused($focusedField, equals: field)
            } else {
                TextField(placeholder, text: text)
                    .foregroundColor(.white)
                    .focused($focusedField, equals: field)
            }
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func login() {
        focusedField = nil
        showError = false

        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            showError = true
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            showError = true
            return
        }

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            isLoggedIn = true
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
