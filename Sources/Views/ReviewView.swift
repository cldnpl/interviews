import SwiftUI

/// Sezione Ripasso: tutte le lezioni del linguaggio attivo.
struct ReviewView: View {
    @Environment(AppState.self) private var state
    @State private var paywall: PaywallReason?

    var body: some View {
        let track = state.activeTrack
        // Senza abbonamento il conto è sulle lezioni aperte: "3/9" farebbe credere
        // che le altre sei si possano leggere.
        let topics = ContentStore.shared.topics(for: track)
            .filter { state.isUnlocked($0) }
        let read = state.readLessons(in: track, among: topics)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    TrackSwitcher()
                        .padding(.horizontal, -20)

                    HStack(spacing: 16) {
                        ZStack {
                            ProgressRing(progress: topics.isEmpty ? 0 : Double(read) / Double(topics.count),
                                         color: track.theme.primary, lineWidth: 8)
                            Text("\(read)/\(topics.count)")
                                .font(.headline.monospacedDigit())
                        }
                        .frame(width: 64, height: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(track.name) lessons")
                                .font(.headline)
                            Text(read == topics.count && !topics.isEmpty
                                 ? "You've read them all. Now test yourself with the quizzes."
                                 : "In order, from the fundamentals to senior topics.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    ForEach(ContentStore.shared.stages(for: track)) { group in
                        let open = state.isUnlocked(group.stage)
                        VStack(alignment: .leading, spacing: 12) {
                            StageHeader(stage: group.stage, reached: group.stage.tier <= state.tier)
                                .padding(.top, 6)
                            if !open {
                                LockedStageNote(stage: group.stage) {
                                    paywall = PaywallReason(String(localized: "The \(group.stage.tier.name) lessons of \(track.name) are part of Interviews Pro.", bundle: .app))
                                }
                            }
                            ForEach(Array(group.topics.enumerated()), id: \.element.id) { i, topic in
                                let row = LessonRow(number: group.firstNumber + i, track: track, topic: topic,
                                                    read: state.isLessonRead(track, topic.id), locked: !open)
                                if open {
                                    NavigationLink {
                                        LessonView(track: track, topic: topic)
                                    } label: { row }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        paywall = PaywallReason(String(localized: "The \(group.stage.tier.name) lessons of \(track.name) are part of Interviews Pro.", bundle: .app))
                                    } label: { row }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Review")
            .sheet(item: $paywall) { PremiumSheet(reason: $0.text) }
        }
    }
}

private struct LessonRow: View {
    let number: Int
    let track: Track
    let topic: Topic
    let read: Bool
    var locked = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(read && !locked ? AnyShapeStyle(track.theme.linear) : AnyShapeStyle(track.theme.soft))
                if locked {
                    LockBadge(size: 26)
                } else if read {
                    Image(systemName: "checkmark").font(.headline).foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(track.theme.primary)
                }
            }
            .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(topic.title).font(.headline)
                Text(topic.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(14)
        .card()
        .opacity(locked ? 0.62 : 1)
    }
}

struct LessonView: View {
    @Environment(AppState.self) private var state
    let track: Track
    let topic: Topic

    @State private var session: QuizSession?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TopicHero(track: track, topic: topic)

                ForEach(Array(topic.lesson.enumerated()), id: \.offset) { i, section in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Text("\(i + 1)")
                                .font(.caption.weight(.heavy).monospacedDigit())
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(track.theme.linear, in: Circle())
                            Text(section.heading)
                                .font(.title3.weight(.bold))
                        }
                        RichText(text: section.body)
                            .lineSpacing(3)
                        if let code = section.code, !code.isEmpty {
                            CodeBlock(code: code, track: track, language: section.language)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
                    .onAppear {
                        if i == topic.lesson.count - 1 { state.markLessonRead(track, topic.id) }
                    }
                }

                Button {
                    session = QuizSession(mode: .topic(track, topic.id),
                                          items: ContentStore.shared.topicItems(for: track, topic: topic, tier: state.tier),
                                          title: topic.title)
                } label: {
                    Label("Test yourself", systemImage: "bolt.fill")
                }
                .buttonStyle(PrimaryButtonStyle(gradient: track.theme.linear))
                .padding(.top, 6)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $session) { QuizView(session: $0) }
    }
}
