# LifeTrack iOS — SwiftUI

Нативное iOS-приложение LifeTrack на SwiftUI. Минималистичный трекер привычек.

## Как открыть в Xcode

### Шаг 1 — Создать новый проект

1. Открой **Xcode** → **File → New → Project**
2. Выбери **iOS → App**
3. Настройки:
   - **Product Name:** `LifeTrack`
   - **Team:** выбери свой Apple Developer аккаунт
   - **Bundle Identifier:** `co.onezee.lifetrack-native`
   - **Interface:** `SwiftUI`
   - **Language:** `Swift`
   - Убери галочку **Include Tests**
4. Сохрани проект **рядом** с этой папкой или куда удобно

### Шаг 2 — Заменить файлы

1. В Xcode удали `ContentView.swift` (Move to Trash)
2. **Drag & Drop** все `.swift` файлы из папки `lifeTrackIos/LifeTrack/` в Xcode:
   - `Models.swift`
   - `AppStore.swift`
   - `DateUtils.swift`
   - `LifeTrackApp.swift`
   - `ContentView.swift`
   - `CheckInView.swift`
   - `HabitToggleCard.swift`
   - `ProgressRootView.swift`
   - `YearProgressView.swift`
   - `MonthProgressView.swift`
   - `WeekProgressView.swift`
   - `DayProgressView.swift`
   - `HabitsView.swift`
   - `SettingsView.swift`
3. При добавлении выбери **Copy items if needed** ✓ и **Add to target: LifeTrack** ✓

### Шаг 3 — Запустить на симуляторе

1. Выбери симулятор: **iPhone 16 Pro** (или любой другой)
2. Нажми **⌘+R** (Run)

Приложение запустится за ~10 секунд на первом билде.

---

## Структура файлов

```
LifeTrack/
├── LifeTrackApp.swift          # @main точка входа
├── ContentView.swift           # TabView (3 таба)
├── Models.swift                # Habit, DayStatus
├── AppStore.swift              # ObservableObject, UserDefaults persistence
├── DateUtils.swift             # Дата-хелперы, русская локализация
│
├── CheckInView.swift           # Экран чек-ина (главный)
├── HabitToggleCard.swift       # Карточка-переключатель с spring-анимацией
│
├── ProgressRootView.swift      # Контейнер прогресса + навигация + фильтры
├── YearProgressView.swift      # Годовой вид (12 мини-heatmap)
├── MonthProgressView.swift     # Месячный календарь + streaks
├── WeekProgressView.swift      # Недельный вид + бары по привычкам
├── DayProgressView.swift       # Детальный вид дня
│
├── HabitsView.swift            # CRUD привычек + reorder
└── SettingsView.swift          # Настройки (тема, о проекте, ссылки)
```

---

## Что реализовано

| Фича | Статус |
|------|--------|
| Бинарный чек-ин за вчера | ✅ |
| Карточка-переключатель с spring-анимацией | ✅ |
| Haptic feedback при тапе | ✅ |
| Прогресс-бар (X/N) | ✅ |
| Экран «День записан» с саммари | ✅ |
| Годовой heatmap (12 мини-карт) | ✅ |
| Месячный календарь + streaks | ✅ |
| Недельный вид по привычкам | ✅ |
| Дневной вид | ✅ |
| Drill-down навигация Год→Месяц→Неделя→День | ✅ |
| Фильтр по привычке (чипы) | ✅ |
| Пульсирующая рамка «Сегодня» | ✅ |
| CRUD привычек | ✅ |
| Reorder (drag & drop в List) | ✅ |
| Soft-delete (сохранение истории) | ✅ |
| Светлая / тёмная тема | ✅ |
| Настройки (sheet) | ✅ |
| UserDefaults persistence (JSON) | ✅ |
| 5 дефолтных привычек при первом запуске | ✅ |
| Русская локализация (склонения: день/дня/дней) | ✅ |

---

## Технический стек

| Компонент | Технология |
|-----------|-----------|
| UI | SwiftUI |
| State | `@StateObject` + `ObservableObject` |
| Хранение | `UserDefaults` + JSON (Codable) |
| Анимации | SwiftUI `.spring()`, `withAnimation` |
| Haptics | `UIImpactFeedbackGenerator` |
| Min iOS | 16.0+ |

---

> LifeTrack iOS — нативный SwiftUI трекер привычек.
