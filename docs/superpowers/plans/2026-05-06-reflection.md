# Reflection (v0.6.0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a passive "Reflection card" to the Progress tab that gently surfaces drift on individual habits and weekly summaries, replacing the existing intrusive coach-overlay in DailyGreetingView. Rule-based, no LLM, no backend.

**Architecture:** Pure-compute `ReflectionEngine` (testable in isolation) → `Reflection` enum value → `ReflectionCopy` renderer → `ReflectionCard` SwiftUI view. State lives in UserDefaults. New code in `lifeTrackIos/LifeTrack/Reflection/`. Spec: [docs/superpowers/specs/2026-05-06-reflection-design.md](../specs/2026-05-06-reflection-design.md).

**Tech Stack:** SwiftUI (iOS 16+), Swift, XCTest, UserDefaults. No third-party deps. New `LifeTrackTests` target required.

**Branch:** Work on `feature/v0.6.0` off `master`.

**Important user preference:** **Do NOT run `git commit`.** At the end of each task, stage files and **propose** a commit message; user will review and commit manually.

---

## Task 0: Create LifeTrackTests target (manual, one-time)

**Why:** Project currently has no test target (verified `productType = "com.apple.product-type.application"` is the only target in `LifeTrack.xcodeproj/project.pbxproj`). Engine work is TDD-driven, so this is a hard prerequisite.

**This task is operator-driven (Xcode UI), not agent-driven.** Agent should pause and ask user to do this.

- [ ] **Step 1: User opens Xcode**

```
open /Users/onezee/OneZeeProjects/life-track/life-track-ios/lifeTrackIos/LifeTrack.xcodeproj
```

- [ ] **Step 2: User adds Unit Testing Bundle target**

In Xcode: File → New → Target → iOS → Unit Testing Bundle.
- Product Name: `LifeTrackTests`
- Team: same as main app
- Target to be Tested: `LifeTrack`
- Language: Swift
- Press Finish.

- [ ] **Step 3: Verify test target builds**

```bash
xcodebuild -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build-for-testing 2>&1 | tail -5
```
Expected: `** TEST BUILD SUCCEEDED **`.

- [ ] **Step 4: Stage and propose commit**

```bash
git -C /Users/onezee/OneZeeProjects/life-track/life-track-ios add lifeTrackIos/LifeTrack.xcodeproj/ lifeTrackIos/LifeTrackTests/
```
Proposed message:
```
Add LifeTrackTests XCTest target

Prereq for v0.6.0 Reflection engine TDD work.
```

---

## Task 1: Remove deprecated coach system

**Files:**
- Modify: `lifeTrackIos/LifeTrack/AppStore.swift:417-491` — delete `missedDaysCount()`, `longestMissedHabit()`, `coachMessage()`, `coachEmoji()`
- Modify: `lifeTrackIos/LifeTrack/DailyGreetingView.swift` — remove coach branch
- Modify: `lifeTrackIos/LifeTrack/L10n.swift:406-425` — delete `coachMissed1/2/4/7`, `coachHabitNudge`

- [ ] **Step 1: Confirm coach functions are isolated**

```bash
grep -rn "coachMessage\|coachEmoji\|longestMissedHabit\|missedDaysCount\|coachHabitNudge\|coachMissed" lifeTrackIos/LifeTrack/ --include="*.swift"
```
Expected: hits only in `AppStore.swift`, `DailyGreetingView.swift`, `L10n.swift`. If any other file references them, stop and re-evaluate.

- [ ] **Step 2: Read exact line ranges in AppStore.swift**

Read `lifeTrackIos/LifeTrack/AppStore.swift` lines 415–495 to capture the exact start/end of the four functions plus their `// MARK:` comment if any. Note: `missedDaysCount()`, `longestMissedHabit()`, `coachMessage()`, `coachEmoji()` are contiguous; delete the entire block including any preceding `// MARK: - Coach` line.

- [ ] **Step 3: Delete coach functions in AppStore.swift**

Use Edit to remove lines spanning the four functions. After removal, verify the surrounding code (likely `trackedHabitIds()` etc.) is intact.

- [ ] **Step 4: Update DailyGreetingView.swift**

Replace the file body with:

```swift
import SwiftUI

struct DailyGreetingView: View {
    @EnvironmentObject var store: AppStore

    let onDismiss: () -> Void

    private var streak: Int { store.currentStreak() }
    private var habitCount: Int { store.activeHabits.count }

    private var yesterdayText: String {
        if let stats = store.yesterdayStats() {
            return L10n.greetingYesterdayResult(stats.done, stats.total)
        }
        return L10n.greetingNoYesterday
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        onDismiss()
                    }
                }

            VStack(spacing: 16) {
                Text(L10n.greetingEmoji())
                    .font(.system(size: 56))

                Text(L10n.greeting())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if streak >= 2 {
                    Text("\u{1F525} \(streak) \(L10n.pluralDays(streak)) \(L10n.inARow)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.systemOrange))
                        .padding(.top, 4)
                }

                VStack(spacing: 8) {
                    Text(L10n.greetingHabitsWaiting(habitCount))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)

                    Text(yesterdayText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                Text(L10n.greetingTapToDismiss)
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor.systemGray3))
                    .padding(.top, 16)
            }
            .multilineTextAlignment(.center)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
        .transition(.opacity)
    }
}
```

- [ ] **Step 5: Delete coach strings in L10n.swift**

Find lines containing `coachMissed1`, `coachMissed2`, `coachMissed4`, `coachMissed7`, `coachHabitNudge` (around L10n.swift:406-425) — delete each `static var` / `static func` block. Both `ru` and `en` branches inside.

- [ ] **Step 6: Verify zero coach hits**

```bash
grep -rn "coach" lifeTrackIos/LifeTrack/ --include="*.swift"
```
Expected: zero hits.

- [ ] **Step 7: Build**

```bash
xcodebuild -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | grep -E "error:|BUILD" | tail -10
```
Expected: `** BUILD SUCCEEDED **`, no errors.

- [ ] **Step 8: Manual smoke test**

Run the app in simulator. Trigger morning greeting (force `shouldShowGreeting()` to true by editing `lt_greeting_shown_date` in UserDefaults via lldb or manually setting the simulator clock). Verify:
- Greeting appears with emoji + greeting text + streak (if any) + "N habits waiting" + yesterday line
- **No coach text/emoji/missed-habit nudge** anywhere
- Tap dismisses

- [ ] **Step 9: Stage and propose commit**

