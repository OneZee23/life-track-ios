import SwiftUI

struct YearProgressView: View {
    @EnvironmentObject var store: AppStore

    let year: Int
    let onYearChange: (Int) -> Void
    let onDayTap: (Date) -> Void
    let onAnalyticsTap: () -> Void

    private let cellSize: CGFloat = DT.cellSize
    private let cellSpacing: CGFloat = DT.cellSpacing
    private let dayLabelWidth: CGFloat = 28

    private var now: Date { Date() }
    private var currentYear: Int { Calendar.current.component(.year, from: now) }

    var body: some View {
        VStack(spacing: 12) {
            navHeader
            yearSummary
            heatmapCard
            githubLegend
            analyticsButton
        }
    }

    // MARK: - Nav header

    var navHeader: some View {
        HStack {
            NavArrowButton(left: true) { onYearChange(year - 1) }
            Spacer()
            Text(verbatim: String(year))
                .font(.system(size: 17, weight: .bold))
            Spacer()
            NavArrowButton(left: false) { onYearChange(year + 1) }
        }
        .padding(.bottom, 2)
    }

    // MARK: - Summary cards

    var yearSummary: some View {
        let totalDaysInYear = isLeapYear(year) ? 366 : 365
        let totals = computeYearTotals()

        return HStack(spacing: 8) {
            if year == currentYear {
                let dayOfYear = currentDayOfYear()
                firstCard(
                    label: L10n.dayOfYear,
                    valueText: "\(dayOfYear)",
                    suffix: "/\(totalDaysInYear)",
                    hint: L10n.hintDayOfYear,
                    color: .primary
                )
            } else if year < currentYear {
                let missed = totalDaysInYear - totals.tracked
                firstCard(
                    label: L10n.missed,
                    valueText: "\(missed)",
                    suffix: nil,
                    hint: L10n.hintMissedDays,
                    color: Color(UIColor.systemOrange)
                )
            } else {
                firstCard(
                    label: L10n.totalDays,
                    valueText: "\(totalDaysInYear)",
                    suffix: nil,
                    hint: L10n.hintTotalDays,
                    color: .primary
                )
            }

            summaryCard(label: L10n.completed, hint: L10n.hintCompleted, value: totals.done, color: Color(UIColor.systemGreen))
            summaryCard(label: L10n.perfect, hint: L10n.hintPerfect, value: totals.perfect, color: Color(UIColor.systemGreen))
        }
    }

