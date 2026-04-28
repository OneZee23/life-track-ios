import Foundation
import HealthKit
import SwiftUI
import UserNotifications

enum ThemeMode: String {
    case auto
    case light
    case dark

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .auto:  return .unspecified
        case .light: return .light
        case .dark:  return .dark
        }
    }
}

enum AppLanguage: String {
    case auto
    case ru
    case en
}

class AppStore: ObservableObject {
    @Published var habits: [Habit] = [] {
        didSet { _activeHabitIds = nil }
    }
    @Published var checkins: [String: [String: Int]] = [:]  // date -> habitId -> 0|1
    @Published var checkinExtras: [String: [String: CheckinExtra]] = [:]  // date -> habitId -> extra
    @Published var themeMode: ThemeMode = .auto
    @Published var lang: AppLanguage = .auto
    @Published var notifEnabled: Bool = false
    @Published var notifHour: Int = 21
    @Published var notifMinute: Int = 0
    @Published var onboardingCompleted: Bool = false

    private let habitsKey = "lt_habits_v1"
    private let checkinsKey = "lt_checkins_v1"
    private let themeKey = "lt_theme"
    private let legacyThemeKey = "lt_isDark"
    private let langKey = "lt_lang"
    private let notifEnabledKey = "lt_notif_enabled"
    private let notifHourKey    = "lt_notif_hour"
    private let notifMinuteKey  = "lt_notif_minute"
    private let greetingDateKey = "lt_greeting_shown_date"
    private let onboardingKey = "lt_onboarding_completed"
    private let extrasKey = "lt_checkin_extras_v1"
    private let schemaVersionKey = "lt_schema_version"
    private let backupPrefix = "lt_backup_"
    private let healthKit = HealthKitService()

    /// Increment when adding migrations.
    private static let currentSchemaVersion = 2

    // MARK: - Undo/Redo

