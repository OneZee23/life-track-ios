import Combine
import HealthKit
import SwiftUI
import UserNotifications

private let EMOJIS = [
    "🛌","🚴","🥗","🧠","💻","📖","💪","🧘","💊","🎯",
    "🎨","🎵","✍️","🏃","🧹","💧","☀️","🤝","📵","🌿"
]

struct HabitsView: View {
    @EnvironmentObject var store: AppStore

    @State private var showAddForm = false
    @State private var editingHabit: Habit? = nil

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.habits)
                            .font(.system(size: 32, weight: .bold))
                        Text(L10n.habitsCount(store.activeHabits.count))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    // Undo / Redo
                    if store.canUndo || store.canRedo {
                        HStack(spacing: 0) {
                            undoRedoButton(
                                systemName: "arrow.uturn.backward",
                                enabled: store.canUndo
                            ) {
                                withAnimation { store.undo() }
                            }
                            undoRedoButton(
                                systemName: "arrow.uturn.forward",
                                enabled: store.canRedo
                            ) {
                                withAnimation { store.redo() }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.systemGray5))
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

                List {
                    ForEach(store.activeHabits) { habit in
                        HabitRow(
                            habit: habit,
                            onEdit: { editingHabit = habit }
                        )
                        .listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .onMove { store.moveHabits(from: $0, to: $1) }
                    .deleteDisabled(true)
                }
                .listStyle(.insetGrouped)
                .environment(\.editMode, .constant(.active))

                // Add button
                if store.activeHabits.count < AppConstants.maxHabits && !showAddForm {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showAddForm = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text(L10n.addHabit)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color(UIColor.systemGreen))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(UIColor.systemGreen).opacity(0.12))
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if store.activeHabits.count >= AppConstants.maxHabits {
                    Text(L10n.maxHabits)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 12)
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            HabitFormView(mode: .add) { name, emoji, ext, wType, mType, reminder, target in
                store.addHabit(name: name, emoji: emoji, extendedField: ext, healthKitWorkoutType: wType, healthKitMetricType: mType, reminder: reminder, targetPerDay: target)
                if wType != nil || mType != nil { Task { await store.syncHealthKitWorkouts() } }
                showAddForm = false
            } onCancel: {
                showAddForm = false
            }
        }
        .sheet(item: $editingHabit) { habit in
            HabitFormView(mode: .edit(habit), onSave: { name, emoji, ext, wType, mType, reminder, target in
                store.updateHabit(id: habit.id, name: name, emoji: emoji, extendedField: ext, healthKitWorkoutType: wType, healthKitMetricType: mType, reminder: reminder, targetPerDay: target)
                if wType != nil || mType != nil { Task { await store.syncHealthKitWorkouts() } }
                editingHabit = nil
            }, onCancel: {
                editingHabit = nil
            }, onDelete: {
                withAnimation { store.deleteHabit(id: habit.id) }
                editingHabit = nil
            })
        }
    }

    // MARK: - Undo/Redo button

    private func undoRedoButton(
        systemName: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(enabled ? Color(UIColor.systemGreen) : Color(UIColor.systemGray4))
                .frame(width: 32, height: 28)
        }
        .disabled(!enabled)
    }
}

// MARK: - Habit Row

struct HabitRow: View {
    let habit: Habit
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: 40, height: 40)
                Text(habit.emoji)
                    .font(.system(size: 20))
            }

            Text(habit.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if habit.reminder != nil {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(UIColor.systemOrange))
                    .accessibilityLabel(L10n.habitReminder)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
    }
}

// MARK: - Habit Form

enum HabitFormMode {
    case add
    case edit(Habit)
}

struct HabitFormView: View {
    let mode: HabitFormMode
    let onSave: (String, String, ExtendedFieldConfig?, String?, String?, HabitReminder?, Int?) -> Void
    let onCancel: () -> Void
    var onDelete: (() -> Void)? = nil

    @EnvironmentObject var store: AppStore

