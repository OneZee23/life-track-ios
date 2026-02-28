import SwiftUI

struct DayProgressView: View {
    @EnvironmentObject var store: AppStore

    let date: Date
    let onDayChange: (Date) -> Void

    private var dateStr: String { formatDate(date) }
    private var today: Bool { isToday(date) }

    private var visibleHabits: [Habit] {
        store.activeHabits
    }

    private var doneCount: Int {
        visibleHabits.filter {
            store.checkinValue(habitId: $0.id, date: dateStr) == 1
        }.count
    }

    private var isFutureNextDay: Bool {
        isFuture(date) && !isToday(date)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Day header with navigation
            VStack(spacing: 4) {
                HStack {
                    navArrow(left: true) {
                        let prev = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                        onDayChange(prev)
                    }
                    Spacer()
                    Text(L10n.weekdaysFull[weekdayIndex(date)])
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    navArrow(left: false) {
                        let next = Calendar.current.date(byAdding: .day, value: 1, to: date)!
                        onDayChange(next)
                    }
                    .opacity(isFutureNextDay ? 0.3 : 1.0)
                    .disabled(isFutureNextDay)
                }
                Text(verbatim: L10n.dayDateLabel(date: date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if today && doneCount < visibleHabits.count {
                    Text(L10n.awaitingCheckIn)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemOrange))
                        .padding(.top, 2)
                }
            }

            // Score circle
            scoreCircle

            // Habit list
            VStack(spacing: 6) {
                ForEach(visibleHabits) { habit in
                    habitRow(habit: habit)
                }
            }
        }
    }

    // MARK: - Score circle

    var scoreCircle: some View {
        let total = visibleHabits.count
        let status: DayStatus = {
            guard total > 0 else { return .none }
            if doneCount == 0 { return .none }
            let pct = Double(doneCount) / Double(total) * 100.0
            if pct <= 25 { return .low }
            if pct <= 50 { return .medium }
            if pct <= 75 { return .high }
            return .full
        }()

        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        status != .none
                            ? status.color.opacity(0.25)
                            : Color(UIColor.systemGray5)
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        Group {
                            if today {
                                Circle()
                                    .strokeBorder(Color(UIColor.systemOrange), lineWidth: 2)
                                    .modifier(PulseModifier())
                            }
                        }
                    )

                Text("\(doneCount)/\(total)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(
                        status != .none
                            ? Color(UIColor.systemGreen)
                            : .secondary
                    )
            }

            if total > 0 {
                Text(doneCount == total ? L10n.allDone : doneCount > 0 ? L10n.partial : L10n.notDone)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(
                        status != .none
                            ? Color(UIColor.systemGreen)
                            : .secondary
                    )
            }
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

    // MARK: - Habit row

    func habitRow(habit: Habit) -> some View {
        let done = store.checkinValue(habitId: habit.id, date: dateStr) == 1
        let hasData = store.checkins[dateStr]?[habit.id] != nil

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(done ? Color(UIColor.systemGreen).opacity(0.15) : Color(UIColor.systemGray5))
                    .frame(width: 40, height: 40)
                Text(habit.emoji)
                    .font(.system(size: 18))
            }

            Text(habit.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if hasData {
                ZStack {
                    Circle()
                        .fill(done ? Color(UIColor.systemGreen) : Color(UIColor.systemGray5))
                        .frame(width: 32, height: 32)
                    if done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("—")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("—")
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor.systemGray4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}
