import SwiftUI

struct HabitDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let habit: Habit
    var noteDate: Date = Date()

    @State private var selectedPeriod: Period = .days30
    @State private var selectedBarIndex: Int? = nil

    // Inline-in-log note editor — only one row is expanded at a time.
    @State private var expandedLogDate: String? = nil
    @State private var inlineNoteText: String = ""
    @State private var inlineLastSaved: String = ""
    @State private var inlineSaveTask: Task<Void, Never>? = nil

    enum Period: Int, CaseIterable {
        case days7 = 7
        case days30 = 30
        case days90 = 90
        case year = 365

        var label: String {
            switch self {
            case .days7:  return L10n.habitDetailPeriod7d
            case .days30: return L10n.habitDetailPeriod30d
            case .days90: return L10n.habitDetailPeriod90d
            case .year:   return L10n.habitDetailPeriodYear
            }
        }
    }

    private var isNumeric: Bool { habit.extendedField?.type == .numeric }
    private var isCount: Bool { habit.isCountBased }
    private var unit: String { habit.extendedField?.unit ?? "" }

    // MARK: - Pre-computed detail data

    private var detailData: HabitDetailData {
        if isCount {
            let history = store.habitCountHistory(habitId: habit.id, days: selectedPeriod.rawValue)
            return HabitDetailData(countHistory: history)
        } else {
            let history = store.habitHistory(habitId: habit.id, days: selectedPeriod.rawValue)
            return HabitDetailData(history: history, isSleep: habit.isSleep, unit: unit)
        }
    }

    private struct HabitDetailData {
        // Numeric / binary path
        let history: [(date: String, done: Bool, value: Double?)]
        let avg: Double?
        let min: Double?
        let max: Double?
        let bestStreak: Int
        let completion: Int

        // Count path
        let countHistory: [(date: String, value: Int, target: Int)]
        let countSum: Int
        let countAvg: Double
        let countMax: Int
        let perfectDays: Int
        let overflowDays: Int
        let countCompletion: Int   // sum(value) / sum(target) clamped to 100

        init(history: [(date: String, done: Bool, value: Double?)], isSleep: Bool, unit: String) {
            self.history = history
            let values = history.compactMap(\.value)
            self.avg = values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
            self.min = values.min()
            self.max = values.max()

            var best = 0, cur = 0
            for entry in history.reversed() {
                if entry.done { cur += 1; best = Swift.max(best, cur) } else { cur = 0 }
            }
            self.bestStreak = best

            let doneCount = history.filter(\.done).count
            self.completion = history.isEmpty ? 0 : Int(Double(doneCount) / Double(history.count) * 100)

            self.countHistory = []
            self.countSum = 0
            self.countAvg = 0
            self.countMax = 0
            self.perfectDays = 0
            self.overflowDays = 0
            self.countCompletion = 0
        }

        init(countHistory: [(date: String, value: Int, target: Int)]) {
            self.countHistory = countHistory
            self.history = []
            self.avg = nil; self.min = nil; self.max = nil
            self.bestStreak = 0; self.completion = 0

            let values = countHistory.map(\.value)
            self.countSum = values.reduce(0, +)
            self.countAvg = countHistory.isEmpty ? 0 : Double(countSum) / Double(countHistory.count)
            self.countMax = values.max() ?? 0

            let target = countHistory.first?.target ?? 1
            self.perfectDays = countHistory.filter { $0.value >= target }.count
            self.overflowDays = countHistory.filter { $0.value > target }.count

            let totalTarget = countHistory.reduce(0) { $0 + $1.target }
            // Don't clamp above 100 — overflow is informative ("122%" tells the
            // user they consistently exceeded their goal).
            self.countCompletion = totalTarget > 0
                ? Int(Double(countSum) / Double(totalTarget) * 100)
                : 0
        }
    }

    /// True when inline note editing is meaningful in the log — text-extended
    /// habits already have a per-day text field via ExtendedCheckinPanel.
    private var supportsInlineNotes: Bool {
        habit.extendedField?.type != .text
    }

    var body: some View {
        let dd = detailData
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    statsView(dd)
                    periodSelector
                    chartView(dd)
                    if !isNumeric {
                        heatmapSection(dd)
                    }
                    logView(dd)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.done) {
                        flushInlineNote()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(UIColor.systemGreen))
                }
            }
            .onAppear {
                // Auto-expand the row matching `noteDate` so the user lands
                // directly on the day they care about (today / yesterday /
                // a specific past day chosen from Progress).
                if supportsInlineNotes {
                    autoExpandTargetDate()
                }
            }
            .onDisappear { flushInlineNote() }
        }
    }

    private func autoExpandTargetDate() {
        let target = formatDate(noteDate)
        let history = isCount
            ? detailData.countHistory.map(\.date)
            : detailData.history.map(\.date)
        guard history.contains(target) else { return }
        expandLogRow(target)
    }

    private func expandLogRow(_ date: String) {
        flushInlineNote()
        let loaded = store.getNote(habitId: habit.id, date: date) ?? ""
        inlineNoteText = loaded
        inlineLastSaved = loaded
        expandedLogDate = date
    }

    private func collapseLogRow() {
        flushInlineNote()
        expandedLogDate = nil
        inlineNoteText = ""
        inlineLastSaved = ""
    }

    private func toggleLogRow(_ date: String) {
        if expandedLogDate == date {
            collapseLogRow()
        } else {
            expandLogRow(date)
        }
    }

    /// Cancels any pending debounced save and writes the inline text
    /// immediately if it differs from the last persisted value.
    private func flushInlineNote() {
        inlineSaveTask?.cancel()
        inlineSaveTask = nil
        guard let date = expandedLogDate, inlineNoteText != inlineLastSaved else { return }
        store.setNote(habitId: habit.id, date: date, note: inlineNoteText)
        inlineLastSaved = inlineNoteText
    }

    private func saveInlineNoteIfChanged() {
        guard let date = expandedLogDate, inlineNoteText != inlineLastSaved else { return }
        store.setNote(habitId: habit.id, date: date, note: inlineNoteText)
        inlineLastSaved = inlineNoteText
    }

    // MARK: - Inline log note editor

    private var inlineNoteEditor: some View {
        VStack(spacing: 0) {
            TextField(L10n.habitDetailNotePlaceholder, text: $inlineNoteText, axis: .vertical)
                .font(.system(size: 14))
                .lineLimit(2...6)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.systemGray6))
                )
                .onChange(of: inlineNoteText) { _ in
                    // Debounce: persist 400ms after typing stops to avoid encoding
                    // the entire UserDefaults blob on every keystroke.
                    inlineSaveTask?.cancel()
                    inlineSaveTask = Task {
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        guard !Task.isCancelled else { return }
                        await MainActor.run { saveInlineNoteIfChanged() }
                    }
                }
        }
        .padding(.top, 4)
        .padding(.bottom, 10)
        .padding(.horizontal, 4)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.systemGreen).opacity(0.15))
                    .frame(width: 52, height: 52)
                Text(habit.emoji)
                    .font(.system(size: 26))
            }

            Text(habit.name)
                .font(.system(size: DT.titleSize, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            let streak = store.habitStreak(habitId: habit.id, asOf: Date())
            if streak >= 1 {
                streakBadge(label: L10n.habitDetailStreak,
                            value: "\(streak)\(L10n.habitDetailDays)",
                            color: .systemOrange)
            }

            if isCount {
                let perfect = store.habitPerfectStreak(habitId: habit.id, asOf: Date())
                if perfect >= 1 {
                    streakBadge(label: "🌟",
                                value: "\(perfect)\(L10n.habitDetailDays)",
                                color: .systemPurple)
                }
            }
        }
        .healthCard(padding: 16)
    }

    private func streakBadge(label: String, value: String, color: UIColor) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color(color))
        }
    }

    // MARK: - Stats

    private func statsView(_ data: HabitDetailData) -> some View {
        Group {
            if isCount {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        statCard(label: L10n.habitDetailTotal,
                                 value: "\(data.countSum)",
                                 accent: .systemGreen)
                        statCard(label: L10n.habitDetailAvg,
                                 value: formatAvg(data.countAvg),
                                 accent: .systemGreen)
                    }
                    HStack(spacing: 8) {
                        statCard(label: L10n.habitDetailBestDay,
                                 value: "\(data.countMax)",
                                 accent: data.countMax > (data.countHistory.first?.target ?? 0) ? .systemPurple : .systemGreen)
                        statCard(label: L10n.habitDetailPerfectDays,
                                 value: "\(data.perfectDays)",
                                 accent: .systemGreen,
                                 sub: data.overflowDays > 0
                                    ? "🔥 \(data.overflowDays) \(L10n.habitDetailOverflowSuffix)"
                                    : nil)
                    }
                    HStack(spacing: 8) {
                        statCard(label: L10n.habitDetailCompletion,
                                 value: "\(data.countCompletion)%",
                                 accent: .systemGreen)
                    }
                }
            } else if isNumeric {
                HStack(spacing: 8) {
                    statCard(label: L10n.habitDetailAvg,
                             value: data.avg.map { formatNumericDisplay($0, unit: unit, isSleep: habit.isSleep) } ?? "—")
                    statCard(label: L10n.habitDetailMin,
                             value: data.min.map { formatNumericDisplay($0, unit: unit, isSleep: habit.isSleep) } ?? "—")
                    statCard(label: L10n.habitDetailMax,
                             value: data.max.map { formatNumericDisplay($0, unit: unit, isSleep: habit.isSleep) } ?? "—")
                }
            } else {
                let streak = store.habitStreak(habitId: habit.id, asOf: Date())
                HStack(spacing: 8) {
                    statCard(label: L10n.habitDetailStreak, value: "\(streak)\(L10n.habitDetailDays)")
                    statCard(label: L10n.habitDetailBestStreak, value: "\(data.bestStreak)\(L10n.habitDetailDays)")
                    statCard(label: L10n.habitDetailCompletion, value: "\(data.completion)%")
                }
            }
        }
    }

    private func statCard(label: String,
                          value: String,
                          accent: UIColor = .systemGreen,
                          sub: String? = nil) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(Color(accent))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let sub = sub {
                Text(sub)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(UIColor.systemPurple))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .healthCard(padding: 14)
    }

    private func formatAvg(_ v: Double) -> String {
        if v == 0 { return "0" }
        if v >= 10 { return "\(Int(v.rounded()))" }
        return String(format: "%.1f", v)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(Period.allCases, id: \.rawValue) { period in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.label)
                        .font(.system(size: 13, weight: selectedPeriod == period ? .semibold : .medium))
                        .foregroundColor(selectedPeriod == period ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            Group {
                                if selectedPeriod == period {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                                        .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
                                }
                            }
                        )
                        .padding(2)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.systemGray5))
        )
        .frame(height: 36)
    }

    // MARK: - Chart router

    private func chartView(_ dd: HabitDetailData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if isCount {
                countBarChart(dd)
            } else if isNumeric {
                numericBarChart(dd)
            } else {
                binaryDotsChart(dd)
            }
        }
        .healthCard(padding: 16)
    }

    // MARK: - Count Bar Chart

    private func countBarChart(_ dd: HabitDetailData) -> some View {
        let data = Array(dd.countHistory.reversed()) // oldest first
        let target = data.first?.target ?? 1
        let chartMax = max(target, dd.countMax, 1)
        let chartHeight: CGFloat = DT.chartHeight

        return VStack(spacing: 6) {
            // Header line: tooltip when bar selected, otherwise target line label
            if let idx = selectedBarIndex, idx < data.count {
                let entry = data[idx]
                let isOverflow = entry.value > entry.target
                HStack(spacing: 6) {
                    Text(formatLogDate(entry.date))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(entry.value)/\(entry.target)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Color(isOverflow ? .systemPurple : .systemGreen))
                    if isOverflow {
                        Text("🔥").font(.system(size: 13))
                    }
                }
                .transition(.opacity)
                .frame(height: 20)
            } else {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color(UIColor.systemOrange).opacity(0.6))
                        .frame(width: 14, height: 1.5)
                    Text(L10n.habitDetailTargetLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(target)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemOrange))
                }
                .frame(height: 20)
            }

            if data.isEmpty {
                Text(L10n.habitDetailNoData)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(height: chartHeight)
                    .frame(maxWidth: .infinity)
            } else {
                ZStack(alignment: .bottom) {
                    // Target reference line
                    let targetRatio = CGFloat(target) / CGFloat(chartMax)
                    GeometryReader { geo in
                        Path { path in
                            let y = chartHeight * (1 - targetRatio)
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                        .stroke(Color(UIColor.systemOrange), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                    .frame(height: chartHeight)

                    GeometryReader { geo in
                        let count = CGFloat(data.count)
                        let spacing: CGFloat = count > 60 ? 0.5 : (count > 30 ? 1 : 2)
                        let totalSpacing = spacing * max(count - 1, 0)
                        let barW = max(1, (geo.size.width - totalSpacing) / max(count, 1))

                        HStack(alignment: .bottom, spacing: spacing) {
                            ForEach(Array(data.enumerated()), id: \.offset) { idx, entry in
                                let isSelected = selectedBarIndex == idx
                                let h = chartHeight * CGFloat(entry.value) / CGFloat(chartMax)
                                let color = countBarColor(value: entry.value, target: entry.target, isSelected: isSelected)
                                RoundedRectangle(cornerRadius: barW > 4 ? 3 : 1)
                                    .fill(color)
                                    .frame(width: barW, height: max(entry.value > 0 ? 1 : 1, h))
                                    .opacity(entry.value == 0 ? 0.6 : 1.0)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            selectedBarIndex = selectedBarIndex == idx ? nil : idx
                                        }
                                    }
                            }
                        }
                    }
                    .frame(height: chartHeight)
                }

                timeAxisLabels(dates: data.map(\.date))
            }
        }
        .onChange(of: selectedPeriod) { _ in selectedBarIndex = nil }
    }

    private func countBarColor(value: Int, target: Int, isSelected: Bool) -> Color {
        if value == 0 {
            return Color(UIColor.systemGray5)
        }
        if value > target {
            return Color(UIColor.systemPurple).opacity(isSelected ? 1.0 : 0.85)
        }
        if value >= target {
            return Color(UIColor.systemGreen).opacity(isSelected ? 1.0 : DT.barInactiveOpacity)
        }
        return Color(UIColor.systemGreen).opacity(isSelected ? 0.7 : 0.4)
    }

    // MARK: - Heatmap (count + binary)

    private func heatmapSection(_ dd: HabitDetailData) -> some View {
        // Build 7×N grid: rows = weekdays (Mon..Sun), columns = weeks
        let days = isCount
            ? dd.countHistory.map { (date: $0.date, value: $0.value, target: $0.target) }
            : dd.history.map { (date: $0.date, value: $0.done ? 1 : 0, target: 1) }

        // Anchor on selected period: grid spans from oldest to newest entry
        let cal = Calendar.current
        let sorted = days.sorted { $0.date < $1.date }
        guard let firstDate = sorted.first.flatMap({ parseDate($0.date) }),
              let lastDate = sorted.last.flatMap({ parseDate($0.date) }) else {
            return AnyView(EmptyView())
        }

        // Find Monday of the first week in range
        let firstWeekStart = weekStart(for: firstDate)
        // Find Monday of the week containing lastDate
        let lastWeekStart = weekStart(for: lastDate)
        let weeksApart = (cal.dateComponents([.day], from: firstWeekStart, to: lastWeekStart).day ?? 0) / 7
        let weekCount = max(1, weeksApart + 1)

        // Build map for quick lookup
        let dayMap: [String: (value: Int, target: Int)] = Dictionary(
            uniqueKeysWithValues: days.map { ($0.date, (value: $0.value, target: $0.target)) }
        )

        let cellSize: CGFloat = weekCount > 26 ? 8 : (weekCount > 13 ? 11 : 14)
        let cellSpacing: CGFloat = 2

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.habitDetailHeatmap)
                    .font(.system(size: DT.labelSize, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: cellSpacing) {
                        ForEach(0..<weekCount, id: \.self) { weekIdx in
                            VStack(spacing: cellSpacing) {
                                ForEach(0..<7, id: \.self) { dayOfWeek in
                                    let dayOffset = weekIdx * 7 + dayOfWeek
                                    let cellDate = cal.date(byAdding: .day, value: dayOffset, to: firstWeekStart)
                                    cellView(date: cellDate,
                                             dayMap: dayMap,
                                             cellSize: cellSize)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                heatmapLegend()
            }
            .healthCard(padding: 16)
        )
    }

    private func cellView(date: Date?,
                          dayMap: [String: (value: Int, target: Int)],
                          cellSize: CGFloat) -> some View {
        Group {
            if let date = date, !isFuture(date) || isToday(date) {
                let ds = formatDate(date)
                let entry = dayMap[ds]
                RoundedRectangle(cornerRadius: 3)
                    .fill(heatmapColor(entry: entry))
                    .frame(width: cellSize, height: cellSize)
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.clear)
                    .frame(width: cellSize, height: cellSize)
            }
        }
    }

    private func heatmapColor(entry: (value: Int, target: Int)?) -> Color {
        guard let entry = entry, entry.value > 0 else {
            return Color(UIColor.systemGray5)
        }
        let target = max(1, entry.target)
        let ratio = Double(entry.value) / Double(target)
        if ratio > 1.0 { return Color(UIColor.systemPurple) }
        if ratio >= 1.0 { return Color(UIColor.systemGreen) }
        if ratio >= 0.66 { return Color(UIColor.systemGreen).opacity(0.70) }
        if ratio >= 0.33 { return Color(UIColor.systemGreen).opacity(0.45) }
        return Color(UIColor.systemGreen).opacity(0.20)
    }

    private func heatmapLegend() -> some View {
        HStack(spacing: 6) {
            Text(L10n.habitDetailHeatmapLess)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            ForEach([0.0, 0.20, 0.45, 0.70, 1.0], id: \.self) { o in
                RoundedRectangle(cornerRadius: 2)
                    .fill(o == 0
                          ? Color(UIColor.systemGray5)
                          : Color(UIColor.systemGreen).opacity(o == 1.0 ? 1.0 : o))
                    .frame(width: 10, height: 10)
            }
            if isCount {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(UIColor.systemPurple))
                    .frame(width: 10, height: 10)
            }
            Text(L10n.habitDetailHeatmapMore)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Numeric Bar Chart (existing, untouched)

    private func numericBarChart(_ dd: HabitDetailData) -> some View {
        let data = Array(dd.history.reversed())
        let values = data.compactMap(\.value)
        let maxVal = values.max() ?? 1.0
        let avgVal = dd.avg ?? 0
        let chartHeight: CGFloat = DT.chartHeight

        return VStack(spacing: 6) {
            if let idx = selectedBarIndex, idx < data.count {
                let entry = data[idx]
                HStack(spacing: 6) {
                    Text(formatLogDate(entry.date))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    if let val = entry.value {
                        Text(formatNumericDisplay(val, unit: unit, isSleep: habit.isSleep))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Color(UIColor.systemGreen))
                    }
                }
                .transition(.opacity)
                .frame(height: 20)
            } else {
                if avgVal > 0 {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color(UIColor.systemOrange).opacity(0.6))
                            .frame(width: 14, height: 1.5)
                        Text(L10n.habitDetailAvg)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(formatNumericDisplay(avgVal, unit: unit, isSleep: habit.isSleep))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemOrange))
                    }
                    .frame(height: 20)
                } else {
                    Color.clear.frame(height: 20)
                }
            }

            if values.isEmpty {
                Text(L10n.habitDetailNoData)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(height: chartHeight)
                    .frame(maxWidth: .infinity)
            } else {
                ZStack(alignment: .bottom) {
                    if maxVal > 0 && avgVal > 0 {
                        let ratio = CGFloat(avgVal / maxVal)
                        GeometryReader { geo in
                            Path { path in
                                let y = chartHeight * (1 - ratio)
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: geo.size.width, y: y))
                            }
                            .stroke(Color(UIColor.systemOrange), lineWidth: 1)
                        }
                        .frame(height: chartHeight)
                    }

                    GeometryReader { geo in
                        let count = CGFloat(data.count)
                        let spacing: CGFloat = count > 60 ? 0.5 : (count > 30 ? 1 : 2)
                        let totalSpacing = spacing * max(count - 1, 0)
                        let barW = max(1, (geo.size.width - totalSpacing) / max(count, 1))

                        HStack(alignment: .bottom, spacing: spacing) {
                            ForEach(Array(data.enumerated()), id: \.offset) { idx, entry in
                                let isSelected = selectedBarIndex == idx
                                if let val = entry.value, maxVal > 0 {
                                    let h = chartHeight * CGFloat(val / maxVal)
                                    RoundedRectangle(cornerRadius: barW > 4 ? 3 : 1)
                                        .fill(isSelected
                                              ? Color(UIColor.systemGreen)
                                              : Color(UIColor.systemGreen).opacity(DT.barInactiveOpacity))
                                        .frame(width: barW, height: max(1, h))
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                selectedBarIndex = selectedBarIndex == idx ? nil : idx
                                            }
                                        }
                                } else {
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color(UIColor.systemGray5))
                                        .frame(width: barW, height: 1)
                                }
                            }
                        }
                    }
                    .frame(height: chartHeight)
                }

                timeAxisLabels(dates: data.map(\.date))
            }
        }
        .onChange(of: selectedPeriod) { _ in selectedBarIndex = nil }
    }

    private func timeAxisLabels(dates: [String]) -> some View {
        let cal = Calendar.current
        let count = dates.count
        var labelMap: [Int: String] = [:]

        for (idx, ds) in dates.enumerated() {
            guard let dateObj = parseDate(ds) else { continue }
            let day = cal.component(.day, from: dateObj)
            let month = cal.component(.month, from: dateObj) - 1
            let weekday = weekdayIndex(dateObj)

            switch selectedPeriod {
            case .days7:
                labelMap[idx] = L10n.weekdaysShort[weekday]
            case .days30:
                if weekday == 0 || idx == 0 || idx == count - 1 {
                    labelMap[idx] = "\(day)"
                }
            case .days90:
                if day == 1 || idx == 0 {
                    labelMap[idx] = "\(month + 1)/\(String(format: "%02d", day))"
                }
            case .year:
                if day == 1 || idx == 0 {
                    labelMap[idx] = "\(month + 1)"
                }
            }
        }

        return HStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { idx in
                if let label = labelMap[idx] {
                    Text(label)
                        .font(.system(size: DT.labelSize, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                }
            }
        }
    }

    // MARK: - Binary Dots Chart (existing)

    private func binaryDotsChart(_ dd: HabitDetailData) -> some View {
        let data = Array(dd.history.reversed())

        let dotSize: CGFloat = selectedPeriod == .days7 ? 32 : (selectedPeriod == .days30 ? 18 : 12)
        let spacing: CGFloat = selectedPeriod == .days7 ? 6 : (selectedPeriod == .days30 ? 4 : 2)

        return VStack(spacing: 8) {
            if !data.isEmpty && data.count < selectedPeriod.rawValue / 2 {
                Text(L10n.isRu
                     ? "Трекинг: \(data.count) \(L10n.pluralDays(data.count))"
                     : "Tracking: \(data.count) \(L10n.pluralDays(data.count))")
                    .font(.system(size: DT.labelSize, weight: .medium))
                    .foregroundColor(.secondary)
            }

            if data.isEmpty {
                Text(L10n.habitDetailNoData)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
            } else {
                let columns = [GridItem(.adaptive(minimum: dotSize + spacing), spacing: spacing)]
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, entry in
                        ZStack {
                            Circle()
                                .fill(entry.done
                                      ? Color(UIColor.systemGreen)
                                      : Color(UIColor.systemGray5))
                                .frame(width: dotSize, height: dotSize)

                            if selectedPeriod == .days7 || selectedPeriod == .days30 {
                                if entry.done {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: dotSize * 0.4, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "xmark")
                                        .font(.system(size: dotSize * 0.35, weight: .medium))
                                        .foregroundColor(Color(UIColor.systemGray3))
                                }
                            }
                        }
                    }
                }

                if selectedPeriod == .days7 {
                    HStack(spacing: 0) {
                        ForEach(Array(data.enumerated()), id: \.offset) { _, entry in
                            if let dateObj = parseDate(entry.date) {
                                Text(L10n.weekdaysShort[weekdayIndex(dateObj)])
                                    .font(.system(size: DT.labelSize, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Log

    private func logView(_ dd: HabitDetailData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.habitDetailLog)
                .font(.system(size: DT.labelSize, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            if isCount {
                if dd.countHistory.isEmpty {
                    Text(L10n.habitDetailNoData)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(dd.countHistory.enumerated()), id: \.offset) { idx, entry in
                            countLogRow(entry: entry)
                            if expandedLogDate == entry.date && supportsInlineNotes {
                                inlineNoteEditor
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            if idx < dd.countHistory.count - 1 {
                                Divider().padding(.leading, 12)
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: expandedLogDate)
                }
            } else {
                let data = dd.history
                if data.isEmpty {
                    Text(L10n.habitDetailNoData)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(data.enumerated()), id: \.offset) { idx, entry in
                            logRow(entry: entry)
                            if expandedLogDate == entry.date && supportsInlineNotes {
                                inlineNoteEditor
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            if idx < data.count - 1 {
                                Divider().padding(.leading, 12)
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: expandedLogDate)
                }
            }
        }
        .healthCard(padding: 16)
    }

    private func logRow(entry: (date: String, done: Bool, value: Double?)) -> some View {
        let isExpanded = expandedLogDate == entry.date
        return HStack(spacing: 10) {
            Text(formatLogDate(entry.date))
                .font(.system(size: DT.bodySize, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 70, alignment: .leading)

            if store.hasNote(habitId: habit.id, date: entry.date) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(UIColor.systemGray2))
            }

            Spacer()

            if isNumeric, let val = entry.value {
                Text(formatNumericDisplay(val, unit: unit, isSleep: habit.isSleep))
                    .font(.system(size: DT.bodySize, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(UIColor.systemGreen))
            } else if entry.done {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(UIColor.systemGreen))
            } else {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(UIColor.systemGray3))
            }

            if supportsInlineNotes {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(UIColor.systemGray3))
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            guard supportsInlineNotes else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            toggleLogRow(entry.date)
        }
    }

    private func countLogRow(entry: (date: String, value: Int, target: Int)) -> some View {
        let isOverflow = entry.value > entry.target
        let isPerfect = entry.value >= entry.target
        let isExpanded = expandedLogDate == entry.date
        return HStack(spacing: 10) {
            Text(formatLogDate(entry.date))
                .font(.system(size: DT.bodySize, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 70, alignment: .leading)

            if store.hasNote(habitId: habit.id, date: entry.date) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(UIColor.systemGray2))
            }

            Spacer()

            HStack(spacing: 4) {
                Text("\(entry.value)/\(entry.target)")
                    .font(.system(size: DT.bodySize, weight: .semibold, design: .monospaced))
                    .foregroundColor(
                        isOverflow ? Color(UIColor.systemPurple)
                        : isPerfect ? Color(UIColor.systemGreen)
                        : entry.value > 0 ? Color(UIColor.systemGreen).opacity(0.7)
                        : Color(UIColor.systemGray3)
                    )
                if isOverflow {
                    Text("🔥").font(.system(size: 11))
                }
            }

            if supportsInlineNotes {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(UIColor.systemGray3))
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            guard supportsInlineNotes else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            toggleLogRow(entry.date)
        }
    }

    // MARK: - Helpers

    private func formatLogDate(_ ds: String) -> String {
        guard let date = parseDate(ds) else { return ds }
        let day = Calendar.current.component(.day, from: date)
        let monthIdx = Calendar.current.component(.month, from: date) - 1
        if L10n.isRu {
            return "\(day) \(L10n.monthsShort[monthIdx].lowercased())"
        } else {
            return "\(L10n.monthsShort[monthIdx]) \(day)"
        }
    }

}