    func firstCard(label: String, valueText: String, suffix: String?, hint: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: DT.labelSize, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
            if let suffix = suffix {
                HStack(alignment: .bottom, spacing: 1) {
                    Text(valueText)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(color)
                    Text(suffix)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)
                }
            } else {
                Text(valueText)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(color)
            }
            Text(hint)
                .font(.system(size: 10))
                .foregroundColor(Color(UIColor.systemGray3))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .healthCard(padding: 14)
    }

    func summaryCard(label: String, hint: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: DT.labelSize, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
            Text("\(value)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(hint)
                .font(.system(size: 10))
                .foregroundColor(Color(UIColor.systemGray3))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .healthCard(padding: 14)
    }

    // MARK: - GitHub-style heatmap

    var heatmapCard: some View {
        let grid = buildYearGrid()

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Fixed day labels column
                VStack(spacing: 0) {
                    // Spacer for month label row
                    Color.clear.frame(width: dayLabelWidth, height: 16)

                    ForEach(0..<7, id: \.self) { row in
                        if row == 0 || row == 2 || row == 4 {
                            Text(L10n.weekdaysShort[row])
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: dayLabelWidth, height: cellSize, alignment: .trailing)
                                .padding(.trailing, 4)
                                .padding(.bottom, row < 6 ? cellSpacing : 0)
                        } else {
                            Color.clear
                                .frame(width: dayLabelWidth, height: cellSize)
                                .padding(.bottom, row < 6 ? cellSpacing : 0)
                        }
                    }
                }

                // Scrollable area: month labels + grid
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            // Month labels
                            monthLabelsRow(grid: grid)

                            // Grid columns
                            HStack(spacing: cellSpacing) {
                                ForEach(0..<grid.columns.count, id: \.self) { col in
                                    VStack(spacing: cellSpacing) {
                                        ForEach(0..<7, id: \.self) { row in
                                            cellView(cell: grid.columns[col][row])
                                        }
                                    }
                                    .id(col)
                                }
                            }
                            .padding(.trailing, 4)
                        }
                    }
                    .onAppear {
                        let targetCol = currentWeekColumn(grid: grid)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.none) {
                                proxy.scrollTo(targetCol, anchor: .trailing)
                            }
                        }
                    }
                }
            }
        }
        .healthCard(padding: 14)
    }

    // MARK: - Month labels

    func monthLabelsRow(grid: YearGrid) -> some View {
        let step = cellSize + cellSpacing

        return HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Invisible spacer for full width
                Color.clear
                    .frame(
                        width: CGFloat(grid.columns.count) * step - cellSpacing,
                        height: 12
                    )

                ForEach(Array(grid.monthLabels.enumerated()), id: \.offset) { _, item in
                    Text(item.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .offset(x: CGFloat(item.column) * step)
                }
            }
        }
        .frame(height: 12)
    }

    // MARK: - Cell view

    @ViewBuilder
    func cellView(cell: YearHeatmapCell?) -> some View {
        if let cell = cell {
            let status = cell.status ?? .none
            let today = isToday(cell.date)
            let isFutureDate = isFuture(cell.date) && !today
            let tooFar = isBeyondTomorrow(cell.date)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onDayTap(cell.date)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: DT.cellRadius)
                        .fill(isFutureDate ? Color(UIColor.systemGray6) : status.color)
                        .frame(width: cellSize, height: cellSize)

                    if today {
                        RoundedRectangle(cornerRadius: DT.cellRadius)
                            .strokeBorder(Color(UIColor.systemOrange), lineWidth: 2)
                            .frame(width: cellSize, height: cellSize)
                            .modifier(PulseModifier())
                    }
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .disabled(tooFar)
        } else {
            Color.clear
                .frame(width: cellSize, height: cellSize)
        }
    }

    // MARK: - Legend

    var githubLegend: some View {
        HStack(spacing: 4) {
            Text(L10n.less)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            ForEach([DayStatus.none, .low, .medium, .high, .full], id: \.level) { status in
                RoundedRectangle(cornerRadius: 3)
                    .fill(status.color)
                    .frame(width: 12, height: 12)
            }

            Text(L10n.more)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color(UIColor.systemOrange), lineWidth: 1.5)
                    .frame(width: 12, height: 12)
                Text(L10n.today)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Analytics button

    var analyticsButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onAnalyticsTap()
        } label: {
            HStack {
                Text(L10n.detailedAnalytics)
                    .font(.system(size: DT.bodySize, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(Color(UIColor.systemGreen))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DT.cardRadius)
                    .fill(Color(UIColor.systemGreen).opacity(0.1))
            )
            .shadow(color: Color(UIColor.systemGreen).opacity(0.10), radius: 6, x: 0, y: 2)
        }
    }

    // MARK: - Data

    func buildYearGrid() -> YearGrid {
        let cal = Calendar.current

        let jan1 = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let jan1Wd = weekdayIndex(jan1) // 0=Mon..6=Sun

        // Start from Monday of the week containing Jan 1
        let startDate = cal.date(byAdding: .day, value: -jan1Wd, to: jan1)!

        let dec31 = cal.date(from: DateComponents(year: year, month: 12, day: 31))!
        let dec31Wd = weekdayIndex(dec31)
        // End on Sunday of the week containing Dec 31
        let endDate = cal.date(byAdding: .day, value: 6 - dec31Wd, to: dec31)!

        let totalDays = cal.dateComponents([.day], from: startDate, to: endDate).day! + 1
        let totalColumns = totalDays / 7

        var columns: [[YearHeatmapCell?]] = Array(
            repeating: Array(repeating: nil, count: 7),
            count: totalColumns
        )

        var monthLabels: [(label: String, column: Int)] = []
        var currentMonth = -1
        var lastLabelCol = -10

        for dayOffset in 0..<totalDays {
            let date = cal.date(byAdding: .day, value: dayOffset, to: startDate)!
            let col = dayOffset / 7
            let row = dayOffset % 7

            let dateYear = cal.component(.year, from: date)
            let month = cal.component(.month, from: date) - 1

            // Month labels (only for dates in target year, skip if too close to previous)
            if dateYear == year && month != currentMonth {
                currentMonth = month
                if col - lastLabelCol >= 4 {
                    monthLabels.append((L10n.monthsShort[month], col))
                    lastLabelCol = col
                }
            }

            // Only populate cells for dates in the target year
            guard dateYear == year else {
                columns[col][row] = nil
                continue
            }

            let ds = formatDate(date)
            let today = isToday(date)
            let status: DayStatus? = (isFuture(date) && !today) ? nil : store.dayStatus(date: ds)
            columns[col][row] = YearHeatmapCell(date: date, status: status)
        }

        return YearGrid(columns: columns, monthLabels: monthLabels)
    }

    func computeYearTotals() -> (done: Int, perfect: Int, tracked: Int) {
        var done = 0, perfect = 0, tracked = 0
        for month in 0..<12 {
            let days = daysInMonth(year: year, month: month)
            for day in 1...days {
                guard let d = makeDate(year: year, month: month, day: day) else { continue }
                if isFuture(d) && !isToday(d) { continue }
                let ds = formatDate(d)
                if let s = store.dayStatus(date: ds) {
                    tracked += 1
                    if s != .none { done += 1 }
                }
                // Perfect = actual 100% (all tracked habits done)
                let ids = store.trackedHabitIds(on: d)
                if !ids.isEmpty {
                    let dayData = store.checkins[ds] ?? [:]
                    let dayDone = ids.filter { dayData[$0] == 1 }.count
                    if dayDone == ids.count { perfect += 1 }
                }
            }
        }
        return (done, perfect, tracked)
    }

    func currentDayOfYear() -> Int {
        let cal = Calendar.current
        if year == currentYear {
            return cal.ordinality(of: .day, in: .year, for: Date()) ?? 1
        } else if year < currentYear {
            return isLeapYear(year) ? 366 : 365
        }
        return 1
    }

    func isLeapYear(_ y: Int) -> Bool {
        (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
    }

    func currentWeekColumn(grid: YearGrid) -> Int {
        let cal = Calendar.current
        let jan1 = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let jan1Wd = weekdayIndex(jan1)
        let startDate = cal.date(byAdding: .day, value: -jan1Wd, to: jan1)!

        let today = Date()
        let daysSinceStart = cal.dateComponents([.day], from: startDate, to: today).day ?? 0
        let col = daysSinceStart / 7
        return min(max(col, 0), grid.columns.count - 1)
    }
}

// MARK: - Data models

struct YearHeatmapCell {
    let date: Date
    let status: DayStatus?
}

struct YearGrid {
    let columns: [[YearHeatmapCell?]]  // [weekColumn][dayRow]
    let monthLabels: [(label: String, column: Int)]
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
