import SwiftUI

struct HabitToggleCard: View {
    let habit: Habit
    let isDone: Bool
    let onToggle: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onToggle()
        }) {
            HStack(spacing: 14) {
                // Emoji container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDone
                              ? Color(UIColor.systemGreen).opacity(0.15)
                              : Color(UIColor.systemGray5))
                        .frame(width: 42, height: 42)
                    Text(habit.emoji)
                        .font(.system(size: 20))
                }

                // Name
                Text(habit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Toggle indicator
                ZStack {
                    Circle()
                        .fill(isDone ? Color(UIColor.systemGreen) : Color.clear)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isDone ? Color.clear : Color(UIColor.systemGray4),
                                    lineWidth: 2
                                )
                        )
                        .scaleEffect(isDone ? 1.0 : 0.9)

                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("—")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(Color(UIColor.systemGray4))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isDone)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDone
                          ? Color(UIColor.systemGreen).opacity(0.1)
                          : Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: isDone
                            ? Color(UIColor.systemGreen).opacity(0.15)
                            : Color.black.opacity(0.04),
                            radius: 1, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isDone
                            ? Color(UIColor.systemGreen).opacity(0.25)
                            : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(SpringButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDone)
    }
}

// MARK: - Spring press effect

struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
