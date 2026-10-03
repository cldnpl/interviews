import Foundation

/// Un percorso di preparazione. Ognuno è a sé: Swift e UIKit sono due
/// percorsi distinti, non due facce dello stesso "iOS".
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

    /// Una riga sotto il nome: che cos'è questa cosa, in parole povere.
    /// "Il linguaggio" non diceva niente a chi non sa già che Swift è un linguaggio.
    var subtitle: String {
        switch self {
        case .swift: String(localized: "The language of iPhone apps", bundle: .app)
        case .uikit: String(localized: "The classic way to build iPhone screens", bundle: .app)
        case .kotlin: String(localized: "The language of Android apps", bundle: .app)
        case .flutter: String(localized: "One app for Android and iPhone together", bundle: .app)
        }
    }

    /// Una riga brevissima da mettere accanto al nome, dove non c'è spazio per il sottotitolo.
    var tag: String {
        switch self {
        case .swift: String(localized: "Language · iPhone", bundle: .app)
        case .uikit: String(localized: "Interfaces · iPhone", bundle: .app)
        case .kotlin: String(localized: "Language · Android", bundle: .app)
        case .flutter: String(localized: "Both · Android and iPhone", bundle: .app)
        }
    }

    /// Che cos'è e che cosa si studia: la spiegazione lunga, per la scelta in onboarding.
    var blurb: String {
        switch self {
        case .swift:
            String(localized: "A programming language made by Apple in 2014. Every app on the iPhone is written in it, and it took the place of the older Objective-C. You study: optionals, value and reference types, protocols and generics, closures, how memory is freed (ARC) and how to do two things at once (async/await).", bundle: .app)
        case .uikit:
            String(localized: "The toolbox that draws the screens of an iPhone app: buttons, lists, the passage from one screen to the next. It has been there since the first iPhone in 2008, so most apps already on the App Store use it. SwiftUI is the newer toolbox that is slowly taking its place, but interviews still ask about this one. You study: the life of a screen, Auto Layout, long lists, navigation and the common ways of organising the code.", bundle: .app)
        case .kotlin:
            String(localized: "A programming language made by JetBrains, and since 2017 the one Google recommends for Android apps. It took the place of Java, which is why interviewers compare the two. You study: avoiding the null crash, coroutines for work that takes time, data classes, collections, and the life of an Android screen with Jetpack.", bundle: .app)
        case .flutter:
            String(localized: "A toolbox made by Google to write the app once and run it on both Android and iPhone. The language it uses is called Dart. You study: widgets and state, Dart and its asynchronous code, isolates for heavy work, how to organise a project, how to call native code and how to publish.", bundle: .app)
        }
    }

    /// Il simbolo di sistema più vicino, per i posti dove serve un `Image(systemName:)`
    /// e non si può disegnare una forma (le notifiche, per esempio).
    /// Nell'interfaccia si usa `TrackMark`, che disegna i marchi veri.
    var symbol: String {
        switch self {
        case .swift: "swift"
        case .uikit: "square.on.square"
        case .kotlin: "chevron.right.square.fill"
        case .flutter: "square.stack.3d.up.fill"
        }
    }
}

struct LessonSection: Codable, Hashable {
    let heading: String
    let body: String
    let code: String?
    /// L'etichetta del blocco di codice quando non è il linguaggio del track
    /// (uno snippet Swift o Kotlin dentro una lezione Flutter, una shell, un albero di cartelle).
    let language: String?
}

struct Question: Codable, Hashable, Identifiable {
    let id: String
    let prompt: String
    let code: String?
    let options: [String]
    let answer: Int
    let explanation: String
    let difficulty: Int
    /// Per ogni opzione, perché è sbagliata (nil sulla risposta giusta).
    let whyWrong: [String?]?

    func whyWrong(_ option: Int) -> String? {
        guard let whyWrong, whyWrong.indices.contains(option) else { return nil }
        return whyWrong[option]
    }
}

/// A che punto del percorso sta un argomento. È anche l'ordine in cui si studia:
/// prima le fondamenta, poi il mestiere di tutti i giorni, infine i temi da senior.
/// Nei JSON è scritto per esteso ("junior"), perciò è un enum a stringa e non Tier,
/// che ha invece un raw value intero.
enum Stage: String, Codable, CaseIterable, Identifiable, Hashable, Comparable {
    case junior, mid, senior

    var id: String { rawValue }

    /// La fascia corrispondente, da cui arrivano nome, simbolo e colori del grado.
    var tier: Tier {
        switch self {
        case .junior: .junior
        case .mid: .mid
        case .senior: .senior
        }
    }

    var caption: String {
        switch self {
        case .junior: String(localized: "The fundamentals: start here.", bundle: .app)
        case .mid: String(localized: "What you need every day.", bundle: .app)
        case .senior: String(localized: "Where experience shows.", bundle: .app)
        }
    }

    static func < (a: Stage, b: Stage) -> Bool { a.tier < b.tier }
}

struct Topic: Codable, Hashable, Identifiable {
    let id: String
    /// Dove si trova nel percorso. Dentro il JSON gli argomenti sono già in ordine
    /// di studio, e questo dice dove finisce uno stage e comincia il successivo.
    let stage: Stage
    let title: String
    let icon: String
    let summary: String
    let lesson: [LessonSection]
    let questions: [Question]
}

/// Uno stage con i suoi argomenti, pronto da mostrare come sezione.
struct StageGroup: Identifiable {
    let stage: Stage
    let topics: [Topic]
    /// Il numero del primo argomento del gruppo nella numerazione continua del percorso.
    let firstNumber: Int

