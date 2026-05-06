# Reflection — design spec (v0.6.0)

**Status:** draft, awaiting approval
**Date:** 2026-05-06
**Author:** Nikita (with Claude as collaborator)

## 1. Goal

Когда пользователь начинает выпадать из привычки или заканчивается неделя, приложение **тихо** замечает это в табе «Прогресс» — без пушей, бейджей и уговоров. Один компактный card-нативного вида, поддерживающий тон, без AI и без бэкенда.

**Что закрывает:** запрос подписчика Сергея — «приложение замечает спад дисциплины и предлагает мягкий вариант продолжения».
**Что не закрывает:** медицинские объяснения, персонализированный текст «как у друга-эксперта», push-напоминания, монетизация.

### 1.1 Scope split: v0.5.5 ≠ v0.6.0

В письме Сергея — два независимых пласта:

- **Стратегия / новая фича** → reflection card. Это **v0.6.0**, спек ниже.
- **Два бага в v0.5.4**: (a) кнопка «минус» — nested-button hit-test issue в `HabitToggleCard`; (b) гейт `if habitDone && habit.extendedField != nil` в `CheckInView.habitPage` скрывал extended-панель при снятой галочке. Оба — **v0.5.5 maintenance**, не часть этого спека. Фиксы уже сделаны в working tree, ждут release.

Гейт-баг (b) канонически объясняет все три симптома, описанные Сергеем (panel появляется только после галочки → текст «пропадает» при unchek → возвращается при ре-чеке = persisted data + UI gate). Удаление гейта закрывает все три.

## 2. Non-goals (явный список)

- Никаких LLM (ни локальных, ни облачных). На будущее — Apple Foundation Models в iOS 26+ как опциональный layer; в этой версии нет.
- Никакого backend, аккаунтов, аналитики наружу.
- Никаких push-уведомлений (даже опциональных — соблазн сорваться).
- Никакой телеметрии «показано/закрыто».
- Никаких медицинских/физиологических утверждений в копирайте.
- Никаких платных тиров.

## 3. Design principles (задают копирайт и UI)

Из ресёрча:

1. **Autonomy-supportive language** (Self-Determination Theory) — «можно / попробовать» вместо «надо / должен».
2. **Никогда не показывать долг** — никаких «ты пропустил», «не сдавайся», «не подведи».
3. **При спаде — уменьшать поведение, а не давить** (BJ Fogg). Drift-card всегда заканчивается **меньшим** вариантом, никогда «соберись».
4. **Идентичность важнее цифр** — обращаемся к тому, кем человек становится, а не к счёту.
5. **«Догонять не нужно»** — критическая фраза для нулевой недели; ровно она удерживает от удаления приложения.
6. **Краткость = уважение.** Один insight = одна короткая фраза. Card не лекция.
7. **Passive surface** — card живёт в Прогрессе; пользователь приходит сам, app не дёргает.

## 4. UX/UI

### 4.1 Расположение

Таб **Прогресс** → ровно между segment-контролом «Месяц / Год» и контентом (`MonthProgressView` / `YearProgressView`). При hide — место схлопывается без gap.

Card виден **только** на верхнем уровне (`level == .month || .year`, `navSource == .normal`) — на детальных экранах (week/day/analytics) скрыт.

### 4.2 Внешний вид

- Контейнер: `RoundedRectangle(cornerRadius: 12, style: .continuous)`, fill `Color(.secondarySystemGroupedBackground)`. **Без border, без shadow** — sibling по тону с остальными карточками Прогресса.
- Padding внутри: 16pt по всем сторонам. VStack spacing 6pt.
- Lead icon (опционально, 16pt SF Symbol, `.secondary` tint, leading): `wind` для drift, `chart.line.uptrend.xyaxis` для weekly. Без яркой подсветки.
- Line 1 — caption: `.font(.footnote).foregroundStyle(.secondary)` — тип («Эта неделя» / «Этой неделей»).
- Line 2 — основной текст: `.font(.subheadline).fontWeight(.medium)`, primary color, до 3 строк, без truncation.
- Line 3 (опционально) — inline-link на привычку: `.font(.footnote)` в системном зелёном, текст «Открыть «🏃 Утренний бег»». Нажатие → открывает `HabitDetailView` для этой привычки. Только в drift-card.
  - **Tap-target обязательно ≥ 44×44.** Footnote ≈ 13pt → высота строки ~16pt; обернуть в `Button` с `.padding(.vertical, 12).contentShape(Rectangle())`. Иначе повторяем баг кнопки «минус» из v0.5.4.