```bash
git -C /Users/onezee/OneZeeProjects/life-track/life-track-ios add lifeTrackIos/LifeTrack/AppStore.swift lifeTrackIos/LifeTrack/DailyGreetingView.swift lifeTrackIos/LifeTrack/L10n.swift
```
Proposed message:
```
Remove deprecated coach system

Removes coachMessage/coachEmoji/longestMissedHabit/missedDaysCount
and DailyGreetingView coach overlay block. New ReflectionCard
(v0.6.0) covers this signal better and on a passive surface.
```

---

## Task 2: Reflection types skeleton

**Files:**
- Create: `lifeTrackIos/LifeTrack/Reflection/Reflection.swift`

- [ ] **Step 1: Create Reflection.swift**

```swift
import Foundation

/// What the engine returns when it has something to surface.
/// Pure value type, equatable for tests.
enum Reflection: Equatable {
    case drift(habit: Habit, days: Int, suggestion: DriftSuggestion)
    case weekly(daysFullyDone: Int, daysCounted: Int, weekKey: String)
}

/// Concrete suggestion attached to a drift card.
enum DriftSuggestion: Equatable {
    /// "минут пять" — derived from habit.extendedField.step
    case smallerNumeric(value: Double, unit: String)
    /// fallback when no numeric step available
    case smallestVariant
}

/// Type-tag for dedup / disable storage.
enum ReflectionType: String {
    case drift
    case weekly
}

extension Reflection {
    var type: ReflectionType {
        switch self {
        case .drift: return .drift
        case .weekly: return .weekly
        }
    }
}
```

- [ ] **Step 2: Add file to Xcode project**

In Xcode: drag `Reflection.swift` into the `LifeTrack` group. Ensure target membership: `LifeTrack` ✅, `LifeTrackTests` ✅ (the test target needs access to these types).

- [ ] **Step 3: Build**

```bash
xcodebuild -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | grep -E "error:|BUILD" | tail -5
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Stage and propose commit**

```bash
git -C /Users/onezee/OneZeeProjects/life-track/life-track-ios add lifeTrackIos/LifeTrack/Reflection/Reflection.swift lifeTrackIos/LifeTrack.xcodeproj/project.pbxproj
```
Proposed message:
```
Add Reflection type skeleton

Pure value types: Reflection (drift|weekly), DriftSuggestion,
ReflectionType. No engine logic yet.
```

---

## Task 3: Empty engine + UserDefaults keys

**Files:**
- Create: `lifeTrackIos/LifeTrack/Reflection/ReflectionEngine.swift`

- [ ] **Step 1: Create ReflectionEngine.swift**

```swift
import Foundation

/// Pure computer that decides whether to surface a Reflection now.
///
/// Stateless from the engine's POV — all persistence reads/writes go through
/// `defaults`. Tests inject a custom UserDefaults via `init(suite:)` to avoid
/// polluting the real app domain.
struct ReflectionEngine {
    let store: AppStore
    let now: Date
    let defaults: UserDefaults

    init(store: AppStore, now: Date = Date(), defaults: UserDefaults = .standard) {
        self.store = store
        self.now = now
        self.defaults = defaults
    }

    // MARK: - Public

    /// Top-level entry point. Returns the single Reflection to show, or nil.
    func currentReflection() -> Reflection? {
        guard masterEnabled else { return nil }
        guard !isShownToday() else { return nil }

        if let drift = computeDrift() { return drift }
        if let weekly = computeWeeklySummary() { return weekly }
        return nil
    }

    /// Caller invokes this when the card is actually rendered on screen.
    func recordShown(_ reflection: Reflection) {
        defaults.set(Self.todayKey(now), forKey: Keys.todayShown)
        switch reflection {
        case .drift(let habit, _, _):
            defaults.set(Self.todayKey(now), forKey: Keys.driftSeen(habitId: habit.id))
        case .weekly(_, _, let weekKey):
            defaults.set(weekKey, forKey: Keys.weeklySeen)
        }
    }

    /// "Скрыть на неделю" via long-press menu — same as recordShown.
    func dismissForWeek(_ reflection: Reflection) {
        recordShown(reflection)
    }

    /// "Не показывать такие" — disables a whole type until user re-enables in Settings.
    func disableType(_ type: ReflectionType) {
        switch type {
        case .drift: defaults.set(true, forKey: Keys.driftDisabled)
        case .weekly: defaults.set(true, forKey: Keys.weeklyDisabled)
        }
    }

    // MARK: - Internal (will be implemented in later tasks)

    private func computeDrift() -> Reflection? {
        // Implemented in Task 6
        return nil
    }

    private func computeWeeklySummary() -> Reflection? {
        // Implemented in Task 5
        return nil
    }

    // MARK: - Gates

    private var masterEnabled: Bool {
        // Default true if key absent.
        defaults.object(forKey: Keys.masterEnabled) as? Bool ?? true
    }

    private func isShownToday() -> Bool {
        defaults.string(forKey: Keys.todayShown) == Self.todayKey(now)
    }

    // MARK: - Keys

    enum Keys {
        static let todayShown = "lt_reflection_today_shown"
        static let weeklySeen = "lt_reflection_weekly_seen"
        static let driftDisabled = "lt_reflection_drift_disabled"
        static let weeklyDisabled = "lt_reflection_weekly_disabled"
        static let hintShown = "lt_reflection_hint_shown"
        static let masterEnabled = "lt_reflection_enabled"

        static func driftSeen(habitId: String) -> String {
            "lt_reflection_drift_seen_\(habitId)"
        }
    }

    // MARK: - Date utils

    /// ISO yyyy-MM-dd in the user's calendar.
    static func todayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: date)
    }

    /// ISO week key, e.g. "2026-W18".
    static func weekKey(_ date: Date) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2  // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", comps.yearForWeekOfYear ?? 0, comps.weekOfYear ?? 0)
    }
}
```

- [ ] **Step 2: Add file to Xcode project**

Drag into `LifeTrack` group. Target membership: `LifeTrack` ✅, `LifeTrackTests` ✅.

- [ ] **Step 3: Build**

```bash
xcodebuild -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | grep -E "error:|BUILD" | tail -5
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Stage and propose commit**

```bash
git -C /Users/onezee/OneZeeProjects/life-track/life-track-ios add lifeTrackIos/LifeTrack/Reflection/ReflectionEngine.swift lifeTrackIos/LifeTrack.xcodeproj/project.pbxproj
```
Proposed message:
```
Add ReflectionEngine skeleton

Public surface: currentReflection(), recordShown(), dismissForWeek(),
disableType(). Master toggle + today-shown gating wired.
computeDrift/computeWeeklySummary stubs return nil.
```

