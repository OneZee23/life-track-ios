import SwiftUI

struct HabitDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let habit: Habit

    @State private var selectedPeriod: Period = .days30
    @State private var selectedBarIndex: Int? = nil

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

    private var isNumeric: Bool {
        habit.extendedField?.type == .numeric
    }

    private var unit: String {
        habit.extendedField?.unit ?? ""
    }

    // MARK: - Pre-computed detail data (single habitHistory call per render)

    private var detailData: HabitDetailData {
        let history = store.habitHistory(habitId: habit.id, days: selectedPeriod.rawValue)
        return HabitDetailData(history: history, isSleep: habit.isSleep, unit: unit)
    }

    private struct HabitDetailData {
        let history: [(date: String, done: Bool, value: Double?)]
        let avg: Double?
        let min: Double?
        let max: Double?
        let bestStreak: Int
        let completion: Int

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
        }
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
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(UIColor.systemGreen))
                }
            }
        }
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
                HStack(spacing: 4) {
                    Text(L10n.habitDetailStreak)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(streak)\(L10n.habitDetailDays)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.systemOrange))
                }
            }
        }
        .healthCard(padding: 16)
    }

    // MARK: - Stats

    private func statsView(_ data: HabitDetailData) -> some View {
        HStack(spacing: 8) {
            if isNumeric {
                statCard(
                    label: L10n.habitDetailAvg,
                    value: data.avg.map { formatNumericDisplay($0, unit: unit, isSleep: habit.isSleep) } ?? "—"
                )
                statCard(
                    label: L10n.habitDetailMin,
                    value: data.min.map { formatNumericDisplay($0, unit: unit, isSleep: habit.isSleep) } ?? "—"
                )
                statCard(
                    label: L10n.habitDetailMax,
                    value: data.max.map { formatNumericDisplay($0, unit: unit, isSleep: habit.isSleep) } ?? "—"
                )
            } else {
                let streak = store.habitStreak(habitId: habit.id, asOf: Date())
                statCard(
                    label: L10n.habitDetailStreak,
                    value: "\(streak)\(L10n.habitDetailDays)"
                )
                statCard(
                    label: L10n.habitDetailBestStreak,
                    value: "\(data.bestStreak)\(L10n.habitDetailDays)"
                )
                statCard(
                    label: L10n.habitDetailCompletion,
                    value: "\(data.completion)%"
                )
            }
        }
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(Color(UIColor.systemGreen))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .healthCard(padding: 14)
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

    // MARK: - Chart

    private func chartView(_ dd: HabitDetailData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if isNumeric {
                numericBarChart(dd)
            } else {
                binaryDotsChart(dd)
            }
        }
        .healthCard(padding: 16)
    }

    // MARK: - Numeric Bar Chart

    private func numericBarChart(_ dd: HabitDetailData) -> some View {
        let data = Array(dd.history.reversed()) // oldest first
        let values = data.compactMap(\.value)
        let maxVal = values.max() ?? 1.0
        let avgVal = dd.avg ?? 0
        let chartHeight: CGFloat = DT.chartHeight

        return VStack(spacing: 6) {
            // Selected bar tooltip
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
                // Average label (like Apple's "Average Calories" line)
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
                // Chart + average line
                ZStack(alignment: .bottom) {
                    // Average line
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

                    // Bars — each day is one bar
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

                // Time axis labels
                timeAxisLabels(data: data)
            }
        }
        .onChange(of: selectedPeriod) { _ in selectedBarIndex = nil }
    }

    /// Generates time axis labels like Apple Health — adaptive to period.
    private func timeAxisLabels(data: [(date: String, done: Bool, value: Double?)]) -> some View {
        let cal = Calendar.current
        let count = data.count

        // Determine which indices get a label
        var labelMap: [Int: String] = [:]

        for (idx, entry) in data.enumerated() {
            guard let dateObj = parseDate(entry.date) else { continue }
            let day = cal.component(.day, from: dateObj)
            let month = cal.component(.month, from: dateObj) - 1
            let weekday = weekdayIndex(dateObj)

            switch selectedPeriod {
            case .days7:
                // Every day: M T W T F S S
                labelMap[idx] = L10n.weekdaysShort[weekday]
            case .days30:
                // Every Monday + first/last day
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

    // MARK: - Binary Dots Chart

    private func binaryDotsChart(_ dd: HabitDetailData) -> some View {
        let data = Array(dd.history.reversed())

        let dotSize: CGFloat = selectedPeriod == .days7 ? 32 : (selectedPeriod == .days30 ? 18 : 12)
        let spacing: CGFloat = selectedPeriod == .days7 ? 6 : (selectedPeriod == .days30 ? 4 : 2)

        return VStack(spacing: 8) {
            // Show tracking period hint when data is sparse relative to selected period
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

                // Day labels for 7d
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

                        if idx < data.count - 1 {
                            Divider()
                                .padding(.leading, 12)
                        }
                    }
                }
            }
        }
        .healthCard(padding: 16)
    }

    private func logRow(entry: (date: String, done: Bool, value: Double?)) -> some View {
        HStack(spacing: 10) {
            Text(formatLogDate(entry.date))
                .font(.system(size: DT.bodySize, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 70, alignment: .leading)

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
        }
        .padding(.vertical, 10)
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
