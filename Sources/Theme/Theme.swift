import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// I colori di ogni linguaggio, presi dai rispettivi marchi:
/// Swift arancio su bianco, UIKit il blu di sistema di iOS,
/// Kotlin il gradiente viola-magenta-corallo, Flutter blu notte e azzurro.
struct Theme {
    let primary: Color
    let secondary: Color
    let deep: Color        // per testi su sfondo chiaro e gradienti
    let gradient: [Color]

    var linear: LinearGradient {
        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Fondo delicato per card e schermate, si adatta al tema scuro.
    var soft: Color { primary.opacity(0.10) }
}

extension Track {
    var theme: Theme {
        switch self {
        case .swift:
            Theme(primary: Color(hex: 0xF05138), secondary: Color(hex: 0xFF9F43),
                  deep: Color(hex: 0xC8361F),
                  gradient: [Color(hex: 0xFA7343), Color(hex: 0xF05138)])
        case .uikit:
            Theme(primary: Color(hex: 0x007AFF), secondary: Color(hex: 0x5AC8FA),
                  deep: Color(hex: 0x0051A8),
                  gradient: [Color(hex: 0x3FA2FF), Color(hex: 0x007AFF)])
        case .kotlin:
            Theme(primary: Color(hex: 0x7F52FF), secondary: Color(hex: 0xE44857),
                  deep: Color(hex: 0x5B2FD6),
                  gradient: [Color(hex: 0x7F52FF), Color(hex: 0xC711E1), Color(hex: 0xE44857)])
        case .flutter:
            Theme(primary: Color(hex: 0x0175C2), secondary: Color(hex: 0x13B9FD),
                  deep: Color(hex: 0x02569B),
                  gradient: [Color(hex: 0x13B9FD), Color(hex: 0x02569B)])
        }
    }
}

/// Il colore del fuoco dello streak: uguale per tutti, arancio caldo.
extension Color {
    static let flame = Color(hex: 0xFF7A00)
    static let correct = Color(hex: 0x2FB36B)
    static let wrong = Color(hex: 0xE5484D)
    static let codeBackground = Color(hex: 0x1E1F29)
}

extension Locale {
    /// L'app è in italiano anche su un iPhone impostato in un'altra lingua.
    static let app = Locale(identifier: "it_IT")
}
