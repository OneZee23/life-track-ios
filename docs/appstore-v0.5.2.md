# App Store Connect — v0.5.2

## What's New (Release Notes)

### English
• Custom emoji: pick any emoji for your habit — tap "+" in the emoji picker and type one from the keyboard. No more being stuck with 20 presets
• Multi-count check-ins: habits with multiple reminders per day (e.g. squats 9× from 9 to 17) now track progress like 3/9, 5/9, with a progress bar on the card
• Soft streaks: even one check-in out of nine keeps your streak alive — partial progress counts
• Cleaner reminder setup: pick Every day, Weekdays, or Custom days — the weekday grid only appears when you need it
• Tap a habit in Week view to open its detailed stats
• No more surprise keyboard when opening a habit for editing

### Russian
• Свои эмодзи: теперь можно поставить любой эмодзи для привычки — тап на «+» в списке эмодзи и ввод с клавиатуры. 20 пресетов больше не предел
• Несколько отметок в день: привычки с частыми напоминаниями (например, приседания 9 раз с 9:00 до 17:00) теперь считают прогресс как 3/9, 5/9, с прогресс-баром на карточке
• Мягкие стрики: даже одна отметка из девяти сохраняет стрик — частичное выполнение засчитывается
• Упрощённая настройка дней: выбери «Каждый день», «Будни» или «Свои дни» — сетка дней появляется только когда нужна
• Тап по привычке во вкладке Неделя открывает её детальную статистику
• Больше никакой неожиданной клавиатуры при открытии привычки на редактирование

---

## Promotional Text (170 chars max)

### English
Custom emojis and multi-count check-ins. Track squats 3/9, 5/9 with progress bars. Pick any emoji, not just 20 presets. Plus cleaner reminder setup.

### Russian
Свои эмодзи и отметки несколько раз в день. Отслеживай 3/9, 5/9 с прогресс-баром. Любой эмодзи для привычки. Плюс упрощённые настройки напоминаний.

---

## Review Notes (for Apple reviewer)

### English
This update adds custom emoji input, count-based check-ins (multiple completions per day), and several UX improvements.

To test Custom emoji:
1. Open the app → Habits tab → tap "+" to create a new habit
2. Tap the emoji in the top-left of the form to open the emoji picker
3. At the bottom-right of the grid, tap the "+" cell
4. A sheet appears with the emoji keyboard already active — type any emoji
5. Tap "Save" — your emoji is applied to the habit
6. Only valid emoji are accepted; letters and symbols are rejected

To test Daily target (count-based habits):
1. Create a new habit, e.g. "Squats"
2. In the "Reminders" section, toggle reminders ON
3. Set time range 09:00–17:00, interval 1h → auto-fills "Daily target: 9 times"
4. Save the habit
5. On the Check-in screen, tap the habit card — the counter increments 0 → 1 → 2 → … → 9
6. At 9/9 the green checkmark appears; tap again to reset to 0
7. The card shows "3/9" text and a progress bar for partial completion
8. In the analytics/month view, a day with at least one check-in counts toward the streak (soft streak)

To test reminder day modes:
1. In a habit with reminders enabled, try the three chips: Every day / Weekdays / Custom days
2. The weekday grid (Mon–Sun buttons) appears only when "Custom days" is selected
3. Selecting Every day or Weekdays auto-fills the underlying selection

To test Week view habit tap:
1. Go to Progress tab → tap today's day in the week strip → scroll to a habit bar
2. Tap anywhere on the habit bar — opens the habit detail view with statistics

Backward compatibility: existing habits without a "Daily target" continue to work as simple toggle habits (one tap = done). No data migration required.

No new permissions. No server, no push, no account.

Demo credentials: N/A (no login required)

### Russian
Это обновление добавляет кастомные эмодзи, несколько отметок в день (count-based) и несколько UX-улучшений.

Тестирование Кастомных эмодзи:
1. Откройте приложение → вкладка Habits → «+» для новой привычки
2. Тап на эмодзи в левом верхнем углу формы — откроется сетка эмодзи
3. В правом нижнем углу сетки — ячейка «+»
4. Тап на неё — откроется sheet с уже активной emoji-клавиатурой
5. Введите любой эмодзи → «Save»
6. Буквы и символы не принимаются, только эмодзи

Тестирование Цели в день (count-based):
1. Создайте новую привычку, например «Приседания»
2. В секции «Напоминания» включите тумблер
3. Диапазон 09:00–17:00, интервал 1ч → автоматически: «Цель в день: 9 раз»
4. Сохраните
5. На экране Check-in тапайте по карточке — счётчик 0 → 1 → 2 → … → 9
6. На 9/9 появится зелёная галочка; ещё тап — сброс в 0
7. Карточка показывает «3/9» и прогресс-бар
8. В аналитике день с хотя бы одной отметкой засчитывается в стрик (мягкий стрик)

Тестирование режимов дней в напоминаниях:
1. В привычке с напоминаниями попробуйте три кнопки: Каждый день / Будни / Свои дни
2. Сетка дней недели (Пн–Вс) появляется только при «Свои дни»

Тестирование тапа по привычке во вкладке Неделя:
1. Progress → тап по сегодняшнему дню → список привычек за неделю
2. Тап по строке привычки открывает экран детальной статистики

Обратная совместимость: старые привычки без «Цели в день» работают как обычный toggle (один тап = выполнено). Миграция данных не требуется.

Новых разрешений нет. Сервера нет, push нет, аккаунта нет.
