import Foundation
import Observation

struct TopicStat: Codable, Hashable {
    var answered = 0
    var correct = 0
    var bestScore = 0      // miglior percentuale in un quiz completo
    var completedRuns = 0
}

struct DailyResult: Codable, Hashable {
    var correct: Int
    var total: Int
}

/// Tutto ciò che va salvato fra un avvio e l'altro.
struct SavedState: Codable {
    var hasOnboarded = false
    var enabledTracks: [Track] = []
    var activeTrack: Track = .swift
    var completedDays: Set<Day> = []
    var bestStreak = 0
    var dailyResults: [String: DailyResult] = [:]
    var topicStats: [String: TopicStat] = [:]
    var lessonsRead: Set<String> = []
    var mistakes: Set<String> = []
    var totalAnswered = 0
    var totalCorrect = 0
    var reminderEnabled = true
    var reminderHour = 19
    var reminderMinute = 0
    var startingTier: Tier = .junior
    var xp = 0
    /// Domande già indovinate almeno una volta: danno XP pieni solo la prima volta.
    var mastered: Set<String> = []
    /// Per ogni domanda sbagliata, l'ultima risposta data: serve a mostrare la correzione.
    var wrongChoices: [String: Int] = [:]

    init() {}

    /// Decodifica tollerante: i campi aggiunti nelle versioni nuove prendono il default
    /// invece di far buttare via tutto il salvataggio (streak compreso).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = SavedState()
        func v<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? c.decodeIfPresent(T.self, forKey: key)) ?? fallback
        }
        hasOnboarded = v(.hasOnboarded, d.hasOnboarded)
        enabledTracks = v(.enabledTracks, d.enabledTracks)
        activeTrack = v(.activeTrack, d.activeTrack)
        completedDays = v(.completedDays, d.completedDays)
        bestStreak = v(.bestStreak, d.bestStreak)
        dailyResults = v(.dailyResults, d.dailyResults)
        topicStats = v(.topicStats, d.topicStats)
        lessonsRead = v(.lessonsRead, d.lessonsRead)
        mistakes = v(.mistakes, d.mistakes)
        totalAnswered = v(.totalAnswered, d.totalAnswered)
        totalCorrect = v(.totalCorrect, d.totalCorrect)
        reminderEnabled = v(.reminderEnabled, d.reminderEnabled)
        reminderHour = v(.reminderHour, d.reminderHour)
        reminderMinute = v(.reminderMinute, d.reminderMinute)
        startingTier = v(.startingTier, d.startingTier)
        xp = v(.xp, d.xp)
        mastered = v(.mastered, d.mastered)
        wrongChoices = v(.wrongChoices, d.wrongChoices)
    }
}

@Observable
final class AppState {
    private(set) var saved: SavedState {
        didSet { persist() }
    }

    private static let key = "interviews.state.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key),
           let s = try? JSONDecoder().decode(SavedState.self, from: data) {
            saved = s
        } else {
            saved = SavedState()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(saved) { defaults.set(data, forKey: Self.key) }
    }

    // MARK: Profilo

    var hasOnboarded: Bool { saved.hasOnboarded }
    var tracks: [Track] { saved.enabledTracks }

    var activeTrack: Track {
        get { tracks.contains(saved.activeTrack) ? saved.activeTrack : (tracks.first ?? .swift) }
        set { saved.activeTrack = newValue }
    }

    func completeOnboarding(tracks: Set<Track>, tier: Tier, reminderEnabled: Bool, hour: Int, minute: Int) {
        // L'ordine è sempre quello di Track.allCases, non quello in cui li hai toccati.
        let chosen = Track.allCases.filter { tracks.contains($0) }
        saved.startingTier = tier
        // Chi dichiara di essere Mid o Senior parte dal primo gradino di quella fascia.
        saved.xp = max(saved.xp, Rank.start(of: tier).minXP)
        saved.enabledTracks = chosen
        saved.activeTrack = chosen.first ?? .swift
        saved.reminderEnabled = reminderEnabled
        saved.reminderHour = hour
        saved.reminderMinute = minute
        saved.hasOnboarded = true
    }

    func setTrack(_ track: Track, enabled: Bool) {
        var t = Set(saved.enabledTracks)
        if enabled { t.insert(track) } else if t.count > 1 { t.remove(track) }
        saved.enabledTracks = Track.allCases.filter { t.contains($0) }
    }

    // MARK: Promemoria

    var reminderEnabled: Bool {
        get { saved.reminderEnabled }
        set { saved.reminderEnabled = newValue }
    }

    var reminderTime: Date {
        get { Calendar.current.date(from: DateComponents(hour: saved.reminderHour, minute: saved.reminderMinute)) ?? .now }
        set {
            let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            saved.reminderHour = c.hour ?? 19
            saved.reminderMinute = c.minute ?? 0
        }
    }

    var reminderHour: Int { saved.reminderHour }
    var reminderMinute: Int { saved.reminderMinute }

    // MARK: Streak

    var didDailyToday: Bool { saved.completedDays.contains(.today) }

