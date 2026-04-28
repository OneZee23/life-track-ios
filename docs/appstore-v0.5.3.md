# App Store Connect — v0.5.3

## What's New (Release Notes)

### English
• Daily target without reminders: a new "Multiple times per day" toggle in the habit form lets you set a count goal (3 glasses of water, 9 squats) without needing push notifications
• Beat your goal: counters no longer cap at your daily target. Did 11 squats when you planned 9? The card shows "11/9 🔥" in purple to celebrate the overflow
• Minus button to fix a stray tap: when a count habit's progress is above 0, a small minus button appears next to the indicator. One tap = −1
• Tap to dismiss celebration: when you finish the day, the confetti overlay dismisses on tap — no more waiting through the animation
• Rich count statistics: open a count habit's detail view to see a perfect-day streak (🌟), totals, averages, best day, completion %, an overflow-aware bar chart with target line, and a calendar heatmap
• Notes for any habit: open a habit's detail view to add a free-form note for today (or yesterday). Useful when a binary "yes/no" doesn't capture nuance — e.g. "had half a cigarette" or "long hike instead of squats". A small bubble icon appears on the card when a note exists

### Russian
• Цель в день без напоминаний: новый toggle «Несколько раз в день» в форме привычки позволяет задать count-цель (3 стакана воды, 9 приседаний) даже если push-уведомления не нужны
• Перевыполнение плана: счётчик больше не упирается в дневную цель. Сделал 11 приседаний при плане 9? Карточка покажет «11/9 🔥» фиолетовым в честь перевыполнения
• Кнопка минус для исправления: когда счётчик count-привычки больше 0, рядом с индикатором появляется маленькая кнопка минус. Один тап = −1
• Тап, чтобы закрыть поздравление: когда выполнил все привычки за день, confetti-оверлей закрывается одним тапом — не нужно ждать пока анимация доиграет
• Расширенная статистика для count-привычек: открой деталь привычки — там идеальный стрик (🌟), сумма, среднее, лучший день, % выполнения, bar chart с фиолетовой подсветкой перевыполнений и пунктирной линией target, плюс календарный heatmap
• Заметки к любой привычке: открой деталь — там можно оставить свободную заметку на сегодня (или вчера). Полезно когда «да/нет» не передаёт нюанс — например, «полсигареты» или «горный поход вместо приседаний». На карточке появляется маленькая иконка-облачко если заметка есть

---

## Promotional Text (170 chars max)

### English
Daily targets without reminders, overflow celebrations (11/9 🔥 purple), minus to fix taps, perfect-day streaks, and a rich stats screen with heatmap. Track better, smarter.

### Russian
Цели в день без напоминаний, перевыполнение «11/9 🔥», минус для исправлений, идеальный стрик и подробная статистика с heatmap. Точнее, гибче, мотивирующее.

---

## Review Notes (for Apple reviewer)

### English
This update polishes the count-based habits added in v0.5.2 and adds rich statistics for them.

To test Daily target without reminders:
1. Open the app → Habits tab → "+" to create a new habit
2. Skip the Reminders toggle (leave it off)
3. In the new "Multiple times per day" section, toggle it on — a stepper appears
4. Set a target (e.g. 3) and save the habit
5. On Check-in, the card now shows "0/3" and a progress bar — works exactly like a count habit, just without notifications

To test Minus button:
1. On a count habit, tap the card several times to increment (e.g. 3/9)
2. A small minus button appears between the progress bar area and the indicator
3. Tap minus → counter decreases by 1; at 0 the button disappears

To test Overflow above target:
1. Tap a count habit past the target (e.g. for target 9, tap 10 times)
2. Card shows "10/9" with a 🔥 icon, text and progress bar turn purple
3. Streak and the day's "done" status remain intact

To test Celebration dismiss:
1. Complete all habits for the day so they all show the green checkmark
2. The confetti overlay appears
3. Tap anywhere on the screen — the overlay fades away immediately

