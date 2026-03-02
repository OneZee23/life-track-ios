import Foundation
import SwiftUI
import UserNotifications

class AppStore: ObservableObject {
    @Published var habits: [Habit] = [] {
        didSet { _activeHabitIds = nil }
    }
    @Published var checkins: [String: [String: Int]] = [:]  // date -> habitId -> 0|1
    @Published var themeMode: String = "auto"  // "auto" | "light" | "dark"
    @Published var lang: String = "auto"       // "auto" | "ru" | "en"
    @Published var notifEnabled: Bool = false
    @Published var notifHour: Int = 21
    @Published var notifMinute: Int = 0

    private let habitsKey = "lt_habits_v1"
    private let checkinsKey = "lt_checkins_v1"
    private let themeKey = "lt_theme"
    private let legacyThemeKey = "lt_isDark"
    private let langKey = "lt_lang"
    private let notifEnabledKey = "lt_notif_enabled"
    private let notifHourKey    = "lt_notif_hour"
    private let notifMinuteKey  = "lt_notif_minute"
    private let greetingDateKey = "lt_greeting_shown_date"

    // MARK: - Undo/Redo

    private struct Snapshot {
        let habits: [Habit]
        let checkins: [String: [String: Int]]
    }

    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []
    private let maxUndo = 5

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    private func pushUndo() {
        undoStack.append(Snapshot(habits: habits, checkins: checkins))
        if undoStack.count > maxUndo { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    func undo() {
        guard let snap = undoStack.popLast() else { return }
        redoStack.append(Snapshot(habits: habits, checkins: checkins))
        habits = snap.habits
        checkins = snap.checkins
        save()
    }

    func redo() {
        guard let snap = redoStack.popLast() else { return }
        undoStack.append(Snapshot(habits: habits, checkins: checkins))
        habits = snap.habits
        checkins = snap.checkins
        save()
    }

    private var _activeHabitIds: Set<String>?
    private var activeHabitIds: Set<String> {
        if let cached = _activeHabitIds { return cached }
        let ids = Set(habits.lazy.filter { !$0.isDeleted }.map { $0.id })
        _activeHabitIds = ids
        return ids
    }

    var activeHabits: [Habit] {
        habits.filter { !$0.isDeleted }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var allHabits: [Habit] {
        habits.sorted {
            if $0.isDeleted != $1.isDeleted { return !$0.isDeleted }
            return $0.sortOrder < $1.sortOrder
        }
    }

    init() {
        load()
        if habits.isEmpty { seedDefaults() }
        if notifEnabled { scheduleDaily() }
    }

    // MARK: - CheckIns

    func checkinValue(habitId: String, date: String) -> Int {
        checkins[date]?[habitId] ?? 0
    }

    /// Возвращает nil если нет данных вообще (будущее или нет записей)
    func dayStatus(date: String, habitId: String? = nil) -> DayStatus? {
        if let hid = habitId {
            guard let v = checkins[date]?[hid] else { return nil }
            return v == 1 ? DayStatus.full : DayStatus.none
        }

        guard let dayData = checkins[date], !dayData.isEmpty else { return nil }
        guard let dateObj = parseDate(date) else { return nil }

        let relevantIds = trackedHabitIds(on: dateObj)
        let relevant = dayData.filter { relevantIds.contains($0.key) }
        guard !relevant.isEmpty else { return nil }

        let done = relevant.values.filter { $0 == 1 }.count
        let total = relevantIds.count
        if done == 0 { return DayStatus.none }

        let pct = Double(done) / Double(total) * 100.0
        if pct <= 25 { return .low }
        if pct <= 50 { return .medium }
        if pct <= 75 { return .high }
        return .full
    }

    func saveDay(date: String, values: [String: Bool]) {
        var dayData = checkins[date] ?? [:]
        for (hid, done) in values {
            dayData[hid] = done ? 1 : 0
        }
        checkins[date] = dayData
        save()
    }

    func toggleCheckin(habitId: String, date: String) {
        var dayData = checkins[date] ?? [:]
        dayData[habitId] = (dayData[habitId] ?? 0) == 1 ? 0 : 1
        // Ensure all active habits have explicit entries (0 if untouched)
        for habit in activeHabits {
            if dayData[habit.id] == nil {
                dayData[habit.id] = 0
            }
        }
        checkins[date] = dayData
        save()
    }

    // MARK: - Streaks

    func currentStreak() -> Int {
        let cal = Calendar.current
        var streak = 0

        // Include today if already checked in
        let todayDs = formatDate(Date())
        if let s = dayStatus(date: todayDs), s != .none {
            streak = 1
        }

        // Count backwards from yesterday
        var date = yesterday()
        while true {
            let ds = formatDate(date)
            let status = dayStatus(date: ds)

            if let s = status, s != .none {
                streak += 1
            } else {
                break
            }
            date = cal.date(byAdding: .day, value: -1, to: date)!
        }
        return streak
    }

    func bestStreakAllTime() -> Int {
        let cal = Calendar.current
        let dateStrings = checkins.keys.sorted()
        guard let first = dateStrings.first else { return 0 }

        let parts = first.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return 0 }
        let startYear = parts[0], startMonth = parts[1] - 1

        let now = Date()
        let endYear = cal.component(.year, from: now)
        let endMonth = cal.component(.month, from: now) - 1

        var best = 0, cur = 0
        for year in startYear...endYear {
            let mStart = (year == startYear) ? startMonth : 0
            let mEnd = (year == endYear) ? endMonth : 11
            for month in mStart...mEnd {
                let days = daysInMonth(year: year, month: month)
                for day in 1...days {
                    guard let d = makeDate(year: year, month: month, day: day) else { continue }
                    if isFuture(d) && !isToday(d) { break }
                    let ds = formatDate(d)
                    let status = dayStatus(date: ds)
                    if let s = status, s != .none {
                        cur += 1
                        best = max(best, cur)
                    } else if !cal.isDateInToday(d) {
                        cur = 0
                    }
                }
            }
        }
        return best
    }

    func bestStreak(year: Int, month: Int, habitId: String? = nil) -> Int {
        var best = 0, cur = 0
        let cal = Calendar.current
        let days = daysInMonth(year: year, month: month)

        for day in 1...days {
            guard let d = makeDate(year: year, month: month, day: day) else { continue }
            if isFuture(d) { break }

            let ds = formatDate(d)
            let status = dayStatus(date: ds, habitId: habitId)

            if let s = status, s != .none {
                cur += 1
                best = max(best, cur)
            } else if !cal.isDateInToday(d) {
                cur = 0
            }
        }
        return best
    }

    func currentStreak(year: Int, month: Int, habitId: String? = nil) -> Int {
        let cal = Calendar.current
        var cur = 0
        let days = daysInMonth(year: year, month: month)
        let now = Date()

        for day in stride(from: days, through: 1, by: -1) {
            guard let d = makeDate(year: year, month: month, day: day) else { continue }
            if d >= now && !cal.isDateInToday(d) { continue }
            if cal.isDateInToday(d) { continue }

            let ds = formatDate(d)
            let status = dayStatus(date: ds, habitId: habitId)
            if let s = status, s != .none {
                cur += 1
            } else {
                break
            }
        }
        return cur
    }

    func habitStreak(habitId: String, asOf date: Date) -> Int {
        let cal = Calendar.current
        var streak = 0
        var d = date
        while true {
            let ds = formatDate(d)
            guard let v = checkins[ds]?[habitId], v == 1 else { break }
            streak += 1
            d = cal.date(byAdding: .day, value: -1, to: d)!
        }
        return streak
    }

    // MARK: - Daily greeting

    func shouldShowGreeting() -> Bool {
        let today = formatDate(Date())
        let shown = UserDefaults.standard.string(forKey: greetingDateKey) ?? ""
        return shown != today
    }

    func markGreetingShown() {
        UserDefaults.standard.set(formatDate(Date()), forKey: greetingDateKey)
    }

    func yesterdayStats() -> (done: Int, total: Int)? {
        let y = yesterday()
        let ids = trackedHabitIds(on: y)
        guard !ids.isEmpty else { return nil }
        let ds = formatDate(y)
        let dayData = checkins[ds] ?? [:]
        let done = ids.filter { dayData[$0] == 1 }.count
        return (done, ids.count)
    }

    /// Returns habit IDs that should be counted on a given date.
    /// Primary: habits active on date (createdAt <= date, not deleted before date).
    /// Fallback (when no habits are "active" but data exists — first-day "yesterday" check-in):
    /// include habits created up to 1 day after the date.
    func trackedHabitIds(on date: Date) -> Set<String> {
        let ds = formatDate(date)
        let dayData = checkins[ds] ?? [:]
        guard !dayData.isEmpty else { return [] }

        let cal = Calendar.current
        let allIds = Set(habits.map { $0.id })
        let activeIds = Set(habits.filter { habitWasActive($0, on: date) }.map { $0.id })
        let dataIds = Set(dayData.keys).intersection(allIds)

        // Normal case: active habits exist on this date
        if !activeIds.isEmpty {
            return activeIds.union(dataIds)
        }

        // Fallback: no habits were "active" on this date, but data exists.
        // This happens when user checked in via "yesterday" on the first day of usage
        // (habits created the next day). Include habits created within 1 day.
        let nextDay = cal.date(byAdding: .day, value: 1, to: date)!
        var fallbackIds = Set<String>()
        for habit in habits {
            if let deleted = habit.deletedAt,
               cal.compare(deleted, to: date, toGranularity: .day) == .orderedAscending {
                continue
            }
            if cal.compare(habit.createdAt, to: nextDay, toGranularity: .day) != .orderedDescending {
                fallbackIds.insert(habit.id)
            }
        }
        return fallbackIds.union(dataIds)
    }

    // MARK: - Habit date filtering

    /// Check if a habit existed (was active) on a specific date
    func habitWasActive(_ habit: Habit, on date: Date) -> Bool {
        let cal = Calendar.current
        // Not yet created
        if cal.compare(habit.createdAt, to: date, toGranularity: .day) == .orderedDescending {
            return false
        }
        // Already deleted before this date
        if let deleted = habit.deletedAt,
           cal.compare(deleted, to: date, toGranularity: .day) == .orderedAscending {
            return false
        }
        return true
    }

    /// Returns all habits that existed at any point during the given date range
    func habitsExisted(from start: Date, to end: Date) -> [Habit] {
        let cal = Calendar.current
        return habits.filter { habit in
            // Created on or before end of range
            guard cal.compare(habit.createdAt, to: end, toGranularity: .day) != .orderedDescending else { return false }
            // Not deleted before start of range
            if let deleted = habit.deletedAt {
                return cal.compare(deleted, to: start, toGranularity: .day) != .orderedAscending
            }
            return true
        }.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Analytics

    /// Compute per-habit stats for a given year, optionally scoped to a single month (0-indexed).
    func computeHabitStats(year: Int, month: Int? = nil) -> [HabitStat] {
        let monthRange: Range<Int> = month.map { $0..<($0 + 1) } ?? 0..<12

        var habitTracked: [String: Int] = [:]
        var habitDone: [String: Int] = [:]

        for m in monthRange {
            let days = daysInMonth(year: year, month: m)
            for day in 1...days {
                guard let d = makeDate(year: year, month: m, day: day) else { continue }
                if isFuture(d) && !isToday(d) { continue }
                let ids = trackedHabitIds(on: d)
                guard !ids.isEmpty else { continue }
                let ds = formatDate(d)
                let dayData = checkins[ds] ?? [:]
                for id in ids {
                    habitTracked[id, default: 0] += 1
                    if dayData[id] == 1 { habitDone[id, default: 0] += 1 }
                }
            }
        }

        var results: [HabitStat] = []
        for (habitId, tracked) in habitTracked {
            guard tracked > 0 else { continue }
            guard let habit = habits.first(where: { $0.id == habitId }) else { continue }
            let done = habitDone[habitId] ?? 0
            let rate = Double(done) / Double(tracked) * 100.0
            results.append(HabitStat(habit: habit, done: done, tracked: tracked, rate: rate))
        }

        return results.sorted {
            if $0.rate != $1.rate { return $0.rate > $1.rate }
            return $0.habit.sortOrder < $1.habit.sortOrder
        }
    }

    // MARK: - Habits

    func addHabit(name: String, emoji: String) {
        pushUndo()
        let maxOrder = activeHabits.map { $0.sortOrder }.max() ?? -1
        habits.append(Habit(name: name, emoji: emoji, sortOrder: maxOrder + 1))
        save()
    }

    func updateHabit(id: String, name: String, emoji: String) {
        pushUndo()
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].name = name
        habits[idx].emoji = emoji
        save()
    }

    func deleteHabit(id: String) {
        pushUndo()
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].deletedAt = Date()
        save()
    }

    func moveHabits(from source: IndexSet, to destination: Int) {
        pushUndo()
        var active = activeHabits
        active.move(fromOffsets: source, toOffset: destination)
        for (i, h) in active.enumerated() {
            if let idx = habits.firstIndex(where: { $0.id == h.id }) {
                habits[idx].sortOrder = i
            }
        }
        save()
    }

    // MARK: - Theme

    func setTheme(_ mode: String) {
        themeMode = mode
        save()
        applyThemeToWindows()
    }

    /// Applies the theme override directly to UIKit windows.
    /// This ensures sheets and other presented controllers follow the theme immediately.
    func applyThemeToWindows() {
        let style: UIUserInterfaceStyle = {
            switch themeMode {
            case "light": return .light
            case "dark":  return .dark
            default:      return .unspecified
            }
        }()
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }

    // MARK: - Language

    func setLanguage(_ value: String) {
        lang = value
        applyLanguage()
        save()
    }

    private func applyLanguage() {
        switch lang {
        case "ru": L10n.isRu = true
        case "en": L10n.isRu = false
        default:   L10n.isRu = Locale.current.language.languageCode?.identifier == "ru"
        }
    }

    // MARK: - Notifications

    func setNotifEnabled(_ enabled: Bool) {
        notifEnabled = enabled
        save()
        if enabled {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        self.scheduleDaily()
                    } else {
                        self.notifEnabled = false
                        self.save()
                    }
                }
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    func setNotifTime(hour: Int, minute: Int) {
        notifHour = hour
        notifMinute = minute
        save()
        if notifEnabled { scheduleDaily() }
    }

    func scheduleDaily() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "LifeTrack"
        content.body = L10n.randomReminder()
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: notifHour, minute: notifMinute),
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "lt_daily",
            content: content,
            trigger: trigger
        )
        center.add(request, withCompletionHandler: nil)
    }

    // MARK: - Persistence

    private func save() {
        if let d = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(d, forKey: habitsKey)
        }
        if let d = try? JSONEncoder().encode(checkins) {
            UserDefaults.standard.set(d, forKey: checkinsKey)
        }
        UserDefaults.standard.set(themeMode, forKey: themeKey)
        UserDefaults.standard.set(lang, forKey: langKey)
        UserDefaults.standard.set(notifEnabled, forKey: notifEnabledKey)
        UserDefaults.standard.set(notifHour, forKey: notifHourKey)
        UserDefaults.standard.set(notifMinute, forKey: notifMinuteKey)
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: habitsKey),
           let v = try? JSONDecoder().decode([Habit].self, from: d) {
            habits = v
        }
        if let d = UserDefaults.standard.data(forKey: checkinsKey),
           let v = try? JSONDecoder().decode([String: [String: Int]].self, from: d) {
            checkins = v
        }
        // Theme: migrate from legacy isDark bool
        if let saved = UserDefaults.standard.string(forKey: themeKey) {
            themeMode = saved
        } else if UserDefaults.standard.object(forKey: legacyThemeKey) != nil {
            themeMode = UserDefaults.standard.bool(forKey: legacyThemeKey) ? "dark" : "light"
            UserDefaults.standard.removeObject(forKey: legacyThemeKey)
        }
        lang = UserDefaults.standard.string(forKey: langKey) ?? "auto"
        applyLanguage()
        // Notifications
        notifEnabled = UserDefaults.standard.bool(forKey: notifEnabledKey)
        if UserDefaults.standard.object(forKey: notifHourKey) != nil {
            notifHour = UserDefaults.standard.integer(forKey: notifHourKey)
        }
        if UserDefaults.standard.object(forKey: notifMinuteKey) != nil {
            notifMinute = UserDefaults.standard.integer(forKey: notifMinuteKey)
        }
    }

    private func seedDefaults() {
        habits = L10n.defaultHabits.enumerated().map { i, d in
            Habit(name: d.1, emoji: d.0, sortOrder: i)
        }
        save()
    }
}