    /// Giorni consecutivi fino a oggi. Se oggi non hai ancora giocato lo streak
    /// di ieri resta vivo fino a mezzanotte.
    var currentStreak: Int {
        var day = didDailyToday ? Day.today : Day.today.adding(-1)
        var n = 0
        while saved.completedDays.contains(day) {
            n += 1
            day = day.adding(-1)
        }
        return n
    }

    var bestStreak: Int { max(saved.bestStreak, currentStreak) }

    func isCompleted(_ day: Day) -> Bool { saved.completedDays.contains(day) }

    var todayResult: DailyResult? { saved.dailyResults[Day.today.description] }

    var dailyItems: [QuizItem] { ContentStore.shared.dailyItems(for: tracks, tier: tier, day: .today) }

    // MARK: XP e gradi

    var xp: Int { saved.xp }
    var rank: Rank { Rank.forXP(saved.xp) }
    var tier: Tier { rank.tier }

    /// Avanzamento verso il grado successivo, da 0 a 1.
    var rankProgress: Double {
        guard let next = rank.next else { return 1 }
        return Double(saved.xp - rank.minXP) / Double(next.minXP - rank.minXP)
    }

    var xpToNextRank: Int? { rank.next.map { $0.minXP - saved.xp } }

    private func addXP(_ amount: Int) { saved.xp += amount }

    // MARK: Risultati

    /// Registra una risposta e restituisce gli XP guadagnati.
    @discardableResult
    func record(_ item: QuizItem, choice: Int, awardsXP: Bool = true) -> Int {
        let correct = choice == item.question.answer
        let key = "\(item.track.rawValue)/\(item.topicID)"
        var stat = saved.topicStats[key] ?? TopicStat()
        stat.answered += 1
        if correct { stat.correct += 1 }
        saved.topicStats[key] = stat
        saved.totalAnswered += 1
        guard correct else {
            saved.mistakes.insert(item.id)
            saved.wrongChoices[item.id] = choice
            return 0
        }
        saved.totalCorrect += 1
        saved.mistakes.remove(item.id)
        saved.wrongChoices[item.id] = nil
        let firstTime = !saved.mastered.contains(item.id)
        saved.mastered.insert(item.id)
        guard awardsXP else { return 0 }
        let gained = XP.forCorrect(difficulty: item.question.difficulty, firstTime: firstTime)
        addXP(gained)
        return gained
    }

    /// Restituisce il bonus XP del quiz.
    func finishTopicQuiz(track: Track, topicID: String, correct: Int, total: Int) -> Int {
        let key = "\(track.rawValue)/\(topicID)"
        var stat = saved.topicStats[key] ?? TopicStat()
        let score = total == 0 ? 0 : correct * 100 / total
        // Il bonus arriva solo quando si migliora il proprio record oltre l'80%.
        let bonus = score >= 80 && score > stat.bestScore ? XP.topicPassBonus : 0
        stat.completedRuns += 1
        stat.bestScore = max(stat.bestScore, score)
        saved.topicStats[key] = stat
        addXP(bonus)
        return bonus
    }

    /// Restituisce il bonus XP del quiz del giorno (zero se era già stato fatto oggi).
    func finishDaily(correct: Int, total: Int) -> Int {
        guard !didDailyToday else { return 0 }
        saved.dailyResults[Day.today.description] = DailyResult(correct: correct, total: total)
        saved.completedDays.insert(.today)
        saved.bestStreak = max(saved.bestStreak, currentStreak)
        let bonus = XP.dailyBonus + (correct == total ? XP.perfectBonus : 0) + XP.streakBonus(currentStreak)
        addXP(bonus)
        return bonus
    }

    func stat(_ track: Track, _ topicID: String) -> TopicStat {
        saved.topicStats["\(track.rawValue)/\(topicID)"] ?? TopicStat()
    }

    var totalAnswered: Int { saved.totalAnswered }

    var accuracy: Int {
        saved.totalAnswered == 0 ? 0 : saved.totalCorrect * 100 / saved.totalAnswered
    }

    // MARK: Lezioni ed errori

    func isLessonRead(_ track: Track, _ topicID: String) -> Bool {
        saved.lessonsRead.contains("\(track.rawValue)/\(topicID)")
    }

    func markLessonRead(_ track: Track, _ topicID: String) {
        saved.lessonsRead.insert("\(track.rawValue)/\(topicID)")
    }

    func lessonsRead(in track: Track) -> Int {
        saved.lessonsRead.filter { $0.hasPrefix(track.rawValue + "/") }.count
    }

    func wrongChoice(for item: QuizItem) -> Int? { saved.wrongChoices[item.id] }

    var mistakeItems: [QuizItem] {
        ContentStore.shared.allItems(for: tracks).filter { saved.mistakes.contains($0.id) }
    }

    func resetProgress() {
        let keep = saved
        saved = SavedState()
        saved.hasOnboarded = true
        saved.enabledTracks = keep.enabledTracks
        saved.activeTrack = keep.activeTrack
        saved.reminderEnabled = keep.reminderEnabled
        saved.reminderHour = keep.reminderHour
        saved.reminderMinute = keep.reminderMinute
        saved.startingTier = keep.startingTier
        saved.xp = Rank.start(of: keep.startingTier).minXP
    }

    #if DEBUG
    func restartOnboarding() { saved.hasOnboarded = false }
    #endif
}