- Без кнопки X. Без CTA-кнопок. Без destructive-цветов. Без `!` нигде.
- Высота — content-driven (~80–110pt типично). Не фиксированная.

### 4.3 Анимация и появление

- Появление: `.transition(.opacity.combined(with: .move(edge: .top)))` + `.animation(.easeInOut(duration: 0.25))`. **Без spring/scale/bounce** — это не celebration.
- Скрытие при resolve (пользователь сделал привычку, drift пропал): анимация ровно та же, но с `.removed`.

### 4.4 Dismissal

Native iOS-pattern: **long-press → context menu** (как Photos Memories).

```
.contextMenu {
    Button("Скрыть на неделю", systemImage: "eye.slash") { ... }
    Button("Не показывать такие", systemImage: "minus.circle") { ... }
}
```

«Скрыть на неделю» — пишет `lt_reflection_seen_<id>` с датой; следующая сводка того же типа покажется через 7 дней.
«Не показывать такие» — пишет `lt_reflection_disabled_<type>` (drift или weekly); раздел в Settings позволит включить обратно.

Без X-кнопки. Tap по card — без действия (либо открывает related habit для drift).

**Discoverability hint (one-time):** при первом показе любого reflection card в жизни приложения — снизу под card на 3 секунды subtle подпись «Удержи, чтобы скрыть» (`.font(.caption2).foregroundStyle(.tertiary)`), затем сама исчезает. Состояние в `lt_reflection_hint_shown: Bool`. Без этого hint long-press не дискаверим — никто не догадается. Hint показывается ровно один раз за всю жизнь приложения.

### 4.5 Когда card НЕ показывается (rate limits)

- Уже виден другой reflection в этом дне → один card в день максимум.
- `lt_reflection_drift_seen_<habitId>` < 7 дней назад → не повторяем drift по той же привычке.
- `lt_reflection_weekly_seen` совпадает с текущей weekly-bucket → не повторяем weekly.
- Пользователь полностью отключил тип в настройках.
- Условие drift «само рассосалось» (пользователь сегодня отметил привычку) → card исчезает.

## 5. Reflection types (только два в v0.6.0)

### 5.1 Drift (приоритет 1)

**Что детектим:** конкретная привычка, которая раньше шла стабильно, начала проседать.

**Триггер (см. §6 для алгоритма):** возвращаем самую «свежую» drift среди активных привычек, у которой условие выполнено и cooldown пройден.

**Текст (RU/EN):**

| Контекст | RU | EN |
|---|---|---|
| Daily habit, 3-дневный gap | «Три тихих дня без «🏃 Утренний бег». Может, завтра — короткая, минут пять?» | «Three quiet days without «🏃 Morning run». Want to try a 5-minute version tomorrow?» |
| Daily habit, 4-7 дней gap | ««🏃 Утренний бег» молчит почти неделю. Самый маленький вариант — тоже считается.» | «It's been almost a week without «🏃 Morning run». The smallest version still counts.» |
| Weekly habit, ритм просел вдвое | «Прошлая неделя «🧘 Медитации» не сложилась. На этой — даже один раз будет да.» | «Last week didn't happen for «🧘 Meditation». This week, even one sit is a yes.» |

«🏃 Утренний бег» — placeholder, в коде `habit.emoji` + `habit.name` в кавычках-ёлочках. RU использует **«ты», без «!», без `всего`/`только`**.

«Может, попробовать минут N» — N подбирается так:
- если у привычки задан numeric `extendedField` с `step` — берём `step` (минимальный осмысленный кусок),
- иначе — fallback «короткая версия» / «самый маленький вариант».