To test Rich count statistics (HabitDetailView):
1. Long-press a count habit on the Check-in screen — opens the detail view
2. Top header shows two streaks: the standard streak (orange) and the perfect-day streak (🌟 purple) where value ≥ target every day
3. Stat grid: Total (sum across period), Average per day, Best day (purple if overflow), Perfect days (with "N over goal" subtitle if any overflow)
4. Switch periods (7d/30d/90d/Year) — chart and stats update
5. Bar chart: green bar = full target, light green = partial, purple = overflow, dashed orange line = target reference
6. Calendar heatmap: 7-row weekday × N-column week grid with intensity reflecting value/target ratio. Purple cells = overflow days
7. Log: per-day rows show "N/target" in matching colors with 🔥 for overflow

To test Notes:
1. Long-press any habit on Check-in to open detail view
2. Scroll to "Note for today" section at the bottom — multi-line TextField
3. Type a note (e.g. "half a cigarette today") — auto-saves on each change
4. Close the detail view — a small bubble icon appears next to the habit name on the card
5. Switch the Check-in tab to "Yesterday" and long-press the same habit → the note section now reads "Note for yesterday" and shows yesterday's note (separate from today's)
6. Clearing the field removes the note

Backward compatibility: existing count habits continue to work; the new statistics view simply adds new sections. No data migration required. Stored daily targets from v0.5.2 onwards remain valid.

No new permissions. No server, no push, no account.

Demo credentials: N/A (no login required)

### Russian
Это обновление полирует count-привычки из v0.5.2 и добавляет для них развёрнутую статистику.

Тестирование Цели в день без напоминаний:
1. Откройте приложение → вкладка Habits → «+» для новой привычки
2. Не включайте напоминания
3. В новой секции «Несколько раз в день» переключите toggle — появится степпер
4. Задайте цель (напр. 3) и сохраните привычку
5. На Check-in карточка покажет «0/3» и прогресс-бар — работает как count-привычка, но без push

Тестирование Кнопки минус:
1. На count-привычке тапайте по карточке для инкремента (напр. до 3/9)
2. Между прогресс-баром и индикатором появится маленькая кнопка минус
3. Тап на минус → счётчик уменьшается на 1; на 0 кнопка исчезает

Тестирование Перевыполнения:
1. На count-привычке тапайте после достижения цели (напр. для цели 9 тапните 10 раз)
2. Карточка покажет «10/9» и иконку 🔥; текст и прогресс-бар станут фиолетовыми
3. Стрик и статус «выполнено» за день не меняется (за перевыполнение не штрафуем)

Тестирование Закрытия поздравления:
1. Выполните все привычки за день до зелёных галочек
2. Появляется confetti-оверлей
3. Тап в любую точку экрана — оверлей исчезает сразу

Тестирование Расширенной статистики (HabitDetailView):
1. Long-press по count-привычке на экране Check-in — открывает деталь
2. В шапке два стрика: обычный (оранжевый) и идеальный (🌟 фиолетовый) — где value ≥ target каждый день
3. Сетка stat-карточек: Всего (sum за период), Среднее в день, Лучший день (фиолетовый если overflow), Идеальных дней (с подзаголовком «N сверх плана» при overflow)
4. Переключение периодов (7д/30д/90д/Год) — графики и статы обновляются
5. Bar chart: зелёный бар = полное target, светло-зелёный = частично, фиолетовый = overflow, пунктирная оранжевая линия = target reference
6. Календарный heatmap: 7 рядов дней недели × N столбцов недель, цвет ячейки по value/target. Фиолетовые ячейки = дни перевыполнения
7. Лог: по дням «N/target» в соответствующих цветах с 🔥 для overflow

Тестирование Заметок:
1. Long-press любую привычку на Check-in — откроется деталь
2. Скролл вниз до секции «Заметка на сегодня» — multi-line TextField
3. Введите заметку (например, «полсигареты сегодня») — auto-save при изменении
4. Закройте деталь — рядом с именем привычки на карточке появится маленькая иконка-облачко
5. Переключите Check-in на «Вчера» и long-press той же привычке → секция называется «Заметка на вчера» и показывает заметку за yesterday (отдельную от today's)
6. Очистка поля удаляет заметку

Обратная совместимость: существующие count-привычки работают; новая статистика просто добавляет секции. Миграция данных не требуется. Daily target с v0.5.2 и заметки в `CheckinExtra.noteValue` — оба опциональные поля, decodeIfPresent.

Новых разрешений нет. Сервера нет, push нет, аккаунта нет.
