import SwiftUI

struct DailyGreetingView: View {
    @EnvironmentObject var store: AppStore

    let onDismiss: () -> Void

    private var streak: Int { store.currentStreak() }
    private var habitCount: Int { store.activeHabits.count }
    private var coach: String? { store.coachMessage() }
    private var coachEmoji: String { store.coachEmoji() }
    private var missedHabit: Habit? { store.longestMissedHabit() }

    private var yesterdayText: String {
        if let stats = store.yesterdayStats() {
            return L10n.greetingYesterdayResult(stats.done, stats.total)
        }
        return L10n.greetingNoYesterday
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        onDismiss()
                    }
                }

            VStack(spacing: 16) {
                Text(coach != nil ? coachEmoji : L10n.greetingEmoji())
                    .font(.system(size: 56))

                Text(L10n.greeting())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if let message = coach {
                    Text(message)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(Color(UIColor.systemOrange))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                    if let habit = missedHabit {
                        Text("\(habit.emoji) \(L10n.coachHabitNudge(habit.name))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(UIColor.systemOrange).opacity(0.8))
                            .padding(.top, 2)
                    }
                } else if streak >= 2 {
                    Text("\u{1F525} \(streak) \(L10n.pluralDays(streak)) \(L10n.inARow)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.systemOrange))
                        .padding(.top, 4)
                }

                VStack(spacing: 8) {
                    Text(L10n.greetingHabitsWaiting(habitCount))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)

                    Text(yesterdayText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                Text(L10n.greetingTapToDismiss)
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor.systemGray3))
                    .padding(.top, 16)
            }
            .multilineTextAlignment(.center)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
        .transition(.opacity)
    }
}