    @State private var showDeleteConfirm = false
    @State private var name: String = ""
    @State private var emoji: String = "🎯"
    @State private var showEmojiPicker = false
    @State private var showCustomEmojiSheet = false
    @State private var customEmojiInput = ""
    @FocusState private var nameFocused: Bool

    // HealthKit sync
    enum HealthKitSyncMode: Int, CaseIterable {
        case workout, sleep, steps
    }
    @State private var healthKitEnabled = false
    @State private var healthKitSyncMode: HealthKitSyncMode = .workout
    @State private var selectedWorkoutType: WorkoutType = .cycling
    @State private var showHealthKitDenied = false

    // Extended field config
    @State private var selectedExtendedType: ExtendedFieldType? = nil
    @State private var selectedPreset: NumericPreset = .time
    @State private var customUnit: String = ""
    @State private var customStep: Double = 1

    // Habit reminder
    @State private var reminderEnabled = false
    @State private var reminderStartHour = 9
    @State private var reminderEndHour = 17
    @State private var reminderIntervalMinutes = 60
    @State private var reminderWeekdays: Set<Int> = Set(1...7)
    @State private var showReminderDenied = false
    @State private var reminderDaysMode: ReminderDaysMode = .everyDay

    // Daily target (count-based check-ins, independent of reminders)
    @State private var useDailyTarget: Bool = false
    @State private var dailyTargetCount: Int = 1
    @State private var targetWasManuallyEdited: Bool = false

    enum ReminderDaysMode {
        case weekdays, everyDay, custom
    }

    private var title: String {
        switch mode {
        case .add: return L10n.newHabit
        case .edit: return L10n.editHabit
        }
    }

    init(mode: HabitFormMode, onSave: @escaping (String, String, ExtendedFieldConfig?, String?, String?, HabitReminder?, Int?) -> Void, onCancel: @escaping () -> Void, onDelete: (() -> Void)? = nil) {
        self.mode = mode
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
        if case .edit(let habit) = mode {
            _name = State(initialValue: habit.name)
            _emoji = State(initialValue: habit.emoji)
            if let wType = habit.healthKitWorkoutType, let parsed = WorkoutType(rawValue: wType) {
                _healthKitEnabled = State(initialValue: true)
                _healthKitSyncMode = State(initialValue: .workout)
                _selectedWorkoutType = State(initialValue: parsed)
            } else if let mType = habit.healthKitMetricType, let parsed = HealthKitMetricType(rawValue: mType) {
                _healthKitEnabled = State(initialValue: true)
                _healthKitSyncMode = State(initialValue: parsed == .sleep ? .sleep : .steps)
            }
            if let ext = habit.extendedField {
                _selectedExtendedType = State(initialValue: ext.type)
                if ext.type == .numeric {
                    _selectedPreset = State(initialValue: Self.detectPreset(from: ext))
                    if Self.detectPreset(from: ext) == .custom {
                        _customUnit = State(initialValue: ext.unit ?? "")
                        _customStep = State(initialValue: ext.step ?? 1)
                    }
                }
            }
            if let reminder = habit.reminder {
                _reminderEnabled = State(initialValue: true)
                _reminderStartHour = State(initialValue: reminder.startHour)
                _reminderEndHour = State(initialValue: reminder.endHour)
                _reminderIntervalMinutes = State(initialValue: reminder.intervalMinutes)
                _reminderWeekdays = State(initialValue: reminder.weekdays)
                let mode: ReminderDaysMode
                if reminder.weekdays == Set(1...5) { mode = .weekdays }
                else if reminder.weekdays == Set(1...7) { mode = .everyDay }
                else { mode = .custom }
                _reminderDaysMode = State(initialValue: mode)
            }
            if let t = habit.targetPerDay {
                _useDailyTarget = State(initialValue: true)
                _dailyTargetCount = State(initialValue: t)
                _targetWasManuallyEdited = State(initialValue: true)
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Emoji + name row
                        HStack(spacing: 12) {
                            Button {
                                withAnimation { showEmojiPicker.toggle() }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                                        .frame(width: 52, height: 52)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(Color(UIColor.systemGray4), lineWidth: 1)
                                        )
                                    Text(emoji)
                                        .font(.system(size: 26))
                                }
                            }

                            ZStack(alignment: .trailing) {
                                TextField(L10n.name, text: $name)
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .strokeBorder(Color(UIColor.systemGray4), lineWidth: 1)
                                            )
                                    )
                                    .focused($nameFocused)
                                    .onReceive(Just(name)) { _ in
                                        if name.count > AppConstants.habitNameMaxLength {
                                            name = String(name.prefix(AppConstants.habitNameMaxLength))
                                        }
                                    }
                                    .onSubmit { if canSave { save() } }

                                Text("\(name.count)/\(AppConstants.habitNameMaxLength)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 14)
                            }
                        }