### 5.2 Weekly summary (приоритет 2)

**Когда:** воскресенье 18:00 — вторник 23:59 локального времени, после завершения календарной недели. Bucket = ISO-неделя.

**Что показываем:** одну фразу про прошедшую неделю в зависимости от bucket.

| Кол-во полностью выполненных дней (из 7) | RU | EN |
|---|---|---|
| **7** | «Семь дней подряд. Так и складываются ритмы.» | «Seven days. That's how rhythms get built.» |
| **5–6** | «{N} дней за неделю. Из таких недель и складывается.» | «{N} days this week. That's the kind of week that adds up.» |
| **3–4** | «Неделя вышла неровной. {N} дней — уже что-то.» | «An uneven week. {N} days is something.» |
| **1–2** | «Неделя вышла рваной. Может, на следующей выбрать один день и защитить его?» | «A patchy week. Want to pick one day next week and protect it?» |
| **0** | «Жизнь бывает и такой. Догонять ничего не надо — просто то, что окажется по силам дальше.» | «Life happens in weeks like this too. No catch-up needed — just whatever feels possible next.» |

«Полностью выполненный день» = для каждой даты `d` в неделе берём `store.habitsExisted(from: d, to: d)` (привычки, которые **уже были созданы** к этой дате и не archived) и считаем день полным, если все эти привычки выполнены. Если на конкретный день привычек ещё не было — день не считается ни полным, ни пустым (исключаем из деления).

**Почему не `activeHabits`:** привычка, созданная в среду, не должна штрафовать понедельник-вторник. Иначе воскресный summary новосозданной привычки выдаст «4/7 дней» вместо честных «4/4». `habitsExisted(from:to:)` уже реализован в `AppStore.swift:543`, переиспользуем.

Если за всю неделю не было ни одной активной привычки или onboarding не пройден — weekly не показываем.

## 6. Drift-detection algorithm (rule-based, deterministic)

### 6.1 Eligibility gates (cheap, fail fast)

```
shouldEvaluateDrift(habit, today) -> Bool:
    if today - habit.createdAt < 21 days: return false
    completions = habit.completionsInLast(days: 60)
    if completions.count < 8: return false
    if today - lastDriftNudgeAt[habit.id] < 7 days: return false
    if completions.contains(today): return false
    return true
```

Цифры (`21d`, `8 completions`, `7d cooldown`) — из исследования: ниже Lally's curves нестабильны, MAD взрывается, и мы ловим false positives.

### 6.2 Daily-cadence путь (gap-based, MAD)

«Daily-cadence» = baseline-частота **≥ 5 раз в неделю** за последние 4 недели.

```
gaps = consecutiveCompletionGaps(completions)   // целые дни между датами галочек, gap=1 = «следующий день»
if gaps.count < 6: return false

med = median(gaps)
mad = median(|g - med| for g in gaps)
threshold = max(med + 3 * 1.4826 * mad, med + 2)

currentGap = daysSince(completions.last)
if currentGap < 2: return false      // одна пропущенная — это шум, не сигнал (Lally)
if currentGap > 10: return false     // привычка уже не drift, а gone — давить = стыдить
if currentGap < threshold: return false

return true
```

`med + 2` floor — для очень плотных привычек (med=1, MAD=0); опирается на «never miss twice» правило Clear.
`1.4826 * MAD` — стандартная конверсия MAD→σ; `3σ` ≈ 99.7-перцентиль *поведения этого пользователя*.
`<= 10` потолок — медиана decay-плато по Diefenbacher 2024 ≈ 9–10 дней; дальше — это уже не drift.

### 6.3 Weekly-cadence путь (rate-based)

«Weekly-cadence» = baseline-частота **от 1 до < 5 раз в неделю** (граница 5 строго на стороне daily).

```
baselineRate = completionsPerWeek over [today-56 .. today-14]
recentRate   = completionsPerWeek over [today-14 .. today]
if baselineRate < 1: return false
if recentRate <= 0.5 * baselineRate AND recentRate < baselineRate - 1: return true
return false
```

