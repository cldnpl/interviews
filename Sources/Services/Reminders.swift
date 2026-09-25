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
            // Due frasi intere invece di incollare "day"/"days": una lingua che declina
            // il numero non si traduce una parola alla volta.
            let title = streak == 1 ? String(localized: "🔥 1 day in a row", bundle: .app)
                                    : String(localized: "🔥 \(streak) days in a row", bundle: .app)
            return (title, String(localized: "Don't break the streak: 5 questions on \(tracks) are waiting.", bundle: .app))
        }
        let pool = [
            (String(localized: "Today's quiz is ready", bundle: .app),
             String(localized: "Five questions, two minutes. Your next interview will thank you.", bundle: .app)),
            (String(localized: "Practice of the day", bundle: .app),
             String(localized: "A recruiter could ask you tomorrow. Better to know it today.", bundle: .app)),
            (String(localized: "Two minutes for you", bundle: .app),
             String(localized: "Pick up today's questions on \(tracks).", bundle: .app)),
            (String(localized: "Ready for the interview?", bundle: .app),
             String(localized: "Today's questions have arrived.", bundle: .app)),
        ]
        return pool[abs(index) % pool.count]
    }
}
