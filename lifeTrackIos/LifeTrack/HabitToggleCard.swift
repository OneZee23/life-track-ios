import SwiftUI

struct HabitToggleCard: View {
    let habit: Habit
    let value: Int
    let streak: Int
    let hasNote: Bool
    let onToggle: () -> Void
    let onDecrement: () -> Void
    let onOpenDetail: () -> Void

    @State private var firePulse = false

    private var target: Int { habit.effectiveTarget }
    private var isCount: Bool { habit.isCountBased }
    private var isDone: Bool { value >= target }
    private var isOverflow: Bool { isCount && value > target }
    private var progress: Double {
        target > 0 ? min(1.0, Double(value) / Double(target)) : 0
    }

    private var accentColor: Color {
        if isOverflow { return Color(UIColor.systemPurple) }
        if isDone     { return Color(UIColor.systemGreen) }
        return Color(UIColor.systemGreen).opacity(0.6)
    }

    private var showsDecrementButton: Bool {
        isCount && value > 0
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onToggle()
        }) {
            HStack(spacing: 14) {
                emojiBadge
                detailsColumn
                if showsDecrementButton {
                    Color.clear.frame(width: 44, height: 44)
                }
                indicator
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardFill)
                    .shadow(color: cardShadow, radius: 1, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(SpringButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDone)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOverflow)
        .overlay(alignment: .trailing) {
            if showsDecrementButton {
                decrementButton
                    .padding(.trailing, Self.decrementOverlayTrailing)
            }
        }
    }

    /// Sits between the decrement-slot reservation in the row and the indicator
    /// circle on the right edge. Update if indicator size or row padding changes.
    private static let decrementOverlayTrailing: CGFloat = 62

    private var cardFill: Color {
        if isOverflow { return Color(UIColor.systemPurple).opacity(0.10) }
        if isDone     { return Color(UIColor.systemGreen).opacity(0.10) }
        return Color(UIColor.secondarySystemGroupedBackground)
    }

    private var cardStroke: Color {
        if isOverflow { return Color(UIColor.systemPurple).opacity(0.25) }
        if isDone     { return Color(UIColor.systemGreen).opacity(0.25) }
        return .clear
    }

    private var cardShadow: Color {
        if isOverflow { return Color(UIColor.systemPurple).opacity(0.15) }
        if isDone     { return Color(UIColor.systemGreen).opacity(0.15) }
        return Color.black.opacity(0.04)
    }

    // MARK: - Subviews

    private var emojiBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isDone || isOverflow
                      ? accentColor.opacity(0.15)
                      : Color(UIColor.systemGray5))
                .frame(width: 42, height: 42)
            Text(habit.emoji)
                .font(.system(size: 20))
        }
    }

    private var detailsColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Text(habit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                if habit.isNew {
                    Text(L10n.newBadge)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemOrange))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.systemOrange).opacity(0.12))
                        )
                }

                if habit.isHealthKitLinked {
                    Text(L10n.healthKitAutoLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemGreen))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.systemGreen).opacity(0.12))
                        )
                }

                if hasNote {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onOpenDetail()
                    } label: {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(UIColor.systemGray2))
                            .padding(.vertical, 2)
                            .padding(.horizontal, 4)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.habitDetailNotePlaceholder)
                }
            }

            if isCount {
                HStack(spacing: 6) {
                    Text("\(value)/\(target)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(isDone || isOverflow ? accentColor : .secondary)
                    if isOverflow {
                        Text("🔥")
                            .font(.system(size: 11))
                            .scaleEffect(firePulse ? 1.18 : 1.0)
                            .onAppear { firePulse = true }
                            .animation(
                                .easeInOut(duration: 0.85).repeatForever(autoreverses: true),
                                value: firePulse
                            )
                    }
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 72, height: 4)
                        Capsule()
                            .fill(accentColor)
                            .frame(width: 72 * CGFloat(progress), height: 4)
                    }
                }
            } else if streak >= 2 {
                HStack(spacing: 3) {
                    Text("🔥")
                        .font(.system(size: 11))
                    Text("\(streak) \(L10n.pluralDays(streak))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemOrange))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var indicator: some View {
        ZStack {
            Circle()
                .fill(isDone || isOverflow ? accentColor : Color.clear)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .strokeBorder(
                            isDone || isOverflow ? Color.clear : Color(UIColor.systemGray4),
                            lineWidth: 2
                        )
                )
                .scaleEffect(isDone || isOverflow ? 1.0 : 0.9)

            if isDone || isOverflow {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            } else if isCount {
                Text("\(value)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(UIColor.systemGreen))
            } else {
                Text("—")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color(UIColor.systemGray4))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: value)
    }

    private var decrementButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onDecrement()
        } label: {
            ZStack {
                Circle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 28, height: 28)
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(UIColor.systemGray))
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .transition(.scale.combined(with: .opacity))
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
