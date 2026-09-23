import Foundation

/// Un giorno di calendario nel fuso dell'utente. Lo streak ragiona in giorni,
/// non in istanti: confrontare Date dirette fa saltare lo streak a mezzanotte UTC.
struct Day: Hashable, Codable, Comparable, CustomStringConvertible {
    let year: Int, month: Int, day: Int

    init(_ date: Date = .now, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        year = c.year!; month = c.month!; day = c.day!
    }

    static var today: Day { Day() }

    var date: Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func adding(_ days: Int) -> Day {
        Day(Calendar.current.date(byAdding: .day, value: days, to: date)!)
    }

    /// Giorni dal 1/1/2001: serve come seme per il quiz del giorno.
    var ordinal: Int {
        Calendar.current.dateComponents([.day], from: Date(timeIntervalSinceReferenceDate: 0), to: date).day ?? 0
    }

    var description: String { String(format: "%04d-%02d-%02d", year, month, day) }

    static func < (a: Day, b: Day) -> Bool { (a.year, a.month, a.day) < (b.year, b.month, b.day) }
}
