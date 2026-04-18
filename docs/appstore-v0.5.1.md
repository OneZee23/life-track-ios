# App Store Connect — v0.5.1

## What's New (Release Notes)

### English
• Habit reminders: set custom notifications per habit — choose time range, interval (1h/2h/3h), and specific weekdays. Quick presets for weekdays-only or every day
• Sleep tracking fix: stepper now adjusts in 15-minute increments instead of 30. Raw HealthKit values rounded to whole minutes
• Foreground notifications: reminders now show as banners even when the app is open
• Permission check: if notifications are disabled in Settings, the reminder toggle auto-resets with a helpful message

### Russian
• Напоминания для привычек: настраиваемые уведомления — диапазон часов, интервал (1ч/2ч/3ч), выбор дней недели. Быстрые кнопки «Будни» и «Каждый день»
• Исправление трекинга сна: степпер теперь меняет значение на 15 минут вместо 30. Дробные значения из Apple Health округляются
• Уведомления в приложении: напоминания показываются как баннер, даже когда приложение открыто
• Проверка разрешений: если уведомления отключены в Настройках, тумблер сбрасывается с подсказкой

---

## Promotional Text (170 chars max)

### English
Habit reminders are here! Set custom notifications with flexible schedules — by hour, interval, and weekday. Plus improved sleep tracking accuracy.

### Russian
Напоминания для привычек! Настраиваемые уведомления по часам, интервалу и дням недели. Плюс улучшенная точность трекинга сна.

---

## Review Notes (for Apple reviewer)

### English
This update adds per-habit notification reminders and fixes sleep tracking accuracy.

To test Reminders:
1. Open the app → Habits tab → tap "+" to create a new habit (or edit an existing one)
2. Scroll down to the "Reminders" section with the bell icon
3. Toggle reminders ON — the app will request notification permission
4. Configure: time range (e.g. 09:00 to 17:00), interval (1h/2h/3h), weekdays
5. Tap "Weekdays" for Mon-Fri only, or "Every day" for all 7 days
6. The footer shows total notification count (e.g. "45 reminders per week")
7. Save the habit — notifications are scheduled immediately
8. The habit list shows a small orange bell icon next to habits with active reminders

To test Sleep fix:
1. Create or edit a habit with Apple Health → Sleep sync
2. Tap +/- buttons — value changes by 15 minutes (was 30)
3. Auto-synced values from HealthKit are rounded to whole minutes

Notification behavior:
- Reminders appear as banners even when the app is in the foreground
- If user revokes notification permission in iOS Settings, the reminder toggle auto-disables on next form open
- iOS limits local notifications to 64 total — the app enforces this budget (global daily reminder first, then per-habit reminders in order)

No new permissions required. The app uses UNUserNotificationCenter for local notifications (no push notifications, no server).

Demo credentials: N/A (no login required)

### Russian
Это обновление добавляет напоминания для привычек и исправляет точность трекинга сна.

Для тестирования напоминаний:
1. Откройте приложение → вкладка Habits → "+" для новой привычки (или редактируйте существующую)
2. Пролистайте до секции «Напоминания» с иконкой колокольчика
3. Включите тумблер — приложение запросит разрешение на уведомления
4. Настройте: диапазон часов (напр. 09:00–17:00), интервал (1ч/2ч/3ч), дни недели
5. Кнопка «Будни» — Пн-Пт, «Каждый день» — все 7 дней
6. Внизу показывается количество уведомлений (напр. «45 напоминаний в неделю»)
7. Сохраните — уведомления запланируются сразу
8. В списке привычек появится оранжевый колокольчик рядом с привычками с напоминаниями

Для тестирования исправления сна:
1. Создайте или отредактируйте привычку с Apple Health → Сон
2. Кнопки +/- меняют значение на 15 минут (было 30)
3. Автозначения из HealthKit округляются до целых минут

Новых разрешений не требуется. Приложение использует локальные уведомления (без push, без сервера).
