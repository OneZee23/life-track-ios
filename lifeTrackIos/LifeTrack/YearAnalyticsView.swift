import SwiftUI

struct YearAnalyticsView: View {
    @EnvironmentObject var store: AppStore

    let year: Int
    let onYearChange: (Int) -> Void
    let onMonthTap: (Int) -> Void

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    var body: some View {
        VStack(spacing: 16) {
            navHeader
            completionRateCard
            streakCards
            habitRankingCard
            monthlyBreakdownCard
        }
    }

    // MARK: - Nav header

    var navHeader: some View {
        HStack {
            navArrow(left: true) { onYearChange(year - 1) }
            Spacer()
            Text(verbatim: String(year))
                .font(.system(size: 17, weight: .bold))
            Spacer()
            navArrow(left: false) { onYearChange(year + 1) }
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

            // Progress bar
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
        let best = computeYearBestStreak()
        let current = computeCurrentStreak()

        return HStack(spacing: 8) {
            streakCard(label: L10n.bestStreak, value: best)
            streakCard(label: L10n.currentStreak, value: current)
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
                    .foregroundColor(
                        item.rate >= 75 ? Color(UIColor.systemGreen) : .secondary
                    )
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

    // MARK: - Monthly breakdown

    var monthlyBreakdownCard: some View {
        let stats = computeMonthlyStats()

        return VStack(alignment: .leading, spacing: 12) {
            Text(L10n.monthlyBreakdown)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ForEach(stats, id: \.month) { item in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onMonthTap(item.month)
                } label: {
                    monthRow(item: item)
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

    func monthRow(item: MonthlyStat) -> some View {
        HStack(spacing: 10) {
            Text(L10n.monthsShort[item.month])
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 32, alignment: .leading)

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

    // MARK: - Data computation

    struct HabitStat {
        let habit: Habit
        let done: Int
        let tracked: Int
        let rate: Double
    }

    struct MonthlyStat {
        let month: Int
        let done: Int
        let tracked: Int
        let rate: Double
    }

    func computeCompletionRate() -> (done: Int, tracked: Int, rate: Double) {
        let habits = store.activeHabits
        guard !habits.isEmpty else { return (0, 0, 0) }

        var totalDone = 0, totalTracked = 0
        for month in 0..<12 {
            let days = daysInMonth(year: year, month: month)
            for day in 1...days {
                guard let d = makeDate(year: year, month: month, day: day) else { continue }
                if isFuture(d) && !isToday(d) { continue }
                let ds = formatDate(d)
                for habit in habits {
                    if store.checkins[ds]?[habit.id] != nil {
                        totalTracked += 1
                        if store.checkinValue(habitId: habit.id, date: ds) == 1 {
                            totalDone += 1
                        }
                    }
                }
            }
        }
        let rate = totalTracked > 0 ? Double(totalDone) / Double(totalTracked) * 100.0 : 0
        return (totalDone, totalTracked, rate)
    }

    func computeYearBestStreak() -> Int {
        var best = 0, cur = 0
        for month in 0..<12 {
            let days = daysInMonth(year: year, month: month)
            for day in 1...days {
                guard let d = makeDate(year: year, month: month, day: day) else { continue }
                if isFuture(d) && !isToday(d) { break }
                let ds = formatDate(d)
                if let s = store.dayStatus(date: ds), s != .none {
                    cur += 1
                    best = max(best, cur)
                } else if !isToday(d) {
                    cur = 0
                }
            }
        }
        return best
    }

    func computeCurrentStreak() -> Int {
        let cal = Calendar.current
        let viewingCurrentYear = year == cal.component(.year, from: Date())

        // For past years, start from Dec 31; for current year, start from yesterday
        var date: Date
        if viewingCurrentYear {
            date = yesterday()
        } else if year > currentYear {
            return 0  // future year
        } else {
            date = cal.date(from: DateComponents(year: year, month: 12, day: 31))!
        }

        var streak = 0
        while true {
            let y = cal.component(.year, from: date)
            if y != year { break }  // only count within the viewed year
            let ds = formatDate(date)
            guard let status = store.dayStatus(date: ds), status != .none else { break }
            streak += 1
            date = cal.date(byAdding: .day, value: -1, to: date)!
        }
        return streak
    }

    func computeHabitStats() -> [HabitStat] {
        let habits = store.activeHabits
        var results: [HabitStat] = []

        for habit in habits {
            var done = 0, tracked = 0
            for month in 0..<12 {
                let days = daysInMonth(year: year, month: month)
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
            }
            let rate = tracked > 0 ? Double(done) / Double(tracked) * 100.0 : 0
            results.append(HabitStat(habit: habit, done: done, tracked: tracked, rate: rate))
        }

        return results.sorted { $0.rate > $1.rate }
    }

    func computeMonthlyStats() -> [MonthlyStat] {
        let habits = store.activeHabits
        let currentMonth = Calendar.current.component(.month, from: Date()) - 1
        var results: [MonthlyStat] = []

        for month in 0..<12 {
            // Skip fully future months
            if year > currentYear { continue }
            if year == currentYear && month > currentMonth { continue }

            let days = daysInMonth(year: year, month: month)
            var done = 0, tracked = 0
            for day in 1...days {
                guard let d = makeDate(year: year, month: month, day: day) else { continue }
                if isFuture(d) && !isToday(d) { continue }
                let ds = formatDate(d)
                for habit in habits {
                    if store.checkins[ds]?[habit.id] != nil {
                        tracked += 1
                        if store.checkinValue(habitId: habit.id, date: ds) == 1 {
                            done += 1
                        }
                    }
                }
            }
            let rate = tracked > 0 ? Double(done) / Double(tracked) * 100.0 : 0
            results.append(MonthlyStat(month: month, done: done, tracked: tracked, rate: rate))
        }

        return results
    }
}
