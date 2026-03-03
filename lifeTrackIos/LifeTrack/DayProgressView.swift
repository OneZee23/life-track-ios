import SwiftUI

struct DayProgressView: View {
    @EnvironmentObject var store: AppStore

    let date: Date
    let onDayChange: (Date) -> Void

    private var dateStr: String { formatDate(date) }
    private var today: Bool { isToday(date) }

    private var visibleHabits: [Habit] {
        store.habitsExisted(from: date, to: date)
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
                    NavArrowButton(left: true) {
                        let prev = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                        onDayChange(prev)
                    }
                    Spacer()
                    Text(L10n.weekdaysFull[weekdayIndex(date)])
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    NavArrowButton(left: false) {
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

    // MARK: - Habit row

    func habitRow(habit: Habit) -> some View {
        let done = store.checkinValue(habitId: habit.id, date: dateStr) == 1
        let hasData = store.checkins[dateStr]?[habit.id] != nil
        let extra = store.getExtra(habitId: habit.id, date: dateStr)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
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

            // Extended data display
            if let extra = extra {
                extraLabel(extra: extra, config: habit.extendedField)
                    .padding(.leading, 52)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    private func formatNumeric(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    private func extraLabel(extra: CheckinExtra, config: ExtendedFieldConfig?) -> some View {
        Group {
            if let numVal = extra.numericValue {
                HStack(spacing: 4) {
                    Image(systemName: "number")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(formatNumeric(numVal)) \(config?.unit ?? "")")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color(UIColor.systemGreen))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(UIColor.systemGreen).opacity(0.12))
                )
            } else if let rating = extra.ratingValue {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text("\(rating)/10")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.12))
                )
            } else if let text = extra.textValue, !text.isEmpty {
                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(.primary.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.systemGray6))
                    )
            }
        }
    }
}