---

## Task 4: Failing tests for all 14 cases

**Files:**
- Create: `lifeTrackIos/LifeTrackTests/ReflectionEngineTests.swift`
- Create: `lifeTrackIos/LifeTrackTests/Helpers/ReflectionTestHelpers.swift`

**Approach:** Build helpers first so tests are clean. Then write all 14 tests. Run them — every test should fail because the engine returns nil (or for the master-toggle-off test, nil is the *correct* answer; that one will incidentally pass — flag it explicitly).

- [ ] **Step 1: Create ReflectionTestHelpers.swift**

```swift
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

    static func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: date)
    }
}

enum TestStore {
    /// A fresh AppStore backed by an in-memory UserDefaults suite.
    /// Caller responsible for cleaning the suite via `defaults.removePersistentDomain`.
    static func fresh(suite: UserDefaults) -> AppStore {
        // AppStore reads/writes through .standard at the moment. If AppStore
        // can be made suite-aware (DI), use that. Otherwise these tests will
        // need to clean .standard between cases. For v0.6.0 we accept the
        // coupling and run sequentially.
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
```

- [ ] **Step 2: Create ReflectionEngineTests.swift with all 14 tests**

```swift
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
        // 10 days old, 5 completions → fails 21d gate
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
        // Daily for 35 days, then 3-day gap before today
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
        // Daily through yesterday only — gap = 1
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
        // Daily until 11 days ago — past ceiling
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
        // 7 weeks of Mon-Fri completions, missing weekends consistently.
        // currentGap will be 3 (Sat, Sun, today is Monday but no completion yet means
        // last completion was Friday) — but median gap for Fri→Mon is 3, so threshold lifts.
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
        // Pretend we showed drift 3 days ago.
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
        let mondayAfterEmptyWeek = TestDates.date(2026, 5, 4)  // Mon → window open
        // Create a habit a month ago, no completions in the prior week.
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
        // Mark all 7 days of the prior ISO week (Mon Apr 27 .. Sun May 3 2026).
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
        let wednesday = TestDates.date(2026, 5, 6)  // Wednesday — outside Sun-evening..Tue window
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -30, to: wednesday)!
        _ = TestStore.addHabit(store, name: "Run", createdAt: createdAt)

        let engine = ReflectionEngine(store: store, now: wednesday, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }

    func testWeekly_habitCreatedMidWeek_doesNotPenaliseDays() {
        let store = TestStore.fresh(suite: defaults)
        let mondayAfter = TestDates.date(2026, 5, 4)
        // Habit created Wednesday Apr 29; completed Wed-Sun (5 of 5 active days).
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
        // No habits at all.

        let engine = ReflectionEngine(store: store, now: today, defaults: defaults)
        XCTAssertNil(engine.currentReflection())
    }

    func testPriority_driftBeatsWeekly_whenBoth() {
        let store = TestStore.fresh(suite: defaults)
        let mondayInWindow = TestDates.date(2026, 5, 4)
        let createdAt = TestDates.calendar.date(byAdding: .day, value: -40, to: mondayInWindow)!
        let h = TestStore.addHabit(store, name: "Run", createdAt: createdAt)
        // Daily for 35 days then 3-day gap → drift fires
        for offset in 4...38 {
            TestStore.mark(store, habit: h, on: TestDates.calendar.date(byAdding: .day, value: -offset, to: mondayInWindow)!)
        }
        // Also weekly window is open (Monday). Weekly would compute too.

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
```

- [ ] **Step 3: Add files to Xcode test target**

In Xcode: drag `ReflectionEngineTests.swift` and `Helpers/ReflectionTestHelpers.swift` into `LifeTrackTests` group. Target membership: `LifeTrackTests` ✅ only.

- [ ] **Step 4: Run all tests; verify failures**

```bash
xcodebuild test -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:LifeTrackTests/ReflectionEngineTests 2>&1 | grep -E "Test Case|XCTAssert|passed|failed" | tail -40
```

Expected outcome:
- `testTodayAlreadyShown_returnsNil` — **PASSES** (engine returns nil because gate sees `lt_reflection_today_shown`).
- `testMasterToggleOff_returnsNil` — **PASSES** (master gate hits).
- `testReflection_noActiveHabits_returnsNil` — **PASSES** (engine stub returns nil; this is incidentally correct — note for later, will be retested after engine is real).
- `testDrift_brandNewHabit_returnsNil` / `testDrift_dailyHabit_oneDayGap_doesNotFire` / `testDrift_dailyHabit_elevenDayGap_doesNotFire` / `testDrift_weekendSkipper_doesNotFire` / `testDrift_cooldown_sevenDays_blocks` / `testDrift_archivedHabit_doesNotFire` / `testWeekly_outsideWindow_returnsNil` — **PASS** for the wrong reason (engine returns nil for everything). Acceptable for v0.6.0; they'll exercise real logic once engine is implemented.
- `testDrift_dailyHabit_threeDayGap_fires` / `testWeekly_zeroDays_returnsZeroBucket` / `testWeekly_sevenDays_returnsFullBucket` / `testWeekly_habitCreatedMidWeek_doesNotPenaliseDays` / `testPriority_driftBeatsWeekly_whenBoth` — **FAIL** (engine returns nil, tests want a value).

Confirm: **5 fails, 9 passes**, total 14. If anything else is amiss, do not proceed.

- [ ] **Step 5: Stage and propose commit**

```bash
git -C /Users/onezee/OneZeeProjects/life-track/life-track-ios add lifeTrackIos/LifeTrackTests/ lifeTrackIos/LifeTrack.xcodeproj/project.pbxproj
```
Proposed message:
```
Add Reflection engine test suite (14 cases, 5 failing)

TDD scaffold for Tasks 5-7. Helpers: TestDates, TestStore.
Failing tests: 3-day drift, weekly 0/7/midweek, priority.
Passing-by-stub: gates, ineligible cases.
```

🛑 **REVIEW CHECKPOINT 1:** User pauses here, reviews the test cases, confirms they exercise the right scenarios. After approval, proceed to Task 5.

---

## Task 5: Implement computeWeeklySummary

**Files:**
- Modify: `lifeTrackIos/LifeTrack/Reflection/ReflectionEngine.swift`

- [ ] **Step 1: Add weekly window helper to ReflectionEngine**

Inside the `ReflectionEngine` struct (after `weekKey(_:)`), add:

