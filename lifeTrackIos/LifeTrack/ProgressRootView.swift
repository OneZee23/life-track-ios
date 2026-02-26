import SwiftUI

enum ProgressLevel {
    case year, month, week, day
}

struct ProgressRootView: View {
    @EnvironmentObject var store: AppStore

    // Navigation state
    @State private var level: ProgressLevel = .month
    @State private var topLevel: ProgressLevel = .month  // year или month (переключатель)
    @State private var filterHabitId: String? = nil

    // Navigation targets
    @State private var navYear: Int = Calendar.current.component(.year, from: Date())
    @State private var navMonth: Int = Calendar.current.component(.month, from: Date()) - 1
    @State private var navWeekStart: Date = weekStart(for: Date())
    @State private var navDay: Date = Date()

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    filterChips
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    Group {
                        switch level {
                        case .year:
                            YearProgressView(
                                year: navYear,
                                filterHabitId: filterHabitId,
                                onYearChange: { navYear = $0 },
                                onMonthTap: { m in
                                    navMonth = m
                                    withAnimation { level = .month; topLevel = .month }
                                }
                            )
                        case .month:
                            MonthProgressView(
                                year: navYear,
                                month: navMonth,
                                filterHabitId: filterHabitId,
                                onMonthChange: { newMonth in
                                    var m = newMonth
                                    var y = navYear
                                    if m < 0 { m = 11; y -= 1 }
                                    else if m > 11 { m = 0; y += 1 }
                                    navMonth = m; navYear = y
                                },
                                onDayTap: { date in
                                    navWeekStart = weekStart(for: date)
                                    navDay = date
                                    withAnimation { level = .week }
                                }
                            )
                        case .week:
                            WeekProgressView(
                                weekStartDate: navWeekStart,
                                filterHabitId: filterHabitId,
                                onWeekChange: { navWeekStart = $0 },
                                onDayTap: { date in
                                    navDay = date
                                    withAnimation { level = .day }
                                }
                            )
                        case .day:
                            DayProgressView(
                                date: navDay,
                                filterHabitId: filterHabitId
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Header

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if level == .year || level == .month {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Прогресс")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)

                    // Segment control: Месяц / Год
                    HStack(spacing: 0) {
                        segButton(title: "Месяц", selected: topLevel == .month) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                topLevel = .month; level = .month
                            }
                        }
                        segButton(title: "Год", selected: topLevel == .year) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                topLevel = .year; level = .year
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.systemGray5))
                    )
                    .frame(height: 36)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 14)
            } else {
                // Back button
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if level == .week { level = .month }
                            else if level == .day { level = .week }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text(level == .week
                                 ? monthsFullRu[navMonth]
                                 : "Неделя")
                            .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color(UIColor.systemBlue))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)
            }
        }
    }

    // MARK: - Filter chips

    var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chipButton(label: "Все", active: filterHabitId == nil) {
                    withAnimation { filterHabitId = nil }
                }
                ForEach(store.activeHabits) { habit in
                    chipButton(
                        label: "\(habit.emoji) \(habit.name)",
                        active: filterHabitId == habit.id
                    ) {
                        withAnimation {
                            filterHabitId = filterHabitId == habit.id ? nil : habit.id
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Reusable buttons

    @ViewBuilder
    func segButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: selected ? .semibold : .medium))
                .foregroundColor(selected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    Group {
                        if selected {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
                        }
                    }
                )
                .padding(2)
        }
    }

    @ViewBuilder
    func chipButton(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(active ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(active ? Color(UIColor.systemGreen) : Color(UIColor.systemGray5))
                )
        }
    }
}
