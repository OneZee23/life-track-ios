import SwiftUI

private enum SelectedDay: Equatable {
    case yesterday
    case today
}

struct CheckInView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedDay: SelectedDay = .yesterday
    @State private var showSettings = false
    @State private var showConfetti = false
    @State private var showCelebration = false
    @State private var celebrationStreak = 0
    @State private var celebrationMessage = ""
    @State private var hideWork: DispatchWorkItem?
    @State private var confettiWork: DispatchWorkItem?

    private var viewedDate: Date {
        selectedDay == .yesterday ? yesterday() : Date()
    }

    private var dateStr: String {
        formatDate(viewedDate)
    }

    private var doneCount: Int {
        store.activeHabits.filter {
            store.checkinValue(habitId: $0.id, date: dateStr) == 1
        }.count
    }

    private var total: Int { store.activeHabits.count }

    private func isDone(_ habitId: String) -> Bool {
        store.checkinValue(habitId: habitId, date: dateStr) == 1
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    checkInContent
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }

            // Fixed gear button — always pinned top-right
            HStack {
                Spacer()
                Button { showSettings = true } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 36, height: 36)
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)

            // Celebration overlay — blocks all touches behind it
            if showCelebration {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .contentShape(Rectangle())

                VStack(spacing: 10) {
                    Text(celebrationMessage)
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .shadow(color: .green.opacity(0.3), radius: 24, x: 0, y: 6)
                    if celebrationStreak >= 2 {
                        Text("🔥 \(celebrationStreak) \(L10n.pluralDays(celebrationStreak)) \(L10n.inARow)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(UIColor.systemOrange))
                    }
                }
                .multilineTextAlignment(.center)
                .transition(.scale(scale: 0.5).combined(with: .opacity))
                .allowsHitTesting(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Confetti on top of everything
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            showConfetti = false
            showCelebration = false
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Check-in form

    var checkInContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.checkIn)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Day selector
            daySelectorView
                .padding(.bottom, 20)

            // Habit cards
            VStack(spacing: 8) {
                ForEach(Array(store.activeHabits.enumerated()), id: \.element.id) { index, habit in
                    HabitToggleCard(
                        habit: habit,
                        isDone: isDone(habit.id),
                        streak: habitStreak(for: habit),
                        onToggle: { toggle(habitId: habit.id) }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }

            // Progress bar
            HStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 4)
                        Capsule()
                            .fill(Color(UIColor.systemGreen))
                            .frame(
                                width: total > 0
                                    ? geo.size.width * CGFloat(doneCount) / CGFloat(total)
                                    : 0,
                                height: 4
                            )
                            .animation(.easeInOut(duration: 0.4), value: doneCount)
                    }
                }
                .frame(height: 4)

                Text("\(doneCount)/\(total)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(doneCount == total && total > 0
                                     ? Color(UIColor.systemGreen)
                                     : .secondary)
                    .frame(minWidth: 32, alignment: .trailing)
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Day Selector (sliding)

    @Namespace private var daySelector

    private var daySelectorView: some View {
        HStack(spacing: 0) {
            dayTab(
                emoji: "🌙",
                label: L10n.yesterdayPrefix,
                sublabel: L10n.dateLabel(for: yesterday()),
                isSelected: selectedDay == .yesterday
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedDay = .yesterday
                }
            }

            dayTab(
                emoji: "☀️",
                label: L10n.today,
                sublabel: L10n.dateLabel(for: Date()),
                isSelected: selectedDay == .today
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedDay = .today
                }
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color(UIColor.systemGray5).opacity(0.8))
        )
    }

    private func dayTab(
        emoji: String,
        label: String,
        sublabel: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(emoji)
                    .font(.system(size: 14))
                    .opacity(isSelected ? 1 : 0.5)
                Text("\(label), \(sublabel)")
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 1)
                            .matchedGeometryEffect(id: "daySlider", in: daySelector)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Streak

    private func habitStreak(for habit: Habit) -> Int {
        let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: viewedDate)!
        let baseStreak = store.habitStreak(habitId: habit.id, asOf: dayBefore)
        return isDone(habit.id) ? baseStreak + 1 : baseStreak
    }

    // MARK: - Actions

    private func toggle(habitId: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            store.toggleCheckin(habitId: habitId, date: dateStr)
        }

        // Check if all habits are now done — trigger celebration
        let newDoneCount = store.activeHabits.filter {
            store.checkinValue(habitId: $0.id, date: dateStr) == 1
        }.count

        if newDoneCount == total && total > 0 {
            triggerCelebration()
        }
    }

    private func triggerCelebration() {
        // Cancel any pending hide timers from previous celebration
        hideWork?.cancel()
        confettiWork?.cancel()

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Calculate streak: currentStreak() counts from yesterday backwards.
        // Add +1 for today if today is fully done.
        let baseStreak = store.currentStreak()
        let todayStr = formatDate(Date())
        let todayAllDone = store.activeHabits.allSatisfy {
            store.checkinValue(habitId: $0.id, date: todayStr) == 1
        }
        celebrationStreak = todayAllDone ? baseStreak + 1 : baseStreak
        celebrationMessage = L10n.randomCongrats()

        // Fresh start
        showConfetti = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            showCelebration = true
        }

        // Schedule smooth fade out
        let hide = DispatchWorkItem { [self] in
            withAnimation(.easeInOut(duration: 1.2)) {
                showCelebration = false
            }
        }
        hideWork = hide
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: hide)

        // Schedule confetti cleanup
        let confetti = DispatchWorkItem { [self] in
            showConfetti = false
        }
        confettiWork = confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: confetti)
    }
}
