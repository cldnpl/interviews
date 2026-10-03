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
                        PageDots(count: 5, index: step, color: theme.primary)
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
                    case 3: goodToKnow
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
                Text("Get ready for mobile tech interviews,\nwith five questions a day and short lessons.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                ForEach(Track.allCases) { TrackChip(track: $0) }
            }
            Spacer()
            Button("Let's start") { go(to: 1) }
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
                Text("What's your focus?")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("Each track stands on its own, with its own topics and questions. Pick more than one: the daily quiz will mix them.")
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

            Button("Continue") { go(to: 2) }
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
                Text("What's your level?")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("Questions adapt to you. Answering earns XP and raises your rank, all the way to Staff.")
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

            Button("Continue") { go(to: 3) }
                .buttonStyle(PrimaryButtonStyle(gradient: theme.linear))
                .disabled(tier == nil)
                .opacity(tier == nil ? 0.4 : 1)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Quello che è giusto sapere

    private var goodToKnow: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("A few things about the app")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("Nothing hidden: this is what you get, and what costs money.")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)

            ScrollView {
                VStack(spacing: 12) {
                    FactCard(symbol: "book.fill", tint: theme.primary,
                             title: "Free from the first day",
                             detail: "Every Junior topic of every track is free: the lessons, the quizzes and five questions a day. No trial that runs out.")
                    FactCard(symbol: "lock.fill", tint: Color(hex: 0xF5A000),
                             title: "Mid and Senior with Interviews Pro",
                             detail: "The harder topics are part of a subscription at \(Store.shared.priceText) a month. It's a symbolic price to support an independent developer. You can look at it later, from your profile.")
                    FactCard(symbol: "globe", tint: Track.flutter.theme.primary,
                             title: "Six languages",
                             detail: "English, Italiano, Español, Français, Deutsch, Português. You pick yours in the profile, whenever you want. Lessons and questions are written in English and Italian.")
                    FactCard(symbol: "circle.lefthalf.filled", tint: Track.kotlin.theme.primary,
                             title: "Light and dark",
                             detail: "By default the app follows your iPhone. If you prefer, you can fix it on light or on dark from the profile.")
                    FactCard(symbol: "wifi.slash", tint: Track.swift.theme.primary,
                             title: "Works with no internet",
                             detail: "Lessons and questions are inside the app. Nothing of yours leaves your iPhone: there is no account and no sign-up.")
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)

            Button("Continue") { go(to: 4) }
                .buttonStyle(PrimaryButtonStyle(gradient: theme.linear))
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Promemoria

    private var reminder: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("When do you practice?")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("We send a reminder at the time you prefer, only on days you haven't done the quiz yet.")
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

            DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 150)
                .clipped()

            Spacer()

            VStack(spacing: 12) {
                Button("Turn on reminders") { finish(reminders: true) }
                    .buttonStyle(PrimaryButtonStyle(gradient: theme.linear))
                Button("Later") { finish(reminders: false) }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                LegalConsentNote(tint: theme.primary)
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
                    TrackMark(track, size: 30)
                }
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(track.name)
                            .font(.title3.weight(.bold))
                        Text(track.tag)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .foregroundStyle(track.theme.primary)
                            .background(track.theme.soft, in: Capsule())
                    }
                    Text(track.subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
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

/// Una delle cose da sapere, nell'onboarding: un simbolo, una riga e la spiegazione.
private struct FactCard: View {
    let symbol: String
    let tint: Color
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tint, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .multilineTextAlignment(.leading)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
