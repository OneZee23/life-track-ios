import Foundation

// MARK: - App Constants

enum AppConstants {
    static let maxHabits = 10
    static let maxUndoStack = 5
    static let textCharLimit = 140
    static let numericUnboundedMax: Double = 99999
    static let habitNameMaxLength = 20
    static let unitMaxLength = 6
    static let daysLookback = 365
    static let notificationIdentifier = "lt_daily"
    static let maxLocalNotifications = 64
}

/// Convert ISO 8601 weekday (1=Mon … 7=Sun) to Apple DateComponents weekday (1=Sun, 2=Mon … 7=Sat).
func isoToAppleWeekday(_ iso: Int) -> Int {
    (iso % 7) + 1
}

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
    Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
}

/// 0 = Понедельник, 6 = Воскресенье
func weekdayIndex(_ date: Date) -> Int {
    (Calendar.current.component(.weekday, from: date) + 5) % 7
}

func weekStart(for date: Date) -> Date {
    let wd = weekdayIndex(date)
    return Calendar.current.date(byAdding: .day, value: -wd, to: date) ?? date
}

/// Returns the number of days in the given month.
/// - Parameters:
///   - year: Calendar year (e.g. 2024)
///   - month: **0-indexed** month (0 = January, 11 = December)
func daysInMonth(year: Int, month: Int) -> Int {
    let comps = DateComponents(year: year, month: month + 1)
    guard let date = Calendar.current.date(from: comps),
          let range = Calendar.current.range(of: .day, in: .month, for: date) else { return 30 }
    return range.count
}

/// Creates a Date from year, month, day components.
/// - Parameters:
///   - year: Calendar year (e.g. 2024)
///   - month: **0-indexed** month (0 = January, 11 = December)
///   - day: Day of month (1-based)
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
    guard let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) else { return false }
    return cal.startOfDay(for: date) > cal.startOfDay(for: tomorrow)
}

// MARK: - Formatting

/// Formats a Double as integer if whole, or to 1 decimal place.
func formatValue(_ value: Double) -> String {
    value.truncatingRemainder(dividingBy: 1) == 0
        ? String(format: "%.0f", value)
        : String(format: "%.1f", value)
}

/// Formats sleep duration from minutes to "Xч Yм" / "Xh Ym" format.
func formatSleepMinutes(_ minutes: Double) -> String {
    let totalMinutes = Int(minutes)
    let h = totalMinutes / 60
    let m = totalMinutes % 60
    if m == 0 {
        return L10n.isRu ? "\(h)ч" : "\(h)h"
    }
    return L10n.isRu ? "\(h)ч \(m)м" : "\(h)h \(m)m"
}

/// Formats a numeric value for display, handling sleep (minutes→hours) and units.
func formatNumericDisplay(_ val: Double, unit: String, isSleep: Bool) -> String {
    if isSleep { return formatSleepMinutes(val) }
    let formatted = formatValue(val)
    return unit.isEmpty ? formatted : "\(formatted) \(unit)"
}

