import SwiftUI

enum QuizMode: Hashable {
    case daily
    case topic(Track, String)
    case mistakes
    case practice
}

struct QuizSession: Identifiable, Hashable {
    let id = UUID()
    let mode: QuizMode
    let items: [QuizItem]
    let title: String
}

struct HomeView: View {
    @Environment(AppState.self) private var state
    @State private var session: QuizSession?

    private var theme: Theme { state.activeTrack.theme }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    TrackSwitcher()
                        .padding(.horizontal, -20)
                    StreakCard()
                    RankCard()
                    dailyCard
                    if !state.mistakeItems.isEmpty { mistakesCard }
                    topicsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: Topic.self) { TopicView(track: state.activeTrack, topic: $0) }
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(item: $session) { QuizView(session: $0) }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Ready for today?")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(state.didDailyToday ? Color.flame : .secondary)
                Text("\(state.currentStreak)")
                    .font(.headline.monospacedDigit())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
        }
        .padding(.top, 12)
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        return h < 13 ? String(localized: "Good morning", bundle: .app)
             : h < 18 ? String(localized: "Good afternoon", bundle: .app) : String(localized: "Good evening", bundle: .app)
    }

    // MARK: Quiz del giorno

    private var dailyCard: some View {
        let items = state.dailyItems
        let tracks = Track.allCases.filter { t in items.contains { $0.track == t } }
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Daily quiz", systemImage: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(.app)))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }

            if let result = state.todayResult {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Done! \(result.correct)/\(result.total) correct")
                        .font(.system(.title, design: .rounded).weight(.bold))
                    Text("Come back tomorrow for new questions. Meanwhile you can review.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Button {
                    session = QuizSession(mode: .practice, items: items, title: String(localized: "Today's quiz", bundle: .app))
                } label: {
                    Label("Take it again for practice", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.2), in: Capsule())
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(items.count) questions, about 2 minutes")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    Text("Level \(state.tier.name) · \(tracks.map(\.name).formatted(.list(type: .and).locale(.app)))")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Button {
                    session = QuizSession(mode: .daily, items: items, title: String(localized: "Daily quiz", bundle: .app))
                } label: {
                    HStack {
                        Text("Start")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundStyle(theme.deep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(items.isEmpty)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 26, style: .continuous).fill(theme.linear)
                Image(systemName: state.activeTrack.symbol)
                    .font(.system(size: 120, weight: .bold))
                    .foregroundStyle(.white.opacity(0.1))
                    .rotationEffect(.degrees(-12))
                    .offset(x: 20, y: -10)
                    .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .shadow(color: theme.primary.opacity(0.35), radius: 18, y: 10)
    }

    private var mistakesCard: some View {
        NavigationLink {
            MistakesView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.wrong)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your mistakes")
                        .font(.headline)
                    Text("\(state.mistakeItems.count) to review, with corrections")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(16)
            .card()
        }
        .buttonStyle(.plain)
    }

    // MARK: Il percorso

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Your path")
                        .font(.title2.weight(.bold))
                    Spacer()
                    Text(state.activeTrack.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.primary)
                }
                Text("Topics are in order: each one builds on the one before.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(ContentStore.shared.stages(for: state.activeTrack)) { group in
                VStack(alignment: .leading, spacing: 12) {
                    StageHeader(stage: group.stage, reached: group.stage.tier <= state.tier)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                              spacing: 14) {
                        ForEach(Array(group.topics.enumerated()), id: \.element.id) { i, topic in
                            NavigationLink(value: topic) {
                                TopicTile(track: state.activeTrack, topic: topic,
                                          number: group.firstNumber + i)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

/// L'intestazione di uno stage del percorso: Junior, Mid, Senior.
struct StageHeader: View {
    let stage: Stage
    let reached: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: stage.tier.symbol)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(stage.tier.gradient, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(stage.tier.name)
                    .font(.subheadline.weight(.bold))
                Text(reached ? stage.caption
                             : String(localized: "Enters the daily quiz from the \(stage.tier.name) rank", bundle: .app))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .opacity(reached ? 1 : 0.65)
    }
}

struct TopicTile: View {
    @Environment(AppState.self) private var state
    let track: Track
    let topic: Topic
    /// La posizione nel percorso, continua da 1 fino all'ultimo argomento.
    let number: Int

    var body: some View {
        let stat = state.stat(track, topic.id)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack(alignment: .topLeading) {
                    Image(systemName: topic.icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(track.theme.primary)
                        .frame(width: 42, height: 42)
                        .background(track.theme.soft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Text("\(number)")
                        .font(.caption2.weight(.heavy).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 19, height: 19)
                        .background(track.theme.primary, in: Circle())
                        .overlay {
                            Circle().strokeBorder(Color(.secondarySystemGroupedBackground), lineWidth: 2)
                        }
                        .offset(x: -6, y: -6)
                }
                Spacer()
                ZStack {
                    ProgressRing(progress: Double(stat.bestScore) / 100, color: track.theme.primary, lineWidth: 4)
                    if stat.bestScore == 100 {
                        Image(systemName: "checkmark").font(.caption2.bold()).foregroundStyle(track.theme.primary)
                    }
                }
                .frame(width: 26, height: 26)
            }
            Text(topic.title)
                .font(.headline)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            Text(stat.completedRuns > 0 ? "Best \(stat.bestScore)%"
                 : "\(ContentStore.shared.topicItems(for: track, topic: topic, tier: state.tier).count) questions")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

/// La settimana corrente con i giorni fatti accesi.
struct StreakCard: View {
    @Environment(AppState.self) private var state

    var body: some View {
        let days = (0..<7).map { Day.today.adding($0 - 6) }
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        state.currentStreak > 0
                            ? AnyShapeStyle(LinearGradient(colors: [.yellow, .flame, .red], startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(Color.secondary.opacity(0.4))
                    )
                    .symbolEffect(.bounce, value: state.currentStreak)
                Text("\(state.currentStreak)")
                    .font(.system(.title2, design: .rounded).weight(.heavy).monospacedDigit())
                Text(state.currentStreak == 1 ? "day" : "days")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 64)

            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    let done = state.isCompleted(day)
                    let isToday = day == .today
                    VStack(spacing: 6) {
                        Text(day.date.formatted(.dateTime.weekday(.abbreviated).locale(.app)).prefix(1).uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(isToday ? .primary : .secondary)
                        ZStack {
                            Circle()
                                .fill(done ? AnyShapeStyle(Color.flame) : AnyShapeStyle(Color.secondary.opacity(0.12)))
                            if done {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 30, height: 30)
                        .overlay {
                            if isToday && !done {
                                Circle().strokeBorder(Color.flame, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .card()
    }
}
