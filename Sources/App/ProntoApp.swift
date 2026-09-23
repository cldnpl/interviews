import SwiftUI

@main
struct ProntoApp: App {
    @State private var state = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(state)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await Reminders.reschedule(for: state) } }
                }
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Group {
            if state.hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: state.hasOnboarded)
        .tint(state.activeTrack.theme.primary)
        // Il design è pensato su fondo bianco: arancio e bianco per Swift, e così via.
        .preferredColorScheme(.light)
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Oggi", systemImage: "flame.fill") }
            ReviewView()
                .tabItem { Label("Ripasso", systemImage: "book.fill") }
            ProfileView()
                .tabItem { Label("Profilo", systemImage: "person.crop.circle.fill") }
        }
    }
}