```swift
// MARK: - Weekly window

/// True when `now` is within Sunday 18:00 → Tuesday 23:59 of the user's local time.
/// Using ISO calendar (Mon=2 ... Sun=1).
private var isInWeeklyWindow: Bool {
    var cal = Calendar(identifier: .iso8601)
    cal.firstWeekday = 2
    cal.timeZone = .current
    let weekday = cal.component(.weekday, from: now)
    let hour = cal.component(.hour, from: now)
    // ISO weekday: Mon=2, Tue=3, ... Sun=1
    if weekday == 1 && hour >= 18 { return true }   // Sunday evening
    if weekday == 2 { return true }                 // Monday all day
    if weekday == 3 { return true }                 // Tuesday all day
    return false
}

/// Returns Mon..Sun dates of the most recently completed ISO week relative to `now`.
private func priorWeekDates() -> [Date] {
    var cal = Calendar(identifier: .iso8601)
    cal.firstWeekday = 2
    cal.timeZone = .current
    // Find this week's Monday, subtract 7 days for prior week's Monday.
    let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
    guard let thisMon = cal.date(from: comps) else { return [] }
    guard let priorMon = cal.date(byAdding: .day, value: -7, to: thisMon) else { return [] }
    return (0...6).compactMap { cal.date(byAdding: .day, value: $0, to: priorMon) }
}
```

- [ ] **Step 2: Replace the stub of `computeWeeklySummary`**

```swift
private func computeWeeklySummary() -> Reflection? {
    guard isInWeeklyWindow else { return nil }
    if defaults.bool(forKey: Keys.weeklyDisabled) { return nil }

    let dates = priorWeekDates()
    guard !dates.isEmpty else { return nil }
    let weekKey = Self.weekKey(dates.first!)

    if defaults.string(forKey: Keys.weeklySeen) == weekKey { return nil }

    var fullyDone = 0
    var counted = 0
    for d in dates {
        let habits = store.habitsExisted(from: d, to: d)
        guard !habits.isEmpty else { continue }
        counted += 1
        let ds = TestDates_dateString(d)
        let allDone = habits.allSatisfy { habit in
            store.checkinValue(habitId: habit.id, date: ds) >= habit.effectiveTarget
        }
        if allDone { fullyDone += 1 }
    }

    guard counted > 0 else { return nil }
    return .weekly(daysFullyDone: fullyDone, daysCounted: counted, weekKey: weekKey)
}

/// Local equivalent of TestDates.dateString — production code can't import test helpers.
private func TestDates_dateString(_ date: Date) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .iso8601)
    f.dateFormat = "yyyy-MM-dd"
    f.timeZone = .current
    return f.string(from: date)
}
```

**Note:** Rename `TestDates_dateString` to `Self.iso8601DateString` — production code shouldn't carry "TestDates" in identifier names. Use:

```swift
static func iso8601DateString(_ date: Date) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .iso8601)
    f.dateFormat = "yyyy-MM-dd"
    f.timeZone = .current
    return f.string(from: date)
}
```

And in `computeWeeklySummary`: `let ds = Self.iso8601DateString(d)`.

- [ ] **Step 3: Update test helper to share the date utility**

In `TestDates`, change `dateString` to delegate:

```swift
static func dateString(_ date: Date) -> String {
    return ReflectionEngine.iso8601DateString(date)
}
```

This guarantees test data and production read the same ISO string.

- [ ] **Step 4: Run tests; verify weekly tests now pass**

```bash
xcodebuild test -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:LifeTrackTests/ReflectionEngineTests 2>&1 | grep -E "passed|failed" | tail -5
```
Expected: **at least 12 of 14 pass**. The two still failing should be `testDrift_dailyHabit_threeDayGap_fires` and `testPriority_driftBeatsWeekly_whenBoth` (drift not implemented yet).

- [ ] **Step 5: Stage and propose commit**

```bash
git -C /Users/onezee/OneZeeProjects/life-track/life-track-ios add lifeTrackIos/LifeTrack/Reflection/ReflectionEngine.swift lifeTrackIos/LifeTrackTests/Helpers/ReflectionTestHelpers.swift
```
Proposed message:
```
Implement computeWeeklySummary

Sun-evening to Tue window via ISO calendar. habitsExisted-aware
day count avoids penalising mid-week-created habits. Dedup via
lt_reflection_weekly_seen.
```

---

## Task 6: Implement computeDrift (MAD-based)

**Files:**
- Modify: `lifeTrackIos/LifeTrack/Reflection/ReflectionEngine.swift`

- [ ] **Step 1: Add drift compute body**

Replace the `computeDrift` stub with:

