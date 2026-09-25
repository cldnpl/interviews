import SwiftUI

/// La scheda di un argomento: da qui si studia la lezione o si fa il quiz.
struct TopicView: View {
    @Environment(AppState.self) private var state
    let track: Track
    let topic: Topic

    @State private var session: QuizSession?

    private var theme: Theme { track.theme }

    var body: some View {
        let stat = state.stat(track, topic.id)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TopicHero(track: track, topic: topic)

                HStack(spacing: 12) {
                    StatBox(value: "\(stat.bestScore)%", label: "Best", color: theme.primary)
                    StatBox(value: "\(stat.completedRuns)", label: "Quizzes taken", color: theme.primary)
                    StatBox(value: state.isLessonRead(track, topic.id) ? String(localized: "Yes", bundle: .app) : String(localized: "No", bundle: .app), label: "Lesson read", color: theme.primary)
                }

                NavigationLink {
                    LessonView(track: track, topic: topic)
                } label: {
                    ActionRow(icon: "book.fill", title: "Study the lesson",
                              subtitle: "\(topic.lesson.count) cards, about \(max(2, topic.lesson.count)) minutes", theme: theme)
                }
                .buttonStyle(.plain)

                Button {
                    session = QuizSession(mode: .topic(track, topic.id),
                                          items: ContentStore.shared.topicItems(for: track, topic: topic, tier: state.tier),
                                          title: topic.title)
                } label: {
                    ActionRow(icon: "bolt.fill", title: "Take the quiz",
                              subtitle: "\(ContentStore.shared.topicItems(for: track, topic: topic, tier: state.tier).count) questions for the \(state.tier.name) level", theme: theme)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .fullScreenCover(item: $session) { QuizView(session: $0) }
    }
}

struct TopicHero: View {
    let track: Track
    let topic: Topic

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: topic.icon)
                    .font(.title.weight(.semibold))
                    .frame(width: 60, height: 60)
                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                Spacer()
                Text(track.name)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.2), in: Capsule())
            }
            Text(topic.title)
                .font(.system(.title, design: .rounded).weight(.bold))
            Text(topic.summary)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(track.theme.linear, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: track.theme.primary.opacity(0.3), radius: 16, y: 8)
    }
}

struct StatBox: View {
    let value: String
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .card()
    }
}

struct ActionRow: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let theme: Theme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(theme.linear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(16)
        .card()
    }
}
