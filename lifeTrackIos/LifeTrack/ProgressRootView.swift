import SwiftUI

enum ProgressLevel {
    case year, month, week, day, analytics, monthAnalytics
}

enum NavSource {
    case normal
    case yearAnalytics
    case monthAnalytics
}

struct ProgressRootView: View {
    @EnvironmentObject var store: AppStore
    let resetID: UUID

    // Navigation state
    @State private var level: ProgressLevel = .month
    @State private var topLevel: ProgressLevel = .month  // year или month (переключатель)
    @State private var navSource: NavSource = .normal

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

                    Group {
                        switch level {
                        case .year:
                            YearProgressView(
                                year: navYear,
                                onYearChange: { navYear = $0 },
                                onDayTap: { date in
                                    let cal = Calendar.current
                                    navMonth = cal.component(.month, from: date) - 1
                                    navYear = cal.component(.year, from: date)
                                    navWeekStart = weekStart(for: date)
                                    navDay = date
                                    withAnimation { level = .week }
                                },
                                onAnalyticsTap: {
                                    withAnimation { level = .analytics }
                                }
                            )
                        case .month:
                            MonthProgressView(
                                year: navYear,
                                month: navMonth,
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
                                },
                                onAnalyticsTap: {
                                    withAnimation { level = .monthAnalytics }
                                }
                            )
                        case .week:
                            WeekProgressView(
                                weekStartDate: navWeekStart,
                                onWeekChange: { navWeekStart = $0 },
                                onDayTap: { date in
                                    navDay = date
                                    withAnimation { level = .day }
                                }
                            )
                        case .day:
                            DayProgressView(
                                date: navDay,
                                onDayChange: { date in
                                    navDay = date
                                }
                            )
                        case .analytics:
                            YearAnalyticsView(
                                year: navYear,
                                onYearChange: { navYear = $0 },
                                onMonthTap: { month in
                                    navMonth = month
                                    navSource = .yearAnalytics
                                    withAnimation { level = .month }
                                }
                            )
                        case .monthAnalytics:
                            MonthAnalyticsView(
                                year: navYear,
                                month: navMonth,
                                onMonthChange: { newMonth in
                                    var m = newMonth
                                    var y = navYear
                                    if m < 0 { m = 11; y -= 1 }
                                    else if m > 11 { m = 0; y += 1 }
                                    navMonth = m; navYear = y
                                },
                                onWeekTap: { weekDate in
                                    navWeekStart = weekDate
                                    navSource = .monthAnalytics
                                    withAnimation { level = .week }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: resetID) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                level = .month
                topLevel = .month
                navSource = .normal
                navYear = Calendar.current.component(.year, from: Date())
                navMonth = Calendar.current.component(.month, from: Date()) - 1
            }
        }
    }

    // MARK: - Header

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if (level == .year || level == .month) && navSource == .normal {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.progress)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)

                    // Segment control
                    HStack(spacing: 0) {
                        segButton(title: L10n.month, selected: topLevel == .month) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                topLevel = .month; level = .month; navSource = .normal
                            }
                        }
                        segButton(title: L10n.year, selected: topLevel == .year) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                topLevel = .year; level = .year; navSource = .normal
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
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            switch (level, navSource) {
                            // Year analytics path
                            case (.analytics, _):
                                level = .year; navSource = .normal
                            case (.month, .yearAnalytics):
                                level = .analytics
                            case (.week, .yearAnalytics):
                                level = .month
                            case (.day, .yearAnalytics):
                                level = .week

                            // Month analytics path
                            case (.monthAnalytics, _):
                                level = .month; navSource = .normal
                            case (.week, .monthAnalytics):
                                level = .monthAnalytics
                            case (.day, .monthAnalytics):
                                level = .week

                            // Normal path
                            case (.week, .normal):
                                level = topLevel
                            case (.day, .normal):
                                level = .week
                            default:
                                break
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text(backLabel)
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

    private var backLabel: String {
        switch (level, navSource) {
        case (.analytics, _):
            return String(navYear)
        case (.monthAnalytics, _):
            return L10n.monthsFull[navMonth]
        case (.month, .yearAnalytics):
            return L10n.detailedAnalytics
        case (.week, .yearAnalytics):
            return L10n.monthsFull[navMonth]
        case (.week, .monthAnalytics):
            return L10n.detailedAnalytics
        case (.week, .normal):
            return topLevel == .year ? String(navYear) : L10n.monthsFull[navMonth]
        case (.day, _):
            return L10n.week
        default:
            return ""
        }
    }

    // MARK: - Reusable buttons

    @ViewBuilder
    func segButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
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

}
