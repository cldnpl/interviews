import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var state
    @State private var confirmReset = false
    @State private var notificationsDenied = false

    var body: some View {
        @Bindable var state = state

        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        StatBox(value: "\(state.currentStreak)", label: "Streak", color: .flame)
                        StatBox(value: "\(state.bestStreak)", label: "Best", color: .flame)
                        StatBox(value: "\(state.accuracy)%", label: "Accuracy", color: state.activeTrack.theme.primary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    Text("\(state.totalAnswered) questions answered in total")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }

                Section {
                    RankCard()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    ForEach(Rank.all) { rank in
                        let reached = state.xp >= rank.minXP
                        let current = rank == state.rank
                        HStack(spacing: 12) {
                            RankBadge(tier: rank.tier, size: 32)
                                .saturation(reached ? 1 : 0)
                                .opacity(reached ? 1 : 0.45)
                            Text(rank.name)
                                .fontWeight(current ? .bold : .regular)
                                .foregroundStyle(reached ? .primary : .secondary)
                            Spacer()
                            if current {
                                Text("You're here")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(rank.tier.gradient, in: Capsule())
                            } else {
                                Text("\(rank.minXP.formatted(.number.locale(.app))) XP")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Ranks")
                } footer: {
                    Text("Every correct answer is worth 10, 20 or 30 XP depending on difficulty, in full only the first time. The daily quiz adds a bonus, larger when your streak is long. As your rank goes up the questions get harder.")
                }

                Section {
                    ForEach(Track.allCases) { track in
                        Toggle(isOn: Binding(
                            get: { state.tracks.contains(track) },
                            set: { on in
                                withAnimation { state.setTrack(track, enabled: on) }
                            }
                        )) {
                            HStack(spacing: 12) {
                                Image(systemName: track.symbol)
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(track.theme.linear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(track.name)
                                    Text(track.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .tint(track.theme.primary)
                        .disabled(state.tracks == [track])
                    }
                } header: {
                    Text("Your tracks")
                } footer: {
                    Text("Each track has its own topics, in order from the fundamentals to senior material. The daily questions mix the active tracks, drawing only from the topics your rank has already reached. At least one track must stay on.")
                }

                Section {
                    Picker("Language", selection: Binding(
                        get: { state.language },
                        set: { language in
                            state.language = language
                            // Anche i promemoria già in coda vanno riscritti nella lingua nuova.
                            Task { await Reminders.reschedule(for: state) }
                        }
                    )) {
                        ForEach(AppLanguage.allCases) { language in
                            // Ogni lingua col suo nome, come in Impostazioni: chi non capisce
                            // la lingua attuale deve comunque riconoscere la propria.
                            Text(verbatim: language.nativeName).tag(language)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Language")
                } footer: {
                    Text("Lessons, questions and reminders switch too. Your progress stays as it is.")
                }

                Section {
                    Toggle("Daily reminder", isOn: Binding(
                        get: { state.reminderEnabled },
                        set: { on in
                            Task {
                                if on, !(await Reminders.isAuthorized()) {
                                    let granted = await Reminders.requestPermission()
                                    notificationsDenied = !granted
                                    state.reminderEnabled = granted
                                } else {
                                    state.reminderEnabled = on
                                }
                                await Reminders.reschedule(for: state)
                            }
                        }
                    ))
                    if state.reminderEnabled {
                        DatePicker("Time", selection: Binding(
                            get: { state.reminderTime },
                            set: { state.reminderTime = $0; Task { await Reminders.reschedule(for: state) } }
                        ), displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text(notificationsDenied
                         ? "Notifications are turned off in iOS Settings: turn them on there for Interviews."
                         : "It only rings on days you haven't done the quiz yet.")
                }

                Section {
                    Button("Reset progress", role: .destructive) { confirmReset = true }
                    #if DEBUG
                    Button("Redo onboarding") { state.restartOnboarding() }
                    #endif
                }

                AboutSection()
            }
            .navigationTitle("Profile")
            .confirmationDialog("Reset streak, stats and mistakes?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    state.resetProgress()
                    Task { await Reminders.reschedule(for: state) }
                }
            }
        }
    }
}
