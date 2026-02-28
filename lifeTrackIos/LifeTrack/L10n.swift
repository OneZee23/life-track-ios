import Foundation

enum L10n {
    // Mutable flag — updated by AppStore when language changes
    static var isRu: Bool = {
        Locale.current.language.languageCode?.identifier == "ru"
    }()

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
        isRu ? "\(n) из 10" : "\(n) of 10"
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
    static var version:          String { isRu ? "Версия"       : "Version" }

    static var aboutDescription: String {
        isRu
        ? "LifeTrack — минималистичный трекер привычек. Отмечай свой день за 5 секунд, смотри прогресс на тепловой карте. Без оценок, без стресса — просто делал или не делал."
        : "LifeTrack is a minimalist habit tracker. Log your day in 5 seconds, see your progress on a heat map. No ratings, no stress — just did or didn't."
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

    static var awaitingCheckIn: String { isRu ? "Ожидает чек-ина"  : "Awaiting check-in" }
    static var allDone:         String { isRu ? "Все выполнено!"    : "All done!" }
    static var partial:         String { isRu ? "Частично"          : "Partial" }
    static var notDone:         String { isRu ? "Не выполнено"      : "Not done" }

    // MARK: - Month progress

    static var bestStreak:    String { isRu ? "Лучшая серия"  : "Best streak" }
    static var currentStreak: String { isRu ? "Текущая серия"  : "Current streak" }

    // MARK: - Week progress

    static var weekTotal: String { isRu ? "Итог недели" : "Week total" }

    // MARK: - Year progress

    static var completed: String { isRu ? "Выполнено" : "Completed" }
    static var dayOfYear: String { isRu ? "День"      : "Day" }
    static var perfect:   String { isRu ? "Идеальных" : "Perfect" }
    static var missed:    String { isRu ? "Пропуск"   : "Missed" }
    static var today:     String { isRu ? "Сегодня"   : "Today" }
    static var less:      String { isRu ? "Меньше"    : "Less" }
    static var more:      String { isRu ? "Больше"    : "More" }

    static var hintDayOfYear:  String { isRu ? "Текущий день года"  : "Current day of year" }
    static var hintMissedDays: String { isRu ? "Дни без чекина"    : "Days without check-in" }
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
        return options.randomElement()!
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
        if isRu {
            let mod10 = n % 10
            let mod100 = n % 100
            if mod10 == 1 && mod100 != 11 { return "день" }
            if mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14) { return "дня" }
            return "дней"
        } else {
            return n == 1 ? "day" : "days"
        }
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

    // MARK: - Default habits

    static var defaultHabits: [(String, String)] {
        isRu
        ? [("🛌", "Сон"), ("🚴", "Активность"), ("🥗", "Питание"),
           ("🧠", "Ментальное"), ("💻", "Проекты")]
        : [("🛌", "Sleep"), ("🚴", "Activity"), ("🥗", "Nutrition"),
           ("🧠", "Mental"), ("💻", "Projects")]
    }
}
