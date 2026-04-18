import SwiftUI

struct MonthAnalyticsView: View {
    @EnvironmentObject var store: AppStore

    let year: Int
    let month: Int
    let onMonthChange: (Int) -> Void
    let onWeekTap: (Date) -> Void
    var onHabitTap: ((Habit) -> Void)? = nil

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    private var currentMonth: Int { Calendar.current.component(.month, from: Date()) - 1 }
    private var isFutureMonth: Bool {
        year > currentYear || (year == currentYear && month > currentMonth)
    }

    private var hasNoData: Bool { computeCompletionRate().tracked == 0 }

    var body: some View {
        VStack(spacing: 16) {
            navHeader
            if isFutureMonth {
                PlaceholderView(emoji: "🔮", title: L10n.futureTitle, subtitle: L10n.futureSubtitle)
            } else if hasNoData {
                PlaceholderView(emoji: "😴", title: L10n.emptyTitle, subtitle: L10n.emptySubtitle)
            } else {
                completionRateCard
                habitRankingCard
                weeklyBreakdownCard
            }
        }
    }

    // MARK: - Nav header

    var navHeader: some View {
        HStack {
            NavArrowButton(left: true) { onMonthChange(month - 1) }
            Spacer()
            VStack(spacing: 2) {
                Text(verbatim: "\(L10n.monthsFull[month]) \(String(year))")
                    .font(.system(size: 17, weight: .bold))
            }
            Spacer()
            NavArrowButton(left: false) { onMonthChange(month + 1) }
        }
        .padding(.bottom, 2)
    }

    // MARK: - Completion rate

