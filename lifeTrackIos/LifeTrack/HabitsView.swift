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
            HabitFormView(mode: .add) { name, emoji in
                store.addHabit(name: name, emoji: emoji)
                showAddForm = false
            } onCancel: {
                showAddForm = false
            }
        }
        .sheet(item: $editingHabit) { habit in
            HabitFormView(mode: .edit(habit)) { name, emoji in
                store.updateHabit(id: habit.id, name: name, emoji: emoji)
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
    let onSave: (String, String) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var emoji: String = "🎯"
    @State private var showEmojiPicker = false
    @FocusState private var nameFocused: Bool

    private var title: String {
        switch mode {
        case .add: return L10n.newHabit
        case .edit: return L10n.editHabit
        }
    }

    init(mode: HabitFormMode, onSave: @escaping (String, String) -> Void, onCancel: @escaping () -> Void) {
        self.mode = mode
        self.onSave = onSave
        self.onCancel = onCancel
        if case .edit(let habit) = mode {
            _name = State(initialValue: habit.name)
            _emoji = State(initialValue: habit.emoji)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

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

                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.cancel, action: onCancel)
                        .foregroundColor(Color(UIColor.systemGreen))
                }
            }
        }
        .onAppear { nameFocused = true }
    }

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private func save() {
        guard canSave else { return }
        onSave(String(name.trimmingCharacters(in: .whitespaces).prefix(20)), emoji)
    }
}