```swift
private func computeDrift() -> Reflection? {
    if defaults.bool(forKey: Keys.driftDisabled) { return nil }

    var candidates: [(reflection: Reflection, score: Double)] = []
    for habit in store.activeHabits where !habit.isDeleted {
        guard let result = evaluateDrift(habit: habit) else { continue }
        candidates.append(result)
    }

    return candidates.max(by: { $0.score < $1.score })?.reflection
}

/// Returns the drift Reflection plus a priority score (higher = more urgent),
/// or nil if this habit doesn't qualify.
private func evaluateDrift(habit: Habit) -> (reflection: Reflection, score: Double)? {
    // Eligibility gates (cheap)
    let cal = Calendar.current
    guard let daysSinceCreated = cal.dateComponents([.day], from: habit.createdAt, to: now).day,
          daysSinceCreated >= 21 else { return nil }

    if let lastShownStr = defaults.string(forKey: Keys.driftSeen(habitId: habit.id)),
       let lastShown = parseISO8601(lastShownStr),
       let daysSinceShown = cal.dateComponents([.day], from: lastShown, to: now).day,
       daysSinceShown < 7 {
        return nil
    }

    let completions = completionDates(habit: habit, lastNDays: 60)
    guard completions.count >= 8 else { return nil }
    if completions.contains(where: { cal.isDate($0, inSameDayAs: now) }) { return nil }

    // Branch by cadence
    let weeksObserved = max(1, daysSinceCreated / 7)
    let baselineRate = Double(completions.count) / Double(min(weeksObserved, 8))  // per week, capped 8w window

    if baselineRate >= 5 {
        return evaluateDailyCadenceDrift(habit: habit, completions: completions)
    } else if baselineRate >= 1 {
        return evaluateWeeklyCadenceDrift(habit: habit, completions: completions, baselineRate: baselineRate)
    }
    return nil
}

private func evaluateDailyCadenceDrift(habit: Habit, completions: [Date]) -> (reflection: Reflection, score: Double)? {
    let sorted = completions.sorted()
    var gaps: [Int] = []
    let cal = Calendar.current
    for i in 1..<sorted.count {
        if let g = cal.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day, g > 0 {
            gaps.append(g)
        }
    }
    guard gaps.count >= 6 else { return nil }

    let med = median(gaps.map(Double.init))
    let mad = median(gaps.map { abs(Double($0) - med) })
    let threshold = max(med + 3.0 * 1.4826 * mad, med + 2.0)

    guard let last = sorted.last,
          let currentGap = cal.dateComponents([.day], from: last, to: now).day else { return nil }
    if currentGap < 2 { return nil }
    if currentGap > 10 { return nil }
    if Double(currentGap) < threshold { return nil }

    let suggestion = suggestSmaller(habit: habit)
    let score = Double(currentGap) / max(threshold, 1.0)
    return (.drift(habit: habit, days: currentGap, suggestion: suggestion), score)
}

private func evaluateWeeklyCadenceDrift(habit: Habit, completions: [Date], baselineRate: Double) -> (reflection: Reflection, score: Double)? {
    let cal = Calendar.current
    guard let twoWeeksAgo = cal.date(byAdding: .day, value: -14, to: now) else { return nil }
    let recent = completions.filter { $0 >= twoWeeksAgo }
    let recentRate = Double(recent.count) / 2.0   // per week

    guard recentRate <= 0.5 * baselineRate, recentRate < baselineRate - 1 else { return nil }
    guard let last = completions.sorted().last,
          let daysSinceLast = cal.dateComponents([.day], from: last, to: now).day else { return nil }
    if daysSinceLast < 2 { return nil }

    let suggestion = suggestSmaller(habit: habit)
    let score = (baselineRate - recentRate) / max(baselineRate, 1.0)
    return (.drift(habit: habit, days: daysSinceLast, suggestion: suggestion), score)
}

// MARK: - Compute helpers

private func completionDates(habit: Habit, lastNDays: Int) -> [Date] {
    let cal = Calendar.current
    var dates: [Date] = []
    for offset in 0..<lastNDays {
        guard let d = cal.date(byAdding: .day, value: -offset, to: now) else { continue }
        let ds = Self.iso8601DateString(d)
        if store.checkinValue(habitId: habit.id, date: ds) >= habit.effectiveTarget {
            dates.append(d)
        }
    }
    return dates
}

private func suggestSmaller(habit: Habit) -> DriftSuggestion {
    if let cfg = habit.extendedField,
       cfg.type == .numeric,
       let step = cfg.step,
       let unit = cfg.unit, !unit.isEmpty {
        return .smallerNumeric(value: step, unit: unit)
    }
    return .smallestVariant
}

private func median(_ xs: [Double]) -> Double {
    let s = xs.sorted()
    guard !s.isEmpty else { return 0 }
    let n = s.count
    return n % 2 == 1 ? s[n/2] : (s[n/2 - 1] + s[n/2]) / 2.0
}

private func parseISO8601(_ s: String) -> Date? {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .iso8601)
    f.dateFormat = "yyyy-MM-dd"
    f.timeZone = .current
    return f.date(from: s)
}
```

- [ ] **Step 2: Run tests**

```bash
xcodebuild test -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:LifeTrackTests/ReflectionEngineTests 2>&1 | grep -E "passed|failed" | tail -5
```
Expected: **all 14 pass**.

If `testDrift_weekendSkipper_doesNotFire` fails — MAD threshold is too tight. Verify median gap on Mon-Fri pattern is 1 with one 3-day jump per week, and threshold = max(1+2, 1 + 3·1.4826·MAD). Adjust only if explained by data.

If `testDrift_dailyHabit_elevenDayGap_doesNotFire` fails — verify the `currentGap > 10` check is hit before threshold compare.

- [ ] **Step 3: Stage and propose commit**

```bash
git -C /Users/onezee/OneZeeProjects/life-track/life-track-ios add lifeTrackIos/LifeTrack/Reflection/ReflectionEngine.swift
```
Proposed message:
```
Implement computeDrift (MAD-based)

Daily-cadence path: median + 1.4826·MAD threshold with med+2 floor
and 10-day ceiling. Weekly-cadence path: rate halving with absolute
margin. Eligibility gates: 21d age, 8 completions, 7d cooldown.
Priority by currentGap/threshold.
```

🛑 **REVIEW CHECKPOINT 2:** User pauses, reviews engine logic. Verifies MAD math is right, edge cases hold. After approval, proceed to UI.

---

## Task 7: L10n strings + ReflectionCopy renderer

**Files:**
- Modify: `lifeTrackIos/LifeTrack/L10n.swift` — add reflection strings (RU + EN branches)
- Create: `lifeTrackIos/LifeTrack/Reflection/ReflectionCopy.swift`

- [ ] **Step 1: Add L10n strings**

In `L10n.swift`, find the existing language dispatch (around the existing `coachMissed*` block we removed). Add a new `// MARK: - Reflection` section. Add these keys with RU/EN values:

