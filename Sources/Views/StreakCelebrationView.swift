import SwiftUI

/// La festa dello streak: arriva a tutto schermo appena il quiz del giorno è
/// finito e i giorni di fila sono aumentati. Il numero vecchio si gira e
/// diventa quello nuovo, i raggi girano, i coriandoli cadono.
struct StreakCelebrationView: View {
    /// Lo streak prima di oggi, da cui parte il numero.
    let from: Int
    /// Quello di adesso, dove arriva.
    let to: Int
    let onContinue: () -> Void

    @State private var shown: Int
    @State private var rising = false
    @State private var rays = false
    @State private var punch = false
    @State private var confetti = false
    @State private var copy = false

    init(from: Int, to: Int, onContinue: @escaping () -> Void) {
        self.from = from
        self.to = to
        self.onContinue = onContinue
        // Il numero parte da quello di ieri: è da lì che deve girare.
        _shown = State(initialValue: from)
    }

    /// Un traguardo tondo si festeggia con una riga diversa.
    private var milestone: Bool { to % 7 == 0 || to == 3 || to == 30 || to == 100 }

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    turningRays
                    flame
                }
                .frame(height: 300)

                VStack(spacing: 10) {
                    Group {
                        if to == 1 {
                            Text("Streak started!", bundle: .app)
                        } else {
                            Text("\(to) day streak!", bundle: .app)
                        }
                    }
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 32)
                }
                .foregroundStyle(.white)
                .opacity(copy ? 1 : 0)
                .offset(y: copy ? 0 : 16)

                Spacer()

                WeekStrip()
                    .padding(.horizontal, 24)
                    .opacity(copy ? 1 : 0)

                Button(action: onContinue) {
                    Text("Keep going", bundle: .app)
                        .font(.headline)
                        .foregroundStyle(Color(hex: 0xB03A00))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 16)
                .opacity(copy ? 1 : 0)
            }

            Confetti(running: confetti)
                .allowsHitTesting(false)
        }
        .onAppear(perform: run)
        .sensoryFeedback(.success, trigger: punch)
    }

    // MARK: Le parti

    private var backdrop: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFF9A1F), Color(hex: 0xF5600A), Color(hex: 0xC02B12)],
                           startPoint: .top, endPoint: .bottom)
            // Un alone caldo dietro alla fiamma.
            RadialGradient(colors: [.white.opacity(0.35), .clear], center: .center,
                           startRadius: 2, endRadius: 320)
                .scaleEffect(rising ? 1.1 : 0.7)
                .opacity(rising ? 1 : 0)
        }
        .ignoresSafeArea()
    }

    /// I raggi che girano dietro al numero: sono quelli che fanno sembrare la cosa una festa.
    private var turningRays: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                Capsule()
                    .fill(.white.opacity(i.isMultiple(of: 2) ? 0.3 : 0.15))
                    .frame(width: 14, height: 150)
                    .offset(y: -150)
                    .rotationEffect(.degrees(Double(i) / 16 * 360))
            }
        }
        .rotationEffect(.degrees(rays ? 360 : 0))
        .scaleEffect(rising ? 1 : 0.2)
        .opacity(rising ? 1 : 0)
        .blur(radius: 0.5)
    }

    private var flame: some View {
        VStack(spacing: -14) {
            Image(systemName: "flame.fill")
                .font(.system(size: 108))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: 0xFFF1A8), Color(hex: 0xFFC63D), Color(hex: 0xFF7A00)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Color(hex: 0x8A2800).opacity(0.4), radius: 14, y: 8)
                .scaleEffect(rising ? (punch ? 1 : 0.94) : 0.3)
            Text("\(shown)")
                .font(.system(size: 92, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .shadow(color: Color(hex: 0x8A2800).opacity(0.35), radius: 10, y: 6)
                .contentTransition(.numericText(value: Double(shown)))
                .scaleEffect(punch ? 1.14 : 1)
        }
    }

    private var subtitle: String {
        if to == 1 {
            return String(localized: "One day done. Come back tomorrow and it becomes two.", bundle: .app)
        }
        if milestone {
            return String(localized: "\(to) days without missing one. This is how an interview gets easy.", bundle: .app)
        }
        return String(localized: "One more day in a row. See you tomorrow, same time.", bundle: .app)
    }

    // MARK: La coreografia

    private func run() {
        withAnimation(.spring(duration: 0.65, bounce: 0.4)) { rising = true }
        withAnimation(.linear(duration: 26).repeatForever(autoreverses: false)) { rays = true }
        Task {
            // Prima si vede il numero di ieri, poi gira: è quello il momento che piace.
            try? await Task.sleep(for: .milliseconds(520))
            withAnimation(.spring(duration: 0.5, bounce: 0.45)) {
                shown = to
                punch = true
            }
            confetti = true
            try? await Task.sleep(for: .milliseconds(260))
            withAnimation(.spring(duration: 0.4)) { punch = false }
            withAnimation(.easeOut(duration: 0.4)) { copy = true }
        }
    }
}

/// La settimana sotto il numero, con i giorni fatti accesi: dice a che punto si è.
private struct WeekStrip: View {
    @Environment(AppState.self) private var state

    var body: some View {
        HStack(spacing: 0) {
            ForEach((0..<7).map { Day.today.adding($0 - 6) }, id: \.self) { day in
                let done = state.isCompleted(day)
                VStack(spacing: 6) {
                    Text(day.date.formatted(.dateTime.weekday(.abbreviated).locale(.app)).prefix(1).uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.75))
                    ZStack {
                        Circle().fill(done ? .white : .white.opacity(0.22))
                        if done {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(Color(hex: 0xF5600A))
                        }
                    }
                    .frame(width: 30, height: 30)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// Coriandoli: pezzetti di carta che partono dall'alto e scendono girando.
/// Nessuna libreria, nessun timer: una sola animazione per pezzo.
private struct Confetti: View {
    let running: Bool

    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat          // 0...1 della larghezza
        let delay: Double
        let duration: Double
        let size: CGSize
        let spin: Double
        let drift: CGFloat
        let color: Color
    }

    private static let palette: [Color] = [
        Color(hex: 0xFFFFFF), Color(hex: 0xFFE066), Color(hex: 0xFFB020),
        Color(hex: 0x7F52FF), Color(hex: 0x13B9FD), Color(hex: 0x2FB36B),
    ]

    private let pieces: [Piece] = (0..<46).map { _ in
        Piece(x: .random(in: 0.02...0.98),
              delay: .random(in: 0...0.55),
              duration: .random(in: 1.7...3.1),
              size: CGSize(width: .random(in: 5...10), height: .random(in: 8...15)),
              spin: .random(in: 220...900),
              drift: .random(in: -70...70),
              color: palette.randomElement()!)
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { piece in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(piece.color)
                    .frame(width: piece.size.width, height: piece.size.height)
                    .offset(x: running ? piece.drift : 0,
                            y: running ? geo.size.height + 60 : -60)
                    .rotationEffect(.degrees(running ? piece.spin : 0))
                    .opacity(running ? 1 : 0)
                    .position(x: piece.x * geo.size.width, y: 0)
                    .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: running)
            }
        }
    }
}

#Preview {
    StreakCelebrationView(from: 6, to: 7) {}
        .environment(AppState())
}
