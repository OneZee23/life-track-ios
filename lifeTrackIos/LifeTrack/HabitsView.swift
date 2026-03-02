import SwiftUI

private let EMOJIS = [
    "🛌","🚴","🥗","🧠","💻","📖","💪","🧘","💊","🎯",
    "🎨","🎵","✍️","🏃","🧹","💧","☀️","🤝","📵","🌿"
]

struct HabitsView: View {
    @EnvironmentObject var store: AppStore

    @State private var showAddForm = false
    @State private var editingHabit: Habit? = nil
    @State private var habitToDelete: Habit? = nil

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
                            onEdit: { editingHabit = habit },
                            onDelete: { habitToDelete = habit }
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
                if store.activeHabits.count < 10 && !showAddForm {
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
                } else if store.activeHabits.count >= 10 {
                    Text(L10n.maxHabits)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 12)
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            HabitFormView(mode: .add) { name, emoji, ext in
                store.addHabit(name: name, emoji: emoji, extendedField: ext)
                showAddForm = false
            } onCancel: {
                showAddForm = false
            }
        }
        .sheet(item: $editingHabit) { habit in
            HabitFormView(mode: .edit(habit)) { name, emoji, ext in
                store.updateHabit(id: habit.id, name: name, emoji: emoji, extendedField: ext)
                editingHabit = nil
            } onCancel: {
                editingHabit = nil
            }
        }
        .confirmationDialog(
            L10n.deleteConfirmTitle,
            isPresented: Binding(
                get: { habitToDelete != nil },
                set: { if !$0 { habitToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.delete, role: .destructive) {
                if let habit = habitToDelete {
                    withAnimation { store.deleteHabit(id: habit.id) }
                }
                habitToDelete = nil
            }
        } message: {
            if let habit = habitToDelete {
                Text(L10n.deleteConfirmMessage(habit.emoji, habit.name))
            }
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
    let onDelete: () -> Void

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
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label(L10n.delete, systemImage: "trash")
            }
        }
    }
}

// MARK: - Habit Form

enum HabitFormMode {
    case add
    case edit(Habit)
}

struct HabitFormView: View {
    let mode: HabitFormMode
    let onSave: (String, String, ExtendedFieldConfig?) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var emoji: String = "🎯"
    @State private var showEmojiPicker = false
    @FocusState private var nameFocused: Bool

    // Extended field config
    @State private var extendedEnabled = false
    @State private var extendedType: ExtendedFieldType = .numeric
    @State private var numericUnit = ""
    @State private var numericMin: Double = 0
    @State private var numericMax: Double = 10
    @State private var numericStep: Double = 1
    @State private var numericStyle: NumericInputStyle = .slider
    @State private var hasMax = true
    @State private var slideFromTrailing = true

    // Preview
    @State private var previewNumeric: Double = 5
    @State private var previewRating: Int? = nil
    @State private var previewText: String = ""
    @State private var isEditingPreviewValue = false
    @State private var editPreviewValueText = ""
    @FocusState private var editPreviewValueFocused: Bool

    private var title: String {
        switch mode {
        case .add: return L10n.newHabit
        case .edit: return L10n.editHabit
        }
    }

