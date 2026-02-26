import Foundation
import SwiftUI

class AppStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var checkins: [String: [String: Int]] = [:]  // date -> habitId -> 0|1
    @Published var isDark: Bool = false

    private let habitsKey = "lt_habits_v1"
    private let checkinsKey = "lt_checkins_v1"
    private let themeKey = "lt_isDark"

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
    }

    // MARK: - CheckIns

    func checkinValue(habitId: String, date: String) -> Int {
        checkins[date]?[habitId] ?? 0
    }

    /// Возвращает nil если нет данных вообще (будущее или нет записей)
    func dayStatus(date: String, habitId: String? = nil) -> DayStatus? {
        if let hid = habitId {
            guard let v = checkins[date]?[hid] else { return nil }
            return v == 1 ? DayStatus.all : DayStatus.none
        }

        guard let dayData = checkins[date], !dayData.isEmpty else { return nil }

        let relevantIds = Set(allHabits.map { $0.id })
        let relevant = dayData.filter { relevantIds.contains($0.key) }
        guard !relevant.isEmpty else { return nil }

        let done = relevant.values.filter { $0 == 1 }.count
        if done == 0 { return DayStatus.none }
        if done == relevant.count { return DayStatus.all }
        return DayStatus.partial
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
        checkins[date] = dayData
        save()
    }

    // MARK: - Streaks

    func currentStreak() -> Int {
        var streak = 0
        var date = yesterday()
        while true {
            let ds = formatDate(date)
            guard let status = dayStatus(date: ds), status != .none else { break }
            streak += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }
        return streak
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
        var cur = 0
        let days = daysInMonth(year: year, month: month)
        let now = Date()

        for day in stride(from: days, through: 1, by: -1) {
            guard let d = makeDate(year: year, month: month, day: day) else { continue }
            if d >= now && !Calendar.current.isDateInToday(d) { continue }
            if Calendar.current.isDateInToday(d) { continue }

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

    // MARK: - Habits

    func addHabit(name: String, emoji: String) {
        let maxOrder = activeHabits.map { $0.sortOrder }.max() ?? -1
        habits.append(Habit(name: name, emoji: emoji, sortOrder: maxOrder + 1))
        save()
    }

    func updateHabit(id: String, name: String, emoji: String) {
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].name = name
        habits[idx].emoji = emoji
        save()
    }

    func deleteHabit(id: String) {
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].deletedAt = Date()
        save()
    }

    func moveHabits(from source: IndexSet, to destination: Int) {
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

    func toggleDark() {
        isDark.toggle()
        save()
    }

    // MARK: - Persistence

    private func save() {
        if let d = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(d, forKey: habitsKey)
        }
        if let d = try? JSONEncoder().encode(checkins) {
            UserDefaults.standard.set(d, forKey: checkinsKey)
        }
        UserDefaults.standard.set(isDark, forKey: themeKey)
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
        isDark = UserDefaults.standard.bool(forKey: themeKey)
    }

    private func seedDefaults() {
        let defaults: [(String, String)] = [
            ("🛌", "Сон"), ("🚴", "Активность"), ("🥗", "Питание"),
            ("🧠", "Ментальное"), ("💻", "Проекты")
        ]
        habits = defaults.enumerated().map { i, d in
            Habit(name: d.1, emoji: d.0, sortOrder: i)
        }
        save()
    }
}