                        // Emoji picker
                        if showEmojiPicker {
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5),
                                spacing: 6
                            ) {
                                ForEach(EMOJIS, id: \.self) { e in
                                    Button {
                                        emoji = e
                                        withAnimation { showEmojiPicker = false }
                                    } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(e == emoji
                                                      ? Color(UIColor.systemGreen).opacity(0.15)
                                                      : Color(UIColor.secondarySystemGroupedBackground))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .strokeBorder(
                                                            e == emoji ? Color(UIColor.systemGreen) : Color(UIColor.systemGray5),
                                                            lineWidth: e == emoji ? 2 : 1
                                                        )
                                                )
                                            Text(e)
                                                .font(.system(size: 24))
                                        }
                                        .frame(height: 50)
                                    }
                                }
                                // Custom emoji cell
                                Button {
                                    customEmojiInput = ""
                                    showCustomEmojiSheet = true
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .strokeBorder(Color(UIColor.systemGray5), lineWidth: 1)
                                            )
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(Color(UIColor.systemGreen))
                                    }
                                    .frame(height: 50)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Apple Health sync section
                        if HKHealthStore.isHealthDataAvailable() {
                            healthKitSection
                        }

                        // Extended check-in section (hidden when metric auto-configures it)
                        if !(healthKitEnabled && healthKitSyncMode != .workout) {
                            extendedFieldSection
                        }

                        // Daily target section
                        dailyTargetSection

                        // Reminder section
                        reminderSection

                        // Buttons
                        HStack(spacing: 10) {
                            Button(action: onCancel) {
                                Text(L10n.cancel)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(UIColor.systemGray5))
                                    )
                            }

                            Button(action: save) {
                                Text(title == L10n.newHabit ? L10n.add : L10n.save)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(canSave ? .white : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(canSave ? Color(UIColor.systemGreen) : Color(UIColor.systemGray5))
                                    )
                            }
                            .disabled(!canSave)
                        }

                        // Delete button (edit mode only)
                        if onDelete != nil {
                            Button { showDeleteConfirm = true } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(L10n.deleteConfirmTitle)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red)
                                )
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.cancel, action: onCancel)
                        .foregroundColor(Color(UIColor.systemGreen))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(L10n.done) {
                        nameFocused = false
                    }
                }
            }
        }
        .onAppear {
            if case .add = mode { nameFocused = true }
        }
        .confirmationDialog(
            L10n.deleteConfirmTitle,
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.delete, role: .destructive) {
                onDelete?()
            }
        } message: {
            if case .edit(let habit) = mode {
                Text(L10n.deleteConfirmMessage(habit.emoji, habit.name))
            }
        }
        .sheet(isPresented: $showCustomEmojiSheet) {
            CustomEmojiSheet(input: $customEmojiInput) { e in
                emoji = e
                showCustomEmojiSheet = false
                withAnimation { showEmojiPicker = false }
            } onCancel: {
                showCustomEmojiSheet = false
            }
            .presentationDetents([.height(260)])
        }
    }

    // MARK: - Extended Field Section

    private var extendedFieldSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.checkinType)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            // Type chips row
            HStack(spacing: 8) {
                typeChip(type: .numeric, label: L10n.extendedNumeric)
                typeChip(type: .text, label: L10n.extendedTextShort)
                typeChip(type: .rating, label: L10n.extendedRating)
            }

            // Numeric presets
            if selectedExtendedType == .numeric {
                HStack(spacing: 8) {
                    presetChip(preset: .time, icon: "clock", label: L10n.presetTime)
                    presetChip(preset: .count, icon: "number", label: L10n.presetCount)
                    presetChip(preset: .money, icon: "banknote", label: L10n.presetMoney)
                    presetChip(preset: .custom, icon: "slider.horizontal.3", label: L10n.presetCustom)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))

                // Custom preset fields
                if selectedPreset == .custom {
                    VStack(spacing: 10) {
                        // Unit field
                        HStack(spacing: 10) {
                            Text(L10n.extendedUnit)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            TextField(L10n.extendedUnitHint, text: Binding(
                                get: { customUnit },
                                set: { customUnit = String($0.prefix(AppConstants.unitMaxLength)) }
                            ))
                            .font(.system(size: 15))
                            .multilineTextAlignment(.trailing)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                        )

                        // Step picker chips
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.extendedStep)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            HStack(spacing: 6) {
                                ForEach([0.5, 1.0, 5.0, 10.0, 50.0, 100.0], id: \.self) { s in
                                    Button {
                                        customStep = s
                                    } label: {
                                        Text(formatValue(s))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(customStep == s ? .white : .primary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 36)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(customStep == s
                                                          ? Color(UIColor.systemGreen)
                                                          : Color(UIColor.systemGray5))
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedExtendedType)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedPreset)
    }

    // MARK: - Type Chip

    private func typeChip(type: ExtendedFieldType, label: String) -> some View {
        let selected = selectedExtendedType == type
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedExtendedType = selected ? nil : type
            }
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selected ? Color(UIColor.systemGreen) : Color(UIColor.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preset Chip

    private func presetChip(preset: NumericPreset, icon: String, label: String) -> some View {
        let selected = selectedPreset == preset
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedPreset = preset
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(selected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selected ? Color(UIColor.systemGreen) : Color(UIColor.systemGray5))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detect Preset

    private static func detectPreset(from config: ExtendedFieldConfig) -> NumericPreset {
        let unit = config.unit ?? ""
        let step = config.step ?? 1
        if (unit == "мин" || unit == "min") && step == 5 { return .time }
        if (unit == "шт" || unit == "pcs") && step == 1 { return .count }
        if (unit == "₽" || unit == "$") && step == 100 { return .money }
        return .custom
    }

    // MARK: - Resolved Numeric Params

    private func resolvedNumericParams() -> (unit: String, step: Double) {
        switch selectedPreset {
        case .time:   return (L10n.isRu ? "мин" : "min", 5)
        case .count:  return (L10n.isRu ? "шт" : "pcs", 1)
        case .money:  return (L10n.isRu ? "₽" : "$", 100)
        case .custom: return (customUnit, customStep)
        }
    }

    // MARK: - Apple Health Section

    private var healthKitSection: some View {
        VStack(spacing: 12) {
            // Toggle
            HStack {
                Text(L10n.healthKitSync)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Toggle("", isOn: $healthKitEnabled)
                    .labelsHidden()
                    .tint(Color(UIColor.systemGreen))
                    .onChange(of: healthKitEnabled) { enabled in
                        if enabled {
                            Task {
                                let granted = await store.requestHealthKitAccess()
                                if !granted {
                                    await MainActor.run {
                                        healthKitEnabled = false
                                        showHealthKitDenied = true
                                    }
                                }
                            }
                        }
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )

            if healthKitEnabled {
                // Sync mode picker: Workout / Sleep / Steps
                Picker("", selection: $healthKitSyncMode) {
                    Text(L10n.healthKitWorkoutLabel).tag(HealthKitSyncMode.workout)
                    Text(L10n.healthKitSleepLabel).tag(HealthKitSyncMode.sleep)
                    Text(L10n.healthKitStepsLabel).tag(HealthKitSyncMode.steps)
                }
                .pickerStyle(.segmented)
                .transition(.opacity.combined(with: .move(edge: .top)))

                switch healthKitSyncMode {
                case .workout:
                    // Workout type grid
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5),
                        spacing: 6
                    ) {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Button {
                                selectedWorkoutType = type
                            } label: {
                                VStack(spacing: 2) {
                                    Text(L10n.workoutTypeEmoji(type))
                                        .font(.system(size: 20))
                                    Text(L10n.workoutTypeName(type))
                                        .font(.system(size: 10, weight: .medium))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedWorkoutType == type
                                              ? Color(UIColor.systemGreen).opacity(0.15)
                                              : Color(UIColor.secondarySystemGroupedBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(
                                                    selectedWorkoutType == type ? Color(UIColor.systemGreen) : Color(UIColor.systemGray5),
                                                    lineWidth: selectedWorkoutType == type ? 2 : 1
                                                )
                                        )
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    Text(L10n.healthKitFooter)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                case .sleep:
                    Text(L10n.healthKitSleepFooter)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))

                case .steps:
                    Text(L10n.healthKitStepsFooter)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: healthKitEnabled)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: healthKitSyncMode)
        .alert(L10n.healthKitSync, isPresented: $showHealthKitDenied) {
            Button(L10n.healthKitOpenSettings) {
                if let url = URL(string: "x-apple-health://") {
                    UIApplication.shared.open(url)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(L10n.healthKitDeniedDetail)
        }
    }

    // MARK: - Save

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private func save() {
        guard canSave else { return }
        let trimmedName = String(name.trimmingCharacters(in: .whitespaces).prefix(AppConstants.habitNameMaxLength))

        var config: ExtendedFieldConfig?
        if let type = selectedExtendedType {
            switch type {
            case .numeric:
                let (unit, step) = resolvedNumericParams()
                config = ExtendedFieldConfig(type: .numeric, unit: unit.isEmpty ? nil : unit, minValue: 0, maxValue: nil, step: step, inputStyle: .stepper)
            case .text:
                config = ExtendedFieldConfig(type: .text)
            case .rating:
                config = ExtendedFieldConfig(type: .rating)
            }
        }

        var workoutType: String? = nil
        var metricType: String? = nil
        if healthKitEnabled {
            switch healthKitSyncMode {
            case .workout: workoutType = selectedWorkoutType.rawValue
            case .sleep:   metricType = HealthKitMetricType.sleep.rawValue
            case .steps:   metricType = HealthKitMetricType.steps.rawValue
            }
        }

        // Sleep/Steps: always force the canonical config (the extended section is hidden for these)
        if metricType != nil {
            switch healthKitSyncMode {
            case .sleep:
                config = .sleepDefault
            case .steps:
                config = .stepsDefault
            case .workout:
                break
            }
        }

        // Auto-configure extended field for distance-based workouts
        if workoutType != nil && selectedExtendedType == nil {
            if let wt = WorkoutType(rawValue: workoutType!), wt.hasDistance {
                config = ExtendedFieldConfig(type: .numeric, unit: L10n.isRu ? "км" : "km", minValue: 0, step: 1, inputStyle: .stepper)
            }
        }

        var reminder: HabitReminder? = nil
        if reminderEnabled && !reminderWeekdays.isEmpty {
            reminder = HabitReminder(
                startHour: reminderStartHour,
                endHour: max(reminderStartHour, reminderEndHour),
                intervalMinutes: reminderIntervalMinutes,
                weekdays: reminderWeekdays
            )
        }

        var targetPerDay: Int? = nil
        if useDailyTarget && dailyTargetCount > 1 {
            targetPerDay = dailyTargetCount
        }

        onSave(trimmedName, emoji, config, workoutType, metricType, reminder, targetPerDay)
    }

    private var reminderDailyCount: Int {
        let preview = HabitReminder(
            startHour: reminderStartHour,
            endHour: max(reminderStartHour, reminderEndHour),
            intervalMinutes: reminderIntervalMinutes,
            weekdays: reminderWeekdays
        )
        return preview.scheduledHours.count
    }

    private func syncTargetIfNeeded() {
        guard reminderEnabled, !targetWasManuallyEdited else { return }
        dailyTargetCount = max(1, reminderDailyCount)
    }

    // MARK: - Daily Target Section

    private var dailyTargetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.systemGreen))
                        .frame(width: 32, height: 32)
                    Image(systemName: "number")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(L10n.dailyTargetToggleLabel)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Toggle("", isOn: $useDailyTarget)
                    .labelsHidden()
                    .tint(Color(UIColor.systemGreen))
                    .onChange(of: useDailyTarget) { enabled in
                        if enabled && dailyTargetCount < 2 {
                            dailyTargetCount = 3
                        }
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )

            if useDailyTarget {
                Stepper(value: $dailyTargetCount, in: 1...99) {
                    HStack {
                        Text(L10n.habitDailyTargetLabel)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(L10n.habitDailyTargetValue(dailyTargetCount))
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(UIColor.systemGreen))
                    }
                }
                .onChange(of: dailyTargetCount) { _ in
                    targetWasManuallyEdited = true
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: useDailyTarget)
    }

    // MARK: - Reminder Section

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toggle row
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.systemOrange))
                        .frame(width: 32, height: 32)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                }
                Text(L10n.habitReminder)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Toggle("", isOn: $reminderEnabled)
                    .labelsHidden()
                    .tint(Color(UIColor.systemGreen))
                    .onChange(of: reminderEnabled) { enabled in
                        if enabled {
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                                DispatchQueue.main.async {
                                    if !granted {
                                        reminderEnabled = false
                                        showReminderDenied = true
                                    }
                                }
                            }
                            // Auto-enable daily target with notification count if user hasn't customized it.
                            if !targetWasManuallyEdited {
                                dailyTargetCount = max(1, reminderDailyCount)
                                if dailyTargetCount > 1 { useDailyTarget = true }
                            }
                        }
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )

            if reminderEnabled {
                // Time range
                HStack(spacing: 8) {
                    Text(L10n.habitReminderFrom)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    hourPicker(selection: $reminderStartHour)
                    Text(L10n.habitReminderTo)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    hourPicker(selection: $reminderEndHour)
                    Spacer()
                }
                .onChange(of: reminderStartHour) { newStart in
                    if reminderEndHour < newStart { reminderEndHour = newStart }
                    syncTargetIfNeeded()
                }
                .onChange(of: reminderEndHour) { _ in syncTargetIfNeeded() }
                .onChange(of: reminderIntervalMinutes) { _ in syncTargetIfNeeded() }

                // Interval
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.habitReminderInterval)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        intervalChip(minutes: 60, label: L10n.habitReminderEvery1h)
                        intervalChip(minutes: 120, label: L10n.habitReminderEvery2h)
                        intervalChip(minutes: 180, label: L10n.habitReminderEvery3h)
                    }
                }

                // Days mode + (optional) custom grid
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.habitReminderDays)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        daysModeChip(.everyDay,  label: L10n.habitReminderAllDays)
                        daysModeChip(.weekdays,  label: L10n.habitReminderWeekdays)
                        daysModeChip(.custom,    label: L10n.habitReminderCustomDays)
                    }

                    if reminderDaysMode == .custom {
                        HStack(spacing: 4) {
                            ForEach(1...7, id: \.self) { day in
                                let selected = reminderWeekdays.contains(day)
                                Button {
                                    if selected { reminderWeekdays.remove(day) }
                                    else { reminderWeekdays.insert(day) }
                                } label: {
                                    Text(L10n.weekdaysShort[day - 1])
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selected ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selected ? Color(UIColor.systemGreen) : Color(UIColor.systemGray5))
                                        )
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: reminderDaysMode)

                // Notification count footer
                let previewReminder = HabitReminder(
                    startHour: reminderStartHour,
                    endHour: max(reminderStartHour, reminderEndHour),
                    intervalMinutes: reminderIntervalMinutes,
                    weekdays: reminderWeekdays
                )
                if previewReminder.notificationCount > 0 {
                    Text(L10n.habitReminderCount(previewReminder.notificationCount))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: reminderEnabled)
        .onAppear {
            if reminderEnabled {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    DispatchQueue.main.async {
                        if settings.authorizationStatus == .denied {
                            reminderEnabled = false
                            showReminderDenied = true
                        }
                    }
                }
            }
        }
        .alert(L10n.habitReminder, isPresented: $showReminderDenied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(L10n.habitReminderDenied)
        }
    }

    private func hourPicker(selection: Binding<Int>) -> some View {
        Menu {
            ForEach(0..<24, id: \.self) { h in
                Button(String(format: "%02d:00", h)) { selection.wrappedValue = h }
            }
        } label: {
            Text(String(format: "%02d:00", selection.wrappedValue))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(UIColor.systemGreen))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.systemGreen).opacity(0.12))
                )
        }
    }

    private func intervalChip(minutes: Int, label: String) -> some View {
        let selected = reminderIntervalMinutes == minutes
        return Button {
            reminderIntervalMinutes = minutes
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? Color(UIColor.systemGreen) : Color(UIColor.systemGray5))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func daysModeChip(_ mode: ReminderDaysMode, label: String) -> some View {
        let selected = reminderDaysMode == mode
        return Button {
            reminderDaysMode = mode
            switch mode {
            case .weekdays: reminderWeekdays = Set(1...5)
            case .everyDay: reminderWeekdays = Set(1...7)
            case .custom:   break
            }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? Color(UIColor.systemGreen) : Color(UIColor.systemGray5))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}

// MARK: - Custom Emoji Sheet

private struct CustomEmojiSheet: View {
    @Binding var input: String
    let onConfirm: (String) -> Void
    let onCancel: () -> Void

    private var firstEmoji: String? {
        guard let first = input.first else { return nil }
        let s = String(first)
        return s.isSingleEmoji ? s : nil
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text(L10n.customEmojiHint)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)

                EmojiTextField(
                    text: $input,
                    placeholder: "🙂",
                    autoFocus: true
                )
                .frame(height: 72)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .onChange(of: input) { v in
                    // Reduce to a single emoji — drop trailing non-emoji input
                    // (e.g. from a keyboard the user switched away from).
                    guard let last = v.last else { return }
                    let s = String(last)
                    if s.isSingleEmoji {
                        if v != s { input = s }
                    } else {
                        input = String(v.dropLast())
                    }
                }

                Button {
                    if let e = firstEmoji { onConfirm(e) }
                } label: {
                    Text(L10n.save)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(firstEmoji != nil ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(firstEmoji != nil ? Color(UIColor.systemGreen) : Color(UIColor.systemGray5))
                        )
                }
                .disabled(firstEmoji == nil)

                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle(L10n.customEmojiTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.cancel, action: onCancel)
                        .foregroundColor(Color(UIColor.systemGreen))
                }
            }
        }
    }
}

// MARK: - Emoji-only TextField (UIKit bridge)

private struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let autoFocus: Bool

    func makeUIView(context: Context) -> _EmojiUITextField {
        let tf = _EmojiUITextField()
        tf.placeholder = placeholder
        tf.font = .systemFont(ofSize: 44)
        tf.textAlignment = .center
        tf.tintColor = .clear
        tf.autocorrectionType = .no
        tf.smartDashesType = .no
        tf.smartQuotesType = .no
        tf.delegate = context.coordinator
        tf.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged
        )
        if autoFocus {
            DispatchQueue.main.async { tf.becomeFirstResponder() }
        }
        return tf
    }

    func updateUIView(_ uiView: _EmojiUITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        let parent: EmojiTextField
        init(_ parent: EmojiTextField) { self.parent = parent }
        @objc func textChanged(_ tf: UITextField) {
            parent.text = tf.text ?? ""
        }
    }
}

/// UITextField that forces the emoji keyboard by overriding its input mode.
/// Falls back to the system default if the user has removed the emoji keyboard.
private final class _EmojiUITextField: UITextField {
    override var textInputContextIdentifier: String? { "" }
    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
            ?? super.textInputMode
    }
}
