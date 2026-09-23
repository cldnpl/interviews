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
}

@Observable
final class AppState {
    private(set) var saved: SavedState {
        didSet { persist() }
    }

    private static let key = "pronto.state.v1"
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

    var platforms: Set<Platform> { Set(tracks.map(\.platform)) }

    func completeOnboarding(platforms: Set<Platform>, reminderEnabled: Bool, hour: Int, minute: Int) {
        let chosen = Track.allCases.filter { platforms.contains($0.platform) }
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

    var dailyItems: [QuizItem] { ContentStore.shared.dailyItems(for: tracks, day: .today) }

    // MARK: Risultati

    func record(_ item: QuizItem, correct: Bool) {
        let key = "\(item.track.rawValue)/\(item.topicID)"
        var stat = saved.topicStats[key] ?? TopicStat()
        stat.answered += 1
        if correct { stat.correct += 1 }
        saved.topicStats[key] = stat
        saved.totalAnswered += 1
        if correct {
            saved.totalCorrect += 1
            saved.mistakes.remove(item.id)
        } else {
            saved.mistakes.insert(item.id)
        }
    }

    func finishTopicQuiz(track: Track, topicID: String, correct: Int, total: Int) {
        let key = "\(track.rawValue)/\(topicID)"
        var stat = saved.topicStats[key] ?? TopicStat()
        stat.completedRuns += 1
        stat.bestScore = max(stat.bestScore, total == 0 ? 0 : correct * 100 / total)
        saved.topicStats[key] = stat
    }

    func finishDaily(correct: Int, total: Int) {
        saved.dailyResults[Day.today.description] = DailyResult(correct: correct, total: total)
        saved.completedDays.insert(.today)
        saved.bestStreak = max(saved.bestStreak, currentStreak)
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
    }

    #if DEBUG
    func restartOnboarding() { saved.hasOnboarded = false }
    #endif
}