```swift
// MARK: - Reflection

static var reflectionCaptionThisWeek: String {
    isRussian ? "Этой неделей" : "This week"
}

static var reflectionCaptionDrift: String {
    isRussian ? "Похоже, ритм просел" : "Pace has dipped"
}

static func reflectionDriftDailyShort(habitDisplay: String, days: Int, smaller: String) -> String {
    if isRussian {
        return "\(pluralDays(days, capitalized: true)) тихих без \(habitDisplay). Может, завтра — \(smaller)?"
    }
    return "\(days) quiet days without \(habitDisplay). Want to try \(smaller) tomorrow?"
}

static func reflectionDriftDailyLong(habitDisplay: String, days: Int, smaller: String) -> String {
    if isRussian {
        return "\(habitDisplay) молчит почти неделю. \(smaller.capitalizedFirst) — тоже считается."
    }
    return "It's been almost a week without \(habitDisplay). \(smaller.capitalizedFirst) still counts."
}

static func reflectionDriftWeekly(habitDisplay: String) -> String {
    if isRussian {
        return "Прошлая неделя \(habitDisplay) не сложилась. На этой — даже один раз будет да."
    }
    return "Last week didn't happen for \(habitDisplay). This week, even one time is a yes."
}

static func reflectionDriftLink(habitDisplay: String) -> String {
    if isRussian {
        return "Открыть \(habitDisplay)"
    }
    return "Open \(habitDisplay)"
}

static func reflectionWeeklyBucket(daysFullyDone: Int) -> String {
    switch daysFullyDone {
    case 7:
        return isRussian
            ? "Семь дней подряд. Так и складываются ритмы."
            : "Seven days. That's how rhythms get built."
    case 5...6:
        return isRussian
            ? "\(daysFullyDone) дней за неделю. Из таких недель и складывается."
            : "\(daysFullyDone) days this week. That's the kind of week that adds up."
    case 3...4:
        return isRussian
            ? "Неделя вышла неровной. \(daysFullyDone) дней — уже что-то."
            : "An uneven week. \(daysFullyDone) days is something."
    case 1...2:
        return isRussian
            ? "Неделя вышла рваной. Может, на следующей выбрать один день и защитить его?"
            : "A patchy week. Want to pick one day next week and protect it?"
    default:  // 0
        return isRussian
            ? "Жизнь бывает и такой. Догонять ничего не надо — просто то, что окажется по силам дальше."
            : "Life happens in weeks like this too. No catch-up needed — just whatever feels possible next."
    }
}

static var reflectionHintLongPress: String {
    isRussian ? "Удержи, чтобы скрыть" : "Press and hold to hide"
}

static var reflectionDismissForWeek: String {
    isRussian ? "Скрыть на неделю" : "Hide for a week"
}

static var reflectionDismissForever: String {
    isRussian ? "Не показывать такие" : "Don't show these"
}

static var reflectionSettingsTitle: String {
    isRussian ? "Замечать спад и подводить итог недели" : "Notice drift and summarize the week"
}

static var reflectionSettingsSubtitle: String {
    isRussian ? "Один тихий блок в разделе Прогресс. Без пушей." : "One quiet block in the Progress tab. No pushes."
}

static var reflectionSmallestVariant: String {
    isRussian ? "самый маленький вариант" : "the smallest version"
}

static func reflectionSmallerNumeric(value: Double, unit: String) -> String {
    let valueStr = value.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(value))
        : String(format: "%.1f", value)
    if isRussian {
        return "коротко, \(valueStr) \(unit)"
    }
    return "a short \(valueStr) \(unit)"
}
```

If `pluralDays(_:)` in L10n.swift only takes one arg, add `pluralDays(_ n: Int, capitalized: Bool) -> String` overload:

```swift
static func pluralDays(_ n: Int, capitalized: Bool) -> String {
    let base = pluralDays(n)
    if !capitalized { return "\(n) \(base)" }
    return "\(n) \(base)"  // RU plural already lowercase; we capitalize the first word of the sentence by other means
}
```

Actually scratch that: `pluralDays(_:)` returns just "дней"/"days" word. The drift template uses `"\(days) тихих ..."` so we don't need a pluralDays helper here — number is already inline. Remove `reflectionDriftDailyShort`'s `pluralDays(days, capitalized:)` call and replace with bare `days`:

```swift
static func reflectionDriftDailyShort(habitDisplay: String, days: Int, smaller: String) -> String {
    if isRussian {
        return "\(days) тихих дня без \(habitDisplay). Может, завтра — \(smaller)?"
    }
    return "\(days) quiet days without \(habitDisplay). Want to try \(smaller) tomorrow?"
}
```

(Note: RU "тихих дня" works for 2-4, "тихих дней" for 5+. For the short variant we know `days` is 2..7 in practice. Use plural "дней" universally for safety:)

```swift
return "\(days) тихих дней без \(habitDisplay). Может, завтра — \(smaller)?"
```

Also add `String.capitalizedFirst` extension if not already present:

```swift
extension String {
    var capitalizedFirst: String {
        guard let f = first else { return self }
        return String(f).uppercased() + dropFirst()
    }
}
```

- [ ] **Step 2: Create ReflectionCopy.swift**

```swift
import Foundation

/// Renders a Reflection into displayable strings.
/// Pure function — no UI imports, no UserDefaults.
enum ReflectionCopy {
    struct Rendered {
        let caption: String      // small label, line 1
        let body: String         // main text, line 2
        let link: String?        // optional inline link, line 3 (drift only)
        let icon: String         // SF Symbol name
    }

    static func render(_ reflection: Reflection) -> Rendered {
        switch reflection {
        case .drift(let habit, let days, let suggestion):
            let display = "«\(habit.emoji) \(habit.name)»"
            let smaller = renderSuggestion(suggestion)
            let body: String
            if days <= 4 {
                body = L10n.reflectionDriftDailyShort(habitDisplay: display, days: days, smaller: smaller)
            } else if days <= 7 {
                body = L10n.reflectionDriftDailyLong(habitDisplay: display, days: days, smaller: smaller)
            } else {
                body = L10n.reflectionDriftWeekly(habitDisplay: display)
            }
            return Rendered(
                caption: L10n.reflectionCaptionDrift,
                body: body,
                link: L10n.reflectionDriftLink(habitDisplay: display),
                icon: "wind"
            )

        case .weekly(let daysFullyDone, _, _):
            return Rendered(
                caption: L10n.reflectionCaptionThisWeek,
                body: L10n.reflectionWeeklyBucket(daysFullyDone: daysFullyDone),
                link: nil,
                icon: "chart.line.uptrend.xyaxis"
            )
        }
    }

    private static func renderSuggestion(_ s: DriftSuggestion) -> String {
        switch s {
        case .smallerNumeric(let value, let unit):
            return L10n.reflectionSmallerNumeric(value: value, unit: unit)
        case .smallestVariant:
            return L10n.reflectionSmallestVariant
        }
    }
}
```

- [ ] **Step 3: Add file to Xcode**

Drag `ReflectionCopy.swift` into `LifeTrack` group. Target: `LifeTrack` ✅, `LifeTrackTests` ✅.

- [ ] **Step 4: Build**

```bash
xcodebuild -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | grep -E "error:|BUILD" | tail -5
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Re-run all tests**

```bash
xcodebuild test -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:LifeTrackTests/ReflectionEngineTests 2>&1 | grep -E "passed|failed" | tail -3
```
Expected: still 14 passed.

- [ ] **Step 6: Stage and propose commit**

```bash
git -C /Users/onezee/OneZeeProjects/life-track/life-track-ios add lifeTrackIos/LifeTrack/L10n.swift lifeTrackIos/LifeTrack/Reflection/ReflectionCopy.swift lifeTrackIos/LifeTrack.xcodeproj/project.pbxproj
```
Proposed message:
```
Add Reflection L10n strings and ReflectionCopy renderer

