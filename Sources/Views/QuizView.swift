import SwiftUI

struct QuizView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    let session: QuizSession

    @State private var index = 0
    @State private var selected: Int?
    @State private var correctCount = 0
    @State private var finished = false
    @State private var streakBefore = 0

    private var item: QuizItem { session.items[index] }
    private var theme: Theme { item.track.theme }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if finished {
                QuizResultView(session: session, correct: correctCount, streakBefore: streakBefore) { dismiss() }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            } else if !session.items.isEmpty {
                quiz
            }
        }
        .animation(.snappy, value: finished)
        .onAppear { streakBefore = state.currentStreak }
    }

    private var quiz: some View {
        VStack(spacing: 0) {
            topBar
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            TrackChip(track: item.track)
                            Spacer()
                            DifficultyDots(level: item.question.difficulty, color: theme.primary)
                        }
                        RichText(text: item.question.prompt, font: .title3.weight(.semibold))
                        if let code = item.question.code, !code.isEmpty {
                            CodeBlock(code: code, track: item.track)
                        }
                        VStack(spacing: 12) {
                            ForEach(Array(item.question.options.enumerated()), id: \.offset) { i, option in
                                OptionButton(text: option, letter: ["A", "B", "C", "D"][i % 4],
                                             state: optionState(i), theme: theme) { choose(i) }
                            }
                        }
                        if selected != nil { explanation.id("explanation") }
                    }
                    .padding(20)
                    .id(index)
                    .background(alignment: .top) { Color.clear.frame(height: 1).id("top") }
                    // La domanda vecchia sparisce subito, la nuova entra da destra: niente sovrapposizioni.
                    .transition(.asymmetric(insertion: .offset(x: 60).combined(with: .opacity),
                                            removal: .opacity.animation(.linear(duration: 0.08))))
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom) {
                    if selected != nil {
                        Button(index + 1 < session.items.count ? "Continua" : "Vedi il risultato") { next() }
                            .buttonStyle(PrimaryButtonStyle(gradient: theme.linear))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(.systemGroupedBackground).opacity(0.95))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .onChange(of: selected) { _, new in
                    guard new != nil else { return }
                    Task {
                        try? await Task.sleep(for: .milliseconds(250))
                        withAnimation(.snappy) { proxy.scrollTo("explanation", anchor: .bottom) }
                    }
                }
                .onChange(of: index) { _, _ in proxy.scrollTo("top", anchor: .top) }
            }
        }
        .animation(.snappy, value: selected)
        .animation(.snappy, value: index)
        .sensoryFeedback(trigger: selected) { _, new in
            guard let new else { return nil }
            return new == item.question.answer ? .success : .error
        }
    }

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(.thinMaterial, in: Circle())
                }
                .foregroundStyle(.primary)
                Spacer()
                Text(session.title).font(.headline)
                Spacer()
                Text("\(index + 1)/\(session.items.count)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 36)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.primary.opacity(0.15))
                    Capsule().fill(theme.linear)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var progress: CGFloat {
        CGFloat(index + (selected == nil ? 0 : 1)) / CGFloat(max(session.items.count, 1))
    }

    private var explanation: some View {
        let right = selected == item.question.answer
        return VStack(alignment: .leading, spacing: 8) {
            Label(right ? "Esatto!" : "Non proprio", systemImage: right ? "checkmark.seal.fill" : "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(right ? Color.correct : Color.flame)
            RichText(text: item.question.explanation, font: .callout)
                .foregroundStyle(.primary.opacity(0.85))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((right ? Color.correct : Color.flame).opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func optionState(_ i: Int) -> OptionButton.State {
        guard let selected else { return .idle }
        if i == item.question.answer { return .correct }
        if i == selected { return .wrong }
        return .dimmed
    }

    private func choose(_ i: Int) {
        guard selected == nil else { return }
        selected = i
        let right = i == item.question.answer
        if right { correctCount += 1 }
        state.record(item, correct: right)
    }

    private func next() {
        if index + 1 < session.items.count {
            selected = nil
            index += 1
        } else {
            complete()
        }
    }

    private func complete() {
        switch session.mode {
        case .daily:
            state.finishDaily(correct: correctCount, total: session.items.count)
            Task { await Reminders.reschedule(for: state) }
        case .topic(let track, let topicID):
            state.finishTopicQuiz(track: track, topicID: topicID, correct: correctCount, total: session.items.count)
        case .mistakes, .practice:
            break
        }
        finished = true
    }
}

struct OptionButton: View {
    enum State { case idle, correct, wrong, dimmed }

    let text: String
    let letter: String
    let state: State
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(badgeFill)
                    switch state {
                    case .correct: Image(systemName: "checkmark").font(.subheadline.bold()).foregroundStyle(.white)
                    case .wrong: Image(systemName: "xmark").font(.subheadline.bold()).foregroundStyle(.white)
                    default: Text(letter).font(.subheadline.bold()).foregroundStyle(theme.primary)
                    }
                }
                .frame(width: 32, height: 32)
                RichText(text: text, font: .body.weight(.medium))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(border, lineWidth: 2)
            }
            .opacity(state == .dimmed ? 0.5 : 1)
            .scaleEffect(state == .correct ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(state == .idle)
    }

    private var badgeFill: Color {
        switch state {
        case .correct: .correct
        case .wrong: .wrong
        default: theme.soft
        }
    }

    private var background: Color {
        switch state {
        case .correct: Color.correct.opacity(0.12)
        case .wrong: Color.wrong.opacity(0.1)
        default: Color(.secondarySystemGroupedBackground)
        }
    }

    private var border: Color {
        switch state {
        case .correct: .correct
        case .wrong: .wrong
        default: .clear
        }
    }
}

struct QuizResultView: View {
    @Environment(AppState.self) private var state
    let session: QuizSession
    let correct: Int
    let streakBefore: Int
    let onDone: () -> Void

    @State private var appeared = false

    private var total: Int { session.items.count }
    private var ratio: Double { total == 0 ? 0 : Double(correct) / Double(total) }
    private var theme: Theme { (session.items.first?.track ?? state.activeTrack).theme }
    private var isDaily: Bool { session.mode == .daily }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            if isDaily {
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 96))
                        .foregroundStyle(LinearGradient(colors: [.yellow, .flame, .red], startPoint: .top, endPoint: .bottom))
                        .symbolEffect(.bounce, value: appeared)
                        .scaleEffect(appeared ? 1 : 0.4)
                    Text("\(state.currentStreak)")
                        .font(.system(size: 64, weight: .heavy, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText(value: Double(state.currentStreak)))
                    Text(state.currentStreak > streakBefore ? "Streak allungato! Ci vediamo domani." : "Giorni di fila")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            ZStack {
                ProgressRing(progress: appeared ? ratio : 0, color: theme.primary, lineWidth: 14)
                VStack(spacing: 2) {
                    Text("\(correct)/\(total)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                    Text("giuste").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .frame(width: isDaily ? 150 : 190, height: isDaily ? 150 : 190)

            Text(message)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()
            Button("Fine", action: onDone)
                .buttonStyle(PrimaryButtonStyle(gradient: theme.linear))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
        .onAppear {
            withAnimation(.spring(duration: 1.0, bounce: 0.35).delay(0.15)) { appeared = true }
        }
        .sensoryFeedback(.success, trigger: appeared)
    }

    private var message: String {
        switch ratio {
        case 1: "Perfetto. Il colloquio è tuo 🎉"
        case 0.8...: "Ottimo lavoro, quasi senza sbavature."
        case 0.5...: "Buona base. Un ripasso e ci sei."
        default: "Nessun problema: le lezioni sono lì apposta."
        }
    }
}