    var id: String { stage.rawValue }
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

/// Carica i JSON dei contenuti della lingua scelta, e li ricarica quando cambia.
/// Id, risposte e difficoltà sono identici nelle due lingue: progressi ed errori
/// salvati restano validi dopo il cambio.
final class ContentStore {
    static let shared = ContentStore()

    private(set) var byTrack: [Track: [Topic]] = [:]
    private(set) var language: AppLanguage

    private init() {
        language = .current
        load()
    }

    func reload(for language: AppLanguage) {
        guard language != self.language else { return }
        self.language = language
        load()
    }

    private func load() {
        byTrack = [:]
        // Lezioni e domande esistono in inglese e in italiano: le altre lingue
        // dell'interfaccia leggono quelle inglesi.
        let folder = language.contentLanguage.rawValue
        for track in Track.allCases {
            guard let url = Bundle.main.url(forResource: track.rawValue, withExtension: "json",
                                            subdirectory: nil, localization: folder),
                  let data = try? Data(contentsOf: url) else { continue }
            do {
                byTrack[track] = try JSONDecoder().decode(TrackContent.self, from: data).topics
            } catch {
                assertionFailure("Invalid content for \(folder)/\(track.rawValue): \(error)")
            }
        }
    }

    /// Gli argomenti del percorso in ordine di studio: prima per stage, poi
    /// nell'ordine in cui stanno nel JSON. Niente di casuale, mai.
    func topics(for track: Track) -> [Topic] { byTrack[track] ?? [] }

    /// Gli argomenti divisi per stage, con la numerazione continua del percorso.
    func stages(for track: Track) -> [StageGroup] {
        var next = 1
        return Stage.allCases.compactMap { stage in
            let group = topics(for: track).filter { $0.stage == stage }
            guard !group.isEmpty else { return nil }
            defer { next += group.count }
            return StageGroup(stage: stage, topics: group, firstNumber: next)
        }
    }

    /// Gli argomenti che a questa fascia sono già stati incontrati nel percorso:
    /// il quiz del giorno non pesca da lezioni che vengono dopo.
    /// `ceiling` è il tetto dell'abbonamento: senza abbonamento si ferma a Junior.
    func topics(for track: Track, upTo tier: Tier, ceiling: Stage? = nil) -> [Topic] {
        topics(for: track).filter { topic in
            topic.stage.tier <= tier && (ceiling.map { topic.stage <= $0 } ?? true)
        }
    }

    func topic(_ id: String, in track: Track) -> Topic? {
        topics(for: track).first { $0.id == id }
    }

    func items(for track: Track, topic: Topic) -> [QuizItem] {
        topic.questions.map { QuizItem(question: $0, track: track, topicID: topic.id) }
    }

    func allItems(for tracks: [Track], ceiling: Stage? = nil) -> [QuizItem] {
        tracks.flatMap { track in
            topics(for: track)
                .filter { topic in ceiling.map { topic.stage <= $0 } ?? true }
                .flatMap { items(for: track, topic: $0) }
        }
    }

    /// Le domande del giorno: stesse per tutta la giornata, diverse ogni giorno,
    /// pescate in modo equo fra i track scelti e dosate sulla fascia dell'utente.
    /// Entrano solo gli argomenti già raggiunti nel percorso: salendo di grado
    /// si sbloccano gli stage successivi.
    func dailyItems(for tracks: [Track], tier: Tier, day: Day, count: Int = 5,
                    ceiling: Stage? = nil) -> [QuizItem] {
        guard !tracks.isEmpty else { return [] }
        var rng = SeededGenerator(seed: UInt64(truncatingIfNeeded: day.ordinal &* 2_654_435_761 &+ tier.rawValue))
        // pools[track][difficoltà] = domande mescolate
        var pools = tracks.map { track in
            let reached = topics(for: track, upTo: tier, ceiling: ceiling)
                .flatMap { items(for: track, topic: $0) }
            return Dictionary(grouping: reached.shuffled(using: &rng), by: \.question.difficulty)
        }
        // Quote fisse per quiz (metodo dei resti più grandi): un Mid riceve sempre
        // 1 junior, 3 mid e 1 senior. Estrarre a caso ogni slot dava giornate da 3 senior e 0 mid.
        let weights = tier.difficultyWeights
        var quota = weights.mapValues { Int($0 * Double(count)) }
        let byRemainder = weights.sorted { ($0.value * Double(count)).truncatingRemainder(dividingBy: 1)
                                         > ($1.value * Double(count)).truncatingRemainder(dividingBy: 1) }
        for (difficulty, _) in byRemainder.prefix(count - quota.values.reduce(0, +)) {
            quota[difficulty, default: 0] += 1
        }
        let wanted = quota.sorted { $0.key < $1.key }
            .flatMap { Array(repeating: $0.key, count: $0.value) }
            .shuffled(using: &rng)

        var result: [QuizItem] = []
        for (slot, difficulty) in wanted.enumerated() {
            let k = slot % pools.count
            // Se quella pila è finita ripiega sulla difficoltà più vicina.
            let order = [difficulty, difficulty + 1, difficulty - 1, difficulty + 2, difficulty - 2]
            guard let d = order.first(where: { !(pools[k][$0]?.isEmpty ?? true) }) else { continue }
            result.append(pools[k][d]!.removeFirst())
        }
        return result.shuffled(using: &rng)
    }

    /// Le domande di un argomento adatte alla fascia, dalla più facile alla più difficile.
    func topicItems(for track: Track, topic: Topic, tier: Tier) -> [QuizItem] {
        let all = items(for: track, topic: topic)
        let fitting = all.filter { tier.topicDifficulties.contains($0.question.difficulty) }
        let chosen = fitting.count >= 5 ? fitting : all
        return chosen.shuffled().sorted { $0.question.difficulty < $1.question.difficulty }
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
