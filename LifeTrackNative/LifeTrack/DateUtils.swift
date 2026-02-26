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

// MARK: - Russian Localization

let monthsFullRu = [
    "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
    "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"
]

let monthsShortRu = [
    "Янв", "Фев", "Мар", "Апр", "Май", "Июн",
    "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"
]

let monthsGenitiveRu = [
    "января", "февраля", "марта", "апреля", "мая", "июня",
    "июля", "августа", "сентября", "октября", "ноября", "декабря"
]

let weekdaysFullRu = [
    "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"
]

let weekdaysShortRu = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

func pluralDays(_ n: Int) -> String {
    let mod10 = n % 10
    let mod100 = n % 100
    if mod10 == 1 && mod100 != 11 { return "день" }
    if mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14) { return "дня" }
    return "дней"
}

/// «15 февраля, воскресенье»
func yesterdayLabel() -> String {
    let d = yesterday()
    let day = Calendar.current.component(.day, from: d)
    let month = monthsGenitiveRu[Calendar.current.component(.month, from: d) - 1]
    let wd = weekdaysFullRu[weekdayIndex(d)].lowercased()
    return "\(day) \(month), \(wd)"
}
