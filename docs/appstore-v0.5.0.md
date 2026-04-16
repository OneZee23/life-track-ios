# App Store Connect — v0.5.0

## What's New (Release Notes)

### English
- Sleep tracking: automatically logs sleep duration from Apple Health, displayed as hours and minutes
- Step counting: syncs exact step count from Apple Health throughout the day
- Workout distance: automatically records kilometers for cycling, running, walking, swimming, and hiking
- Habit detail card: long press any habit to see bar chart, average/min/max stats, and full history log with period selector (7d/30d/90d/Year)
- Simplified habit editor: quick presets for numeric tracking (Time, Count, Money) replace complex settings
- Visual refresh: all progress screens redesigned with card shadows, pill-shaped progress bars, larger charts, and improved typography

### Russian
- Трекинг сна: автоматически записывает длительность сна из Apple Health, отображается в часах и минутах
- Подсчёт шагов: синхронизирует точное количество шагов из Apple Health в течение дня
- Дистанция тренировок: автоматически записывает километры для велосипеда, бега, ходьбы, плавания и хайкинга
- Карточка привычки: долгий тап на привычку — график, статистика avg/min/max и полный лог значений с выбором периода (7д/30д/90д/Год)
- Упрощённый редактор: быстрые пресеты для числового трекинга (Время, Кол-во, Деньги) вместо сложных настроек
- Визуальное обновление: все экраны статистики переработаны — карточки с тенями, pill-shaped прогресс-бары, увеличенные графики, улучшенная типографика

---

## App Description

### English
LifeTrack — the simplest habit tracker. Did you do it or not?

Every habit tracker asks too much. Sliders, ratings, timers, notes. LifeTrack asks one thing: tap = done. Five habits, five taps, five seconds. Watch your GitHub-style heatmap grow green.

KEY FEATURES:
- One-tap check-in — no sliders, no overthinking
- Apple Health sync — sleep, steps, workout distance tracked automatically
- Detailed analytics — bar charts, streaks, completion rates, per-habit history
- Year heatmap — see your consistency at a glance
- Extended tracking — optional numeric, comment, or rating data per habit
- Yesterday/Today switcher — forgot to check in? No problem
- Smart presets — Time, Count, Money for quick numeric setup
- Dark mode — system, light, or dark theme
- Two languages — English and Russian, switch instantly
- No account, no cloud — your data stays on your device

Built for people who want to build habits, not manage an app.

### Russian
LifeTrack — самый простой трекер привычек. Сделал или нет?

Каждый трекер привычек требует слишком много. Слайдеры, оценки, таймеры, заметки. LifeTrack спрашивает одно: тап = сделано. Пять привычек, пять тапов, пять секунд. Смотри, как твоя тепловая карта зеленеет.

КЛЮЧЕВЫЕ ВОЗМОЖНОСТИ:
- Чекин в один тап — без слайдеров и лишних раздумий
- Синхронизация с Apple Health — сон, шаги, дистанция тренировок автоматически
- Детальная аналитика — графики, стрики, процент выполнения, история по каждой привычке
- Тепловая карта за год — наглядная картина твоей стабильности
- Расширенный трекинг — числовые данные, комментарии или оценки по желанию
- Переключатель Вчера/Сегодня — забыл отметить? Не проблема
- Умные пресеты — Время, Кол-во, Деньги для быстрой настройки
- Тёмная тема — системная, светлая или тёмная
- Два языка — русский и английский, переключение мгновенно
- Без аккаунта, без облака — данные остаются на устройстве

Создано для тех, кто хочет выработать привычки, а не управлять приложением.

---

## Keywords (100 chars max)

### English
habit,tracker,health,sleep,steps,heatmap,streak,checkin,routine,daily,wellness,fitness,simple

### Russian
привычки,трекер,здоровье,сон,шаги,привычка,стрик,чекин,режим,ежедневно,фитнес,простой

---

## Promotional Text (170 chars max)

### English
Now with Apple Health sync! Sleep, steps, and workout distance tracked automatically. New habit detail cards with charts and statistics.

### Russian
Теперь с синхронизацией Apple Health! Сон, шаги и дистанция тренировок — автоматически. Новые карточки привычек с графиками и статистикой.

---

## Review Notes (for Apple reviewer)

### English
This update adds Apple Health integration for sleep, steps, and workout distance tracking.

To test HealthKit features:
1. Open the app → Habits tab → tap any habit → Edit
2. Toggle "Apple Health" ON
3. Choose sync type: Workout / Sleep / Steps
4. For Workout: select a workout type (e.g., Cycling). The app reads workouts from Apple Health and auto-checks the habit if a matching workout is found for today/yesterday
5. For Sleep: the app reads sleep analysis data and records total sleep duration in minutes
6. For Steps: the app reads cumulative step count and updates it each time the app comes to foreground

New Habit Detail Card:
1. On the Check-in screen, long-press any habit card
2. A detail sheet appears with: stats (average/min/max or streak/best/completion), a bar chart with period selector (7d/30d/90d/Year), and a full log of historical values

The app only READS data from Apple Health (workouts, sleep analysis, step count). It does NOT write any data to Apple Health.

No user account required. All data is stored locally on device using UserDefaults.

Demo credentials: N/A (no login required)

### Russian
Это обновление добавляет интеграцию с Apple Health для трекинга сна, шагов и дистанции тренировок.

Для тестирования HealthKit:
1. Откройте приложение → вкладка Habits → тапните привычку → Edit
2. Включите "Apple Health"
3. Выберите тип синхронизации: Тренировка / Сон / Шаги
4. Для тренировки: выберите тип (напр. Cycling). Приложение читает тренировки из Apple Health и автоматически отмечает привычку
5. Для сна: читает данные анализа сна и записывает общую длительность в минутах
6. Для шагов: читает суммарное количество шагов, обновляет при каждом открытии

Новая карточка привычки:
1. На экране Check-in сделайте долгий тап на карточку привычки
2. Появится экран с: статистикой (среднее/мин/макс), графиком с выбором периода (7д/30д/90д/Год) и полным логом

Приложение только ЧИТАЕТ данные из Apple Health. НЕ записывает ничего.

Аккаунт не требуется. Все данные хранятся локально.

---

## Support URL
https://t.me/onezee123

## Privacy Policy URL
https://onezee23.github.io/life-track-ios/docs/privacy-policy.html

## Category
Primary: Health & Fitness
Secondary: Lifestyle

## Age Rating
4+ (No objectionable content)

## Copyright
2026 onezee.co
