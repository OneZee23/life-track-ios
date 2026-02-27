import SwiftUI

struct MonthAnalyticsView: View {
    @EnvironmentObject var store: AppStore

    let year: Int
    let month: Int
    let onMonthChange: (Int) -> Void
    let onWeekTap: (Date) -> Void

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    private var currentMonth: Int { Calendar.current.component(.month, from: Date()) - 1 }

    var body: some View {
        VStack(spacing: 16) {
            navHeader
            completionRateCard
            streakCards
            habitRankingCard
            weeklyBreakdownCard
        }
    }

    // MARK: - Nav header

    var navHeader: some View {
        HStack {
            navArrow(left: true) { onMonthChange(month - 1) }
            Spacer()
            VStack(spacing: 2) {
                Text(verbatim: "\(L10n.monthsFull[month]) \(String(year))")
                    .font(.system(size: 17, weight: .bold))
            }
            Spacer()
            navArrow(left: false) { onMonthChange(month + 1) }
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

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(UIColor.systemGreen))
                        .frame(width: geo.size.width * CGFloat(stats.rate / 100.0), height: 8)
                }
            }
            .frame(height: 8)

            Text(L10n.checkinsOf(stats.done, stats.tracked))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Streaks

    var streakCards: some View {
        let best = store.bestStreak(year: year, month: month)
        let cur = store.currentStreak(year: year, month: month)

        return HStack(spacing: 8) {
            streakCard(label: L10n.bestStreak, value: best)
            streakCard(label: L10n.currentStreak, value: cur)
        }
    }

    func streakCard(label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Color(UIColor.systemGreen))
                Text(L10n.pluralDays(value))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Habit ranking

    var habitRankingCard: some View {
        let stats = computeHabitStats()

        return VStack(alignment: .leading, spacing: 12) {
            Text(L10n.habits)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ForEach(Array(stats.enumerated()), id: \.offset) { _, item in
                habitRow(item: item)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    func habitRow(item: HabitStat) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text(item.habit.emoji)
                    .font(.system(size: 16))
                Text(item.habit.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text(item.tracked > 0 ? "\(Int(item.rate))%" : "—")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(item.rate >= 75 ? Color(UIColor.systemGreen) : .secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(rate: item.rate))
                        .frame(width: geo.size.width * CGFloat(item.rate / 100.0), height: 5)
                }
            }
            .frame(height: 5)
        }
    }

    func barColor(rate: Double) -> Color {
        if rate >= 75 { return Color(UIColor.systemGreen) }
        if rate >= 50 { return Color(UIColor.systemGreen).opacity(0.75) }
        if rate >= 25 { return Color(UIColor.systemGreen).opacity(0.50) }
        return Color(UIColor.systemGreen).opacity(0.25)
    }

    // MARK: - Weekly breakdown

    var weeklyBreakdownCard: some View {
        let stats = computeWeeklyStats()

        return VStack(alignment: .leading, spacing: 12) {
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    func weekRow(item: WeeklyStat) -> some View {
        let label = weekLabel(item: item)
        return HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 100, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(rate: item.rate))
                        .frame(width: geo.size.width * CGFloat(item.rate / 100.0), height: 5)
                }
            }
            .frame(height: 5)

            Text(item.tracked > 0 ? "\(Int(item.rate))%" : "—")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(item.rate >= 75 ? Color(UIColor.systemGreen) : .secondary)
                .frame(width: 36, alignment: .trailing)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(UIColor.systemGray3))
        }
    }

    func weekLabel(item: WeeklyStat) -> String {
        let cal = Calendar.current
        let d1 = cal.component(.day, from: item.weekStart)
        let d2 = cal.component(.day, from: item.weekEnd)
        let m1 = cal.component(.month, from: item.weekStart) - 1
        let m2 = cal.component(.month, from: item.weekEnd) - 1
        if m1 == m2 {
            return "\(d1) – \(d2) \(L10n.monthsShort[m1])"
        }
        return "\(d1) \(L10n.monthsShort[m1]) – \(d2) \(L10n.monthsShort[m2])"
    }

    // MARK: - Nav arrow

    func navArrow(left: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 32, height: 32)
                Image(systemName: left ? "chevron.left" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
    }

    // MARK: - Data

    struct HabitStat {
        let habit: Habit
        let done: Int
        let tracked: Int
        let rate: Double
    }

    struct WeeklyStat: Identifiable {
        let weekStart: Date
        let weekEnd: Date
        let done: Int
        let tracked: Int
        let rate: Double
        var id: Date { weekStart }
    }

    func computeCompletionRate() -> (done: Int, tracked: Int, rate: Double) {
        let habits = store.activeHabits
        guard !habits.isEmpty else { return (0, 0, 0) }

        var totalDone = 0, totalTracked = 0
        let days = daysInMonth(year: year, month: month)
        for day in 1...days {
            guard let d = makeDate(year: year, month: month, day: day) else { continue }
            if isFuture(d) && !isToday(d) { continue }
            let ds = formatDate(d)

            var dayHasData = false
            for habit in habits {
                if store.checkins[ds]?[habit.id] != nil {
                    dayHasData = true
                    totalTracked += 1
                    if store.checkinValue(habitId: habit.id, date: ds) == 1 {
                        totalDone += 1
                    }
                }
            }
            if !dayHasData { continue }
        }
        let rate = totalTracked > 0 ? Double(totalDone) / Double(totalTracked) * 100.0 : 0
        return (totalDone, totalTracked, rate)
    }

    func computeHabitStats() -> [HabitStat] {
        let habits = store.activeHabits
        var results: [HabitStat] = []
        let days = daysInMonth(year: year, month: month)

        for habit in habits {
            var done = 0, tracked = 0
            for day in 1...days {
                guard let d = makeDate(year: year, month: month, day: day) else { continue }
                if isFuture(d) && !isToday(d) { continue }
                let ds = formatDate(d)
                if store.checkins[ds]?[habit.id] != nil {
                    tracked += 1
                    if store.checkinValue(habitId: habit.id, date: ds) == 1 {
                        done += 1
                    }
                }
            }
            let rate = tracked > 0 ? Double(done) / Double(tracked) * 100.0 : 0
            results.append(HabitStat(habit: habit, done: done, tracked: tracked, rate: rate))
        }

        return results.sorted { $0.rate > $1.rate }
    }

    func computeWeeklyStats() -> [WeeklyStat] {
        let cal = Calendar.current
        let habits = store.activeHabits
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
                    let ds = formatDate(d)
                    for habit in habits {
                        if store.checkins[ds]?[habit.id] != nil {
                            hasAnyData = true
                            tracked += 1
                            if store.checkinValue(habitId: habit.id, date: ds) == 1 {
                                done += 1
                            }
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
