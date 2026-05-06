import Foundation
@testable import LifeTrack

enum TestDates {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .iso8601)
        c.firstWeekday = 2
        c.timeZone = .current
        return c
    }()

    static func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d; comps.hour = hour
        return calendar.date(from: comps)!
    }

    /// Delegates to ReflectionEngine.iso8601DateString to guarantee tests
    /// and production read the same string format.
    static func dateString(_ date: Date) -> String {
        ReflectionEngine.iso8601DateString(date)
    }
}

enum TestStore {
    /// AppStore is not yet DI-aware for UserDefaults. Tests share .standard
    /// across cases; setUp/tearDown clean reflection-keyed UserDefaults via
    /// the suite-scoped instance owned by the test class. Habit/checkin state
    /// lives directly on the AppStore instance and is reset by `fresh`.
    static func fresh(suite: UserDefaults) -> AppStore {
        let store = AppStore()
        store.habits = []
        store.checkins = [:]
        return store
    }

    static func addHabit(
        _ store: AppStore,
        id: String = UUID().uuidString,
        name: String,
        emoji: String = "🎯",
        targetPerDay: Int? = nil,
        createdAt: Date,
        deletedAt: Date? = nil
    ) -> Habit {
        let habit = Habit(
            id: id,
            name: name,
            emoji: emoji,
            sortOrder: store.habits.count,
            createdAt: createdAt,
            deletedAt: deletedAt,
            targetPerDay: targetPerDay
        )
        store.habits.append(habit)
        return habit
    }

    /// Mark habit fully done on the given date.
    static func mark(_ store: AppStore, habit: Habit, on date: Date) {
        let ds = TestDates.dateString(date)
        var dayDict = store.checkins[ds] ?? [:]
        dayDict[habit.id] = habit.effectiveTarget
        store.checkins[ds] = dayDict
    }

    /// Mark habit done on every date in the inclusive range.
    static func markRange(_ store: AppStore, habit: Habit, from start: Date, to end: Date) {
        var d = start
        while d <= end {
            mark(store, habit: habit, on: d)
            d = TestDates.calendar.date(byAdding: .day, value: 1, to: d)!
        }
    }
}

extension UserDefaults {
    /// Convenience for tests — wipe everything in this suite.
    func wipe() {
        for (key, _) in dictionaryRepresentation() {
            removeObject(forKey: key)
        }
    }
}
