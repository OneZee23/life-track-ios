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

    private var dateStr: String {
        switch selectedDay {
        case .yesterday: return formatDate(yesterday())
        case .today:     return formatDate(Date())
        }
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

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .onAppear { showConfetti = false }
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

    // MARK: - Day Selector

    private var daySelectorView: some View {
        HStack(spacing: 0) {
            dayPill(
                label: L10n.yesterdayPrefix,
                sublabel: L10n.dateLabel(for: yesterday()),
                isSelected: selectedDay == .yesterday
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDay = .yesterday
                }
            }

            dayPill(
                label: L10n.today,
                sublabel: L10n.dateLabel(for: Date()),
                isSelected: selectedDay == .today
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDay = .today
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.systemGray5))
        )
    }

    private func dayPill(
        label: String,
        sublabel: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                Text(sublabel)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(isSelected ? .primary.opacity(0.7) : .secondary)
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
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
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        // Reset confetti to allow re-trigger
        showConfetti = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            showConfetti = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.05) {
            showConfetti = false
        }
    }
}
