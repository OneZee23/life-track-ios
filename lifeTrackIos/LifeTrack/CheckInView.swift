import SwiftUI

struct CheckInView: View {
    @EnvironmentObject var store: AppStore
    @State private var values: [String: Bool] = [:]
    @State private var saved = false
    @State private var showSettings = false
    @State private var showCelebration = false
    @State private var showConfetti = false

    private var dateStr: String { formatDate(yesterday()) }
    private var doneCount: Int { values.values.filter { $0 }.count }
    private var total: Int { store.activeHabits.count }

    private var habitChipColumns: Int {
        min(store.activeHabits.count, 6)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    if saved {
                        savedContent
                    } else {
                        checkInContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }

            // Fixed gear button — always pinned top-right, never moves
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
        .onAppear { initValues() }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Check-in form

    var checkInContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (gear button is in the ZStack overlay, placeholder keeps layout)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Чек-ин")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Вчера, \(yesterdayLabel())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.top, 16)
            .padding(.bottom, 20)

            // Habit cards
            VStack(spacing: 8) {
                ForEach(Array(store.activeHabits.enumerated()), id: \.element.id) { index, habit in
                    HabitToggleCard(
                        habit: habit,
                        isDone: values[habit.id] ?? false,
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

            // Done button
            Button {
                saveChekin()
            } label: {
                Text("Готово ✓")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(UIColor.systemGreen))
                    )
            }
            .buttonStyle(SpringButtonStyle())
        }
    }

    // MARK: - Saved state

    var savedContent: some View {
        VStack(spacing: 0) {
            // Placeholder matching the height of the overlay gear button row
            Color.clear.frame(height: 68)

            // Celebration
            ZStack {
                Circle()
                    .fill(Color(UIColor.systemGreen).opacity(0.15))
                    .frame(width: 80, height: 80)
                Text("🎉")
                    .font(.system(size: 40))
            }
            .scaleEffect(showCelebration ? 1 : 0.5)
            .opacity(showCelebration ? 1 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.6), value: showCelebration)
            .padding(.bottom, 16)

            Text("День записан!")
                .font(.system(size: 24, weight: .bold))
                .padding(.bottom, 6)

            Text("Возвращайся завтра")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 28)

            // Summary card
            VStack(spacing: 6) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(doneCount)")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(Color(UIColor.systemGreen))
                    Text("/\(total)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                }
                Text("привычек выполнено")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemGroupedBackground))
            )
            .padding(.bottom, 16)

            // Habit chips
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: habitChipColumns),
                spacing: 8
            ) {
                ForEach(store.activeHabits) { habit in
                    let done = values[habit.id] ?? false
                    ZStack {
                        Circle()
                            .fill(done
                                  ? Color(UIColor.systemGreen).opacity(0.15)
                                  : Color(UIColor.systemGray5))
                        Text(habit.emoji)
                            .font(.system(size: 20))
                            .opacity(done ? 1.0 : 0.35)
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 24)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    saved = false
                    showCelebration = false
                    showConfetti = false
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .medium))
                    Text("Изменить")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func initValues() {
        var newValues: [String: Bool] = [:]
        for habit in store.activeHabits {
            newValues[habit.id] = store.checkinValue(habitId: habit.id, date: dateStr) == 1
        }
        values = newValues
        if store.checkins[dateStr] != nil {
            saved = true
            showCelebration = true
        }
    }

    private func toggle(habitId: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            values[habitId] = !(values[habitId] ?? false)
        }
    }

    private func saveChekin() {
        store.saveDay(date: dateStr, values: values)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            saved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation { showCelebration = true }
            showConfetti = true
        }
    }
}

// MARK: - Flow Layout (для чипов)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 300
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
