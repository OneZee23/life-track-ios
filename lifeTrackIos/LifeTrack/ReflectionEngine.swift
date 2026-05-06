import Foundation

/// Pure computer that decides whether to surface a Reflection now.
///
/// Stateless from the engine's POV — all persistence reads/writes go through
/// `defaults`. Tests inject a custom `UserDefaults` (e.g. one created with
/// `UserDefaults(suiteName:)`) to avoid polluting the real app domain.
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

    /// "Скрыть на неделю" via long-press menu. Implementation is identical to
    /// `recordShown` — both write the per-habit drift date / per-week weekly
    /// bucket. The 7-day cooldown for drift and the next-bucket-only check for
    /// weekly are enforced at evaluation time in `computeDrift` /
    /// `computeWeeklySummary`, not here.
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
        if defaults.bool(forKey: Keys.driftDisabled) { return nil }

        var candidates: [(reflection: Reflection, score: Double)] = []
        for habit in store.activeHabits where !habit.isDeleted {
            if let result = evaluateDrift(habit: habit) {
                candidates.append(result)
            }
        }
        return candidates.max(by: { $0.score < $1.score })?.reflection
    }

    /// Returns the drift Reflection plus a priority score (higher = more urgent),
    /// or nil if this habit doesn't qualify.
    private func evaluateDrift(habit: Habit) -> (reflection: Reflection, score: Double)? {
        let cal = Calendar.current

        // Gate: 21d minimum age
        guard let daysSinceCreated = cal.dateComponents([.day], from: habit.createdAt, to: now).day,
              daysSinceCreated >= 21 else { return nil }

        // Gate: 7d cooldown for same-habit nudge
        if let lastShownStr = defaults.string(forKey: Keys.driftSeen(habitId: habit.id)),
           let lastShown = Self.parseISO8601(lastShownStr),
           let daysSinceShown = cal.dateComponents([.day], from: lastShown, to: now).day,
           daysSinceShown < 7 {
            return nil
        }

        // Gather last 60 days of completions
        let completions = completionDates(habit: habit, lastNDays: 60)
        guard completions.count >= 8 else { return nil }
        if completions.contains(where: { cal.isDate($0, inSameDayAs: now) }) { return nil }

        // Branch by cadence
        let weeksObserved = max(1, daysSinceCreated / 7)
        let baselineRate = Double(completions.count) / Double(min(weeksObserved, 8))

        if baselineRate >= 5 {
            return evaluateDailyCadenceDrift(habit: habit, completions: completions)
        } else if baselineRate >= 1 {
            return evaluateWeeklyCadenceDrift(habit: habit, completions: completions, baselineRate: baselineRate)
        }
        return nil
    }

    private func evaluateDailyCadenceDrift(habit: Habit, completions: [Date]) -> (reflection: Reflection, score: Double)? {
        let cal = Calendar.current
        let sorted = completions.sorted()

        var gaps: [Int] = []
        for i in 1..<sorted.count {
            if let g = cal.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day, g > 0 {
                gaps.append(g)
            }
        }
        guard gaps.count >= 6 else { return nil }

        let med = median(gaps.map(Double.init))
        let mad = median(gaps.map { abs(Double($0) - med) })
        let maxGap = Double(gaps.max() ?? 0)
        // Three floors:
        //   med + 3·1.4826·MAD — statistical "unusual for this user" (Gaussian-like)
        //   med + 2            — Clear's "never miss twice" rule, prevents fire on floor=1
        //   maxGap + 1         — must EXCEED the largest historically-observed gap.
        //                        Critical for weekend-skipper / bimodal cadences:
        //                        if user normally has 3-day gaps (Fri→Mon), 3 is "normal".
        let threshold = max(med + 3.0 * 1.4826 * mad, med + 2.0, maxGap + 1.0)

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
        let recentRate = Double(recent.count) / 2.0  // per week

        guard recentRate <= 0.5 * baselineRate, recentRate < baselineRate - 1 else { return nil }
        guard let last = completions.sorted().last,
              let daysSinceLast = cal.dateComponents([.day], from: last, to: now).day else { return nil }
        if daysSinceLast < 2 { return nil }

        let suggestion = suggestSmaller(habit: habit)
        // Normalize: daily-cadence score is currentGap/threshold (typically
        // 1.0-3.0). Raw weekly score (baseline-recent)/baseline is bounded
        // 0-1, so a fully-abandoned weekly habit (score≈1.0) would always
        // lose to a barely-drifting daily one. Offset by +1.0 to put weekly
        // on the same 1.0-2.0 axis — severe weekly can still beat mild daily.
        let rawScore = (baselineRate - recentRate) / max(baselineRate, 1.0)
        let score = 1.0 + rawScore
        return (.drift(habit: habit, days: daysSinceLast, suggestion: suggestion), score)
    }

    // MARK: - Drift compute helpers

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

    static func parseISO8601(_ s: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.date(from: s)
    }

    private func computeWeeklySummary() -> Reflection? {
        guard isInWeeklyWindow else { return nil }
        if defaults.bool(forKey: Keys.weeklyDisabled) { return nil }

        let dates = priorWeekDates()
        guard let firstDay = dates.first else { return nil }
        let weekKey = Self.weekKey(firstDay)

        if defaults.string(forKey: Keys.weeklySeen) == weekKey { return nil }

        var fullyDone = 0
        var counted = 0
        for d in dates {
            let activeHabits = store.habitsExisted(from: d, to: d)
            guard !activeHabits.isEmpty else { continue }
            counted += 1
            let ds = Self.iso8601DateString(d)
            let allDone = activeHabits.allSatisfy { habit in
                store.checkinValue(habitId: habit.id, date: ds) >= habit.effectiveTarget
            }
            if allDone { fullyDone += 1 }
        }

        guard counted > 0 else { return nil }
        return .weekly(daysFullyDone: fullyDone, daysCounted: counted, weekKey: weekKey)
    }

    // MARK: - Weekly window

    /// Single ISO 8601 calendar (Monday-first, current TZ) used by all weekly
    /// computations and `weekKey`. Centralised to avoid drift between sites.
    static var isoCalendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.timeZone = .current
        return cal
    }

    /// True when `now` is within Sunday 18:00 → Tuesday 23:59 (local time).
    /// ISO calendar weekday: Sun=1, Mon=2, Tue=3.
    private var isInWeeklyWindow: Bool {
        let cal = Self.isoCalendar
        let weekday = cal.component(.weekday, from: now)
        let hour = cal.component(.hour, from: now)
        if weekday == 1 && hour >= 18 { return true }
        if weekday == 2 { return true }
        if weekday == 3 { return true }
        return false
    }

    /// Returns Mon..Sun dates of the most recently *completed* ISO week
    /// relative to `now`. Sunday ≥18:00 belongs to the just-ending week
    /// (Mon-Sun including today). Mon/Tue belong to the new week, so we
    /// subtract 7 to reach the previous Mon..Sun.
    private func priorWeekDates() -> [Date] {
        let cal = Self.isoCalendar
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        guard let thisWeekMon = cal.date(from: comps) else { return [] }
        let weekday = cal.component(.weekday, from: now)
        // Sun = 1: the week we want IS this week (Mon..Sun, today included).
        // Mon = 2 / Tue = 3: this is the new week; we want the prior (subtract 7).
        let priorWeekMon: Date
        if weekday == 1 {
            priorWeekMon = thisWeekMon
        } else {
            guard let backOne = cal.date(byAdding: .day, value: -7, to: thisWeekMon) else { return [] }
            priorWeekMon = backOne
        }
        return (0...6).compactMap { cal.date(byAdding: .day, value: $0, to: priorWeekMon) }
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

    // MARK: - Date utils (used by engine + tests)

    /// ISO yyyy-MM-dd in the user's calendar. Single source of truth for date strings.
    static func iso8601DateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: date)
    }

    /// Same as iso8601DateString but kept under historical name `todayKey` for the
    /// day-of-show dedup keys.
    static func todayKey(_ date: Date) -> String {
        iso8601DateString(date)
    }

    /// ISO week key, e.g. "2026-W18". Monday-first per ISO 8601, current TZ.
    static func weekKey(_ date: Date) -> String {
        let comps = isoCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", comps.yearForWeekOfYear ?? 0, comps.weekOfYear ?? 0)
    }
}
