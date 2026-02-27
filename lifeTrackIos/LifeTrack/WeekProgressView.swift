import SwiftUI

struct WeekProgressView: View {
    @EnvironmentObject var store: AppStore

    let weekStartDate: Date
    let filterHabitId: String?
    let onWeekChange: (Date) -> Void
    let onDayTap: (Date) -> Void

    private var days: [Date] {
        (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: weekStartDate)
        }
    }

    private var weekTitle: String {
        guard let first = days.first, let last = days.last else { return "" }
        let d1 = Calendar.current.component(.day, from: first)
        let d2 = Calendar.current.component(.day, from: last)
        let m1 = Calendar.current.component(.month, from: first) - 1
        let m2 = Calendar.current.component(.month, from: last) - 1
        if m1 == m2 {
            return "\(d1)–\(d2) \(L10n.monthsFull[m1])"
        } else {
            return "\(d1) \(L10n.monthsShort[m1]) – \(d2) \(L10n.monthsShort[m2])"
        }
    }

    private var weekYear: String {
        "\(Calendar.current.component(.year, from: weekStartDate))"
    }

    var body: some View {
        VStack(spacing: 12) {
            // Nav header
            HStack {
                navArrow(left: true) {
                    let prev = Calendar.current.date(byAdding: .day, value: -7, to: weekStartDate)!
                    onWeekChange(prev)
                }
                Spacer()
                VStack(spacing: 1) {
                    Text(weekTitle)
                        .font(.system(size: 17, weight: .bold))
                    Text(weekYear)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                navArrow(left: false) {
                    let next = Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate)!
                    onWeekChange(next)
                }
            }

            // Day chips
            dayStrip

            // Per-habit bars
            habitBars

            // Week total
            weekTotal
        }
    }

    // MARK: - Day strip

    var dayStrip: some View {
        HStack(spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                let today = isToday(day)
                let ds = formatDate(day)
                let isDone: Bool = {
                    guard !isFuture(day) || today else { return false }
                    if let s = store.dayStatus(date: ds, habitId: filterHabitId) {
                        return s != .none
                    }
                    return false
                }()

                Button { onDayTap(day) } label: {
                    VStack(spacing: 4) {
                        Text(L10n.weekdaysShort[i])
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(today ? Color(UIColor.systemGreen) : .secondary)

                        ZStack {
                            if today {
                                Circle()
                                    .strokeBorder(Color(UIColor.systemGreen), lineWidth: 2)
                                    .modifier(PulseModifier())
                                Text("\(Calendar.current.component(.day, from: day))")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(UIColor.systemGreen))
                            } else if isDone {
                                Circle()
                                    .fill(Color(UIColor.systemGreen).opacity(0.15))
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(UIColor.systemGreen))
                            } else {
                                Circle()
                                    .fill(Color(UIColor.systemGray5))
                                Text("\(Calendar.current.component(.day, from: day))")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 28, height: 28)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        today ? Color(UIColor.systemGreen) : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    )
                }
                .buttonStyle(SpringButtonStyle())
            }
        }
    }

    // MARK: - Habit bars

    var habitBars: some View {
        let visibleHabits = filterHabitId != nil
            ? store.activeHabits.filter { $0.id == filterHabitId }
            : store.activeHabits

        return VStack(spacing: 8) {
            ForEach(visibleHabits) { habit in
                habitBar(habit: habit)
            }
        }
    }

    func habitBar(habit: Habit) -> some View {
        let dayValues: [Bool?] = days.map { day in
            if isFuture(day) && !isToday(day) { return nil }
            let ds = formatDate(day)
            return store.checkinValue(habitId: habit.id, date: ds) == 1
        }
        let done = dayValues.compactMap { $0 }.filter { $0 }.count
        let total = dayValues.compactMap { $0 }.count

        return VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Text(habit.emoji)
                        .font(.system(size: 18))
                    Text(habit.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                Spacer()
                Text("\(done)/\(total)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(done == total && total > 0
                                     ? Color(UIColor.systemGreen)
                                     : .secondary)
            }

            // Weekly bar
            HStack(spacing: 3) {
                ForEach(Array(dayValues.enumerated()), id: \.offset) { i, val in
                    let today = isToday(days[i])
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            today ? Color.clear
                            : (val == true ? Color(UIColor.systemGreen) : Color(UIColor.systemGray5))
                        )
                        .frame(height: 6)
                        .overlay(
                            Group {
                                if today {
                                    RoundedRectangle(cornerRadius: 3)
                                        .strokeBorder(Color(UIColor.systemGreen), lineWidth: 1.5)
                                }
                            }
                        )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Week total

    var weekTotal: some View {
        let doneDays = days.filter { day in
            if isFuture(day) || isToday(day) { return false }
            let ds = formatDate(day)
            if let s = store.dayStatus(date: ds, habitId: filterHabitId) {
                return s != .none
            }
            return false
        }.count
        let totalDays = days.filter { !isFuture($0) && !isToday($0) }.count

        return HStack {
            Text(L10n.weekTotal)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            Spacer()
            HStack(alignment: .bottom, spacing: 2) {
                Text("\(doneDays)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Color(UIColor.systemGreen))
                Text("/\(totalDays)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
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
}
