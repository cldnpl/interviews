import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var state

    @State private var step = 0
    @State private var forward = true
    @State private var tracks: Set<Track> = []
    @State private var tier: Tier?
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? .now

    /// Colore dell'onboarding: segue il primo percorso scelto, arancio Swift finché non si sceglie.
    private var theme: Theme {
        Track.allCases.first { tracks.contains($0) }?.theme ?? Track.swift.theme
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            theme.linear.opacity(0.05)
                .ignoresSafeArea()
                .animation(.easeInOut, value: tracks)

            VStack(spacing: 0) {
                if step > 0 {
                    HStack {
                        Button {
                            go(to: step - 1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .frame(width: 40, height: 40)
                                .background(.thinMaterial, in: Circle())
                        }
                        .foregroundStyle(.primary)
                        Spacer()
                        PageDots(count: 4, index: step, color: theme.primary)
                        Spacer()
                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                Group {
                    switch step {
                    case 0: welcome
                    case 1: trackPicker
                    case 2: levelPicker
                    default: reminder
                    }
                }
                // Avanti entra da destra, indietro da sinistra.
                .transition(.asymmetric(insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                                        removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)))
            }
        }
    }

    // MARK: Benvenuto

    private var welcome: some View {
        VStack(spacing: 28) {
            Spacer()
            AppMark()
                .frame(width: 128, height: 128)
            VStack(spacing: 12) {
                Text("Interviews")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                Text("Preparati ai colloqui tecnici mobile.\nCinque domande al giorno, lezioni brevi, zero ansia.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                ForEach(Track.allCases) { TrackChip(track: $0) }
            }
            Spacer()
            Button("Iniziamo") { go(to: 1) }
                .buttonStyle(PrimaryButtonStyle(gradient: Track.swift.theme.linear))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Che percorsi vuoi seguire

    private var trackPicker: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Su cosa ti prepari?")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("Ogni percorso è a sé, con i suoi argomenti e le sue domande. Puoi sceglierne più di uno: il quiz del giorno li mescolerà.")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(Track.allCases) { track in
                        TrackCard(track: track, selected: tracks.contains(track)) {
                            withAnimation(.snappy) {
                                if tracks.contains(track) { tracks.remove(track) } else { tracks.insert(track) }
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)

            Button("Continua") { go(to: 2) }
                .buttonStyle(PrimaryButtonStyle(gradient: theme.linear))
                .disabled(tracks.isEmpty)
                .opacity(tracks.isEmpty ? 0.4 : 1)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Livello

    private var levelPicker: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Qual è il tuo livello?")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("Le domande si adattano a te. Rispondendo guadagni XP e sali di grado, fino a Staff.")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)

            VStack(spacing: 14) {
                ForEach(Tier.selectable) { t in
                    LevelCard(tier: t, selected: tier == t) {
                        withAnimation(.snappy) { tier = t }
                    }
                }
            }

            Spacer()

            Button("Continua") { go(to: 3) }
                .buttonStyle(PrimaryButtonStyle(gradient: theme.linear))
                .disabled(tier == nil)
                .opacity(tier == nil ? 0.4 : 1)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Promemoria

    private var reminder: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Quando ti alleni?")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("Ti mandiamo un promemoria all'ora che preferisci, solo nei giorni in cui non hai ancora fatto il quiz.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)

            ZStack {
                Circle()
                    .fill(theme.soft)
                    .frame(width: 150, height: 150)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(theme.linear)
                    .symbolEffect(.pulse, options: .repeating)
            }

            DatePicker("Ora", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 150)
                .clipped()

            Spacer()

            VStack(spacing: 12) {
                Button("Attiva i promemoria") { finish(reminders: true) }
                    .buttonStyle(PrimaryButtonStyle(gradient: theme.linear))
                Button("Più tardi") { finish(reminders: false) }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    private func go(to newStep: Int) {
        forward = newStep > step
        withAnimation(.snappy) { step = newStep }
    }

    private func finish(reminders: Bool) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        Task {
            var enabled = reminders
            if reminders { enabled = await Reminders.requestPermission() }
            await MainActor.run {
                state.completeOnboarding(tracks: tracks, tier: tier ?? .junior, reminderEnabled: enabled,
                                         hour: c.hour ?? 19, minute: c.minute ?? 0)
            }
            await Reminders.reschedule(for: state)
        }
    }
}

private struct TrackCard: View {
    let track: Track
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(track.theme.linear)
                        .frame(width: 58, height: 58)
                    Image(systemName: track.symbol)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(track.name)
                            .font(.title3.weight(.bold))
                        Text(track.subtitle)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .foregroundStyle(track.theme.primary)
                            .background(track.theme.soft, in: Capsule())
                    }
                    Text(track.blurb)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selected ? track.theme.primary : Color.secondary.opacity(0.4))
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(selected ? track.theme.primary : .clear, lineWidth: 2.5)
            }
            .shadow(color: selected ? track.theme.primary.opacity(0.25) : .black.opacity(0.05), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }
}

private struct LevelCard: View {
    let tier: Tier
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                RankBadge(tier: tier, size: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.name)
                        .font(.title3.weight(.bold))
                    Text(tier.experience)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selected ? tier.color : Color.secondary.opacity(0.4))
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(selected ? tier.color : .clear, lineWidth: 2.5)
            }
            .shadow(color: selected ? tier.color.opacity(0.25) : .black.opacity(0.05), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }
}

private struct PageDots: View {
    let count: Int
    let index: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? color : color.opacity(0.2))
                    .frame(width: i == index ? 22 : 8, height: 8)
            }
        }
        .animation(.snappy, value: index)
    }
}

/// Il marchio dell'app: quattro spicchi nei colori dei quattro linguaggi.
struct AppMark: View {
    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.28, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                Grid(horizontalSpacing: s * 0.06, verticalSpacing: s * 0.06) {
                    GridRow {
                        tile(.swift, s)
                        tile(.uikit, s)
                    }
                    GridRow {
                        tile(.kotlin, s)
                        tile(.flutter, s)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func tile(_ track: Track, _ s: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: s * 0.1, style: .continuous)
            .fill(track.theme.linear)
            .frame(width: s * 0.3, height: s * 0.3)
    }
}
