import Foundation
import UserNotifications

/// I promemoria sono notifiche singole per i prossimi giorni, non una ripetizione
/// giornaliera: così oggi non suona se il quiz l'hai già fatto.
enum Reminders {
    private static let prefix = "interviews.daily."
    private static let daysAhead = 14

    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func isAuthorized() async -> Bool {
        let s = await UNUserNotificationCenter.current().notificationSettings()
        return s.authorizationStatus == .authorized || s.authorizationStatus == .provisional
    }

    @MainActor
    static func reschedule(for state: AppState) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) })
        try? await center.setBadgeCount(0)

        guard state.reminderEnabled, state.hasOnboarded, await isAuthorized() else { return }

        let streak = state.currentStreak
        let doneToday = state.didDailyToday
        let names = state.tracks.map(\.name).formatted(.list(type: .and).locale(.app))

        for offset in 0..<daysAhead {
            if offset == 0 && doneToday { continue }
            let day = Day.today.adding(offset)
            var c = Calendar.current.dateComponents([.year, .month, .day], from: day.date)
            c.hour = state.reminderHour
            c.minute = state.reminderMinute
            guard let fire = Calendar.current.date(from: c), fire > .now else { continue }

            // Lo streak atteso quel giorno, se l'utente non salta nulla fino ad allora.
            let expected = doneToday ? streak + offset : (offset == 0 ? streak : 0)
            let content = UNMutableNotificationContent()
            (content.title, content.body) = message(streak: expected, tracks: names, index: day.ordinal)
            content.sound = .default
            content.badge = 1

            let trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: prefix + day.description, content: content, trigger: trigger))
        }
    }

    private static func message(streak: Int, tracks: String, index: Int) -> (String, String) {
        if streak > 0 {
            return ("🔥 \(streak) \(streak == 1 ? "giorno" : "giorni") di fila",
                    "Non spezzare la serie: 5 domande su \(tracks) ti aspettano.")
        }
        let pool = [
            ("Il quiz di oggi è pronto", "Cinque domande, due minuti. Il prossimo colloquio ringrazia."),
            ("Allenamento del giorno", "Un recruiter potrebbe chiedertelo domani. Meglio saperlo oggi."),
            ("Due minuti per te", "Riparti con le domande di oggi su \(tracks)."),
            ("Pronto per il colloquio?", "Le domande del giorno sono arrivate."),
        ]
        return pool[abs(index) % pool.count]
    }
}
