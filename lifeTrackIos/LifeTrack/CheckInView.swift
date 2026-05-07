import SwiftUI

private enum SelectedDay: Equatable {
    case yesterday
    case today
}

struct CheckInView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedDay: SelectedDay = .yesterday
    @State private var hasSetInitialDay = false
    @State private var showSettings = false
    @State private var showConfetti = false
    @State private var showCelebration = false
    @State private var celebrationStreak = 0
    @State private var celebrationMessage = ""
    @State private var hideTask: Task<Void, Never>?
    @State private var confettiTask: Task<Void, Never>?
    @State private var selectedHabitForDetail: Habit? = nil

    private var dateStr: String {
        let date = selectedDay == .yesterday ? yesterday() : Date()
        return formatDate(date)
    }

    private var total: Int { store.activeHabits.count }

    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    Text(L10n.checkIn)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
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
                .padding(.bottom, 12)

                // Day selector
                daySelectorView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                // Swipeable habit pages
                TabView(selection: $selectedDay) {
                    habitPage(for: .yesterday).tag(SelectedDay.yesterday)
                    habitPage(for: .today).tag(SelectedDay.today)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: selectedDay)
            }

            // Celebration overlay — blocks all touches behind it
            if showCelebration {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .contentShape(Rectangle())
                    .onTapGesture { dismissCelebration() }

                VStack(spacing: 10) {
                    Text(celebrationMessage)
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .shadow(color: .green.opacity(0.3), radius: 24, x: 0, y: 6)
                    if celebrationStreak >= 2 {
                        Text("🔥 \(celebrationStreak) \(L10n.pluralDays(celebrationStreak)) \(L10n.inARow)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(UIColor.systemOrange))
                    }
                    Text(L10n.celebrationDismissHint)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 18)
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
            if !hasSetInitialDay {
                hasSetInitialDay = true
                if store.yesterdayStats() != nil {
                    selectedDay = .today
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(item: $selectedHabitForDetail) { habit in
            let date = selectedDay == .yesterday ? yesterday() : Date()
            HabitDetailView(habit: habit, noteDate: date)
                .environmentObject(store)
        }
    }

    // MARK: - Habit Page (swipeable)

    private func habitPage(for day: SelectedDay) -> some View {
        let date = day == .yesterday ? yesterday() : Date()
        let ds = formatDate(date)
        let habits = store.activeHabits
        let habitValues: [String: Int] = Dictionary(uniqueKeysWithValues:
            habits.map { ($0.id, store.checkinValue(habitId: $0.id, date: ds)) }
        )
        let done = habits.filter { (habitValues[$0.id] ?? 0) >= $0.effectiveTarget }.count
        let tot = habits.count

        return ScrollView {
            VStack(spacing: 0) {
                // Habit cards
                VStack(spacing: 8) {
                    ForEach(habits) { habit in
                        let currentValue = habitValues[habit.id] ?? 0
                        let habitDone = currentValue >= habit.effectiveTarget
                        VStack(spacing: 2) {
                            HabitToggleCard(
                                habit: habit,
                                value: currentValue,
                                streak: streakForHabit(habit, date: date, isDone: habitDone),
                                totalDays: store.habitTotalDaysCompleted(habitId: habit.id),
                                hasNote: store.hasNote(habitId: habit.id, date: ds),
                                onToggle: { toggle(habitId: habit.id) },
                                onDecrement: { decrement(habitId: habit.id) },
                                onOpenDetail: { selectedHabitForDetail = habit }
                            )

                            if habit.extendedField != nil {
                                ExtendedCheckinPanel(
                                    config: habit.extendedField!,
                                    value: store.getExtra(habitId: habit.id, date: ds),
                                    onChange: { extra in
                                        store.setExtra(habitId: habit.id, date: ds, extra: extra)
                                    },
                                    healthKitMetricType: habit.healthKitMetricType
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .onLongPressGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            selectedHabitForDetail = habit
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: habitDone)
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
                                    width: tot > 0
                                        ? geo.size.width * CGFloat(done) / CGFloat(tot)
                                        : 0,
                                    height: 4
                                )
                                .animation(.easeInOut(duration: 0.4), value: done)
                        }
                    }
                    .frame(height: 4)

                    Text("\(done)/\(tot)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(done == tot && tot > 0
                                         ? Color(UIColor.systemGreen)
                                         : .secondary)
                        .frame(minWidth: 32, alignment: .trailing)
                }
                .padding(.vertical, 16)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .refreshable {
            await store.syncHealthKitWorkouts()
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

    private func streakForHabit(_ habit: Habit, date: Date, isDone: Bool) -> Int {
        guard let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: date) else { return 0 }
        let baseStreak = store.habitStreak(habitId: habit.id, asOf: dayBefore)
        return isDone ? baseStreak + 1 : baseStreak
    }

    // MARK: - Actions

    private func toggle(habitId: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            store.toggleCheckin(habitId: habitId, date: dateStr)
        }

        // Check if all habits are now done — trigger celebration
        let newDoneCount = store.activeHabits.filter {
            store.checkinValue(habitId: $0.id, date: dateStr) >= $0.effectiveTarget
        }.count

        if newDoneCount == total && total > 0 {
            triggerCelebration()
        }
    }

    private func decrement(habitId: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            store.decrementCheckin(habitId: habitId, date: dateStr)
        }
    }

    private func dismissCelebration() {
        hideTask?.cancel()
        confettiTask?.cancel()
        withAnimation(.easeInOut(duration: 0.3)) {
            showCelebration = false
        }
        showConfetti = false
    }

    private func triggerCelebration() {
        hideTask?.cancel()
        confettiTask?.cancel()

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Calculate streak: currentStreak() counts from yesterday backwards.
        // Add +1 for today if today is fully done.
        let baseStreak = store.currentStreak()
        let todayStr = formatDate(Date())
        let todayAllDone = store.activeHabits.allSatisfy {
            store.checkinValue(habitId: $0.id, date: todayStr) >= $0.effectiveTarget
        }
        celebrationStreak = todayAllDone ? baseStreak + 1 : baseStreak
        celebrationMessage = L10n.randomCongrats()

        showConfetti = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            showCelebration = true
        }

        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 1.2)) {
                showCelebration = false
            }
        }

        confettiTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            showConfetti = false
        }
    }
}

