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
