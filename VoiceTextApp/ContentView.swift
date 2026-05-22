import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    @StateObject private var notesStore = NotesStore()

    var body: some View {
        Group {
            if isLoggedIn {
                HomeView(isLoggedIn: $isLoggedIn)
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
        .environmentObject(notesStore)
        .animation(.easeInOut(duration: 0.3), value: isLoggedIn)
    }
}
