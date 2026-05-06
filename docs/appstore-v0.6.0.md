# App Store Connect — v0.6.0

## What's New (Release Notes)

### English
• 🌱 Reflection — a quiet weekly summary in the Progress tab. No pushes, no cloud, no subscription
• Notice when a habit slips — over time, the app gently notices when an established habit is dropping off and offers the smallest possible next step. No nagging, no shame
• Press and hold a Reflection card to hide it for a week — or turn off the type entirely
• New Settings toggle: "Notice drift and summarize the week" (on by default, can be disabled)
• Fixed: the minus button on count habits — tap area expanded to Apple HIG 44×44, taps no longer slip into the +1 button
• Fixed: the comment field on a habit is now available regardless of whether it's marked done — it was previously gated by the done state, even though the text persisted underneath

### Russian
• 🌱 Сводки — тихий итог раз в неделю в разделе «Прогресс». Без пушей, без облака, без подписки
• Со временем приложение начнёт мягко замечать, если какая-то привычка просела, и предложит самый маленький вариант продолжения. Без давления, без чувства вины
• Удержи карточку «Сводки», чтобы скрыть её на неделю — или отключи тип полностью
• Новый переключатель в Settings: «Замечать спад и подводить итог недели» (включён по умолчанию)
• Исправлено: кнопка «минус» под count-привычками — расширена тап-зона до 44×44, тапы больше не «проваливаются» в кнопку +1
• Исправлено: поле комментария к привычке теперь доступно всегда, не привязано к галочке «выполнено» — текст и раньше сохранялся, просто UI его скрывал

---

## Promotional Text (170 chars max)

### English
A quiet weekly summary in Progress, plus gentle drift detection over time. No pushes, no cloud, no subscription. Plus tap-target and comment-field fixes.

### Russian
Тихий итог недели в Прогрессе и мягкое замечание спада со временем. Без пушей, без облака, без подписки. Плюс исправления тап-зоны и поля комментария.

---

## Review Notes (for Apple reviewer)

### English
This update adds a "Reflection" card in the Progress tab that surfaces gentle weekly summaries and habit-drift hints — all computed locally, no network, no account.

To test the weekly summary:
1. Open the app on a Sunday after 18:00 local time, or on Monday/Tuesday — the Reflection card should appear at the top of the Progress tab
2. The card text reflects how many days of the prior week had every habit completed (5 brackets: 7, 5–6, 3–4, 1–2, 0)
3. Press and hold the card → context menu with "Hide for a week" / "Don't show these"
4. Tap "Hide for a week" → card animates away, won't reappear until next week's bucket

To test drift detection (requires history):
1. The drift card requires at least 21 days of habit history with 8+ completions, so won't fire on a fresh install
2. With sufficient history, when a habit's recent gap exceeds the user's typical pattern (statistically: above the maximum-historical gap, not just the average), a drift card appears with a "smallest version" suggestion
3. The drift card will not fire if the user already completed the habit today

To test the Settings toggle:
1. Settings → "Notice drift and summarize the week" → toggle off
2. Open Progress tab → no Reflection card

To test the v0.5.5 fixes:
1. Create a count-based habit (e.g., 5 cups of water)
2. Tap to add 1, 2, 3 — the minus button now reliably decrements without accidentally adding via the parent card
3. Configure the habit with a numeric or text extended field
4. The extended panel is now visible regardless of whether the habit is marked done

Backward compatibility: schema unchanged, no migration. New UserDefaults keys (`lt_reflection_*`) created lazily.

The previous "coach" overlay in the daily greeting (v0.5.4) was removed — the new Reflection card covers the same signal more accurately and on a passive surface (you have to open the Progress tab to see it).

No new permissions. No server, no push, no account. No subscription.

Demo credentials: N/A (no login required)

### Russian
Это обновление добавляет карточку «Сводки» в раздел «Прогресс», которая показывает мягкий итог недели и (со временем) замечание спада привычки. Всё считается локально, без сети, без аккаунта.

Тестирование «Итога недели»:
1. Откройте приложение в воскресенье после 18:00, либо в понедельник/вторник — карточка «Сводки» появится в верхней части таба «Прогресс»
2. Текст карточки отражает количество полностью выполненных дней прошлой недели (5 категорий: 7, 5–6, 3–4, 1–2, 0)
3. Долгое нажатие на карточку → контекстное меню с «Скрыть на неделю» / «Не показывать такие»
4. Тап «Скрыть на неделю» → карточка исчезает, не появится до следующей недели

Тестирование замечания спада (требует истории):
1. Карточка спада требует минимум 21 день истории с 8+ выполнениями, на свежей установке не сработает
2. С достаточной историей, когда текущий разрыв превышает обычный паттерн пользователя (статистически: выше максимального исторического разрыва, не просто среднего), появляется карточка с предложением «самого маленького варианта»
3. Карточка спада не появится, если пользователь сегодня уже отметил привычку

Тестирование переключателя в Settings:
1. Settings → «Замечать спад и подводить итог недели» → выключить
2. Откройте таб «Прогресс» → карточки нет

Тестирование исправлений из v0.5.5:
1. Создайте count-привычку (например, 5 стаканов воды)
2. Тапайте, чтобы добавить 1, 2, 3 — кнопка «минус» теперь надёжно уменьшает счётчик без случайного инкремента через родительскую карточку
3. Сконфигурируйте привычку с numeric/text extended field
4. Расширенная панель теперь видна независимо от того, отмечена привычка как выполненная или нет

Обратная совместимость: schema не менялась, миграций нет. Новые UserDefaults ключи (`lt_reflection_*`) создаются лениво.

Прежний «coach»-блок в утреннем приветствии (v0.5.4) удалён — новая карточка «Сводки» покрывает тот же сигнал точнее и на passive поверхности (нужно самому открыть Прогресс, чтобы её увидеть).

Новых разрешений нет. Сервера нет, push нет, аккаунта нет. Подписки нет.

Demo credentials: N/A (логин не нужен)