Двойное условие защищает от шума на низких частотах.

### 6.4 Приоритет, если несколько drift-кандидатов

Сортируем по `currentGap / threshold` desc — самая «выпавшая» побеждает. Один card за раз.

## 7. Persisted state

Всё в `UserDefaults`. Никаких новых файлов в documents.

| Key | Type | Назначение |
|---|---|---|
| `lt_reflection_drift_seen_<habitId>` | String (ISO date) | Последний показ drift для привычки |
| `lt_reflection_weekly_seen` | String (ISO week, e.g. "2026-W18") | Bucket последнего показа weekly |
| `lt_reflection_drift_disabled` | Bool | «Не показывать такие» для drift |
| `lt_reflection_weekly_disabled` | Bool | «Не показывать такие» для weekly |
| `lt_reflection_today_shown` | String (ISO date) | Дата последнего показа любого card |
| `lt_reflection_hint_shown` | Bool | One-time long-press hint показан |
| `lt_reflection_enabled` | Bool (default true) | Глобальный master-toggle из Settings (см. §8.5) |

Все ключи создаются ленивым доступом. **Schema version не меняется**, миграция не требуется.

## 8. Architecture

### 8.1 New files

- `lifeTrackIos/LifeTrack/Reflection/ReflectionEngine.swift` — pure compute. `func currentReflection(asOf: Date) -> Reflection?`. Без побочных эффектов, читает только `AppStore`-данные.
- `lifeTrackIos/LifeTrack/Reflection/ReflectionCard.swift` — view, кладётся в `ProgressRootView`.
- `lifeTrackIos/LifeTrack/Reflection/ReflectionCopy.swift` — все шаблоны RU/EN, через `L10n`-стиль; единое место для редактуры копирайта.

Размещаем в подпапке, чтобы 6 новых файлов не размывали корень `LifeTrack/`.

### 8.2 Types

```swift
enum Reflection: Equatable {
    case drift(habit: Habit, days: Int, suggestion: DriftSuggestion)
    case weekly(daysFullyDone: Int, weekKey: String)
}

enum DriftSuggestion {
    case smallerNumeric(value: Double, unit: String)   // "минут пять"
    case smallestVariant                                // "самый маленький вариант"
}
```

### 8.3 Engine surface

```swift
struct ReflectionEngine {
    let store: AppStore
    let now: Date

    func currentReflection() -> Reflection? {
        if isShownToday() { return nil }
        if let drift = computeDrift() { return drift }
        if let weekly = computeWeeklySummary() { return weekly }
        return nil
    }

    // Внутренние:
    private func computeDrift() -> Reflection? { ... }
    private func computeWeeklySummary() -> Reflection? { ... }
    private func isShownToday() -> Bool { ... }
}
```

`store` передаём через конструктор, чтобы юнит-тесты могли мокать состояние без singleton.

### 8.4 Integration

В `ProgressRootView.body` — между `headerSection` и контентом:

```swift
if level == .month || level == .year, navSource == .normal,
   let reflection = ReflectionEngine(store: store, now: Date()).currentReflection() {
    ReflectionCard(reflection: reflection, store: store)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .transition(.opacity.combined(with: .move(edge: .top)))
}
```

Нажатие на link «Открыть привычку» в drift-card → `detailHabit = habit; detailNoteDate = Date()` (re-use существующего sheet).

### 8.5 Settings

В `SettingsView` — **один** master-toggle:
- «Замечать спад и подводить итог недели» (default ON)
- Sub-text: «Один тихий блок в разделе Прогресс. Без пушей.»

Хранится в `lt_reflection_enabled`. Один toggle вместо двух — это passive feature на passive surface, два рычага — overkill.

«Не показывать такие» в long-press menu остаётся per-type (drift / weekly) — это runtime-affordance отдельного назначения, пишет `lt_reflection_drift_disabled` / `lt_reflection_weekly_disabled`. Если пользователь отключил оба per-type — master в Settings сохраняет состояние ON (это два разных контроля).

