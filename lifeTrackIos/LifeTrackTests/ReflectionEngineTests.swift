import XCTest
@testable import LifeTrack

final class ReflectionEngineTests: XCTestCase {
    var defaults: UserDefaults!
    let suiteName = "ReflectionEngineTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.wipe()
    }

    override func tearDown() {
        defaults.wipe()
        super.tearDown()
    }

    // MARK: - Drift

    func testDrift_brandNewHabit_returnsNil() {
        let store = TestStore.fresh(suite: defaults)
        let today = TestDates.date(2026, 5, 6)
        let h = TestStore.addHabit(store, name: "Run", createdAt: TestDates.calendar.date(byAdding: .day, value: -10, to: today)!)
        for offset in 1...5 {
            TestStore.mark(store, habit: h, on: TestDates.calendar.date(byAdding: .day, value: -offset, to: today)!)
        }

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }

    func testDrift_dailyHabit_threeDayGap_fires() {
        let store = TestStore.fresh(suite: defaults)
        let today = TestDates.date(2026, 5, 6)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -40, to: today)!
        let h = TestStore.addHabit(store, name: "Run", createdAt: createdAt)
        for offset in 4...38 {
            TestStore.mark(store, habit: h, on: TestDates.calendar.date(byAdding: .day, value: -offset, to: today)!)
        }

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        guard case .drift(let habit, let days, _)? = engine.currentReflection() else {
            return XCTFail("expected .drift, got nil or weekly")
        }
        XCTAssertEqual(habit.id, h.id)
        XCTAssertEqual(days, 3)
    }

    func testDrift_dailyHabit_oneDayGap_doesNotFire() {
        let store = TestStore.fresh(suite: defaults)
        let today = TestDates.date(2026, 5, 6)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -40, to: today)!
        let h = TestStore.addHabit(store, name: "Run", createdAt: createdAt)
        for offset in 2...39 {
            TestStore.mark(store, habit: h, on: TestDates.calendar.date(byAdding: .day, value: -offset, to: today)!)
        }

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }

    func testDrift_dailyHabit_elevenDayGap_doesNotFire() {
        let store = TestStore.fresh(suite: defaults)
        let today = TestDates.date(2026, 5, 6)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -50, to: today)!
        let h = TestStore.addHabit(store, name: "Run", createdAt: createdAt)
        for offset in 12...48 {
            TestStore.mark(store, habit: h, on: TestDates.calendar.date(byAdding: .day, value: -offset, to: today)!)
        }

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }

    func testDrift_weekendSkipper_doesNotFire() {
        let store = TestStore.fresh(suite: defaults)
        let today = TestDates.date(2026, 5, 4)  // Monday
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -50, to: today)!
        let h = TestStore.addHabit(store, name: "Workout", createdAt: createdAt)
        var d = createdAt
        while d <= TestDates.calendar.date(byAdding: .day, value: -1, to: today)! {
            let weekday = TestDates.calendar.component(.weekday, from: d)
            // 2=Mon ... 6=Fri in iso8601 with Monday firstWeekday
            if (2...6).contains(weekday) {
                TestStore.mark(store, habit: h, on: d)
            }
            d = TestDates.calendar.date(byAdding: .day, value: 1, to: d)!
        }

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }

    func testDrift_cooldown_sevenDays_blocks() {
        let store = TestStore.fresh(suite: defaults)
        let today = TestDates.date(2026, 5, 6)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -40, to: today)!
        let h = TestStore.addHabit(store, name: "Run", createdAt: createdAt)
        for offset in 4...38 {
            TestStore.mark(store, habit: h, on: TestDates.calendar.date(byAdding: .day, value: -offset, to: today)!)
        }
        let threeDaysAgo = TestDates.calendar.date(byAdding: .day, value: -3, to: today)!
        defaults.set(ReflectionEngine.todayKey(threeDaysAgo), forKey: ReflectionEngine.Keys.driftSeen(habitId: h.id))

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }

    func testDrift_archivedHabit_doesNotFire() {
        let store = TestStore.fresh(suite: defaults)
        let today = TestDates.date(2026, 5, 6)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -40, to: today)!
        let h = TestStore.addHabit(store, name: "Run", createdAt: createdAt,
                                   deletedAt: TestDates.calendar.date(byAdding: .day, value: -1, to: today)!)
        for offset in 4...38 {
            TestStore.mark(store, habit: h, on: TestDates.calendar.date(byAdding: .day, value: -offset, to: today)!)
        }

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }

    // MARK: - Weekly

    func testWeekly_zeroDays_returnsZeroBucket() {
        let store = TestStore.fresh(suite: defaults)
        let mondayAfterEmptyWeek = TestDates.date(2026, 5, 4)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -30, to: mondayAfterEmptyWeek)!
        _ = TestStore.addHabit(store, name: "Run", createdAt: createdAt)

        let engine = ReflectionEngine(store: store, now: mondayAfterEmptyWeek, defaults: defaults)
        guard case .weekly(let days, _, _)? = engine.currentReflection() else {
            return XCTFail("expected .weekly, got nil or drift")
        }
        XCTAssertEqual(days, 0)
    }

    func testWeekly_sevenDays_returnsFullBucket() {
        let store = TestStore.fresh(suite: defaults)
        let mondayAfterFullWeek = TestDates.date(2026, 5, 4)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -30, to: mondayAfterFullWeek)!
        let h = TestStore.addHabit(store, name: "Run", createdAt: createdAt)
        let priorWeekMon = TestDates.date(2026, 4, 27)
        let priorWeekSun = TestDates.date(2026, 5, 3)
        TestStore.markRange(store, habit: h, from: priorWeekMon, to: priorWeekSun)

        let engine = ReflectionEngine(store: store, now: mondayAfterFullWeek, defaults: defaults)
        guard case .weekly(let days, _, _)? = engine.currentReflection() else {
            return XCTFail("expected .weekly")
        }
        XCTAssertEqual(days, 7)
    }

    func testWeekly_outsideWindow_returnsNil() {
        let store = TestStore.fresh(suite: defaults)
        let wednesday = TestDates.date(2026, 5, 6)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -30, to: wednesday)!
        _ = TestStore.addHabit(store, name: "Run", createdAt: createdAt)

        let engine = ReflectionEngine(store: store, now: wednesday, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }

    func testWeekly_sundayBefore1800_returnsNil() {
        let store = TestStore.fresh(suite: defaults)
        let sunEvening = TestDates.date(2026, 5, 3, hour: 17)  // Sunday 17:00 — before window opens
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -30, to: sunEvening)!
        _ = TestStore.addHabit(store, name: "Run", createdAt: createdAt)

        let engine = ReflectionEngine(store: store, now: sunEvening, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }

    func testWeekly_sundayAt1800_isInWindow() {
        let store = TestStore.fresh(suite: defaults)
        let sunEvening = TestDates.date(2026, 5, 3, hour: 18)  // Sunday 18:00 — window opens
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -30, to: sunEvening)!
        _ = TestStore.addHabit(store, name: "Run", createdAt: createdAt)

        let engine = ReflectionEngine(store: store, now: sunEvening, defaults: defaults)
        guard case .weekly? = engine.currentReflection() else {
            return XCTFail("expected .weekly at Sun 18:00")
        }
    }

    func testWeekly_tuesdayLate_isInWindow() {
        let store = TestStore.fresh(suite: defaults)
        let tuesday2330 = TestDates.date(2026, 5, 5, hour: 23)  // Tuesday 23:00 — last hour of window
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -30, to: tuesday2330)!
        _ = TestStore.addHabit(store, name: "Run", createdAt: createdAt)

        let engine = ReflectionEngine(store: store, now: tuesday2330, defaults: defaults)
        guard case .weekly? = engine.currentReflection() else {
            return XCTFail("expected .weekly on Tuesday late")
        }
    }

    func testDrift_irregularCadence_belowFloor_doesNotFire() {
        // Habit done every other day for 60 days — median gap = 2, MAD = 0,
        // threshold floor = med + 2 = 4. currentGap = 3 → must NOT fire.
        let store = TestStore.fresh(suite: defaults)
        let today = TestDates.date(2026, 5, 6)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -60, to: today)!
        let h = TestStore.addHabit(store, name: "Stretch", createdAt: createdAt)
        // Mark on days -3, -5, -7, -9, ... up to -59. currentGap=3 (today−3=last).
        var offset = 3
        while offset <= 59 {
            TestStore.mark(store, habit: h, on: TestDates.calendar.date(byAdding: .day, value: -offset, to: today)!)
            offset += 2
        }

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        XCTAssertNil(engine.currentReflection(), "currentGap=3 must not fire when threshold floor=4")
    }

    func testDrift_irregularCadence_aboveFloor_fires() {
        // Same every-other-day cadence, but currentGap=5 (last completion 5 days ago) > floor 4.
        let store = TestStore.fresh(suite: defaults)
        let today = TestDates.date(2026, 5, 6)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -60, to: today)!
        let h = TestStore.addHabit(store, name: "Stretch", createdAt: createdAt)
        // Mark on days -5, -7, -9, ... up to -59. currentGap=5.
        var offset = 5
        while offset <= 59 {
            TestStore.mark(store, habit: h, on: TestDates.calendar.date(byAdding: .day, value: -offset, to: today)!)
            offset += 2
        }

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        guard case .drift(let habit, let days, _)? = engine.currentReflection() else {
            return XCTFail("expected .drift at currentGap=5 above floor=4")
        }
        XCTAssertEqual(habit.id, h.id)
        XCTAssertEqual(days, 5)
    }

    func testWeekly_habitCreatedMidWeek_doesNotPenaliseDays() {
        let store = TestStore.fresh(suite: defaults)
        let mondayAfter = TestDates.date(2026, 5, 4)
        let h = TestStore.addHabit(store, name: "New habit", createdAt: TestDates.date(2026, 4, 29))
        TestStore.markRange(store, habit: h, from: TestDates.date(2026, 4, 29), to: TestDates.date(2026, 5, 3))

        let engine = ReflectionEngine(store: store, now: mondayAfter, defaults: defaults)
        guard case .weekly(let days, let counted, _)? = engine.currentReflection() else {
            return XCTFail("expected .weekly")
        }
        XCTAssertEqual(counted, 5, "habit existed only Wed-Sun → 5 active days counted")
        XCTAssertEqual(days, 5, "all 5 active days fully done → bucket = full")
    }

    func testReflection_noActiveHabits_returnsNil() {
        let store = TestStore.fresh(suite: defaults)
        let today = TestDates.date(2026, 5, 4)

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }

    func testPriority_driftBeatsWeekly_whenBoth() {
        let store = TestStore.fresh(suite: defaults)
        let mondayInWindow = TestDates.date(2026, 5, 4)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -40, to: mondayInWindow)!
        let h = TestStore.addHabit(store, name: "Run", createdAt: createdAt)
        for offset in 4...38 {
            TestStore.mark(store, habit: h, on: TestDates.calendar.date(byAdding: .day, value: -offset, to: mondayInWindow)!)
        }

        let engine = ReflectionEngine(store: store, now: mondayInWindow, defaults: defaults)
        guard case .drift = engine.currentReflection() else {
            return XCTFail("drift must beat weekly when both available")
        }
    }

    func testTodayAlreadyShown_returnsNil() {
        let store = TestStore.fresh(suite: defaults)
        let today = TestDates.date(2026, 5, 4)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -30, to: today)!
        _ = TestStore.addHabit(store, name: "Run", createdAt: createdAt)
        defaults.set(ReflectionEngine.todayKey(today), forKey: ReflectionEngine.Keys.todayShown)

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }

    func testMasterToggleOff_returnsNil() {
        let store = TestStore.fresh(suite: defaults)
        let today = TestDates.date(2026, 5, 4)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -30, to: today)!
        let h = TestStore.addHabit(store, name: "Run", createdAt: createdAt)
        TestStore.markRange(store, habit: h, from: TestDates.date(2026, 4, 27), to: TestDates.date(2026, 5, 3))
        defaults.set(false, forKey: ReflectionEngine.Keys.masterEnabled)

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }
}