    private struct Snapshot {
        let habits: [Habit]
        let checkins: [String: [String: Int]]
        let checkinExtras: [String: [String: CheckinExtra]]
    }

    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []
    private let maxUndo = AppConstants.maxUndoStack

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    private func pushUndo() {
        undoStack.append(Snapshot(habits: habits, checkins: checkins, checkinExtras: checkinExtras))
        if undoStack.count > maxUndo { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    func undo() {
        guard let snap = undoStack.popLast() else { return }
        redoStack.append(Snapshot(habits: habits, checkins: checkins, checkinExtras: checkinExtras))
        habits = snap.habits
        checkins = snap.checkins
        checkinExtras = snap.checkinExtras
        save()
        rescheduleAllNotifications()
    }

    func redo() {
        guard let snap = redoStack.popLast() else { return }
        undoStack.append(Snapshot(habits: habits, checkins: checkins, checkinExtras: checkinExtras))
        habits = snap.habits
        checkins = snap.checkins
        checkinExtras = snap.checkinExtras
        save()
        rescheduleAllNotifications()
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

    init() {
        migrateIfNeeded()
        load()
        if habits.isEmpty && !hasExistingCheckinData() {
            seedDefaults()
        }
        let hasAnyReminders = habits.contains { $0.reminder != nil }
        if notifEnabled || hasAnyReminders { rescheduleAllNotifications() }
    }

    // MARK: - CheckIns

    func checkinValue(habitId: String, date: String) -> Int {
        checkins[date]?[habitId] ?? 0
    }

    /// Soft-done: day counts as completed if at least one check-in exists.
    /// Used by streak, day status, and analytics.
    func isCheckedIn(habitId: String, date: String) -> Bool {
        checkinValue(habitId: habitId, date: date) >= 1
    }

    /// Возвращает nil если нет данных вообще (будущее или нет записей)
    func dayStatus(date: String, habitId: String? = nil) -> DayStatus? {
        if let hid = habitId {
            guard let v = checkins[date]?[hid] else { return nil }
            return v >= 1 ? DayStatus.full : DayStatus.none
        }

        guard let dayData = checkins[date], !dayData.isEmpty else { return nil }
        guard let dateObj = parseDate(date) else { return nil }

        let relevantIds = trackedHabitIds(on: dateObj)
        let relevant = dayData.filter { relevantIds.contains($0.key) }
        guard !relevant.isEmpty else { return nil }

        let done = relevant.values.filter { $0 >= 1 }.count
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
        let habit = habits.first { $0.id == habitId }
        let target = max(1, habit?.effectiveTarget ?? 1)
        let current = dayData[habitId] ?? 0
        if target > 1 {
            // Count-based: tap = +1, no upper cap (overflow above target is allowed).
            dayData[habitId] = current + 1
        } else {
            dayData[habitId] = current >= 1 ? 0 : 1
        }
        // Ensure all active habits have explicit entries (0 if untouched)
        for h in activeHabits {
            if dayData[h.id] == nil {
                dayData[h.id] = 0
            }
        }
        checkins[date] = dayData
        save()
    }

    func decrementCheckin(habitId: String, date: String) {
        var dayData = checkins[date] ?? [:]
        let current = dayData[habitId] ?? 0
        guard current > 0 else { return }
        dayData[habitId] = current - 1
        for h in activeHabits where dayData[h.id] == nil {
            dayData[h.id] = 0
        }
        checkins[date] = dayData
        save()
    }

    // MARK: - Checkin Extras

    func getExtra(habitId: String, date: String) -> CheckinExtra? {
        checkinExtras[date]?[habitId]
    }

    func setExtra(habitId: String, date: String, extra: CheckinExtra) {
        if checkinExtras[date] == nil {
            checkinExtras[date] = [:]
        }
        checkinExtras[date]?[habitId] = extra
        save()
    }

    func clearExtra(habitId: String, date: String) {
        checkinExtras[date]?.removeValue(forKey: habitId)
        if checkinExtras[date]?.isEmpty == true {
            checkinExtras.removeValue(forKey: date)
        }
        save()
    }

    // MARK: - Notes (free-form per-day note, separate from extendedField)

    func getNote(habitId: String, date: String) -> String? {
        checkinExtras[date]?[habitId]?.noteValue
    }

    func hasNote(habitId: String, date: String) -> Bool {
        guard let note = getNote(habitId: habitId, date: date) else { return false }
        return !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Sets/clears the per-day note. Empty/whitespace clears it.
    /// Note text is capped at 2000 chars to keep the UserDefaults blob bounded.
    func setNote(habitId: String, date: String, note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        var extra = checkinExtras[date]?[habitId] ?? CheckinExtra()
        extra.noteValue = trimmed.isEmpty ? nil : String(trimmed.prefix(2000))

        // If the entire extra becomes empty, drop it to keep storage clean.
        if extra.numericValue == nil && extra.textValue == nil && extra.ratingValue == nil && extra.noteValue == nil {
            clearExtra(habitId: habitId, date: date)
            return
        }
        if checkinExtras[date] == nil { checkinExtras[date] = [:] }
        checkinExtras[date]?[habitId] = extra
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
            guard let prev = cal.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
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
        habitStreakWhere(habitId: habitId, asOf: date) { $0 >= 1 }
    }

    /// Walks consecutive days backwards from `date`, counting while `predicate`
    /// holds. Single source of truth for both the soft streak (`>= 1`) and
    /// the perfect-day streak (`>= target`).
    private func habitStreakWhere(habitId: String,
                                  asOf date: Date,
                                  predicate: (Int) -> Bool) -> Int {
        let cal = Calendar.current
        var streak = 0
        var d = date
        while true {
            let ds = formatDate(d)
            guard let v = checkins[ds]?[habitId], predicate(v) else { break }
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
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
        let done = ids.filter { (dayData[$0] ?? 0) >= 1 }.count
        return (done, ids.count)
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        onboardingCompleted = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func resetOnboarding() {
        onboardingCompleted = false
        UserDefaults.standard.set(false, forKey: onboardingKey)
    }

    // MARK: - Compassionate Coach

    func missedDaysCount() -> Int {
        let cal = Calendar.current
        var count = 0
        var date = yesterday()

        for _ in 0..<AppConstants.daysLookback {
            let ds = formatDate(date)
            let status = dayStatus(date: ds)

            if let s = status, s != .none { break }

            let trackedIds = trackedHabitIds(on: date)
            if trackedIds.isEmpty { break }

            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }

        return count
    }

    func longestMissedHabit() -> Habit? {
        let cal = Calendar.current
        var worst: (habit: Habit, count: Int)? = nil

        for habit in activeHabits {
            var count = 0
            var date = yesterday()

            for _ in 0..<AppConstants.daysLookback {
                guard habitWasActive(habit, on: date) else { break }

                let ds = formatDate(date)
                if let v = checkins[ds]?[habit.id], v >= 1 { break }

                let trackedIds = trackedHabitIds(on: date)
                if trackedIds.isEmpty { break }

                count += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: date) else { break }
                date = prev
            }

            if count >= 3 {
                if worst == nil || count > worst!.count {
                    worst = (habit, count)
                }
            }
        }

        return worst?.habit
    }

    func coachMessage() -> String? {
        let missed = missedDaysCount()
        if missed == 0 { return nil }
        if missed == 1 { return L10n.coachMissed1 }
        if missed <= 3 { return L10n.coachMissed2 }
        if missed <= 7 { return L10n.coachMissed4 }
        return L10n.coachMissed7
    }

    func coachEmoji() -> String {
        let missed = missedDaysCount()
        if missed == 0 { return "" }
        if missed == 1 { return "💛" }
        if missed <= 3 { return "🌱" }
        if missed <= 7 { return "🌤️" }
        return "✨"
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
        guard let nextDay = cal.date(byAdding: .day, value: 1, to: date) else { return dataIds }
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
        let habitById = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })

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
                    if (dayData[id] ?? 0) >= 1 { habitDone[id, default: 0] += 1 }
                }
            }
        }

        var results: [HabitStat] = []
        for (habitId, tracked) in habitTracked {
            guard tracked > 0 else { continue }
            guard let habit = habitById[habitId] else { continue }
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

    func addHabit(name: String, emoji: String, extendedField: ExtendedFieldConfig? = nil, healthKitWorkoutType: String? = nil, healthKitMetricType: String? = nil, reminder: HabitReminder? = nil, targetPerDay: Int? = nil) {
        pushUndo()
        let maxOrder = activeHabits.map { $0.sortOrder }.max() ?? -1
        habits.append(Habit(name: name, emoji: emoji, sortOrder: maxOrder + 1, extendedField: extendedField, healthKitWorkoutType: healthKitWorkoutType, healthKitMetricType: healthKitMetricType, reminder: reminder, targetPerDay: targetPerDay))
        save()
        rescheduleAllNotifications()
    }

    func updateHabit(id: String, name: String, emoji: String, extendedField: ExtendedFieldConfig? = nil, healthKitWorkoutType: String? = nil, healthKitMetricType: String? = nil, reminder: HabitReminder? = nil, targetPerDay: Int? = nil) {
        pushUndo()
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].name = name
        habits[idx].emoji = emoji
        habits[idx].extendedField = extendedField
        habits[idx].healthKitWorkoutType = healthKitWorkoutType
        habits[idx].healthKitMetricType = healthKitMetricType
        habits[idx].reminder = reminder
        habits[idx].targetPerDay = targetPerDay
        save()
        rescheduleAllNotifications()
    }

    func deleteHabit(id: String) {
        pushUndo()
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].deletedAt = Date()
        save()
        rescheduleAllNotifications()
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

    // MARK: - HealthKit Sync

    func requestHealthKitAccess() async -> Bool {
        await healthKit.requestAuthorization()
    }

    @MainActor
    func syncHealthKitWorkouts() async {
        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        let yesterday = cal.date(byAdding: .day, value: -1, to: now) ?? now
        let startOfYesterday = cal.startOfDay(for: yesterday)
        let todayStr = formatDate(now)
        let yesterdayStr = formatDate(yesterday)
        var changed = false

        // MARK: - Workout sync
        let workoutLinked = activeHabits.filter { $0.healthKitWorkoutType != nil }
        if !workoutLinked.isEmpty {
            let todayTypes = await healthKit.fetchWorkoutTypes(from: startOfToday, to: now)
            let yesterdayTypes = await healthKit.fetchWorkoutTypes(from: startOfYesterday, to: startOfToday)

            for habit in workoutLinked {
                guard let typeStr = habit.healthKitWorkoutType,
                      let workoutType = WorkoutType(rawValue: typeStr) else { continue }

                let hkType = HealthKitService.hkActivityType(for: workoutType)

                for (dateStr, types, rangeStart, rangeEnd) in [
                    (todayStr, todayTypes, startOfToday, now),
                    (yesterdayStr, yesterdayTypes, startOfYesterday, startOfToday)
                ] {
                    if types.contains(hkType.rawValue) && checkinValue(habitId: habit.id, date: dateStr) == 0 {
                        if checkins[dateStr] == nil { checkins[dateStr] = [:] }
                        checkins[dateStr]?[habit.id] = 1
                        changed = true

                        if workoutType.hasDistance {
                            if let km = await healthKit.fetchWorkoutDistance(type: hkType, from: rangeStart, to: rangeEnd), km > 0 {
                                if checkinExtras[dateStr] == nil { checkinExtras[dateStr] = [:] }
                                checkinExtras[dateStr]?[habit.id] = CheckinExtra(numericValue: km)
                            }
                        }
                    }
                }
            }
        }

        // --- Metric sync (sleep / steps) ---
        let metricLinked = activeHabits.filter { $0.healthKitMetricType != nil }
        for habit in metricLinked {
            guard let metricStr = habit.healthKitMetricType,
                  let metric = HealthKitMetricType(rawValue: metricStr) else { continue }

            switch metric {
            case .sleep:
                // Sleep window: 18:00 previous day → 12:00 current day
                let todaySleepStart = cal.date(bySettingHour: 18, minute: 0, second: 0, of: yesterday) ?? startOfYesterday
                let todaySleepEnd = cal.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? startOfToday
                let yesterdaySleepStart = cal.date(byAdding: .day, value: -1, to: todaySleepStart) ?? startOfYesterday
                let yesterdaySleepEnd = cal.date(byAdding: .day, value: -1, to: todaySleepEnd) ?? startOfYesterday

                for (dateStr, sleepStart, sleepEnd) in [
                    (todayStr, todaySleepStart, todaySleepEnd),
                    (yesterdayStr, yesterdaySleepStart, yesterdaySleepEnd)
                ] {
                    guard checkinValue(habitId: habit.id, date: dateStr) == 0 else { continue }
                    if let rawMinutes = await healthKit.fetchSleepDuration(from: sleepStart, to: sleepEnd), rawMinutes > 0 {
                        let minutes = rawMinutes.rounded()
                        if checkins[dateStr] == nil { checkins[dateStr] = [:] }
                        checkins[dateStr]?[habit.id] = 1
                        if checkinExtras[dateStr] == nil { checkinExtras[dateStr] = [:] }
                        checkinExtras[dateStr]?[habit.id] = CheckinExtra(numericValue: minutes)
                        changed = true
                    }
                }

            case .steps:
                for (dateStr, stepStart, stepEnd) in [
                    (todayStr, startOfToday, now),
                    (yesterdayStr, startOfYesterday, startOfToday)
                ] {
                    if let steps = await healthKit.fetchStepCount(from: stepStart, to: stepEnd), steps > 0 {
                        // Always update step value (it grows throughout the day)
                        let existing = checkinExtras[dateStr]?[habit.id]?.numericValue
                        if existing == steps { continue } // value unchanged, skip
                        if checkins[dateStr] == nil { checkins[dateStr] = [:] }
                        if checkinExtras[dateStr] == nil { checkinExtras[dateStr] = [:] }
                        checkins[dateStr]?[habit.id] = 1
                        checkinExtras[dateStr]?[habit.id] = CheckinExtra(numericValue: steps)
                        changed = true
                    }
                }
            }
        }

        if changed { save() }
    }

    // MARK: - Theme

    func setTheme(_ mode: ThemeMode) {
        themeMode = mode
        save()
        applyThemeToWindows()
    }

    /// Applies the theme override directly to UIKit windows.
    /// This ensures sheets and other presented controllers follow the theme immediately.
    func applyThemeToWindows() {
        let style = themeMode.interfaceStyle
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }

    // MARK: - Language

    func setLanguage(_ value: AppLanguage) {
        lang = value
        applyLanguage()
        save()
        rescheduleAllNotifications()
    }

    private func applyLanguage() {
        switch lang {
        case .ru:   L10n.isRu = true
        case .en:   L10n.isRu = false
        case .auto: L10n.isRu = Locale.current.language.languageCode?.identifier == "ru"
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
                        self.rescheduleAllNotifications()
                    } else {
                        self.notifEnabled = false
                        self.save()
                    }
                }
            }
        } else {
            rescheduleAllNotifications()
        }
    }

    func setNotifTime(hour: Int, minute: Int) {
        notifHour = hour
        notifMinute = minute
        save()
        rescheduleAllNotifications()
    }

    func rescheduleAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        var budget = AppConstants.maxLocalNotifications

        // 1. Global daily reminder
        if notifEnabled {
            let content = UNMutableNotificationContent()
            content.title = L10n.appTitle
            content.body = L10n.randomReminder()
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: notifHour, minute: notifMinute),
                repeats: true
            )
            center.add(UNNotificationRequest(
                identifier: AppConstants.notificationIdentifier,
                content: content,
                trigger: trigger
            ))
            budget -= 1
        }

        // 2. Per-habit reminders
        for habit in activeHabits {
            guard let reminder = habit.reminder, !reminder.weekdays.isEmpty else { continue }
            let used = scheduleHabitNotifications(habit: habit, reminder: reminder, budget: budget)
            budget -= used
            if budget <= 0 { break }
        }
    }

    @discardableResult
    private func scheduleHabitNotifications(habit: Habit, reminder: HabitReminder, budget: Int) -> Int {
        let center = UNUserNotificationCenter.current()
        let hours = reminder.scheduledHours
        var scheduled = 0

        for weekday in reminder.weekdays.sorted() {
            for hour in hours {
                guard scheduled < budget else { return scheduled }

                var dc = DateComponents()
                dc.weekday = isoToAppleWeekday(weekday)
                dc.hour = hour
                dc.minute = 0

                let content = UNMutableNotificationContent()
                content.title = "\(habit.emoji) \(habit.name)"
                content.body = L10n.habitReminderBody(habit.name)
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let id = "lt_habit_\(habit.id)_\(weekday)_\(hour)"
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
                scheduled += 1
            }
        }
        return scheduled
    }

    // MARK: - Schema Migration

    private func migrateIfNeeded() {
        let stored = UserDefaults.standard.integer(forKey: schemaVersionKey)
        guard stored < Self.currentSchemaVersion else { return }

        backupCurrentData(version: stored)

        if stored < 1 {
            migrateV0toV1()
        }
        if stored < 2 {
            migrateV1toV2()
        }

        UserDefaults.standard.set(Self.currentSchemaVersion, forKey: schemaVersionKey)
    }

    /// Backup raw data blobs before migration (byte-copy, no decoding).
    private func backupCurrentData(version: Int) {
        let ud = UserDefaults.standard
        let ts = Int(Date().timeIntervalSince1970)
        for key in [habitsKey, checkinsKey, extrasKey] {
            if let data = ud.data(forKey: key) {
                ud.set(data, forKey: "\(backupPrefix)\(key)_v\(version)_\(ts)")
            }
        }
    }

    /// Attempt to recover orphaned checkin data for users who already lost habits
    /// due to Codable decode failure + seedDefaults overwrite.
    private func migrateV0toV1() {
        let ud = UserDefaults.standard
        guard let habitsData = ud.data(forKey: habitsKey),
              let checkinsData = ud.data(forKey: checkinsKey) else { return }

        let currentHabits = [Habit].safeDecoded(from: habitsData)
        guard let allCheckins = try? JSONDecoder().decode(
            [String: [String: Int]].self, from: checkinsData
        ) else { return }

        // Find habit IDs referenced in checkins but missing from current habits
        let checkinIds = Set(allCheckins.values.flatMap(\.keys))
        let habitIds = Set(currentHabits.map(\.id))
        let orphaned = checkinIds.subtracting(habitIds)

        // Only attempt remap if:
        // - there ARE orphaned IDs
        // - current habits look like fresh seeds (created <60 sec ago)
        // - orphan count matches habit count (clean seed-over-old-data scenario)
        guard !orphaned.isEmpty,
              currentHabits.allSatisfy({ $0.createdAt.timeIntervalSinceNow > -60 }),
              orphaned.count == currentHabits.count else { return }

        let oldSorted = orphaned.sorted()
        let newSorted = currentHabits.sorted { $0.sortOrder < $1.sortOrder }

        var remap: [String: String] = [:]
        for (old, new) in zip(oldSorted, newSorted) {
            remap[old] = new.id
        }

        // Remap checkins
        var remapped: [String: [String: Int]] = [:]
        for (date, day) in allCheckins {
            var newDay: [String: Int] = [:]
            for (hid, val) in day {
                newDay[remap[hid] ?? hid] = val
            }
            remapped[date] = newDay
        }
        if let enc = try? JSONEncoder().encode(remapped) {
            ud.set(enc, forKey: checkinsKey)
        }

        // Remap extras
        if let extData = ud.data(forKey: extrasKey),
           let extras = try? JSONDecoder().decode([String: [String: CheckinExtra]].self, from: extData) {
            var remappedExtras: [String: [String: CheckinExtra]] = [:]
            for (date, day) in extras {
                var newDay: [String: CheckinExtra] = [:]
                for (hid, extra) in day {
                    newDay[remap[hid] ?? hid] = extra
                }
                remappedExtras[date] = newDay
            }
            if let enc = try? JSONEncoder().encode(remappedExtras) {
                ud.set(enc, forKey: extrasKey)
            }
        }

        // Update createdAt to distantPast (these habits inherited real user data)
        var updated = currentHabits
        for i in updated.indices {
            updated[i].createdAt = .distantPast
        }
        if let enc = try? JSONEncoder().encode(updated) {
            ud.set(enc, forKey: habitsKey)
        }
    }

    /// Update sleep habit config to canonical step=15 for existing users.
    private func migrateV1toV2() {
        let ud = UserDefaults.standard
        guard let habitsData = ud.data(forKey: habitsKey) else { return }
        var stored = [Habit].safeDecoded(from: habitsData)

        let sleepConfig = ExtendedFieldConfig.sleepDefault
        var changed = false
        for i in stored.indices where stored[i].healthKitMetricType == HealthKitMetricType.sleep.rawValue {
            stored[i].extendedField = sleepConfig
            changed = true
        }
        if changed, let enc = try? JSONEncoder().encode(stored) {
            ud.set(enc, forKey: habitsKey)
        }
    }

    // MARK: - Habit Detail Data

    func habitHistory(habitId: String, days: Int) -> [(date: String, done: Bool, value: Double?)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let habit = habits.first { $0.id == habitId }
        var results: [(date: String, done: Bool, value: Double?)] = []
        for i in 0..<days {
            guard let date = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            let ds = formatDate(date)
            let hasData = checkins[ds]?[habitId] != nil
            let wasActive = habit.map { habitWasActive($0, on: date) } ?? false
            // Include dates where habit was active OR has existing data (e.g. auto-synced before creation)
            guard wasActive || hasData else { continue }
            let done = isCheckedIn(habitId: habitId, date: ds)
            let value = checkinExtras[ds]?[habitId]?.numericValue
            results.append((date: ds, done: done, value: value))
        }
        return results
    }

    func habitAverage(habitId: String, days: Int) -> Double? {
        let history = habitHistory(habitId: habitId, days: days)
        let values = history.compactMap(\.value)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    func habitMin(habitId: String, days: Int) -> Double? {
        habitHistory(habitId: habitId, days: days).compactMap(\.value).min()
    }

    func habitMax(habitId: String, days: Int) -> Double? {
        habitHistory(habitId: habitId, days: days).compactMap(\.value).max()
    }

    // MARK: - Count-based Habit Stats

    /// Returns daily count history for a count-based habit, including the target
    /// effective on the day the snapshot is taken. Empty value entries (days when
    /// the habit was inactive and has no data) are filtered out.
    func habitCountHistory(habitId: String, days: Int) -> [(date: String, value: Int, target: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let habit = habits.first(where: { $0.id == habitId }) else { return [] }
        let target = habit.effectiveTarget
        var results: [(date: String, value: Int, target: Int)] = []
        for i in 0..<days {
            guard let date = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            let ds = formatDate(date)
            let hasData = checkins[ds]?[habitId] != nil
            let wasActive = habitWasActive(habit, on: date)
            guard wasActive || hasData else { continue }
            results.append((date: ds, value: checkinValue(habitId: habitId, date: ds), target: target))
        }
        return results
    }

    /// Streak of days where value reached the target (not just ≥1).
    func habitPerfectStreak(habitId: String, asOf date: Date) -> Int {
        guard let habit = habits.first(where: { $0.id == habitId }) else { return 0 }
        let target = habit.effectiveTarget
        return habitStreakWhere(habitId: habitId, asOf: date) { $0 >= target }
    }

    // MARK: - Persistence

    private func save() {
        if let d = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(d, forKey: habitsKey)
        }
        if let d = try? JSONEncoder().encode(checkins) {
            UserDefaults.standard.set(d, forKey: checkinsKey)
        }
        if let d = try? JSONEncoder().encode(checkinExtras) {
            UserDefaults.standard.set(d, forKey: extrasKey)
        }
        UserDefaults.standard.set(themeMode.rawValue, forKey: themeKey)
        UserDefaults.standard.set(lang.rawValue, forKey: langKey)
        UserDefaults.standard.set(notifEnabled, forKey: notifEnabledKey)
        UserDefaults.standard.set(notifHour, forKey: notifHourKey)
        UserDefaults.standard.set(notifMinute, forKey: notifMinuteKey)
    }

    private func load() {
        // Safe array decoding: one corrupt habit doesn't nuke the rest
        if let d = UserDefaults.standard.data(forKey: habitsKey) {
            let decoded = [Habit].safeDecoded(from: d)
            if !decoded.isEmpty { habits = decoded }
        }
        if let d = UserDefaults.standard.data(forKey: checkinsKey),
           let v = try? JSONDecoder().decode([String: [String: Int]].self, from: d) {
            checkins = v
        }
        if let d = UserDefaults.standard.data(forKey: extrasKey),
           let v = try? JSONDecoder().decode([String: [String: CheckinExtra]].self, from: d) {
            checkinExtras = v
        }
        // Theme: migrate from legacy isDark bool
        if let saved = UserDefaults.standard.string(forKey: themeKey),
           let mode = ThemeMode(rawValue: saved) {
            themeMode = mode
        } else if UserDefaults.standard.object(forKey: legacyThemeKey) != nil {
            themeMode = UserDefaults.standard.bool(forKey: legacyThemeKey) ? .dark : .light
            UserDefaults.standard.removeObject(forKey: legacyThemeKey)
        }
        if let savedLang = UserDefaults.standard.string(forKey: langKey),
           let parsedLang = AppLanguage(rawValue: savedLang) {
            lang = parsedLang
        }
        applyLanguage()
        // Notifications
        notifEnabled = UserDefaults.standard.bool(forKey: notifEnabledKey)
        if UserDefaults.standard.object(forKey: notifHourKey) != nil {
            notifHour = UserDefaults.standard.integer(forKey: notifHourKey)
        }
        if UserDefaults.standard.object(forKey: notifMinuteKey) != nil {
            notifMinute = UserDefaults.standard.integer(forKey: notifMinuteKey)
        }
        onboardingCompleted = UserDefaults.standard.bool(forKey: onboardingKey)

        // Migrate sleep data: hours → minutes (v0.5.0)
        migrateSleepToMinutes()
    }

    /// One-time migration: convert sleep numeric values from hours to minutes.
    /// Pre-v0.5.0 stored sleep as hours (e.g. 7.5), now we store minutes (e.g. 450).
    /// Detect by: value < 24 means it's likely hours.
    /// One-time v0.5.0 migration: sleep hours → minutes.
    /// Flag set BEFORE mutation so crash-restart won't double-convert.
    /// Values < 24 are treated as hours; after ×60 they become >= 60, so re-run is safe.
    private func migrateSleepToMinutes() {
        let migrationKey = "lt_sleep_minutes_migrated"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        UserDefaults.standard.set(true, forKey: migrationKey)

        let sleepHabitIds = Set(habits.filter(\.isSleep).map(\.id))
        guard !sleepHabitIds.isEmpty else { return }

        var anyChanged = false
        for (dateStr, extras) in checkinExtras {
            for habitId in sleepHabitIds {
                if let extra = extras[habitId], let val = extra.numericValue, val > 0 && val < 24 {
                    checkinExtras[dateStr]?[habitId] = CheckinExtra(numericValue: val * 60)
                    anyChanged = true
                }
            }
        }

        if anyChanged { save() }
    }

    /// Returns true if checkin data exists in UserDefaults, even if habits failed to decode.
    private func hasExistingCheckinData() -> Bool {
        guard let d = UserDefaults.standard.data(forKey: checkinsKey),
              let v = try? JSONDecoder().decode([String: [String: Int]].self, from: d)
        else { return false }
        return !v.isEmpty
    }

    private func seedDefaults() {
        habits = L10n.defaultHabits.enumerated().map { i, d in
            Habit(name: d.1, emoji: d.0, sortOrder: i)
        }
        save()
    }
}
