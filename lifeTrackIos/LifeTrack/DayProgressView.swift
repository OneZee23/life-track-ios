import SwiftUI

struct DayProgressView: View {
    @EnvironmentObject var store: AppStore

    let date: Date
    let filterHabitId: String?

    private var dateStr: String { formatDate(date) }
    private var today: Bool { isToday(date) }

    private var visibleHabits: [Habit] {
        filterHabitId != nil
            ? store.activeHabits.filter { $0.id == filterHabitId }
            : store.activeHabits
    }

    private var doneCount: Int {
        visibleHabits.filter {
            store.checkinValue(habitId: $0.id, date: dateStr) == 1
        }.count
    }

    var body: some View {
        VStack(spacing: 16) {
            // Day header
            VStack(spacing: 4) {
                Text(weekdaysFullRu[weekdayIndex(date)])
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Text(verbatim: "\(Calendar.current.component(.day, from: date)) \(monthsGenitiveRu[Calendar.current.component(.month, from: date) - 1]) \(String(Calendar.current.component(.year, from: date)))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if today {
                    Text("Ожидает чек-ина")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemGreen))
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
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        today
                            ? Color(UIColor.systemGray5)
                            : (doneCount == visibleHabits.count && !visibleHabits.isEmpty
                               ? Color(UIColor.systemGreen).opacity(0.15)
                               : Color(UIColor.systemGray5))
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        Group {
                            if today {
                                Circle()
                                    .strokeBorder(Color(UIColor.systemGreen), lineWidth: 2)
                                    .modifier(PulseModifier())
                            }
                        }
                    )

                if today {
                    Text("?")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                } else {
                    Text("\(doneCount)/\(visibleHabits.count)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(
                            doneCount == visibleHabits.count && !visibleHabits.isEmpty
                                ? Color(UIColor.systemGreen)
                                : .secondary
                        )
                }
            }

            if !today && !visibleHabits.isEmpty {
                Text(doneCount == visibleHabits.count ? "Все выполнено!" : doneCount > 0 ? "Частично" : "Не выполнено")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(
                        doneCount == visibleHabits.count
                            ? Color(UIColor.systemGreen)
                            : .secondary
                    )
            }
        }
    }

    // MARK: - Habit row

    func habitRow(habit: Habit) -> some View {
        let done = !today && store.checkinValue(habitId: habit.id, date: dateStr) == 1
        let hasData = !today && store.checkins[dateStr]?[habit.id] != nil

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
