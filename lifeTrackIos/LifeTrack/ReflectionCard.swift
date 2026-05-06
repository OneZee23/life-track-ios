import SwiftUI

struct ReflectionCard: View {
    let reflection: Reflection
    let onLinkTap: () -> Void
    let onDismissForWeek: () -> Void
    let onDisableType: () -> Void

    @State private var hintVisible = false

    private var rendered: ReflectionCopy.Rendered {
        ReflectionCopy.render(reflection)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            cardBody

            if hintVisible {
                Text(L10n.reflectionHintLongPress)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
                    .transition(.opacity)
            }
        }
        .onAppear { triggerHintIfNeeded() }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: rendered.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                Text(rendered.caption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text(rendered.body)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let link = rendered.link {
                Button(action: onLinkTap) {
                    Text(link)
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.systemGreen))
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .contextMenu {
            Button {
                onDismissForWeek()
            } label: {
                Label(L10n.reflectionDismissForWeek, systemImage: "eye.slash")
            }
            Button {
                onDisableType()
            } label: {
                Label(L10n.reflectionDismissForever, systemImage: "minus.circle")
            }
        }
    }

    private func triggerHintIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: ReflectionEngine.Keys.hintShown) { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            hintVisible = true
        }
        defaults.set(true, forKey: ReflectionEngine.Keys.hintShown)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                hintVisible = false
            }
        }
    }
}

#Preview("drift, 3 days") {
    let h = Habit(name: "Утренний бег", emoji: "🏃", sortOrder: 0, targetPerDay: 1)
    return ReflectionCard(
        reflection: .drift(habit: h, days: 3, suggestion: .smallerNumeric(value: 5, unit: "мин")),
        onLinkTap: {},
        onDismissForWeek: {},
        onDisableType: {}
    )
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("weekly, 5 days") {
    ReflectionCard(
        reflection: .weekly(daysFullyDone: 5, daysCounted: 7, weekKey: "2026-W18"),
        onLinkTap: {},
        onDismissForWeek: {},
        onDisableType: {}
    )
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("weekly, 0 days (sensitive)") {
    ReflectionCard(
        reflection: .weekly(daysFullyDone: 0, daysCounted: 7, weekKey: "2026-W18"),
        onLinkTap: {},
        onDismissForWeek: {},
        onDisableType: {}
    )
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
