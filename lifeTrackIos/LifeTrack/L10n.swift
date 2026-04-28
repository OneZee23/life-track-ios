import Foundation

enum L10n {
    // Mutable flag — updated by AppStore when language changes
    static var isRu: Bool = {
        Locale.current.language.languageCode?.identifier == "ru"
    }()

    /// Russian plural form: picks one/few/many based on mod10/mod100 rules.
    static func ruPlural(_ n: Int, one: String, few: String, many: String) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return one }
        if mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14) { return few }
        return many
    }

    // MARK: - App

    static var appTitle: String { "LifeTrack" }

    // MARK: - Tabs

    static var tabCheckIn:  String { isRu ? "Чек-ин"   : "Check-in" }
    static var tabProgress: String { isRu ? "Прогресс"  : "Progress" }
    static var tabHabits:   String { isRu ? "Привычки"  : "Habits" }

    // MARK: - Check-in

    static var checkIn:         String { isRu ? "Чек-ин"  : "Check-in" }
    static var yesterdayPrefix: String { isRu ? "Вчера"   : "Yesterday" }

    // MARK: - Habits

    static var habits:    String { isRu ? "Привычки"           : "Habits" }
    static var done:      String { isRu ? "Готово"              : "Done" }
    static var edit:      String { isRu ? "Изменить"            : "Edit" }
    static var addHabit:  String { isRu ? "Добавить привычку"   : "Add habit" }
    static var maxHabits: String { isRu ? "Максимум 10 привычек" : "Maximum 10 habits" }
    static var newHabit:  String { isRu ? "Новая привычка"      : "New habit" }
    static var editHabit: String { isRu ? "Редактировать"       : "Edit habit" }
    static var name:      String { isRu ? "Название"            : "Name" }
    static var cancel:    String { isRu ? "Отмена"              : "Cancel" }
    static var add:       String { isRu ? "Добавить"            : "Add" }
    static var save:      String { isRu ? "Сохранить"           : "Save" }
    static var delete:    String { isRu ? "Удалить"             : "Delete" }

    static func habitsCount(_ n: Int) -> String {
        isRu ? "\(n) из \(AppConstants.maxHabits)" : "\(n) of \(AppConstants.maxHabits)"
    }

    // MARK: - Settings

    static var settings:         String { isRu ? "Настройки"    : "Settings" }
    static var appearance:       String { isRu ? "Внешний вид"  : "Appearance" }
    static var themeAuto:        String { isRu ? "Системная"    : "System" }
    static var themeLight:       String { isRu ? "Светлая"      : "Light" }
    static var themeDark:        String { isRu ? "Тёмная"       : "Dark" }
    static var language:         String { isRu ? "Язык"         : "Language" }
    static var languageAuto:     String { isRu ? "Системный"    : "System" }
    static var aboutProject:     String { isRu ? "О проекте"    : "About" }
    static var feedback:         String { isRu ? "Обратная связь" : "Feedback" }
    static var writeAuthor:      String { isRu ? "Написать автору" : "Contact author" }
    static var bugsIdeas:        String { isRu ? "Баги, идеи, предложения" : "Bugs, ideas, suggestions" }
    static var links:            String { isRu ? "Ссылки"       : "Links" }
    static var telegramChannel:  String { isRu ? "Telegram-канал" : "Telegram channel" }
    static var telegramSubtitle: String { isRu ? "Разработка LifeTrack в реальном времени" : "LifeTrack development in real time" }
    static var youtubeSubtitle:  String { isRu ? "Канал автора"  : "Author's channel" }
    static var githubSubtitle:   String { isRu ? "Открытый исходный код" : "Open-source project" }
    static var privacyPolicy:    String { isRu ? "Политика конфиденциальности" : "Privacy Policy" }
    static var version:          String { isRu ? "Версия"       : "Version" }

    static var aboutDescription: String {
        isRu
        ? "LifeTrack — минималистичный трекер привычек. Отмечай свой день за 5 секунд, смотри прогресс на тепловой карте. Без оценок, без стресса — просто отмечай свой путь."
        : "LifeTrack is a minimalist habit tracker. Log your day in 5 seconds, see your progress on a heat map. No ratings, no stress — just track your journey."
    }

    static var aboutMVP: String {
        isRu
        ? "Это MVP — приложение создаётся открыто, вместе с сообществом. Весь процесс в Telegram-канале."
        : "This is an MVP — the app is being built openly, with the community. Follow the process on Telegram."
    }

    static var aboutAuthor: String {
        isRu
        ? "Автор — OneZee, инди-разработчик."
        : "Made by OneZee, indie developer."
    }

    static var footerMVP: String {
        isRu
        ? "LifeTrack Native MVP — сделано с душой ♥"
        : "LifeTrack Native MVP — made with love ♥"
    }

    // MARK: - Progress

    static var progress: String { isRu ? "Прогресс" : "Progress" }
    static var month:    String { isRu ? "Месяц"    : "Month" }
    static var year:     String { isRu ? "Год"      : "Year" }
    static var week:     String { isRu ? "Неделя"   : "Week" }
    static var all:      String { isRu ? "Все"      : "All" }

    // MARK: - Day progress

    static var awaitingCheckIn: String { isRu ? "Ждёт тебя"        : "Ready for you" }
    static var allDone:         String { isRu ? "Все выполнено!"    : "All done!" }
    static var partial:         String { isRu ? "Есть прогресс!"    : "Making progress!" }
    static var notDone:         String { isRu ? "Пауза"             : "Rest day" }

    // MARK: - Month progress

    static var bestStreak:    String { isRu ? "Лучшая серия"  : "Best streak" }
    static var currentStreak: String { isRu ? "Текущая серия"  : "Current streak" }

    // MARK: - Week progress

    static var weekTotal: String { isRu ? "Итог недели" : "Week total" }

    // MARK: - Year progress

    static var completed: String { isRu ? "Выполнено" : "Completed" }
    static var dayOfYear: String { isRu ? "День"      : "Day" }
    static var perfect:   String { isRu ? "Идеальных" : "Perfect" }
    static var missed:    String { isRu ? "Перерыв"   : "Break" }
    static var today:     String { isRu ? "Сегодня"   : "Today" }
    static var less:      String { isRu ? "Меньше"    : "Less" }
    static var more:      String { isRu ? "Больше"    : "More" }

    static var hintDayOfYear:  String { isRu ? "Текущий день года"  : "Current day of year" }
    static var hintMissedDays: String { isRu ? "Дни отдыха"        : "Rest days" }
    static var hintTotalDays:  String { isRu ? "Всего дней в году" : "Total days in year" }
    static var totalDays:      String { isRu ? "Всего"             : "Total" }
    static var hintCompleted: String { isRu ? "Дни с выполнением"     : "Days with progress" }
    static var hintPerfect:   String { isRu ? "Дни на 100%"           : "Days at 100%" }

    // MARK: - Year analytics

    static var detailedAnalytics: String { isRu ? "Подробная аналитика" : "Detailed analytics" }
    static var completionRate:    String { isRu ? "Процент выполнения"  : "Completion rate" }
    static var monthlyBreakdown:  String { isRu ? "По месяцам"          : "By month" }
    static var weeklyBreakdown:   String { isRu ? "По неделям"          : "By week" }
    static var habitActivity:     String { isRu ? "Активность по привычкам" : "Activity by habit" }

    static func daysOf(_ done: Int, _ total: Int) -> String {
        isRu ? "\(done) из \(total) \(pluralDays(total))" : "\(done) of \(total) \(pluralDays(total))"
    }

    static func checkinsOf(_ done: Int, _ total: Int) -> String {
        isRu ? "\(done) из \(total) отметок" : "\(done) of \(total) check-ins"
    }

    // MARK: - Celebration

    static var inARow: String { isRu ? "подряд!" : "streak!" }

    static func randomCongrats() -> String {
        let options: [String] = isRu
            ? ["🎉 Все выполнено!", "💪 Отличная работа!", "⭐ Так держать!", "🏆 Молодец!", "✨ День закрыт!"]
            : ["🎉 All done!", "💪 Great work!", "⭐ Keep it up!", "🏆 Well done!", "✨ Day complete!"]
        return options.randomElement() ?? options[0]
    }

    // MARK: - Date arrays

    static var monthsFull: [String] {
        isRu
        ? ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
           "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
        : ["January", "February", "March", "April", "May", "June",
           "July", "August", "September", "October", "November", "December"]
    }

    static var monthsShort: [String] {
        isRu
        ? ["Янв", "Фев", "Мар", "Апр", "Май", "Июн",
           "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"]
        : ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    }

    static var monthsGenitive: [String] {
        isRu
        ? ["января", "февраля", "марта", "апреля", "мая", "июня",
           "июля", "августа", "сентября", "октября", "ноября", "декабря"]
        : ["January", "February", "March", "April", "May", "June",
           "July", "August", "September", "October", "November", "December"]
    }

    static var weekdaysFull: [String] {
        isRu
        ? ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
        : ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    }

    static var weekdaysShort: [String] {
        isRu
        ? ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }

    // MARK: - Pluralization

    static func pluralDays(_ n: Int) -> String {
        isRu ? ruPlural(n, one: "день", few: "дня", many: "дней")
             : (n == 1 ? "day" : "days")
    }

    // MARK: - Date formatting

    static func dateLabel(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let monthIdx = Calendar.current.component(.month, from: date) - 1
        return "\(day) \(monthsShort[monthIdx])"
    }

    static func dayDateLabel(date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let monthStr = monthsGenitive[Calendar.current.component(.month, from: date) - 1]
        let yearStr = String(Calendar.current.component(.year, from: date))
        if isRu {
            return "\(day) \(monthStr) \(yearStr)"
        } else {
            return "\(monthStr) \(day), \(yearStr)"
        }
    }

    // MARK: - Notifications

    static var reminders:       String { isRu ? "Напоминания"           : "Reminders" }
    static var reminderToggle:  String { isRu ? "Ежедневное напоминание" : "Daily reminder" }
    static var reminderTime:    String { isRu ? "Время"                 : "Time" }
    static var reminderFooter:  String { isRu ? "Одно мягкое напоминание в день — без спама" : "One gentle reminder per day — no spam" }

    static func randomReminder() -> String {
        let options: [String] = isRu
            ? ["Привет! Самое время отметить свой день",
               "Твои привычки ждут тебя",
               "5 секунд — и день записан",
               "Зайди отметить свой прогресс",
               "Пора заглянуть в LifeTrack"]
            : ["Hey! Time to log your day",
               "Your habits are waiting for you",
               "5 seconds — and your day is logged",
               "Check in and track your progress",
               "Time to visit LifeTrack"]
        return options.randomElement() ?? options[0]
    }

    // MARK: - Habit Reminders

    static var habitReminder:         String { isRu ? "Напоминания"   : "Reminders" }
    static var habitReminderFrom:     String { isRu ? "С"             : "From" }
    static var habitReminderTo:       String { isRu ? "До"            : "To" }
    static var habitReminderInterval: String { isRu ? "Интервал"      : "Interval" }
    static var habitReminderDays:     String { isRu ? "Дни"           : "Days" }
    static var habitReminderEvery1h:  String { isRu ? "1ч"            : "1h" }
    static var habitReminderEvery2h:  String { isRu ? "2ч"            : "2h" }
    static var habitReminderEvery3h:  String { isRu ? "3ч"            : "3h" }
    static var habitReminderWeekdays: String { isRu ? "Будни"         : "Weekdays" }
    static var habitReminderAllDays:  String { isRu ? "Каждый день"   : "Every day" }
    static var habitReminderCustomDays: String { isRu ? "Свои дни"    : "Custom" }
    static var habitReminderDenied:   String { isRu ? "Разрешите уведомления в Настройках iPhone" : "Enable notifications in iPhone Settings" }

    static func habitReminderBody(_ name: String) -> String {
        isRu ? "Время отметить «\(name)»" : "Time to check in «\(name)»"
    }

    static func habitReminderCount(_ n: Int) -> String {
        let word = isRu
            ? ruPlural(n, one: "напоминание", few: "напоминания", many: "напоминаний")
            : (n == 1 ? "reminder" : "reminders")
        return isRu ? "\(n) \(word) в неделю" : "\(n) \(word) per week"
    }

    // MARK: - Daily Target

    static var dailyTargetToggleLabel: String {
        isRu ? "Несколько раз в день" : "Multiple times per day"
    }

    static var habitDailyTargetLabel: String { isRu ? "Цель в день" : "Daily target" }

    static func habitDailyTargetValue(_ n: Int) -> String {
        let word = isRu
            ? ruPlural(n, one: "раз", few: "раза", many: "раз")
            : (n == 1 ? "time" : "times")
        return "\(n) \(word)"
    }

    // MARK: - Custom Emoji

    static var customEmojiTitle: String { isRu ? "Свой эмодзи" : "Custom emoji" }
    static var customEmojiHint:  String { isRu ? "Введите один эмодзи с клавиатуры" : "Enter one emoji from the keyboard" }

    // MARK: - Daily greeting

    static var greetingMorning: String { isRu ? "Доброе утро" : "Good morning" }
    static var greetingDay:     String { isRu ? "Добрый день" : "Good afternoon" }
    static var greetingEvening: String { isRu ? "Добрый вечер" : "Good evening" }

    static func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return greetingMorning }
        if hour < 18 { return greetingDay }
        return greetingEvening
    }

    static func greetingEmoji() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "☀️" }
        if hour < 18 { return "🌤️" }
        return "🌙"
    }

    static func greetingHabitsWaiting(_ count: Int) -> String {
        isRu ? "\(count) \(pluralHabits(count)) \(count == 1 ? "ждёт" : "ждут") тебя сегодня"
             : "\(count) \(count == 1 ? "habit" : "habits") waiting for you today"
    }

    static func greetingYesterdayResult(_ done: Int, _ total: Int) -> String {
        if done == total && total > 0 {
            return isRu ? "Вчера: всё выполнено ✓" : "Yesterday: all done ✓"
        }
        return isRu ? "Вчера: \(done) из \(total)" : "Yesterday: \(done) of \(total)"
    }

    static var greetingNoYesterday: String { isRu ? "Вчера: перерыв" : "Yesterday: rest day" }
    static var greetingTapToDismiss: String { isRu ? "Нажми, чтобы начать" : "Tap to start" }

    static func pluralHabits(_ n: Int) -> String {
        isRu ? ruPlural(n, one: "привычка", few: "привычки", many: "привычек")
             : (n == 1 ? "habit" : "habits")
    }

    // MARK: - Delete confirmation

    static var deleteConfirmTitle: String { isRu ? "Удалить привычку?" : "Delete habit?" }
    static func deleteConfirmMessage(_ emoji: String, _ name: String) -> String {
        isRu ? "Привычка \(emoji) \(name) будет удалена"
             : "Habit \(emoji) \(name) will be deleted"
    }

    // MARK: - Placeholders

    static var futureTitle: String { isRu ? "Это ещё впереди" : "This is still ahead" }
    static var futureSubtitle: String { isRu ? "Будущее зависит только от вас" : "The future depends only on you" }

    static var emptyTitle: String { isRu ? "Здесь был перерыв" : "This was a break" }
    static var emptySubtitle: String { isRu ? "Ничего страшного — главное продолжать" : "No worries — the key is to keep going" }

    // MARK: - Default habits

    static var defaultHabits: [(String, String)] {
        isRu
        ? [("🛌", "Сон"), ("🚴", "Активность"), ("🥗", "Питание"),
           ("🧠", "Ментальное"), ("💻", "Проекты")]
        : [("🛌", "Sleep"), ("🚴", "Activity"), ("🥗", "Nutrition"),
           ("🧠", "Mental"), ("💻", "Projects")]
    }

    // MARK: - Onboarding

    static var onboardingTagline: String {
        isRu ? "Сделал или нет?" : "Did you do it or not?"
    }

    static var onboardingWhyWord1: String {
        isRu ? "Отмечай" : "Track"
    }

    static var onboardingWhyWord2: String {
        isRu ? "Замечай" : "Notice"
    }

    static var onboardingWhyWord3: String {
        isRu ? "Расти" : "Grow"
    }

    static var onboardingPage2Title: String {
        isRu ? "Отмечай за 5 секунд" : "Check in within 5 seconds"
    }

    static var onboardingPage2Subtitle: String {
        isRu ? "Тап — и привычка записана" : "One tap — and the habit is logged"
    }

    static var onboardingPage3Title: String {
        isRu ? "Смотри свой прогресс" : "See your progress grow"
    }

    static var onboardingPage3Subtitle: String {
        isRu ? "Каждый день оставляет след" : "Every day leaves a mark"
    }

    static var onboardingLetsGo: String {
        isRu ? "Начнём!" : "Let's go!"
    }

    static var onboardingShowAgain: String {
        isRu ? "Показать онбординг" : "Show onboarding"
    }

    // MARK: - Compassionate Coach

    static var coachMissed1: String {
        isRu ? "У всех бывает. Прогресс не потерян." : "Everyone has off days. Your progress is still here."
    }

    static var coachMissed2: String {
        isRu ? "Ты здесь — это уже шаг." : "You're here — that's already a step."
    }

    static var coachMissed4: String {
        isRu ? "Маленький шаг лучше стоять на месте." : "A small step beats standing still."
    }

    static var coachMissed7: String {
        isRu ? "Каждый момент — шанс начать заново." : "Every moment is a chance to start fresh."
    }

    static func coachHabitNudge(_ name: String) -> String {
        isRu ? "Привычка «\(name)» ждёт тебя" : "«\(name)» is waiting for you"
    }

    // MARK: - Extended Check-in

    static var extendedNumeric: String {
        isRu ? "Числовой" : "Numeric"
    }

    static var extendedText: String {
        isRu ? "Комментарий" : "Comment"
    }

    static var extendedRating: String {
        isRu ? "Оценка" : "Rating"
    }

    static var extendedUnit: String {
        isRu ? "Единица" : "Unit"
    }

    static var extendedUnitHint: String {
        isRu ? "ч, км, л..." : "h, km, L..."
    }

    static var extendedStep: String {
        isRu ? "Шаг" : "Step"
    }

    static var extendedNotePlaceholder: String {
        isRu ? "Заметка..." : "Note..."
    }

    static var extendedTextShort: String {
        isRu ? "Коммент." : "Comment"
    }

    // MARK: - Check-in Type & Presets
    static var checkinType: String { isRu ? "Тип чекина" : "Check-in type" }
    static var presetTime: String { isRu ? "Время" : "Time" }
    static var presetCount: String { isRu ? "Кол-во" : "Count" }
    static var presetMoney: String { isRu ? "Деньги" : "Money" }
    static var presetCustom: String { isRu ? "Своё" : "Custom" }

    // MARK: - Habit Detail

    static var habitDetailAvg: String { isRu ? "Среднее" : "Average" }
    static var habitDetailMin: String { isRu ? "Мин" : "Min" }
    static var habitDetailMax: String { isRu ? "Макс" : "Max" }
    static var habitDetailStreak: String { isRu ? "Стрик" : "Streak" }
    static var habitDetailBestStreak: String { isRu ? "Лучший" : "Best" }
    static var habitDetailCompletion: String { isRu ? "Выполн." : "Done" }
    static var habitDetailLog: String { isRu ? "Лог" : "Log" }
    static var habitDetailNoData: String { isRu ? "Нет данных" : "No data" }
    static var habitDetailPeriod7d: String { isRu ? "7д" : "7d" }
    static var habitDetailPeriod30d: String { isRu ? "30д" : "30d" }
    static var habitDetailPeriod90d: String { isRu ? "90д" : "90d" }
    static var habitDetailPeriodYear: String { isRu ? "Год" : "Year" }
    static var habitDetailDays: String { isRu ? "д" : "d" }
    // Count-habit specific
    static var habitDetailTotal: String { isRu ? "Всего" : "Total" }
    static var habitDetailBestDay: String { isRu ? "Лучший день" : "Best day" }
    static var habitDetailPerfectDays: String { isRu ? "Идеальных" : "Perfect days" }
    static var habitDetailOverflowSuffix: String { isRu ? "сверх плана" : "over goal" }
    static var habitDetailTargetLabel: String { isRu ? "Цель" : "Target" }
    static var habitDetailHeatmap: String { isRu ? "Календарь" : "Calendar" }
    static var habitDetailHeatmapLess: String { isRu ? "меньше" : "less" }
    static var habitDetailHeatmapMore: String { isRu ? "больше" : "more" }
    // Note section
    static var habitDetailNoteToday:     String { isRu ? "сегодня" : "today" }
    static var habitDetailNoteYesterday: String { isRu ? "вчера" : "yesterday" }
    static var habitDetailNotePlaceholder: String {
        isRu ? "Добавь заметку…" : "Add a note…"
    }
    static func habitDetailNoteTitle(_ dateLabel: String) -> String {
        isRu ? "Заметка на \(dateLabel)" : "Note for \(dateLabel)"
    }

    // MARK: - Apple Health Sync

    static var healthKitSync: String {
        "Apple Health"
    }

    static var healthKitWorkoutLabel: String {
        isRu ? "Тренировка" : "Workout"
    }

    static var healthKitSleepLabel: String {
        isRu ? "Сон" : "Sleep"
    }

    static var healthKitStepsLabel: String {
        isRu ? "Шаги" : "Steps"
    }

    static var healthKitFooter: String {
        isRu ? "Авто-отмечается при наличии тренировки" : "Auto-checks when workout found"
    }

    static var healthKitSleepFooter: String {
        isRu ? "Авто-записывает длительность сна из Apple Health" : "Auto-logs sleep duration from Apple Health"
    }

    static var healthKitStepsFooter: String {
        isRu ? "Авто-записывает количество шагов из Apple Health" : "Auto-logs step count from Apple Health"
    }

    static var healthKitDenied: String {
        isRu ? "Нет доступа к Apple Health. Проверьте Настройки." : "Health access not granted. Check Settings."
    }

    static var healthKitDeniedDetail: String {
        isRu ? "Откройте приложение Здоровье → Обмен → Программы → LifeTrack и включите доступ к данным"
             : "Open Health app → Sharing → Apps → LifeTrack and enable access"
    }

    static var healthKitOpenSettings: String {
        isRu ? "Открыть Здоровье" : "Open Health"
    }

    static var healthKitAutoLabel: String {
        isRu ? "авто" : "auto"
    }

    static var newBadge: String {
        isRu ? "новая" : "new"
    }

    static func workoutTypeName(_ type: WorkoutType) -> String {
        switch type {
        case .cycling:          return isRu ? "Велосипед"    : "Cycling"
        case .running:          return isRu ? "Бег"          : "Running"
        case .walking:          return isRu ? "Ходьба"       : "Walking"
        case .swimming:         return isRu ? "Плавание"     : "Swimming"
        case .yoga:             return isRu ? "Йога"         : "Yoga"
        case .strengthTraining: return isRu ? "Силовая"      : "Strength"
        case .hiking:           return isRu ? "Хайкинг"      : "Hiking"
        case .dance:            return isRu ? "Танцы"         : "Dance"
        case .martialArts:      return isRu ? "Единоборства"  : "Martial Arts"
        case .pilates:          return isRu ? "Пилатес"       : "Pilates"
        }
    }

    static func workoutTypeEmoji(_ type: WorkoutType) -> String {
        switch type {
        case .cycling:          return "🚴"
        case .running:          return "🏃"
        case .walking:          return "🚶"
        case .swimming:         return "🏊"
        case .yoga:             return "🧘"
        case .strengthTraining: return "🏋️"
        case .hiking:           return "🥾"
        case .dance:            return "💃"
        case .martialArts:      return "🥋"
        case .pilates:          return "🤸"
        }
    }

    static func metricTypeName(_ type: HealthKitMetricType) -> String {
        switch type {
        case .sleep: return isRu ? "Сон"  : "Sleep"
        case .steps: return isRu ? "Шаги" : "Steps"
        }
    }

    static func metricTypeEmoji(_ type: HealthKitMetricType) -> String {
        switch type {
        case .sleep: return "🛌"
        case .steps: return "👟"
        }
    }
}