15 RU/EN strings: drift (3 templates), weekly (5 buckets), hint,
dismiss menu, settings, suggestions. ReflectionCopy renders Reflection
to (caption, body, link?, icon).
```

---

## Task 8: ReflectionCard view

**Files:**
- Create: `lifeTrackIos/LifeTrack/Reflection/ReflectionCard.swift`

- [ ] **Step 1: Create ReflectionCard.swift**

```swift
import SwiftUI

struct ReflectionCard: View {
    let reflection: Reflection
    let onLinkTap: () -> Void
    let onDismissForWeek: () -> Void
    let onDisableType: () -> Void

    @State private var hintVisible = false
    private let hintShownKey = ReflectionEngine.Keys.hintShown

    private var rendered: ReflectionCopy.Rendered {
        ReflectionCopy.render(reflection)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            cardBody

            if hintVisible {
                Text(L10n.reflectionHintLongPress)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
                    .transition(.opacity)
            }
        }
        .onAppear { triggerHintIfNeeded() }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: rendered.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                Text(rendered.caption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text(rendered.body)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let link = rendered.link {
                Button(action: onLinkTap) {
                    Text(link)
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.systemGreen))
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .contextMenu {
            Button {
                onDismissForWeek()
            } label: {
                Label(L10n.reflectionDismissForWeek, systemImage: "eye.slash")
            }
            Button {
                onDisableType()
            } label: {
                Label(L10n.reflectionDismissForever, systemImage: "minus.circle")
            }
        }
    }