## 9. Localization

Все строки — в `L10n.swift`, RU/EN. Раздел `// MARK: - Reflection`.

Ключи именуются `reflection.drift.dailyShort`, `reflection.weekly.full`, etc. — иерархичные имена для будущих расширений.

## 10. Tests (минимум)

Юнит-тесты на `ReflectionEngine` — самая критичная часть, тут легко словить false positive.

- `testDrift_brandNewHabit_returnsNil` — < 21 дня, < 8 completions
- `testDrift_dailyHabit_threeDayGap_fires`
- `testDrift_dailyHabit_oneDayGap_doesNotFire` (Lally noise)
- `testDrift_dailyHabit_elevenDayGap_doesNotFire` (потолок)
- `testDrift_weekendSkipper_doesNotFire` — MAD должен поглотить
- `testDrift_cooldown_sevenDays_blocks`
- `testDrift_archivedHabit_doesNotFire` — `deletedAt != nil` отсекаем сразу
- `testWeekly_zeroDays_returnsZeroBucket`
- `testWeekly_sevenDays_returnsFullBucket`
- `testWeekly_outsideWindow_returnsNil` (среда → не показываем weekly)
- `testWeekly_habitCreatedMidWeek_doesNotPenaliseDays` — привычка создана в среду, выполнена все 4 дня (ср-вс) → bucket = «полная неделя» (не «4/7»)
- `testReflection_noActiveHabits_returnsNil` — после онбординга, `activeHabits` пуст
- `testPriority_driftBeatsWeekly_whenBoth`
- `testTodayAlreadyShown_returnsNil`
- `testMasterToggleOff_returnsNil` — `lt_reflection_enabled = false`

Используем `XCTest` стандартный, никаких новых зависимостей.

## 11. Out of scope (повторно, чтобы зафиксировать)

- Monthly summary (можно в v0.6.x при запросе)
- Streak milestones в card (уже есть в celebration overlay чек-ина)
- Quiet hours / time-of-day gating (overhead против пользы для v1)
- ML-моделирование индивидуальных порогов
- Multi-habit correlation («все привычки просели → жизненная ситуация») — отдельная фича life-state detection
- Apple Foundation Models layer (когда iOS 26+ станет floor — v0.7+ кандидат)
- Per-habit пользовательский pause/vacation mode

## 12. Migration / data compatibility

Никаких изменений в `Habit`, `CheckinExtra`, `ExtendedFieldConfig`. Новые `UserDefaults`-ключи создаются ленивым доступом. **Schema version не меняется.**

## 13. Coach в DailyGreetingView — deprecate

**Конфликт.** В `AppStore.swift:471` уже есть `coachMessage()` / `coachEmoji()` / `longestMissedHabit()` (с порогами 1/2/4/7 missed days), `DailyGreetingView` их показывает overlay'ем при старте, если `missedDaysCount() > 0`. Это **вторая поверхность для того же сигнала** «пользователь пропускает». После v0.6.0 будут две: greeting overlay (push-like, дёргает при запуске) + reflection card (passive, в Прогрессе).

Это противоречит §3 принципа «pasive surface». Greeting именно дёргает — overlay перекрывает чек-ин. Раз новый ReflectionCard покрывает кейс лучше (per-habit MAD, конкретное предложение меньшего шага, не реагирует слепо на «N missed days подряд»), старый coach — лишний.

**Решение (выбираем A, как в ревью):**

- В `DailyGreetingView` убрать coach-блок: убрать использование `store.coachMessage()`, `store.coachEmoji()`, `store.longestMissedHabit()`, `L10n.coachHabitNudge(...)`, всю условную ветку по `coach != nil`.
- Greeting остаётся, но без coaching: только приветствие + count «N привычек ждут» + опционально «вчера: 3/5» (как уже есть в данных).
- В `AppStore.swift` — функции `coachMessage()`, `coachEmoji()`, `longestMissedHabit()`, **и `missedDaysCount()`** удалить. Проверено grep'ом: `missedDaysCount()` зовут только `coachMessage` и `coachEmoji`, без внешних потребителей — становится dead code.
- В `L10n.swift` — строки `coachMissed1/2/4/7`, `coachHabitNudge` удалить.

