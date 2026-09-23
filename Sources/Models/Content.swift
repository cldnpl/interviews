import Foundation

/// Un linguaggio / framework su cui ci si prepara.
enum Track: String, Codable, CaseIterable, Identifiable, Hashable {
    case swift, uikit, kotlin, flutter

    var id: String { rawValue }

    var name: String {
        switch self {
        case .swift: "Swift"
        case .uikit: "UIKit"
        case .kotlin: "Kotlin"
        case .flutter: "Flutter"
        }
    }

    var platform: Platform {
        switch self {
        case .swift, .uikit: .ios
        case .kotlin: .android
        case .flutter: .flutter
        }
    }

    var symbol: String {
        switch self {
        case .swift: "swift"
        case .uikit: "iphone"
        case .kotlin: "k.square.fill"
        case .flutter: "bird.fill"
        }
    }
}

/// Il tipo di sviluppatore scelto in onboarding: ognuno porta con sé uno o più track.
enum Platform: String, Codable, CaseIterable, Identifiable, Hashable {
    case ios, android, flutter

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ios: "iOS"
        case .android: "Android"
        case .flutter: "Flutter"
        }
    }

    var subtitle: String {
        switch self {
        case .ios: "Swift e UIKit"
        case .android: "Kotlin e Jetpack"
        case .flutter: "Dart e widget"
        }
    }

    var symbol: String {
        switch self {
        case .ios: "apple.logo"
        case .android: "smartphone"
        case .flutter: "bird.fill"
        }
    }

    var tracks: [Track] { Track.allCases.filter { $0.platform == self } }
}

struct LessonSection: Codable, Hashable {
    let heading: String
    let body: String
    let code: String?
}

struct Question: Codable, Hashable, Identifiable {
    let id: String
    let prompt: String
    let code: String?
    let options: [String]
    let answer: Int
    let explanation: String
    let difficulty: Int
}

struct Topic: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let icon: String
    let summary: String
    let lesson: [LessonSection]
    let questions: [Question]
}

struct TrackContent: Codable {
    let track: Track
    let topics: [Topic]
}

/// Una domanda con il suo contesto, così il quiz sa di che colore tingerla.
struct QuizItem: Identifiable, Hashable {
    let question: Question
    let track: Track
    let topicID: String
    var id: String { question.id }
}

/// Carica i JSON dei contenuti dal bundle una volta sola.
final class ContentStore {
    static let shared = ContentStore()

    private(set) var byTrack: [Track: [Topic]] = [:]

    private init() {
        for track in Track.allCases {
            guard let url = Bundle.main.url(forResource: track.rawValue, withExtension: "json"),
                  let data = try? Data(contentsOf: url) else { continue }
            do {
                byTrack[track] = try JSONDecoder().decode(TrackContent.self, from: data).topics
            } catch {
                assertionFailure("Contenuto \(track.rawValue) non valido: \(error)")
            }
        }
    }

    func topics(for track: Track) -> [Topic] { byTrack[track] ?? [] }

    func topic(_ id: String, in track: Track) -> Topic? {
        topics(for: track).first { $0.id == id }
    }

    func items(for track: Track, topic: Topic) -> [QuizItem] {
        topic.questions.map { QuizItem(question: $0, track: track, topicID: topic.id) }
    }

    func allItems(for tracks: [Track]) -> [QuizItem] {
        tracks.flatMap { track in topics(for: track).flatMap { items(for: track, topic: $0) } }
    }

    /// Le domande del giorno: stesse per tutta la giornata, diverse ogni giorno,
    /// pescate in modo equo fra i track scelti.
    func dailyItems(for tracks: [Track], day: Day, count: Int = 5) -> [QuizItem] {
        guard !tracks.isEmpty else { return [] }
        var rng = SeededGenerator(seed: UInt64(truncatingIfNeeded: day.ordinal &* 2_654_435_761))
        var pools = tracks.map { allItems(for: [$0]).shuffled(using: &rng) }
        var result: [QuizItem] = []
        var i = 0
        while result.count < count, pools.contains(where: { !$0.isEmpty }) {
            let k = i % pools.count
            if !pools[k].isEmpty { result.append(pools[k].removeFirst()) }
            i += 1
        }
        return result.shuffled(using: &rng)
    }
}

/// SplitMix64: deterministico, così il quiz del giorno non cambia se riapri l'app.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
