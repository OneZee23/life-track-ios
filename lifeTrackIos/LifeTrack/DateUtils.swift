import Foundation

// MARK: - Formatter

private let _dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone.current
    return f
}()

func formatDate(_ date: Date) -> String {
    _dateFormatter.string(from: date)
}

func parseDate(_ str: String) -> Date? {
    _dateFormatter.date(from: str)
}

// MARK: - Helpers

func yesterday() -> Date {
    Calendar.current.date(byAdding: .day, value: -1, to: Date())!
}

/// 0 = Понедельник, 6 = Воскресенье
func weekdayIndex(_ date: Date) -> Int {
    (Calendar.current.component(.weekday, from: date) + 5) % 7
}

func weekStart(for date: Date) -> Date {
    let wd = weekdayIndex(date)
    return Calendar.current.date(byAdding: .day, value: -wd, to: date)!
}

func daysInMonth(year: Int, month: Int) -> Int {
    let comps = DateComponents(year: year, month: month + 1)
    guard let date = Calendar.current.date(from: comps),
          let range = Calendar.current.range(of: .day, in: .month, for: date) else { return 30 }
    return range.count
}

func makeDate(year: Int, month: Int, day: Int) -> Date? {
    Calendar.current.date(from: DateComponents(year: year, month: month + 1, day: day))
}

func isToday(_ date: Date) -> Bool {
    Calendar.current.isDateInToday(date)
}

func isFuture(_ date: Date) -> Bool {
    date > Date()
}

func isBeyondTomorrow(_ date: Date) -> Bool {
    let cal = Calendar.current
    let tomorrow = cal.date(byAdding: .day, value: 1, to: Date())!
    return cal.startOfDay(for: date) > cal.startOfDay(for: tomorrow)
}

