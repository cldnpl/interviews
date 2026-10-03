import SwiftUI

/// La schermata di apertura. Copre l'avvio dell'app: il marchio arriva, respira
/// una volta e sfuma. Il fondo è lo stesso della schermata di lancio di iOS,
/// così fra le due non si vede il passaggio.
struct SplashView: View {
    @State private var landed = false
    @State private var spread = false
    @State private var written = false

    var body: some View {
        ZStack {
            Color.launch.ignoresSafeArea()

            VStack(spacing: 22) {
                AppMark()
                    .frame(width: 124)
                    .scaleEffect(landed ? 1 : 0.55)
                    .rotationEffect(.degrees(landed ? 0 : -14))
                    .opacity(landed ? 1 : 0)

                VStack(spacing: 8) {
                    Text("Interviews")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                    Text("Mobile dev prep", bundle: .app)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .opacity(written ? 1 : 0)
                .offset(y: written ? 0 : 10)

                // I quattro colori che si aprono sotto il nome.
                HStack(spacing: 6) {
                    ForEach(Track.allCases) { track in
                        Capsule()
                            .fill(track.theme.linear)
                            .frame(width: spread ? 26 : 6, height: 6)
                    }
                }
                .opacity(spread ? 1 : 0)
                .padding(.top, 2)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.42)) { landed = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) { written = true }
            withAnimation(.spring(duration: 0.6, bounce: 0.4).delay(0.45)) { spread = true }
        }
    }
}

extension Color {
    /// Il fondo dell'apertura, lo stesso dichiarato nella schermata di lancio.
    static let launch = Color("LaunchBackground")
}

#Preview { SplashView() }
