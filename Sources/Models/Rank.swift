import SwiftUI

/// La fascia di esperienza: decide che domande arrivano.
enum Tier: Int, Codable, CaseIterable, Identifiable, Comparable {
    case junior = 1, mid, senior, staff

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .junior: "Junior"
        case .mid: "Mid"
        case .senior: "Senior"
        case .staff: "Staff"
        }
    }

    var experience: String {
        switch self {
        case .junior: "Meno di 2 anni, o stai cercando il primo lavoro"
        case .mid: "Da 2 a 5 anni, lavori in autonomia"
        case .senior: "Più di 5 anni, guidi scelte tecniche"
        case .staff: "Oltre il senior"
        }
    }

    var symbol: String {
        switch self {
        case .junior: "leaf.fill"
        case .mid: "bolt.fill"
        case .senior: "star.fill"
        case .staff: "crown.fill"
        }
    }

    /// Bronzo, argento, oro, platino: i colori dei gradi, uguali in tutti i linguaggi.
    var color: Color {
        switch self {
        case .junior: Color(hex: 0xC77B3A)
        case .mid: Color(hex: 0x7D8BA3)
        case .senior: Color(hex: 0xE3A400)
        case .staff: Color(hex: 0x9B5CF6)
        }
    }

    var gradient: LinearGradient {
        let colors: [Color] = switch self {
        case .junior: [Color(hex: 0xE9A26B), Color(hex: 0xB0662B)]
        case .mid: [Color(hex: 0xB8C2D3), Color(hex: 0x6B7A94)]
        case .senior: [Color(hex: 0xFFD54A), Color(hex: 0xE09200)]
        case .staff: [Color(hex: 0xC4A1FF), Color(hex: 0x7C3AED)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Quanto pesa ogni difficoltà (1 junior, 2 mid, 3 senior) nel quiz del giorno.
    var difficultyWeights: [Int: Double] {
        switch self {
        case .junior: [1: 0.65, 2: 0.35]
        case .mid: [1: 0.2, 2: 0.6, 3: 0.2]
        case .senior, .staff: [2: 0.4, 3: 0.6]
        }
    }

    /// Le difficoltà che entrano nei quiz per argomento.
    var topicDifficulties: Set<Int> {
        switch self {
        case .junior: [1, 2]
        case .mid: [1, 2, 3]
        case .senior, .staff: [2, 3]
        }
    }

    static func < (a: Tier, b: Tier) -> Bool { a.rawValue < b.rawValue }

    /// Le fasce che si possono scegliere in onboarding: Staff si guadagna.
    static let selectable: [Tier] = [.junior, .mid, .senior]
}

struct Rank: Identifiable, Equatable {
    let tier: Tier
    let step: Int?      // I, II, III; nil per Staff
    let minXP: Int

    var id: Int { minXP }

    var name: String {
        guard let step else { return tier.name }
        return "\(tier.name) \(["I", "II", "III"][step - 1])"
    }

    /// Soglie pensate su ~150 XP al giorno: Mid in circa una settimana, Senior in tre.
    static let all: [Rank] = [
        Rank(tier: .junior, step: 1, minXP: 0),
        Rank(tier: .junior, step: 2, minXP: 200),
        Rank(tier: .junior, step: 3, minXP: 500),
        Rank(tier: .mid, step: 1, minXP: 900),
        Rank(tier: .mid, step: 2, minXP: 1400),
        Rank(tier: .mid, step: 3, minXP: 2000),
        Rank(tier: .senior, step: 1, minXP: 2800),
        Rank(tier: .senior, step: 2, minXP: 3700),
        Rank(tier: .senior, step: 3, minXP: 4800),
        Rank(tier: .staff, step: nil, minXP: 6000),
    ]

    static func forXP(_ xp: Int) -> Rank {
        all.last { xp >= $0.minXP } ?? all[0]
    }

    static func start(of tier: Tier) -> Rank {
        all.first { $0.tier == tier } ?? all[0]
    }

    var next: Rank? {
        guard let i = Rank.all.firstIndex(of: self), i + 1 < Rank.all.count else { return nil }
        return Rank.all[i + 1]
    }
}

/// Le regole degli XP, tutte in un posto.
enum XP {
    static func forCorrect(difficulty: Int, firstTime: Bool) -> Int {
        firstTime ? 10 * max(1, min(3, difficulty)) : 2
    }

    static let dailyBonus = 50
    static let perfectBonus = 25
    static func streakBonus(_ streak: Int) -> Int { 5 * min(streak, 10) }
    static let topicPassBonus = 20   // quiz per argomento con almeno l'80%
}