    init(mode: HabitFormMode, onSave: @escaping (String, String, ExtendedFieldConfig?) -> Void, onCancel: @escaping () -> Void) {
        self.mode = mode
        self.onSave = onSave
        self.onCancel = onCancel
        if case .edit(let habit) = mode {
            _name = State(initialValue: habit.name)
            _emoji = State(initialValue: habit.emoji)
            if let ext = habit.extendedField {
                _extendedEnabled = State(initialValue: true)
                _extendedType = State(initialValue: ext.type)
                _numericUnit = State(initialValue: ext.unit ?? "")
                _numericMin = State(initialValue: ext.minValue ?? 0)
                _numericMax = State(initialValue: ext.maxValue ?? 10)
                _numericStep = State(initialValue: ext.step ?? 1)
                _hasMax = State(initialValue: ext.maxValue != nil)
                _numericStyle = State(initialValue: ext.maxValue != nil ? (ext.inputStyle ?? .slider) : .stepper)
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
                                    .onSubmit { if canSave { save() } }

                                Text("\(name.count)/20")
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
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Extended check-in section
                        extendedFieldSection

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
                        editPreviewValueFocused = false
                    }
                }
            }
        }
        .onAppear { nameFocused = true }
    }

    // MARK: - Extended Field Section

    private var extendedFieldSection: some View {
        VStack(spacing: 12) {
            // Toggle
            HStack {
                Text(L10n.extendedCheckin)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Toggle("", isOn: $extendedEnabled)
                    .labelsHidden()
                    .tint(Color(UIColor.systemGreen))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )

            if extendedEnabled {
                // Type picker — intercept to set slide direction
                Picker("", selection: Binding(
                    get: { extendedType },
                    set: { newType in
                        let order: [ExtendedFieldType] = [.numeric, .text, .rating]
                        slideFromTrailing = (order.firstIndex(of: newType) ?? 0) > (order.firstIndex(of: extendedType) ?? 0)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            extendedType = newType
                        }
                    }
                )) {
                    Text(L10n.extendedNumeric).tag(ExtendedFieldType.numeric)
                    Text(L10n.extendedText).tag(ExtendedFieldType.text)
                    Text(L10n.extendedRating).tag(ExtendedFieldType.rating)
                }
                .pickerStyle(.segmented)

                // Type-dependent content — slides horizontally on type change
                VStack(spacing: 12) {
                    if extendedType == .numeric {
                        numericSettingsSection
                    }
                    extendedPreviewSection
                }
                .id(extendedType)
                .transition(.asymmetric(
                    insertion: .move(edge: slideFromTrailing ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: slideFromTrailing ? .leading : .trailing).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: extendedEnabled)
    }

    // MARK: - Numeric Settings

    private var numericSettingsSection: some View {
        VStack(spacing: 10) {
            // Input style — only when max is set (slider needs bounded range)
            if hasMax {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.extendedInputStyle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Picker("", selection: $numericStyle) {
                        Text(L10n.extendedSlider).tag(NumericInputStyle.slider)
                        Text(L10n.extendedStepper).tag(NumericInputStyle.stepper)
                    }
                    .pickerStyle(.segmented)
                }
            }

            // Unit
            HStack(spacing: 10) {
                Text(L10n.extendedUnit)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                TextField(L10n.extendedUnitHint, text: Binding(
                    get: { numericUnit },
                    set: { numericUnit = String($0.prefix(6)) }
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

            // Min
            numericFieldRow(
                label: L10n.extendedMin,
                value: $numericMin,
                range: 0...max(0, hasMax ? numericMax - numericStep : 99998)
            )

            // Max (optional)
            maxRow

            // Step
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.extendedStep)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    ForEach([0.5, 1.0, 5.0, 10.0], id: \.self) { s in
                        Button {
                            numericStep = s
                            if hasMax && numericMax < numericMin + s {
                                numericMax = numericMin + s
                            }
                        } label: {
                            Text(formatNumericValue(s))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(numericStep == s ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(numericStep == s
                                              ? Color(UIColor.systemGreen)
                                              : Color(UIColor.systemGray5))
                                )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Max Row

    private var maxRow: some View {
        Group {
            if hasMax {
                HStack(spacing: 6) {
                    Text(L10n.extendedMax)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button {
                        numericMax = max(numericMin + numericStep, numericMax - numericStep)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(numericMax <= numericMin + numericStep ? Color(UIColor.systemGray4) : Color(UIColor.systemGreen))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color(UIColor.systemGray5)))
                    }
                    .disabled(numericMax <= numericMin + numericStep)

                    Text(formatNumericValue(numericMax))
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(minWidth: 32)

                    Button {
                        numericMax = min(99999, numericMax + numericStep)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(numericMax >= 99999 ? Color(UIColor.systemGray4) : Color(UIColor.systemGreen))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color(UIColor.systemGray5)))
                    }
                    .disabled(numericMax >= 99999)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            hasMax = false
                            numericStyle = .stepper
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(UIColor.systemGray3))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            } else {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        hasMax = true
                        numericMax = max(numericMin + numericStep, 10)
                    }
                } label: {
                    HStack {
                        Text(L10n.extendedMax)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("∞")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(UIColor.systemGreen))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasMax)
    }

    // MARK: - Field Row Helper

    private func numericFieldRow(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            Button {
                let newVal = max(range.lowerBound, value.wrappedValue - numericStep)
                value.wrappedValue = newVal
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(value.wrappedValue <= range.lowerBound ? Color(UIColor.systemGray4) : Color(UIColor.systemGreen))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(UIColor.systemGray5)))
            }
            .disabled(value.wrappedValue <= range.lowerBound)

            Text(formatNumericValue(value.wrappedValue))
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .frame(minWidth: 32)

            Button {
                let newVal = min(range.upperBound, value.wrappedValue + numericStep)
                value.wrappedValue = newVal
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(value.wrappedValue >= range.upperBound ? Color(UIColor.systemGray4) : Color(UIColor.systemGreen))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(UIColor.systemGray5)))
            }
            .disabled(value.wrappedValue >= range.upperBound)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    private func formatNumericValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    // MARK: - Live Preview

    private var extendedPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.extendedPreview)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            VStack(spacing: 2) {
                // Mini habit card
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.systemGreen).opacity(0.15))
                            .frame(width: 34, height: 34)
                        Text(emoji)
                            .font(.system(size: 15))
                    }

                    Text(name.isEmpty ? L10n.name : name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(name.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemGreen))
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )

                // Preview panel
                Group {
                    switch extendedType {
                    case .numeric:
                        previewNumericPanel
                    case .rating:
                        previewRatingPanel
                    case .text:
                        previewTextPanel
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.systemGray6))
        )
    }

    // MARK: - Preview Panels

    private var effectiveMax: Double {
        hasMax ? numericMax : 99999
    }

    private var safeStep: Double {
        let range = effectiveMax - numericMin
        return range > 0 ? min(numericStep, range) : numericStep
    }

    private var previewNumericPanel: some View {
        Group {
            if numericStyle == .slider && hasMax {
                HStack(spacing: 10) {
                    Slider(
                        value: $previewNumeric,
                        in: numericMin...max(numericMin + safeStep, numericMax),
                        step: safeStep
                    )
                    .tint(Color(UIColor.systemGreen))

                    HStack(spacing: 2) {
                        Text(formatNumericValue(previewNumeric))
                        if !numericUnit.isEmpty { Text(numericUnit) }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(minWidth: 50, alignment: .trailing)
                }
            } else {
                // Stepper with manual input on tap
                HStack(spacing: 12) {
                    Spacer()

                    Button {
                        previewNumeric = max(numericMin, previewNumeric - numericStep)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(previewNumeric <= numericMin ? Color(UIColor.systemGray4) : Color(UIColor.systemGreen))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(UIColor.systemGray5)))
                    }
                    .disabled(previewNumeric <= numericMin)

                    // Value — tap to type manually
                    Group {
                        if isEditingPreviewValue {
                            TextField("", text: $editPreviewValueText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 17, weight: .bold, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .focused($editPreviewValueFocused)
                                .onAppear { editPreviewValueFocused = true }
                                .onChange(of: editPreviewValueFocused) { focused in
                                    if !focused { commitPreviewEdit() }
                                }
                        } else {
                            HStack(spacing: 2) {
                                Text(formatNumericValue(previewNumeric))
                                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                                if !numericUnit.isEmpty {
                                    Text(numericUnit)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editPreviewValueText = formatNumericValue(previewNumeric)
                                isEditingPreviewValue = true
                            }
                        }
                    }
                    .frame(width: 110)

                    Button {
                        previewNumeric = min(effectiveMax, previewNumeric + numericStep)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(previewNumeric >= effectiveMax ? Color(UIColor.systemGray4) : Color(UIColor.systemGreen))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(UIColor.systemGray5)))
                    }
                    .disabled(previewNumeric >= effectiveMax)

                    Spacer()
                }
            }
        }
        .onChange(of: numericMin) { _ in clampPreviewNumeric() }
        .onChange(of: numericMax) { _ in clampPreviewNumeric() }
        .onChange(of: numericStep) { _ in clampPreviewNumeric() }
        .onChange(of: hasMax) { _ in clampPreviewNumeric() }
    }

    private func clampPreviewNumeric() {
        previewNumeric = min(max(numericMin, previewNumeric), effectiveMax)
    }

    private func commitPreviewEdit() {
        isEditingPreviewValue = false
        guard let val = Double(editPreviewValueText) else { return }
        let clamped = min(max(numericMin, val), effectiveMax)
        previewNumeric = (clamped * 100).rounded() / 100
    }

    private var previewRatingPanel: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0...5, id: \.self) { rating in
                    ratingButton(rating: rating)
                }
            }
            HStack(spacing: 4) {
                ForEach(6...10, id: \.self) { rating in
                    ratingButton(rating: rating)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func ratingButton(rating: Int) -> some View {
        Button {
            previewRating = previewRating == rating ? nil : rating
        } label: {
            Text("\(rating)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(previewRating == rating ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(previewRating == rating
                              ? Color(UIColor.systemGreen)
                              : Color(UIColor.systemGray5))
                )
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: previewRating)
    }

    private var previewTextPanel: some View {
        HStack(spacing: 8) {
            TextField(L10n.extendedNotePlaceholder, text: $previewText)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .onChange(of: previewText) { newValue in
                    if newValue.count > 140 {
                        previewText = String(newValue.prefix(140))
                    }
                }

            Text("\(previewText.count)/140")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Save

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private func save() {
        guard canSave else { return }
        let trimmedName = String(name.trimmingCharacters(in: .whitespaces).prefix(20))

        var config: ExtendedFieldConfig?
        if extendedEnabled {
            config = ExtendedFieldConfig(
                type: extendedType,
                unit: extendedType == .numeric && !numericUnit.isEmpty ? numericUnit : nil,
                minValue: extendedType == .numeric ? numericMin : nil,
                maxValue: extendedType == .numeric && hasMax ? numericMax : nil,
                step: extendedType == .numeric ? numericStep : nil,
                inputStyle: extendedType == .numeric ? numericStyle : nil
            )
        }

        onSave(trimmedName, emoji, config)
    }
}
