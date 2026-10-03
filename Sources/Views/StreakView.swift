import Charts
import SwiftUI

/// Il dettaglio dello streak: si apre dalla fiammella in alto a destra in home.
/// Risponde a tre domande — da quanti giorni vado avanti, quali giorni ho
/// saltato, e quanto sto imparando — e a nient'altro.
struct StreakView: View {
    @Environment(AppState.self) private var state

    /// Quanti giorni mostra il grafico. Due settimane: abbastanza da vedere
    /// un ritmo, poche abbastanza da leggere le barre su un telefono.
    private let window = 14

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero
                numbers
                calendar
                chart
                accuracy
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text("Your streak"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: La fiamma

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .font(.system(size: 76))
                .foregroundStyle(
                    state.currentStreak > 0
                        ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFFE07A), .flame, Color(hex: 0xE23B16)],
                                                       startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(Color.secondary.opacity(0.35))
                )
                .shadow(color: .flame.opacity(state.currentStreak > 0 ? 0.3 : 0), radius: 16, y: 8)

            Text("\(state.currentStreak)")
                .font(.system(size: 54, weight: .black, design: .rounded).monospacedDigit())
                .contentTransition(.numericText(value: Double(state.currentStreak)))

            Text(state.currentStreak == 1 ? "day in a row" : "days in a row")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(headline)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .card()
    }

    /// La riga sotto al numero: dice che cosa manca, non si limita a complimentarsi.
    private var headline: String {
        if state.currentStreak == 0 {
            return String(localized: "Do today's quiz and the streak starts again.", bundle: .app)
        }
        if state.didDailyToday {
            return String(localized: "Today is done. Come back tomorrow and it becomes \(state.currentStreak + 1).", bundle: .app)
        }
        return String(localized: "Today is still missing: do the quiz before midnight and the streak holds.", bundle: .app)
    }

    // MARK: I tre numeri

    private var numbers: some View {
        HStack(spacing: 12) {
            StreakStat(symbol: "trophy.fill", tint: Color(hex: 0xE3A400),
                       value: "\(state.bestStreak)", caption: String(localized: "Best streak", bundle: .app))
            StreakStat(symbol: "calendar", tint: .flame,
                       value: "\(state.activeDays)", caption: String(localized: "Days done", bundle: .app))
            StreakStat(symbol: "checkmark.seal.fill", tint: .correct,
                       value: "\(state.perfectDays)", caption: String(localized: "All correct", bundle: .app))
        }
    }

    // MARK: Il calendario

    /// Le ultime cinque settimane, allineate ai giorni della settimana come un
    /// calendario vero: a colpo d'occhio si vede quali giorni si saltano sempre.
    private var calendar: some View {
        let weeks = Self.recentWeeks()
        return VStack(alignment: .leading, spacing: 14) {
            Text("The last five weeks")
                .font(.headline)

            // Le iniziali vengono dalla prima riga: così seguono la lingua
            // dell'app e il giorno da cui comincia la settimana.
            HStack(spacing: 6) {
                ForEach(weeks[0], id: \.self) { day in
                    Text(day.date.formatted(.dateTime.weekday(.abbreviated).locale(.app)).prefix(1).uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 6) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 6) {
                        ForEach(week, id: \.self) { day in
                            DayCell(day: day, done: state.isCompleted(day))
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    /// Cinque settimane che finiscono con quella corrente, allineate al primo
    /// giorno della settimana secondo il calendario dell'utente.
    private static func recentWeeks() -> [[Day]] {
        let cal = Foundation.Calendar.current
        let weekday = cal.component(.weekday, from: .now)
        // Quanti giorni sono passati dall'inizio di questa settimana.
        let offset = (weekday - cal.firstWeekday + 7) % 7
        let start = Day.today.adding(-offset - 7 * 4)
        return (0..<5).map { w in (0..<7).map { d in start.adding(w * 7 + d) } }
    }

    // MARK: Il grafico

    private var chart: some View {
        let days = (0..<window).map { Day.today.adding($0 - (window - 1)) }
        let week = days.suffix(7).reduce(0) { $0 + state.xp(on: $1) }
        let best = days.map { state.xp(on: $0) }.max() ?? 0

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("XP per day")
                    .font(.headline)
                Spacer()
                Text("\(week.formatted(.number.locale(.app))) XP this week")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(state.rank.tier.color)
            }

            if best == 0 {
                Text("Nothing here yet. Every quiz you do adds a bar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(days, id: \.self) { day in
                    BarMark(
                        x: .value(String(localized: "Day", bundle: .app), day.date, unit: .day),
                        y: .value(String(localized: "XP", bundle: .app), state.xp(on: day))
                    )
                    .foregroundStyle(day == .today ? AnyShapeStyle(Color.flame)
                                                   : AnyShapeStyle(state.rank.tier.color.opacity(0.55)))
                    .cornerRadius(5)
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) {
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    // Una etichetta ogni tre giorni: con quattordici barre
                    // scriverle tutte le rende illeggibili.
                    AxisMarks(values: .stride(by: .day, count: 3)) { value in
                        AxisValueLabel(format: .dateTime.day().month(.narrow).locale(.app))
                    }
                }
                .frame(height: 150)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    // MARK: Com'è andata

    private var accuracy: some View {
        VStack(spacing: 0) {
            StreakRow(symbol: "target", tint: .correct,
                      title: String(localized: "Right answers", bundle: .app),
                      value: "\(state.accuracy)%")
            Divider().padding(.leading, 52)
            StreakRow(symbol: "questionmark.circle.fill", tint: state.activeTrack.theme.primary,
                      title: String(localized: "Questions answered", bundle: .app),
                      value: state.totalAnswered.formatted(.number.locale(.app)))
            Divider().padding(.leading, 52)
            StreakRow(symbol: "bolt.fill", tint: state.rank.tier.color,
                      title: String(localized: "Total XP", bundle: .app),
                      value: state.xp.formatted(.number.locale(.app)))
        }
        .padding(.vertical, 4)
        .card()
    }
}

/// Un giorno nel calendario: pieno se fatto, vuoto se saltato, tratteggiato se
/// è oggi e manca ancora, e sbiadito se non è ancora arrivato.
private struct DayCell: View {
    let day: Day
    let done: Bool

    private var isToday: Bool { day == .today }
    private var future: Bool { day > .today }

    var body: some View {
        ZStack {
            Circle()
                .fill(done ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFFB020), .flame],
                                                          startPoint: .top, endPoint: .bottom))
                           : AnyShapeStyle(Color.secondary.opacity(0.12)))
            if done {
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.white)
            } else {
                Text("\(day.day)")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 34)
        .frame(maxWidth: .infinity)
        .overlay {
            if isToday && !done {
                Circle().strokeBorder(Color.flame, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            }
        }
        .opacity(future ? 0.3 : 1)
    }
}

private struct StreakStat: View {
    let symbol: String
    let tint: Color
    let value: String
    let caption: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.heavy).monospacedDigit())
            Text(caption)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .card()
    }
}

private struct StreakRow: View {
    let symbol: String
    let tint: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(title)
                .font(.subheadline)
            Spacer(minLength: 0)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

/// La fiammella in alto a destra nella home: dice a che punto è lo streak,
/// e si tocca per aprirne il dettaglio.
struct StreakPill: View {
    @Environment(AppState.self) private var state

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(state.didDailyToday ? Color.flame : .secondary)
                .symbolEffect(.bounce, value: state.currentStreak)
            Text("\(state.currentStreak)")
                .font(.headline.monospacedDigit())
                .contentTransition(.numericText(value: Double(state.currentStreak)))
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
        .padding(.leading, 12)
        .padding(.trailing, 9)
        .padding(.vertical, 7)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
        .accessibilityLabel(Text("Streak: \(state.currentStreak) days"))
    }
}

#Preview {
    NavigationStack { StreakView() }
        .environment(AppState())
}
