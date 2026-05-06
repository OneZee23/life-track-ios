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

    /// ISO week key, e.g. "2026-W18". Monday-first per ISO 8601.
    static func weekKey(_ date: Date) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2  // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", comps.yearForWeekOfYear ?? 0, comps.weekOfYear ?? 0)
    }
}
