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
                        StatBox(value: "\(state.bestStreak)", label: "Record", color: .flame)
                        StatBox(value: "\(state.accuracy)%", label: "Precisione", color: state.activeTrack.theme.primary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    Text("\(state.totalAnswered) domande risposte in totale")
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
                                Text("Sei qui")
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
                    Text("Gradi")
                } footer: {
                    Text("Ogni risposta giusta vale 10, 20 o 30 XP in base alla difficoltà, piena solo la prima volta. Il quiz del giorno aggiunge un bonus, più alto se lo streak è lungo. Salendo di grado le domande si fanno più difficili.")
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
                    Text("I tuoi percorsi")
                } footer: {
                    Text("Ogni percorso ha i suoi argomenti, in ordine dalle fondamenta ai temi da senior. Le domande del giorno mescolano i percorsi attivi, pescando solo dagli argomenti che il tuo grado ha già raggiunto. Almeno un percorso deve restare acceso.")
                }

                Section {
                    Toggle("Promemoria giornaliero", isOn: Binding(
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
                        DatePicker("Ora", selection: Binding(
                            get: { state.reminderTime },
                            set: { state.reminderTime = $0; Task { await Reminders.reschedule(for: state) } }
                        ), displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Notifiche")
                } footer: {
                    Text(notificationsDenied
                         ? "Le notifiche sono disattivate nelle Impostazioni di iOS: attivale lì per Interviews."
                         : "Suona solo nei giorni in cui non hai ancora fatto il quiz.")
                }

                Section {
                    Button("Azzera i progressi", role: .destructive) { confirmReset = true }
                    #if DEBUG
                    Button("Rifai l'onboarding") { state.restartOnboarding() }
                    #endif
                }
            }
            .navigationTitle("Profilo")
            .confirmationDialog("Azzerare streak, statistiche ed errori?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Azzera", role: .destructive) {
                    state.resetProgress()
                    Task { await Reminders.reschedule(for: state) }
                }
            }
        }
    }
}
