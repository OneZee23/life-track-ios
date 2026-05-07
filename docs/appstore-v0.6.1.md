# App Store Connect — v0.6.1

## What's New (Release Notes)

### English
• Total days counter: alongside the fire streak (🔥), each habit now shows the total number of days you've ever completed it (∑). Streaks reset on misses, but your accumulated commitment never goes away
• Smarter streaks for scheduled habits: a habit set to weekdays only no longer resets every weekend. The streak now skips non-scheduled days and counts only the days the habit is supposed to happen
• "Total days" stat card in habit detail view, alongside the existing streak / best / completion stats

### Russian
• Счётчик общего количества дней: рядом с огоньком стрика (🔥) каждая привычка теперь показывает общее число дней, когда ты её выполнял (∑). Стрик сбивается при пропуске, но накопленный прогресс — никогда
• Умные стрики для привычек с расписанием: привычка только на будние дни больше не сбивается каждые выходные. Стрик теперь пропускает «нерабочие» дни и считает только дни, когда привычка должна была быть выполнена
• Новая статкарточка «Всего дней» в детальной статистике привычки рядом со стриком, лучшим стриком и процентом выполнения

---

## Promotional Text (170 chars max)

### English
A second motivational number alongside your streak: total days completed, all-time. Streaks reset, but your real commitment is now visible.

### Russian
Вторая мотивационная цифра рядом со стриком: общее количество выполненных дней за всё время. Стрик сбивается, твой настоящий прогресс — нет.

---

## Review Notes (for Apple reviewer)

### English
This update adds two related metrics to make commitment more visible: a "total days completed" counter alongside the existing streak, and schedule-aware streak counting (so a Mon-Fri habit doesn't reset every weekend).

To test Total days counter:
1. Open the app → Check-in tab
2. Use any habit a few times (mark as done several days, including past days via Progress tab)
3. The habit card now shows: "🔥 N · ∑ M" where N is current streak and M is the all-time total of completed days
4. Skip a day so streak drops below 2 — the ∑ counter remains visible (proof that long-term commitment is preserved)
5. Open the habit detail view (long-press from Check-in or tap from Progress) — there's a new "Total days" stat card

To test Schedule-aware streaks:
1. Create a new habit, e.g. "Stretch"
2. In the Reminders section, set days to "Weekdays" only (Mon-Fri)
3. Check the habit Mon-Fri
4. On Saturday, do NOT check it
5. On Monday morning, the streak should still show 5+ (or whatever the count) — Saturday and Sunday were not in the schedule, so they were skipped, not counted as misses
6. Compare to a habit with no reminder schedule — that one still requires every day to maintain the streak

Backward compatibility: existing habits' streaks may visually increase after the update (because previously-counted "misses" on non-scheduled days no longer count). No data migration required, no UserDefaults schema change.

No new permissions. No server, no push, no account.

Demo credentials: N/A (no login required)

### Russian
Это обновление добавляет две связанные метрики, чтобы сделать накопленный прогресс заметнее: счётчик «всего дней» рядом со стриком, и schedule-aware стрики (чтобы привычка только на будние не сбивалась каждые выходные).

Тестирование общего счётчика:
1. Откройте приложение → вкладка Check-in
2. Несколько раз отметьте привычку (включая прошлые дни через Progress tab)
3. Карточка привычки теперь показывает: «🔥 N · ∑ M», где N — текущий стрик, M — общее число выполненных дней за всё время
4. Пропустите день — стрик упадёт ниже 2, но ∑ останется виден (доказательство что долгий прогресс сохраняется)
5. Откройте детальный экран привычки (long-press на Check-in или тап из Progress) — там новая статкарточка «Всего дней»

Тестирование schedule-aware стриков:
1. Создайте новую привычку, например «Растяжка»
2. В секции «Напоминания» выберите «Будни»
3. Отмечайте привычку в Пн-Пт
4. В субботу НЕ отмечайте
5. В понедельник утром стрик должен показать 5+ (или больше) — суббота и воскресенье не входили в расписание, они пропускаются, а не считаются пропуском
6. Сравните с привычкой без расписания — там по-прежнему нужны все дни для стрика

Обратная совместимость: стрики существующих привычек могут визуально увеличиться после обновления (потому что раньше «пропуски» в нерасписанные дни считались за пропуски). Миграция данных не требуется, schema UserDefaults не меняется.

Новых разрешений нет. Сервера нет, push нет, аккаунта нет.
