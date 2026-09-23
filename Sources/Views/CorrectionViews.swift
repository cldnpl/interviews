import SwiftUI

/// La correzione di un errore: cosa hai risposto e perché non va, poi la risposta giusta e perché.
struct CorrectionBody: View {
    let item: QuizItem
    let chosen: Int?

    private var question: Question { item.question }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let chosen, chosen != question.answer, question.options.indices.contains(chosen) {
                AnswerBlock(
                    label: "Hai risposto",
                    answer: question.options[chosen],
                    reason: question.whyWrong(chosen),
                    color: .wrong,
                    symbol: "xmark.circle.fill"
                )
            }
            AnswerBlock(
                label: "La risposta giusta",
                answer: question.options[question.answer],
                reason: question.explanation,
                color: .correct,
                symbol: "checkmark.circle.fill"
            )
        }
    }
}

private struct AnswerBlock: View {
    let label: String
    let answer: String
    let reason: String?
    let color: Color
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Capsule()
                .fill(color)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 6) {
                Label(label, systemImage: symbol)
                    .font(.caption.weight(.heavy))
                    .textCase(.uppercase)
                    .foregroundStyle(color)
                RichText(text: answer, font: .subheadline.weight(.semibold))
                if let reason, !reason.isEmpty {
                    RichText(text: reason, font: .callout)
                        .foregroundStyle(.primary.opacity(0.8))
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Una domanda sbagliata con la sua correzione, per il ripasso degli errori.
struct CorrectionCard: View {
    let item: QuizItem
    let chosen: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                TrackChip(track: item.track)
                Spacer()
                DifficultyDots(level: item.question.difficulty, color: item.track.theme.primary)
            }
            RichText(text: item.question.prompt, font: .headline)
            if let code = item.question.code, !code.isEmpty {
                CodeBlock(code: code, track: item.track)
            }
            CorrectionBody(item: item, chosen: chosen)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

/// Le correzioni degli errori fatti in un singolo quiz, dalla schermata dei risultati.
struct SessionCorrectionsView: View {
    @Environment(\.dismiss) private var dismiss
    let mistakes: [QuizMistake]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(mistakes) { CorrectionCard(item: $0.item, chosen: $0.chosen) }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Le tue correzioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fatto") { dismiss() }
                }
            }
        }
    }
}

struct QuizMistake: Identifiable, Hashable {
    let item: QuizItem
    let chosen: Int
    var id: String { item.id }
}

/// Tutti gli errori ancora da sistemare, con la correzione di ciascuno.
struct MistakesView: View {
    @Environment(AppState.self) private var state
    @State private var session: QuizSession?

    var body: some View {
        let items = state.mistakeItems
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if items.isEmpty {
                    ContentUnavailableView("Nessun errore da ripassare",
                                           systemImage: "checkmark.seal.fill",
                                           description: Text("Quando sbagli una domanda la trovi qui, con la correzione."))
                        .padding(.top, 60)
                } else {
                    Text("Leggi le correzioni, poi riprova: quando rispondi giusto l'errore sparisce da qui.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ForEach(items) { CorrectionCard(item: $0, chosen: state.wrongChoice(for: $0)) }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("I tuoi errori")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if !items.isEmpty {
                Button {
                    session = QuizSession(mode: .mistakes, items: Array(items.shuffled().prefix(10)), title: "I tuoi errori")
                } label: {
                    Label("Riprova \(min(items.count, 10)) errori", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(PrimaryButtonStyle(gradient: state.activeTrack.theme.linear))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground).opacity(0.95))
            }
        }
        .fullScreenCover(item: $session) { QuizView(session: $0) }
    }
}