    private func triggerHintIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: hintShownKey) { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            hintVisible = true
        }
        defaults.set(true, forKey: hintShownKey)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                hintVisible = false
            }
        }
    }
}
```

- [ ] **Step 2: Add to Xcode**

Drag `ReflectionCard.swift`. Target: `LifeTrack` ✅, **NOT** `LifeTrackTests`.

- [ ] **Step 3: Preview-render in canvas**

Add at the bottom of `ReflectionCard.swift`:

```swift
#Preview("drift, 3 days") {
    let h = Habit(name: "Утренний бег", emoji: "🏃", sortOrder: 0, targetPerDay: 1)
    return ReflectionCard(
        reflection: .drift(habit: h, days: 3, suggestion: .smallerNumeric(value: 5, unit: "мин")),
        onLinkTap: {},
        onDismissForWeek: {},
        onDisableType: {}
    )
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("weekly, 5 days") {
    ReflectionCard(
        reflection: .weekly(daysFullyDone: 5, daysCounted: 7, weekKey: "2026-W18"),
        onLinkTap: {},
        onDismissForWeek: {},
        onDisableType: {}
    )
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("weekly, 0 days (sensitive)") {
    ReflectionCard(
        reflection: .weekly(daysFullyDone: 0, daysCounted: 7, weekKey: "2026-W18"),
        onLinkTap: {},
        onDismissForWeek: {},
        onDisableType: {}
    )
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
```

Open Xcode previews and verify all three render readably, no truncation, hint label appears for 3s on first show then fades.

- [ ] **Step 4: Build**

```bash
xcodebuild -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | grep -E "error:|BUILD" | tail -5
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Stage and propose commit**

```bash
git -C /Users/onezee/OneZeeProjects/life-track/life-track-ios add lifeTrackIos/LifeTrack/Reflection/ReflectionCard.swift lifeTrackIos/LifeTrack.xcodeproj/project.pbxproj
```
Proposed message:
```
Add ReflectionCard view

Inline card for Progress tab. Long-press contextMenu (no X button).
≥44pt tap-target on inline link via .padding(.vertical, 12).
One-time discoverability hint via lt_reflection_hint_shown.
```

---

## Task 9: Integrate into ProgressRootView

**Files:**
- Modify: `lifeTrackIos/LifeTrack/ProgressRootView.swift`

- [ ] **Step 1: Add reflection state and engine**

After the existing `@State private var detailNoteDate: Date = Date()` line, add:

```swift
@State private var reflectionEngineTick = UUID()  // forces recompute when state changes
```

- [ ] **Step 2: Insert ReflectionCard between header and content**

Find the `body`'s `VStack(spacing: 0)` block, immediately after `headerSection` and before the `Group { switch level { ... } }`. Insert:

```swift
if (level == .month || level == .year), navSource == .normal {
    let engine = ReflectionEngine(store: store)
    if let reflection = engine.currentReflection() {
        ReflectionCard(
            reflection: reflection,
            onLinkTap: {
                if case .drift(let habit, _, _) = reflection {
                    detailNoteDate = Date()
                    detailHabit = habit
                }
            },
            onDismissForWeek: {
                engine.dismissForWeek(reflection)
                withAnimation(.easeInOut(duration: 0.25)) {
                    reflectionEngineTick = UUID()
                }
            },
            onDisableType: {
                engine.disableType(reflection.type)
                withAnimation(.easeInOut(duration: 0.25)) {
                    reflectionEngineTick = UUID()
                }
            }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .id(reflectionEngineTick)  // re-create on dismiss
        .transition(.opacity.combined(with: .move(edge: .top)))
        .onAppear {
            engine.recordShown(reflection)
        }
    }
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | grep -E "error:|BUILD" | tail -5
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Manual integration test**

Run app in simulator. Setup checks (use Xcode Edit Scheme → Arguments, or modify a habit's createdAt via code, or just create old fake state):
1. **Force a weekly card:** create a habit, mark all 7 prior days done, set the simulator clock to a Monday 12:00. Open Progress tab. Card should appear above the month grid with caption "Этой неделей" and full-week text.
2. **Long-press the card** → context menu shows two items. Tap "Скрыть на неделю" → card animates out. Re-open Progress → card stays gone (until next week).
3. **Drift card:** create a habit dated 30 days ago, mark daily for 25 days then 3-day gap. Open Progress → drift card appears. Tap "Открыть «...»" — habit detail sheet opens.
4. **Hint:** verify on a fresh install (delete-app-and-reinstall) the "Удержи, чтобы скрыть" caption appears for ~3s under the card. Subsequent launches: no hint.

- [ ] **Step 5: Stage and propose commit**

```bash
git -C /Users/onezee/OneZeeProjects/life-track/life-track-ios add lifeTrackIos/LifeTrack/ProgressRootView.swift
```
Proposed message:
```
Integrate ReflectionCard into ProgressRootView

Card lives between segment header and content, only on
month/year top-level (navSource == .normal). Long-press menu
wired to engine.dismissForWeek / disableType. Drift link
opens HabitDetailView via existing detailHabit sheet.
```

---

## Task 10: Settings master toggle

**Files:**
- Modify: `lifeTrackIos/LifeTrack/SettingsView.swift`

- [ ] **Step 1: Read current SettingsView structure**

Read `lifeTrackIos/LifeTrack/SettingsView.swift` to identify where existing toggles live (likely a `Section` with `Toggle`s).

- [ ] **Step 2: Add reflection toggle**

Find a logical place in the existing settings sections (next to other notification/UX toggles). Add a new `Section` or row:

```swift
Section {
    Toggle(isOn: Binding(
        get: { UserDefaults.standard.object(forKey: ReflectionEngine.Keys.masterEnabled) as? Bool ?? true },
        set: { UserDefaults.standard.set($0, forKey: ReflectionEngine.Keys.masterEnabled) }
    )) {
        VStack(alignment: .leading, spacing: 2) {
            Text(L10n.reflectionSettingsTitle)
                .font(.body)
            Text(L10n.reflectionSettingsSubtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | grep -E "error:|BUILD" | tail -5
```

- [ ] **Step 4: Manual test**

Open Settings. Toggle off. Open Progress tab — no card. Toggle on. Open Progress — card returns (assuming triggering condition still holds).

- [ ] **Step 5: Stage and propose commit**

```bash
git -C /Users/onezee/OneZeeProjects/life-track/life-track-ios add lifeTrackIos/LifeTrack/SettingsView.swift
```
Proposed message:
```
Add Reflection master toggle to Settings

Single toggle backed by lt_reflection_enabled (default true).
Per-type "don't show these" remains on long-press menu.
```

---

## Task 11: Final QA + release notes

**Files:**
- Modify: `CHANGELOG.md`
- Create: `docs/appstore-v0.6.0.md`

- [ ] **Step 1: Run full test suite**

```bash
xcodebuild test -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' 2>&1 | grep -E "Test Suite.*passed|failed" | tail -5
```
Expected: all 14 tests passing, 0 failures.

- [ ] **Step 2: Final clean build**

```bash
xcodebuild -project lifeTrackIos/LifeTrack.xcodeproj -scheme LifeTrack -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' clean build 2>&1 | grep -E "error:|BUILD" | tail -3
```

- [ ] **Step 3: Manual end-to-end walkthrough**

In simulator with a fresh-install of the build:
1. Onboarding → done
2. Create one habit, daily target — verify check-in works (regression check on v0.5.4 fixes)
3. Verify minus button is easy to hit (regression check)
4. Configure habit with text-type extendedField — verify comment field appears regardless of done state (regression check)
5. Open Progress — no card (insufficient data)
6. Use simulator clock-skip / data injection to fake 30 days of completions, then 3-day gap, then open Progress on a Wednesday — drift card appears
7. Long-press → "Скрыть на неделю" → card disappears
8. Re-open Progress — no card
9. Open Settings → toggle off Reflection → re-open Progress → no card
10. Toggle on → re-open Progress → card returns

- [ ] **Step 4: Update CHANGELOG.md**

Add at top:

```markdown
## v0.6.0 — 2026-05-XX

### Added
- 🌱 **Reflection (тихие сводки в разделе «Прогресс»)**: раз в неделю — спокойный итог; со временем — мягкое напоминание, если какая-то привычка просела, и предложение самого маленького варианта продолжения. Без пушей, без облака, без подписки. Удержи карточку, чтобы её скрыть.

### Removed
- Coaching-блок из утреннего приветствия. Замечать спад теперь умеет более точно — на per-привычку основе в Reflection-карточке.

### Fixed (v0.5.5 maintenance — переехало в эту версию)
- Кнопка «минус» под count-привычками — расширен tap-target до 44×44 (Apple HIG), теперь надёжно срабатывает.
- Поле комментария к привычке доступно всегда, не привязано к галочке выполнено.
```

- [ ] **Step 5: Create docs/appstore-v0.6.0.md**

Following the structure of `docs/appstore-v0.5.4.md` (read it first). Body should be a 100-150 word App Store-ready description in Russian and English.

- [ ] **Step 6: Stage and propose commit**

```bash
git -C /Users/onezee/OneZeeProjects/life-track/life-track-ios add CHANGELOG.md docs/appstore-v0.6.0.md
```
Proposed message:
```
Release notes: v0.6.0

Reflection card + coach removal + v0.5.5 bug fixes (minus
button, comment-on-task) bundled in.
```

---

## Self-review

**Spec coverage:**
- §1, §1.1 → covered by intro + Task 1 framing
- §2 (non-goals) → enforced by what we don't build
- §3 (principles) → influence Tasks 7-9 copy/UI
- §4.1-4.5 → Task 8 (view), Task 9 (placement), Task 7 (copy), Task 6/5 (rate limits in engine)
- §5.1-5.2 → Task 5/6 (engine), Task 7 (copy)
- §6 algorithm → Task 6
- §7 persisted state → Task 3 (keys), Task 5/6/9/10 (writes/reads)
- §8.1-8.5 → Tasks 2, 3, 7, 8, 9, 10
- §9 localization → Task 7
- §10 tests → Task 4 (all 14)
- §11 out of scope → enforced by what's not in plan
- §12 migration → no-op as specified
- §13 coach deprecate → Task 1
- §14 LLM roadmap → covered in CHANGELOG framing (Task 11)
- §15 release notes → Task 11

All 16 spec sections accounted for. ✅

**Placeholder scan:** No "TBD" / "TODO" / vague directives. All test code complete. All function bodies complete. ✅

**Type consistency:** `Reflection.weekly` carries `daysCounted` (added in Task 2) and used in Task 4 tests + Task 5 implementation + Task 7 renderer. `ReflectionEngine.Keys.*` used identically across all tasks. `ReflectionCopy.Rendered` consumed in Task 8 view. `Habit.createdAt` / `deletedAt` / `effectiveTarget` / `extendedField` API confirmed via grep. ✅

**Risks flagged for execution:**
- AppStore is currently not DI-aware for UserDefaults; tests share `.standard`. Helpers wipe between cases via `defaults.wipe()`. If parallel test execution causes flakes, switch to `XCTestCase` with `mainActor` + serial.
- Adding files to Xcode project requires `.pbxproj` edits — agent may need the user to drag files in via Xcode UI (the plan is explicit about this).
- ISO calendar weekday numbering: Mon=2, Sun=1 (`firstWeekday=2`). All date checks use `Calendar(identifier: .iso8601)` consistently.