    var completionRateCard: some View {
        let stats = computeCompletionRate()

        return VStack(alignment: .leading, spacing: 10) {
            Text(L10n.completionRate)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(alignment: .bottom, spacing: 4) {
                Text(stats.tracked > 0 ? "\(Int(stats.rate))%" : "—")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(Color(UIColor.systemGreen))
            }

            HealthProgressBar(rate: stats.rate, height: 8)

            Text(L10n.checkinsOf(stats.done, stats.tracked))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .healthCard()
    }

    // MARK: - Habit ranking

    @ViewBuilder
    var habitRankingCard: some View {
        let stats = computeHabitStats()

        if !stats.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.habits)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                ForEach(Array(stats.enumerated()), id: \.offset) { _, item in
                    if let onHabitTap = onHabitTap {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onHabitTap(item.habit)
                        } label: {
                            habitRow(item: item)
                        }
                        .buttonStyle(.plain)
                    } else {
                        habitRow(item: item)
                    }
                }
            }
            .healthCard()
        }
    }

    func habitRow(item: HabitStat) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text(item.habit.emoji)
                    .font(.system(size: 16))
                Text(item.habit.name)
                    .font(.system(size: DT.bodySize, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text(item.tracked > 0 ? "\(Int(item.rate))%" : "—")
                    .font(.system(size: DT.bodySize, weight: .bold, design: .monospaced))
                    .foregroundColor(item.rate >= 75 ? Color(UIColor.systemGreen) : .secondary)
            }

            HealthProgressBar(rate: item.rate)

            if item.tracked > 0 {
                HStack {
                    Text(L10n.checkinsOf(item.done, item.tracked))
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.systemGray3))
                    Spacer()
                }
            }
        }
    }

    // MARK: - Weekly breakdown

    @ViewBuilder
    var weeklyBreakdownCard: some View {
        let stats = computeWeeklyStats()
        let hasData = stats.contains { $0.tracked > 0 }

        if hasData {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.weeklyBreakdown)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                ForEach(stats, id: \.weekStart) { item in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onWeekTap(item.weekStart)
                    } label: {
                        weekRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .healthCard()
        }
    }

    func weekRow(item: WeeklyStat) -> some View {
        let label = weekLabel(item: item)
        return VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Text(item.tracked > 0 ? "\(Int(item.rate))%" : "—")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(item.rate >= 75 ? Color(UIColor.systemGreen) : .secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(UIColor.systemGray3))
            }

            HealthProgressBar(rate: item.rate)
        }
    }

    func weekLabel(item: WeeklyStat) -> String {
        let cal = Calendar.current
        let d1 = cal.component(.day, from: item.displayStart)
        let d2 = cal.component(.day, from: item.displayEnd)
        let m1 = cal.component(.month, from: item.displayStart) - 1
        let m2 = cal.component(.month, from: item.displayEnd) - 1
        // Single day
        if cal.isDate(item.displayStart, inSameDayAs: item.displayEnd) {
            return "\(d1) \(L10n.monthsShort[m1].lowercased())"
        }
        if m1 == m2 {
            return "\(d1) – \(d2) \(L10n.monthsShort[m1].lowercased())"
        }
        return "\(d1) \(L10n.monthsShort[m1].lowercased()) – \(d2) \(L10n.monthsShort[m2].lowercased())"
    }

    // MARK: - Data

    struct WeeklyStat: Identifiable {
        let weekStart: Date       // Full week start (for navigation)
        let weekEnd: Date         // Full week end
        let displayStart: Date    // Clamped to month (for label)
        let displayEnd: Date      // Clamped to month (for label)
        let done: Int
        let tracked: Int
        let rate: Double
        var id: Date { weekStart }
    }

    func computeCompletionRate() -> (done: Int, tracked: Int, rate: Double) {
        var totalDone = 0, totalTracked = 0
        let days = daysInMonth(year: year, month: month)
        for day in 1...days {
            guard let d = makeDate(year: year, month: month, day: day) else { continue }
            if isFuture(d) && !isToday(d) { continue }
            let ids = store.trackedHabitIds(on: d)
            guard !ids.isEmpty else { continue }
            let ds = formatDate(d)
            let dayData = store.checkins[ds] ?? [:]
            totalTracked += ids.count
            for id in ids {
                if (dayData[id] ?? 0) >= 1 { totalDone += 1 }
            }
        }
        let rate = totalTracked > 0 ? Double(totalDone) / Double(totalTracked) * 100.0 : 0
        return (totalDone, totalTracked, rate)
    }

    func computeHabitStats() -> [HabitStat] {
        store.computeHabitStats(year: year, month: month)
    }

    func computeWeeklyStats() -> [WeeklyStat] {
        let cal = Calendar.current
        let days = daysInMonth(year: year, month: month)
        guard let firstDay = makeDate(year: year, month: month, day: 1) else { return [] }
        guard let lastDay = makeDate(year: year, month: month, day: days) else { return [] }

        var results: [WeeklyStat] = []
        var ws = weekStart(for: firstDay)

        while ws <= lastDay {
            let we = cal.date(byAdding: .day, value: 6, to: ws)!

            // Clamp to month boundaries
            let rangeStart = max(ws, firstDay)
            let rangeEnd = min(we, lastDay)

            var done = 0, tracked = 0
            var hasAnyData = false
            var d = rangeStart
            while d <= rangeEnd {
                if !isFuture(d) || isToday(d) {
                    let ids = store.trackedHabitIds(on: d)
                    if !ids.isEmpty {
                        hasAnyData = true
                        let ds = formatDate(d)
                        let dayData = store.checkins[ds] ?? [:]
                        tracked += ids.count
                        for id in ids {
                            if (dayData[id] ?? 0) >= 1 { done += 1 }
                        }
                    }
                }
                d = cal.date(byAdding: .day, value: 1, to: d)!
            }

            let rate = tracked > 0 ? Double(done) / Double(tracked) * 100.0 : 0

            // Skip fully future weeks
            if hasAnyData || (!isFuture(rangeStart) || isToday(rangeStart)) {
                results.append(WeeklyStat(
                    weekStart: ws,
                    weekEnd: we,
                    displayStart: rangeStart,
                    displayEnd: rangeEnd,
                    done: done,
                    tracked: tracked,
                    rate: rate
                ))
            }

            ws = cal.date(byAdding: .day, value: 7, to: ws)!
        }

        return results
    }
}
