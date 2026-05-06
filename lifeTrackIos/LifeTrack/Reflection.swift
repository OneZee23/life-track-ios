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
