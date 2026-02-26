import SwiftUI

struct YearProgressView: View {
    @EnvironmentObject var store: AppStore

    let year: Int
    let filterHabitId: String?
    let onYearChange: (Int) -> Void
    let onMonthTap: (Int) -> Void

    private var now: Date { Date() }
    private var currentYear: Int { Calendar.current.component(.year, from: now) }
    private var currentMonth: Int { Calendar.current.component(.month, from: now) - 1 }

    var body: some View {
        VStack(spacing: 12) {
            // Nav header
            HStack {
                navArrow(left: true) { onYearChange(year - 1) }
                Spacer()
                Text(verbatim: String(year))
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                navArrow(left: false) { onYearChange(year + 1) }
            }
            .padding(.bottom, 2)

            // Year summary
            yearSummary

            // Month cards
            ForEach(0..<12, id: \.self) { month in
                monthCard(month: month)
            }

            // Legend
            legend
        }
    }

    // MARK: - Summary cards

    var yearSummary: some View {
        let (doneDays, trackedDays) = computeYearTotals()
        return HStack(spacing: 8) {
            summaryCard(label: "Выполнено", value: doneDays, color: Color(UIColor.systemGreen))
            summaryCard(label: "Затрекано", value: trackedDays, color: .primary)
        }
    }

    func summaryCard(label: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(color)
                Text(pluralDays(value))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Month card

    func monthCard(month: Int) -> some View {
        let isCurrentMonth = year == currentYear && month == currentMonth
        let isPast = year < currentYear || (year == currentYear && month <= currentMonth)
        let (cells, doneDays, trackedDays) = computeMonthData(month: month)
        let pct = trackedDays > 0 ? Int(Double(doneDays) / Double(trackedDays) * 100) : nil

        return Button {
            if isPast { onMonthTap(month) }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 8) {
                        Text(monthsFullRu[month])
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(isCurrentMonth ? Color(UIColor.systemGreen) : .primary)
                        if let pct = pct {
                            pctBadge(pct: pct)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // Mini heatmap
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7),
                    spacing: 2
                ) {
                    // Weekday headers
                    ForEach(weekdaysShortRu.prefix(7), id: \.self) { wd in
                        Text(String(wd.prefix(1)))
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemGray4))
                            .frame(maxWidth: .infinity)
                    }
                    // Cells
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                        heatmapCell(cell: cell, compact: true)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isCurrentMonth ? Color(UIColor.systemGreen) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .opacity(isPast ? 1 : 0.4)
        }
        .buttonStyle(SpringButtonStyle())
        .disabled(!isPast)
    }

    // MARK: - Heatmap cell

    @ViewBuilder
    func heatmapCell(cell: HeatmapCell?, compact: Bool) -> some View {
        if let cell = cell {
            let today = isToday(cell.date)
            RoundedRectangle(cornerRadius: compact ? 2 : 6)
                .fill(today ? Color.clear : cellBackground(status: cell.status))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Group {
                        if today {
                            RoundedRectangle(cornerRadius: compact ? 2 : 6)
                                .strokeBorder(Color(UIColor.systemGreen), lineWidth: 1.5)
                                .modifier(PulseModifier())
                        }
                    }
                )
        } else {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
        }
    }

    // MARK: - Legend

    var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: Color(UIColor.systemGreen), label: "Выполнено")
            legendItem(color: Color(UIColor.systemGray5), label: "Пропуск")
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(Color(UIColor.systemGreen), lineWidth: 1.5)
                    .frame(width: 8, height: 8)
                Text("Сегодня")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
    }

    func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    func cellBackground(status: DayStatus?) -> Color {
        guard let status = status else {
            return Color(UIColor.systemGray5)
        }
        switch status {
        case .all:     return Color(UIColor.systemGreen)
        case .partial: return Color(UIColor.systemGreen).opacity(0.45)
        case .none:    return Color(UIColor.systemGray5)
        }
    }

    func pctBadge(pct: Int) -> some View {
        let color: Color = pct >= 70
            ? Color(UIColor.systemGreen)
            : pct >= 40 ? Color(UIColor.systemYellow) : Color(UIColor.systemGray3)
        let bg: Color = pct >= 70
            ? Color(UIColor.systemGreen).opacity(0.15)
            : pct >= 40 ? Color(UIColor.systemYellow).opacity(0.15) : Color(UIColor.systemGray5)
        return Text("\(pct)%")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 6).fill(bg))
    }

    func navArrow(left: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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

    func computeYearTotals() -> (Int, Int) {
        var done = 0, tracked = 0
        for month in 0..<12 {
            let days = daysInMonth(year: year, month: month)
            for day in 1...days {
                guard let d = makeDate(year: year, month: month, day: day) else { continue }
                if isFuture(d) { continue }
                let ds = formatDate(d)
                if let s = store.dayStatus(date: ds, habitId: filterHabitId) {
                    tracked += 1
                    if s != .none { done += 1 }
                }
            }
        }
        return (done, tracked)
    }

    func computeMonthData(month: Int) -> ([HeatmapCell?], Int, Int) {
        let days = daysInMonth(year: year, month: month)
        let firstDow = weekdayIndex(makeDate(year: year, month: month, day: 1)!)
        var cells: [HeatmapCell?] = Array(repeating: nil, count: firstDow)
        var done = 0, tracked = 0

        for day in 1...days {
            guard let d = makeDate(year: year, month: month, day: day) else { continue }
            let ds = formatDate(d)
            let status = isFuture(d) ? nil : store.dayStatus(date: ds, habitId: filterHabitId)
            if let s = status {
                tracked += 1
                if s != .none { done += 1 }
            }
            cells.append(HeatmapCell(date: d, status: status))
        }
        // pad to full weeks
        while cells.count % 7 != 0 { cells.append(nil) }
        return (cells, done, tracked)
    }
}

// MARK: - HeatmapCell model

struct HeatmapCell {
    let date: Date
    let status: DayStatus?
}

// MARK: - Pulse animation modifier

struct PulseModifier: ViewModifier {
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(pulsing ? 0.5 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: pulsing
            )
            .onAppear { pulsing = true }
    }
}
