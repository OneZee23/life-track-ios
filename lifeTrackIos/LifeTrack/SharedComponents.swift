import SwiftUI

// MARK: - Design Tokens

enum DT {
    // Card
    static let cardRadius: CGFloat = 16
    static let cardPadding: CGFloat = 20
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 2

    // Typography
    static let heroSize: CGFloat = 42
    static let valueSize: CGFloat = 28
    static let titleSize: CGFloat = 22
    static let bodySize: CGFloat = 15
    static let captionSize: CGFloat = 13
    static let labelSize: CGFloat = 11

    // Charts
    static let chartHeight: CGFloat = 220
    static let barRadius: CGFloat = 4
    static let barInactiveOpacity: Double = 0.35

    // Progress bars
    static let progressHeight: CGFloat = 7

    // Heatmap
    static let cellSize: CGFloat = 16
    static let cellSpacing: CGFloat = 2
    static let cellRadius: CGFloat = 3.5
    static let miniCellSize: CGFloat = 11
    static let miniCellSpacing: CGFloat = 1.5
}

// MARK: - Health Card Modifier

struct HealthCardModifier: ViewModifier {
    let padding: CGFloat
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DT.cardRadius)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08),
                        radius: DT.cardShadowRadius,
                        x: 0,
                        y: DT.cardShadowY
                    )
            )
    }
}

extension View {
    func healthCard(padding: CGFloat = DT.cardPadding) -> some View {
        modifier(HealthCardModifier(padding: padding))
    }
}

// MARK: - Health Progress Bar

struct HealthProgressBar: View {
    let rate: Double
    var height: CGFloat = DT.progressHeight
    var fillColor: Color? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: height)
                Capsule()
                    .fill(fillColor ?? rateColor)
                    .frame(width: geo.size.width * CGFloat(min(rate, 100) / 100.0), height: height)
            }
        }
        .frame(height: height)
    }

    private var rateColor: Color {
        if rate >= 75 { return Color(UIColor.systemGreen) }
        if rate >= 50 { return Color(UIColor.systemGreen).opacity(0.70) }
        if rate >= 25 { return Color(UIColor.systemGreen).opacity(0.45) }
        return Color(UIColor.systemGreen).opacity(0.25)
    }
}

// MARK: - Nav Arrow Button

struct NavArrowButton: View {
    let left: Bool
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: left ? "chevron.left" : "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(UIColor.systemGray5))
                )
        }
    }
}

// MARK: - Placeholder View

struct PlaceholderView: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 48))
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            Text(subtitle)
                .font(.system(size: DT.bodySize))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .healthCard(padding: DT.cardPadding)
    }
}

// MARK: - Streak Card View

struct StreakCardView: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: DT.labelSize, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: DT.valueSize, weight: .black, design: .rounded))
                    .foregroundColor(Color(UIColor.systemGreen))
                Text(L10n.pluralDays(value))
                    .font(.system(size: DT.captionSize))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .healthCard(padding: 16)
    }
}

// MARK: - Bar Color

func barColor(rate: Double) -> Color {
    if rate >= 75 { return Color(UIColor.systemGreen) }
    if rate >= 50 { return Color(UIColor.systemGreen).opacity(0.70) }
    if rate >= 25 { return Color(UIColor.systemGreen).opacity(0.45) }
    return Color(UIColor.systemGreen).opacity(0.25)
}
