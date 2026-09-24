import SwiftUI

/// Testo con **grassetto** e `codice` inline, preservando gli a capo.
struct RichText: View {
    let text: String
    var font: Font = .body

    var body: some View {
        Text(attributed)
            .font(font)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var attributed: AttributedString {
        var s = (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(text)
        for run in s.runs where run.inlinePresentationIntent?.contains(.code) == true {
            s[run.range].font = .system(.callout, design: .monospaced).weight(.medium)
            s[run.range].backgroundColor = Color.primary.opacity(0.07)
        }
        return s
    }
}

struct CodeBlock: View {
    let code: String
    var track: Track?
    /// Se presente vince sul nome del track: serve alle lezioni che mostrano codice nativo.
    var language: String?

    private var label: String? {
        if let language { return language }
        guard let track else { return nil }
        return track == .flutter ? "dart" : track == .uikit ? "swift" : track.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                ForEach([Color(hex: 0xFF5F57), Color(hex: 0xFEBC2E), Color(hex: 0x28C840)], id: \.self) {
                    Circle().fill($0).frame(width: 9, height: 9)
                }
                Spacer()
                if let label {
                    Text(label)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 13.5, design: .monospaced))
                    .foregroundStyle(Color(hex: 0xE6E6F0))
                    .padding(14)
                    .textSelection(.enabled)
            }
        }
        .background(Color.codeBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct TrackChip: View {
    let track: Track
    var selected = true

    var body: some View {
        Label(track.name, systemImage: track.symbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(selected ? .white : track.theme.primary)
            .background {
                Capsule().fill(selected ? AnyShapeStyle(track.theme.linear) : AnyShapeStyle(track.theme.soft))
            }
    }
}

/// Selettore del linguaggio attivo, visibile solo se l'utente ne ha scelti più d'uno.
struct TrackSwitcher: View {
    @Environment(AppState.self) private var state

    var body: some View {
        if state.tracks.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(state.tracks) { track in
                        let selected = track == state.activeTrack
                        Button {
                            withAnimation(.snappy) { state.activeTrack = track }
                        } label: {
                            Label(track.name, systemImage: track.symbol)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .foregroundStyle(selected ? .white : .primary)
                                .background {
                                    Capsule().fill(selected ? AnyShapeStyle(track.theme.linear)
                                                            : AnyShapeStyle(Color(.secondarySystemBackground)))
                                }
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.selection, trigger: selected)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 5

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct DifficultyDots: View {
    let level: Int
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { i in
                Capsule()
                    .fill(i <= level ? color : color.opacity(0.18))
                    .frame(width: 12, height: 5)
            }
            Text(["Junior", "Mid", "Senior"][max(0, min(2, level - 1))])
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 3)
        }
    }
}

/// Bottone grande e pieno, col gradiente del linguaggio.
struct PrimaryButtonStyle: ButtonStyle {
    var gradient: LinearGradient

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

/// Il distintivo del grado: esagono nel metallo della fascia.
struct RankBadge: View {
    let tier: Tier
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Image(systemName: "hexagon.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(tier.gradient)
                .shadow(color: tier.color.opacity(0.35), radius: size * 0.12, y: size * 0.06)
            Image(systemName: tier.symbol)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

/// Barra degli XP verso il prossimo grado.
struct XPBar: View {
    let progress: Double
    let tier: Tier
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(tier.color.opacity(0.15))
                Capsule().fill(tier.gradient)
                    .frame(width: max(height, geo.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: height)
    }
}

/// Card del grado attuale, usata in home e nel profilo.
struct RankCard: View {
    @Environment(AppState.self) private var state

    var body: some View {
        let rank = state.rank
        HStack(spacing: 14) {
            RankBadge(tier: rank.tier, size: 54)
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(rank.name)
                        .font(.headline)
                    Spacer()
                    Text("\(state.xp.formatted(.number.locale(.app))) XP")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(rank.tier.color)
                        .contentTransition(.numericText(value: Double(state.xp)))
                }
                XPBar(progress: state.rankProgress, tier: rank.tier)
                Group {
                    if let next = rank.next, let missing = state.xpToNextRank {
                        Text("Ancora \(missing.formatted(.number.locale(.app))) XP per diventare **\(next.name)**")
                    } else {
                        Text("Grado massimo raggiunto. Rispetto.")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .card()
        .animation(.snappy, value: state.xp)
    }
}