// MARK: - Extended Check-in Panel

private struct ExtendedCheckinPanel: View {
    let config: ExtendedFieldConfig
    let value: CheckinExtra?
    let onChange: (CheckinExtra) -> Void
    var healthKitMetricType: String? = nil

    @State private var isEditingValue = false
    @State private var editValueText = ""
    @FocusState private var editValueFocused: Bool
    @State private var localText: String = ""

    var body: some View {
        Group {
            switch config.type {
            case .numeric:
                numericPanel
            case .text:
                textPanel
            case .rating:
                ratingPanel
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Helpers

    private var isSleepMetric: Bool { healthKitMetricType == HealthKitMetricType.sleep.rawValue }

    // MARK: - Numeric

    private var numericPanel: some View {
        let minVal = config.minValue ?? 0
        let maxVal = config.maxValue ?? AppConstants.numericUnboundedMax
        let step = config.step ?? 1
        let current = value?.numericValue ?? minVal
        let unit = config.unit ?? ""
        let style: NumericInputStyle = config.maxValue == nil ? .stepper : (config.inputStyle ?? .slider)

        return Group {
            if style == .slider {
                numericSlider(current: current, min: minVal, max: maxVal, step: step, unit: unit)
            } else {
                numericStepper(current: current, min: minVal, max: maxVal, step: step, unit: unit)
            }
        }
    }

    private func numericSlider(current: Double, min: Double, max: Double, step: Double, unit: String) -> some View {
        HStack(spacing: 10) {
            Slider(
                value: Binding(
                    get: { current },
                    set: { newVal in
                        var extra = value ?? CheckinExtra()
                        extra.numericValue = newVal
                        onChange(extra)
                    }
                ),
                in: min...max,
                step: step
            )
            .tint(Color(UIColor.systemGreen))

            Text(formatNumericDisplay(current, unit: unit, isSleep: isSleepMetric))
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .foregroundColor(.primary)
            .frame(minWidth: 50, alignment: .trailing)
        }
    }

    private func numericStepper(current: Double, min: Double, max: Double, step: Double, unit: String) -> some View {
        HStack(spacing: 12) {
            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                let newVal = Swift.max(min, current - step)
                var extra = value ?? CheckinExtra()
                extra.numericValue = newVal
                onChange(extra)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(current <= min ? Color(UIColor.systemGray4) : Color(UIColor.systemGreen))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(UIColor.systemGray5)))
            }
            .disabled(current <= min)

            // Value — tap to type manually
            Group {
                if isEditingValue {
                    HStack(spacing: 4) {
                        TextField("", text: $editValueText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .focused($editValueFocused)
                            .onAppear { editValueFocused = true }
                            .onChange(of: editValueFocused) { focused in
                                if !focused { commitEdit(min: min, max: max) }
                            }

                        Button {
                            editValueFocused = false
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(UIColor.systemGreen))
                        }
                    }
                } else {
                    Text(formatNumericDisplay(current, unit: unit, isSleep: isSleepMetric))
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editValueText = formatValue(current)
                        isEditingValue = true
                    }
                }
            }
            .frame(width: 110)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                let newVal = Swift.min(max, current + step)
                var extra = value ?? CheckinExtra()
                extra.numericValue = newVal
                onChange(extra)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(current >= max ? Color(UIColor.systemGray4) : Color(UIColor.systemGreen))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(UIColor.systemGray5)))
            }
            .disabled(current >= max)

            Spacer()
        }
    }

    private func commitEdit(min: Double, max: Double) {
        isEditingValue = false
        guard let val = Double(editValueText) else { return }
        let clamped = Swift.min(Swift.max(min, val), max)
        let rounded = (clamped * 100).rounded() / 100
        var extra = value ?? CheckinExtra()
        extra.numericValue = rounded
        onChange(extra)
    }

    // MARK: - Rating

    private var ratingPanel: some View {
        let currentRating = value?.ratingValue

        return VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0...5, id: \.self) { rating in
                    ratingCircle(rating: rating, currentRating: currentRating)
                }
            }
            HStack(spacing: 4) {
                ForEach(6...10, id: \.self) { rating in
                    ratingCircle(rating: rating, currentRating: currentRating)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func ratingCircle(rating: Int, currentRating: Int?) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            var extra = value ?? CheckinExtra()
            extra.ratingValue = currentRating == rating ? nil : rating
            onChange(extra)
        } label: {
            Text("\(rating)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(currentRating == rating ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(currentRating == rating
                              ? Color(UIColor.systemGreen)
                              : Color(UIColor.systemGray5))
                )
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: currentRating)
    }

    // MARK: - Text

    private var textPanel: some View {
        HStack(spacing: 8) {
            TextField(L10n.extendedNotePlaceholder, text: $localText)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .onAppear {
                    localText = value?.textValue ?? ""
                }
                .onChange(of: localText) { newValue in
                    if newValue.count > AppConstants.textCharLimit {
                        localText = String(newValue.prefix(AppConstants.textCharLimit))
                        return
                    }
                    var extra = value ?? CheckinExtra()
                    extra.textValue = newValue.isEmpty ? nil : newValue
                    onChange(extra)
                }
                .onChange(of: value?.textValue) { newStoreValue in
                    let text = newStoreValue ?? ""
                    if localText != text {
                        localText = text
                    }
                }

            Text("\(localText.count)/\(AppConstants.textCharLimit)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

}
