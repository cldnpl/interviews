import SwiftUI

@main
struct InterviewsApp: App {
    @State private var state: AppState
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Prima di tutto il resto: stringhe e contenuti si leggono già nella lingua giusta.
        AppLanguage.bootstrap()
        _state = State(initialValue: AppState())
    }

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
    /// Sta qui, sopra l'`.id` della lingua: cambiando lingua dal Profilo si resta sul Profilo.
    @State private var tab = AppTab.today

    var body: some View {
        Group {
            if state.hasOnboarded {
                MainTabView(selection: $tab)
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        // Il locale dell'ambiente decide la lingua di ogni Text; l'id ricostruisce le view,
        // che così rileggono anche i contenuti e le stringhe calcolate nella lingua nuova.
        .environment(\.locale, state.language.locale)
        .id(state.language)
        .animation(.easeInOut(duration: 0.35), value: state.hasOnboarded)
        .tint(state.activeTrack.theme.primary)
        // Il design è pensato su fondo bianco: arancio e bianco per Swift, e così via.
        .preferredColorScheme(.light)
    }
}

enum AppTab: Hashable {
    case today, review, profile
}

struct MainTabView: View {
    @Binding var selection: AppTab

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Today", systemImage: "flame.fill") }
                .tag(AppTab.today)
            ReviewView()
                .tabItem { Label("Review", systemImage: "book.fill") }
                .tag(AppTab.review)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(AppTab.profile)
        }
    }
}
