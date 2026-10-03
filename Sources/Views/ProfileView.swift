import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var state
    @State private var confirmReset = false
    @State private var notificationsDenied = false
    @State private var paywall: PaywallReason?

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
                    if state.isPremium {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title2)
                                .foregroundStyle(Color(hex: 0xF5A000))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Interviews Pro is active")
                                    .font(.headline)
                                Text("Every lesson and every question is open. Thank you, really.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                            Label("Manage subscription", systemImage: "arrow.up.right.square")
                        }
                    } else {
                        Button {
                            paywall = .plain
                        } label: {
                            HStack(spacing: 12) {
                                LockBadge(size: 34)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Unlock every lesson")
                                        .font(.headline)
                                    Text("Junior is free. Mid and Senior with Interviews Pro, \(state.store.priceText) a month.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                        Button("Restore purchases") { Task { await state.store.restore() } }
                    }
                } header: {
                    Text("Subscription")
                } footer: {
                    Text(state.isPremium
                         ? "It renews by itself every month until you cancel it, from Settings on your iPhone."
                         : "Without the subscription you keep all the Junior topics, forever, and five questions a day.")
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
                                TrackMark(track, size: 16)
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
                    Picker("Theme", selection: Binding(
                        get: { state.appearance },
                        set: { state.appearance = $0 }
                    )) {
                        ForEach(Appearance.allCases) { appearance in
                            Label(appearance.name, systemImage: appearance.symbol).tag(appearance)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Theme")
                } footer: {
                    Text("Automatic follows your iPhone: it turns dark in the evening if you have set it that way.")
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
                    Text(state.language.contentIsTranslated
                         ? "Buttons, lessons, questions and reminders all switch. Your progress stays as it is."
                         : "The app switches language. Lessons and questions are written by hand in English and Italian, so in this language you read them in English: better than a machine translation of a hard idea.")
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
                    Button(state.isPremium ? "DEBUG: turn Pro off" : "DEBUG: turn Pro on") { state.debugTogglePremium() }
                    #endif
                }

                AboutSection()
            }
            .navigationTitle("Profile")
            .sheet(item: $paywall) { PremiumSheet(reason: $0.text) }
            .confirmationDialog("Reset streak, stats and mistakes?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    state.resetProgress()
                    Task { await Reminders.reschedule(for: state) }
                }
            }
        }
    }
}
