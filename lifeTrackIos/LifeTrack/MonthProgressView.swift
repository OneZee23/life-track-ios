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
                NavArrowButton(left: true) { onMonthChange(month - 1) }
                Spacer()
                VStack(spacing: 2) {
                    Text(verbatim: "\(L10n.monthsFull[month]) \(String(year))")
                        .font(.system(size: 17, weight: .bold))
                }
                Spacer()
                NavArrowButton(left: false) { onMonthChange(month + 1) }
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

        return VStack(spacing: 4) {
            // Weekday headers
            HStack(spacing: 4) {
                ForEach(L10n.weekdaysShort, id: \.self) { wd in
                    Text(wd)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 4) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        if let cell = cell {
                            dayCell(cell: cell)
                        } else {
                            Color.clear.frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                        }
                    }
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
    func dayCell(cell: MonthCell) -> some View {
        let today = isToday(cell.date)
        let status = cell.status ?? .none
        let isFutureDate = cell.date > now && !today
        let tooFar = isBeyondTomorrow(cell.date)

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
        .disabled(tooFar)
    }

    // MARK: - Streaks

    var streakCards: some View {
        let best = store.bestStreakAllTime()
        let cur = store.currentStreak()
        return HStack(spacing: 8) {
            StreakCardView(label: L10n.bestStreak, value: best)
            StreakCardView(label: L10n.currentStreak, value: cur)
        }
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

    // MARK: - Data

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
