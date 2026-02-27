import SwiftUI

struct MonthProgressView: View {
    @EnvironmentObject var store: AppStore

    let year: Int
    let month: Int
    let onMonthChange: (Int) -> Void
    let onDayTap: (Date) -> Void
    let onAnalyticsTap: () -> Void

    private var now: Date { Date() }

    var body: some View {
        VStack(spacing: 12) {
            // Nav header
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

            // Calendar grid
            calendarGrid

            // Streaks
            streakCards

            // Analytics button
            analyticsButton
        }
    }

    // MARK: - Calendar

    var calendarGrid: some View {
        let cells = buildCells()
        let rows = stride(from: 0, to: cells.count, by: 7).map {
            Array(cells[$0..<min($0 + 7, cells.count)])
        }
        let weekRates = computeWeeklyRates(rows: rows)

        return VStack(spacing: 4) {
            // Weekday headers
            HStack(spacing: 4) {
                ForEach(L10n.weekdaysShort, id: \.self) { wd in
                    Text(wd)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                Color.clear.frame(width: 32)
            }

            // Day cells + weekly indicator
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                HStack(spacing: 4) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        if let cell = cell {
                            dayCell(cell: cell)
                        } else {
                            Color.clear.frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                        }
                    }
                    weekProgressIndicator(rate: weekRates[idx])
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    @ViewBuilder
    func weekProgressIndicator(rate: Double) -> some View {
        if rate < 0 {
            Color.clear.frame(width: 32)
        } else {
            VStack(spacing: 2) {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(weekBarColor(rate: rate))
                            .frame(height: geo.size.height * CGFloat(rate / 100.0))
                    }
                }
                .frame(width: 4)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(UIColor.systemGray5))
                )

                Text("\(Int(rate))%")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(rate >= 75 ? Color(UIColor.systemGreen) : .secondary)
            }
            .frame(width: 32)
        }
    }

    func weekBarColor(rate: Double) -> Color {
        if rate >= 75 { return Color(UIColor.systemGreen) }
        if rate >= 50 { return Color(UIColor.systemGreen).opacity(0.75) }
        if rate >= 25 { return Color(UIColor.systemGreen).opacity(0.50) }
        return Color(UIColor.systemGreen).opacity(0.25)
    }

    @ViewBuilder
    func dayCell(cell: MonthCell) -> some View {
        let today = isToday(cell.date)
        let status = cell.status ?? .none
        let isFutureDate = cell.date > now && !today

        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onDayTap(cell.date)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFutureDate ? Color(UIColor.systemGray6) : status.color)

                if today {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color(UIColor.systemOrange), lineWidth: 2)
                        .modifier(PulseModifier())
                }

                Text("\(cell.day)")
                    .font(.system(size: 12, weight: today ? .bold : .medium))
                    .foregroundColor(
                        today
                            ? (status != .none ? .white : Color(UIColor.systemOrange))
                            : (status.needsWhiteText ? .white : Color(UIColor.systemGray3))
                    )
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(SpringButtonStyle())
        .disabled(isFutureDate)
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

    // MARK: - Analytics button

    var analyticsButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onAnalyticsTap()
        } label: {
            HStack {
                Text(L10n.detailedAnalytics)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(Color(UIColor.systemGreen))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.systemGreen).opacity(0.1))
            )
        }
    }

    // MARK: - Nav

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

    func computeWeeklyRates(rows: [[MonthCell?]]) -> [Double] {
        let habits = store.activeHabits
        guard !habits.isEmpty else { return rows.map { _ in -1 } }

        return rows.map { row in
            var done = 0, tracked = 0
            for cell in row {
                guard let cell = cell else { continue }
                if isFuture(cell.date) && !isToday(cell.date) { continue }
                let ds = formatDate(cell.date)
                for habit in habits {
                    if store.checkins[ds]?[habit.id] != nil {
                        tracked += 1
                        if store.checkinValue(habitId: habit.id, date: ds) == 1 {
                            done += 1
                        }
                    }
                }
            }
            return tracked > 0 ? Double(done) / Double(tracked) * 100.0 : -1
        }
    }

    func buildCells() -> [MonthCell?] {
        let days = daysInMonth(year: year, month: month)
        let firstDow = weekdayIndex(makeDate(year: year, month: month, day: 1)!)
        var cells: [MonthCell?] = Array(repeating: nil, count: firstDow)

        for day in 1...days {
            guard let d = makeDate(year: year, month: month, day: day) else { continue }
            let ds = formatDate(d)
            let status: DayStatus? = (isFuture(d) && !isToday(d))
                ? nil
                : store.dayStatus(date: ds)
            cells.append(MonthCell(day: day, date: d, status: status))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}

struct MonthCell {
    let day: Int
    let date: Date
    let status: DayStatus?
}