**Что нельзя забыть:** удалить **все** вызовы из view-tree. Перед merge — `grep -r 'coach' lifeTrackIos/` должен вернуть ноль hit'ов в исходниках (кроме, возможно, `// removed` комментариев — их тоже не оставлять).

## 14. LLM roadmap — честный ответ Сергею

Сергей предлагает локальную или серверную нейронку. Спек отвечает «нет в v0.6.0», но это не отказ навсегда — это последовательность.

| Версия | Подход | Что меняется |
|---|---|---|
| v0.6.0 | Rule-based reflection (этот спек) | `ReflectionEngine` как pure compute. Деterministic база. |
| v0.7+ (опционально) | **Apple Foundation Models** layer | Тот же `ReflectionEngine` выдаёт `Reflection`-структуру; FoundationModels paraphrase-ит шаблон под контекст пользователя. **Локально, бесплатно, 0 MB к app-size, privacy by design** (модель в системе). Без подписки, без backend, без аккаунта. |
| Никогда | Server-side LLM с подпиской | Противоречит §1: без backend, без аккаунтов. Privacy + zero-onboarding-friction — ключевая ценность LifeTrack. |

⚠️ **Verify before promising:** до того как обещать v0.7 в release-notes / переписке с Сергеем — подтвердить документацией Apple, что Foundation Models on-device API в iOS 26 поддерживает summarization/paraphrase use case с нашим объёмом данных (несколько habit-имён + статистика). Если окажется, что API только для классификации/генерации с system prompt — переоценить.

Этот roadmap-кусок попадает в release-notes v0.6.0 как намёк («первый шаг к мягкому замечающему помощнику — без облака, без подписки») и в личный ответ Сергею.

## 15. Rollout & release-notes

**Реалити-чек.** Eligibility gate `21 day + 8 completions` означает: в первые 3 недели после релиза v0.6.0 у действующих пользователей drift-card **не выстрелит**. Покажется только weekly summary (по воскресеньям-вторникам). Это правильный trade-off (false positives дороже false negatives), но release-notes должны это учитывать — иначе early-adopters прочитают «приложение замечает спад», ткнут, не увидят и решат, что фича сломана.

**Точная формулировка для release-notes (RU):**

> 🌱 Сводки.
> Раз в неделю — тихий итог в разделе Прогресс. Со временем приложение начнёт мягко замечать, если какая-то привычка просела, и предложит самый маленький вариант продолжения.
> Без пушей, без облака, без подписки. Удержи карточку, чтобы её скрыть.

Ключ: «со временем» — управляет ожиданиями. «Удержи карточку» — заранее обучает long-press-паттерну ещё до того, как пользователь увидит in-app hint.

## 16. Sources / research

- [Lally et al., 2010 — How are habits formed (EJSP)](https://onlinelibrary.wiley.com/doi/10.1002/ejsp.674)
- [Diefenbacher et al., 2024 — Temporal trajectories of habit decay (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC11635905/)
- [Should or could? Autonomy-supportive language (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC6393822/)
- [BJ Fogg — Tiny Habits](https://tinyhabits.com/)
- [James Clear — Never Miss Twice](https://bookniblits.substack.com/p/atomic-habits-never-miss-twice-the)
- [Apple Health Summary guide](https://support.apple.com/guide/iphone/view-your-health-data-iphe3d379c32/ios)
- [Photos Memories controls (long-press dismiss pattern)](https://support.apple.com/en-al/guide/iphone/iph10a9dd2a1/ios)
- [Streaks 3 review — MacStories](https://www.macstories.net/reviews/streaks-3-review/)
- [Duolingo Needs to Chill (Medium)](https://debugger.medium.com/duolingo-needs-to-chill-8f1832745ca0)
- [InfluxData — MAD for anomaly detection](https://www.influxdata.com/blog/anomaly-detection-with-median-absolute-deviation/)
