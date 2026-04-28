# App Store Connect — v0.5.4

## What's New (Release Notes)

### English
• Pulsing fire on overflow: the 🔥 icon on a perfectly-overflown counter now gently pulses to celebrate going beyond your daily goal
• "Tap to continue" hint on celebrations: the end-of-day confetti overlay now shows a subtle hint at the bottom so you know to tap anywhere to dismiss
• Inline notes in the log: tap any day in a habit's log to expand it and read or edit its note inline — much easier to browse the history of "why I marked this day this way"
• Auto-jump to the right day: opening a habit from a specific day in Progress automatically expands that day's row in the log so you land on the note you want
• Tap the bubble icon to jump in: when a habit card shows a note bubble next to the name, tapping it opens the habit detail view directly (no long-press needed)
• Note indicators in Day and Week Progress: a small bubble icon appears next to a habit's name in Day Progress when that day has a note, and in Week Progress when any day of the week has a note — see at a glance which entries have context

### Russian
• Пульсирующий огонёк при перевыполнении: иконка 🔥 на карточке с перевыполнением теперь мягко пульсирует — визуальное «вау, ты молодец»
• Подсказка «Нажми, чтобы продолжить» на поздравлении: confetti-оверлей в конце дня теперь показывает тонкий намёк внизу, чтобы было ясно что можно тапнуть и закрыть
• Заметки прямо в логе: тап по любому дню в логе привычки разворачивает строку для чтения и редактирования заметки inline — намного удобнее листать историю «почему я отметил этот день именно так»
• Автоматический переход к нужному дню: когда открываешь привычку из конкретного дня в Progress, автоматически разворачивается соответствующая строка лога — сразу попадаешь на нужную заметку
• Тап по облачку для быстрого перехода: маленькая иконка заметки рядом с именем привычки на карточке Check-in теперь кликабельна — тап откроет детальный экран (без long-press)
• Индикаторы заметок в Day и Week Progress: маленькая иконка-облачко появляется рядом с именем привычки в Day Progress если у этого дня есть заметка, и в Week Progress если хоть у одного дня недели есть заметка — видно сразу в обзоре где есть контекст

---

## Promotional Text (170 chars max)

### English
Polish for v0.5.3's count habits: pulsing fire on overflow, dismiss-hint on celebration, and notes for any past day with at-a-glance indicators in the log.

### Russian
Шлифовка count-привычек: пульсирующий огонёк, подсказка для поздравления, заметки для любого прошлого дня и иконки в логе. Делаем приложение ещё нативнее.

---

## Review Notes (for Apple reviewer)

### English
This update polishes count-based habits and notes added in v0.5.2-v0.5.3.

To test pulsing fire:
1. Create a count habit with target 3 (squats, e.g.)
2. Tap card 4+ times → "4/3 🔥" appears in purple
3. The fire icon visibly pulses (scale animation, ~0.85s loop)

To test celebration hint:
1. Complete all habits for the day so confetti overlay appears
2. Bottom of overlay shows small text "Tap to continue" / "Нажми, чтобы продолжить"
3. Tap anywhere → overlay dismisses immediately

To test inline notes in the log:
1. Open any habit's detail view (long-press on Check-in or tap from Progress)
2. Scroll to the log section — each day row has a chevron on the right
3. Tap a row → it expands inline to show a TextField for that day's note
4. Type a note → auto-saves with debounce. Tap the row again or open another row → collapses
5. Each day with an existing note shows a `text.bubble.fill` icon next to its date

To test auto-jump to specific day:
1. Switch to Progress tab → Day level → navigate to a past day (e.g. last Tuesday)
2. Tap a habit on that day → habit detail view opens
3. The log row for last Tuesday is automatically expanded with its note ready to read/edit
4. From CheckInView (long-press on a habit), it auto-expands today's row instead

To test tap-to-detail bubble:
1. On a habit with a note for today, the card shows a small bubble icon next to the habit name
2. Tap the bubble → opens habit detail view directly (instead of long-press on the whole card)
3. Tap the rest of the card → still increments the count as before

Backward compatibility: pure UX polish; no model changes, no migrations.

No new permissions. No server, no push, no account.

Demo credentials: N/A (no login required)

### Russian
Это обновление шлифует count-привычки и заметки из v0.5.2-v0.5.3.

Тестирование Пульсирующего огонька:
1. Создайте count-привычку с целью 3 (например, приседания)
2. Тапните по карточке 4+ раз → появится «4/3 🔥» фиолетовым
3. Иконка огонька видимо пульсирует (scale animation ~0.85с loop)

Тестирование Подсказки для поздравления:
1. Выполните все привычки за день — появится confetti-оверлей
2. Внизу оверлея показывается мелкая строка «Нажми, чтобы продолжить»
3. Тап в любую точку — оверлей закрывается сразу

Тестирование Inline-заметок в логе:
1. Откройте любую деталь привычки (long-press на Check-in или тап из Progress)
2. Пролистайте до секции лога — каждая строка лога имеет шеврон справа
3. Тапните по строке — она развернётся inline с TextField для заметки этого дня
4. Введите заметку — auto-save с debounce. Повторный тап / тап на другой день — свернёт
5. Каждый день с уже существующей заметкой показывает иконку `text.bubble.fill` рядом с датой

Тестирование Автоперехода к нужному дню:
1. Перейдите Progress → Day → навигируйте к прошлому дню (например, прошлый вторник)
2. Тапните по привычке этого дня — откроется деталь
3. Строка лога за прошлый вторник автоматически развёрнута с заметкой, готовой к редактированию
4. Из CheckInView (long-press на привычку) — автоматически разворачивается today's row

Тестирование Тап-bubble:
1. У привычки с заметкой за сегодня на карточке появляется маленькая иконка-облачко рядом с именем
2. Тап по облачку — открывается детальный экран (вместо long-press на всю карточку)
3. Тап по остальной карточке — по-прежнему +1, как было

Обратная совместимость: чистая UX-шлифовка; модель не менялась, миграций нет.

Новых разрешений нет. Сервера нет, push нет, аккаунта нет.
