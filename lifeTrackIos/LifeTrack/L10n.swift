import Foundation

enum L10n {
    static let isRu: Bool = {
        Locale.current.language.languageCode?.identifier == "ru"
    }()

    // MARK: - Tabs

    static let tabCheckIn  = isRu ? "Чек-ин"   : "Check-in"
    static let tabProgress = isRu ? "Прогресс"  : "Progress"
    static let tabHabits   = isRu ? "Привычки"  : "Habits"

    // MARK: - Check-in

    static let checkIn          = isRu ? "Чек-ин"              : "Check-in"
    static let yesterdayPrefix  = isRu ? "Вчера"               : "Yesterday"
    static let doneButton       = isRu ? "Готово ✓"            : "Done ✓"
    static let daySaved         = isRu ? "День записан!"       : "Day saved!"
    static let comeBackTomorrow = isRu ? "Возвращайся завтра"  : "Come back tomorrow"
    static let habitsCompleted  = isRu ? "привычек выполнено"  : "habits completed"
    static let editCheckin      = isRu ? "Изменить"            : "Edit"

    // MARK: - Habits

    static let habits    = isRu ? "Привычки"           : "Habits"
    static let done      = isRu ? "Готово"              : "Done"
    static let edit      = isRu ? "Изменить"            : "Edit"
    static let addHabit  = isRu ? "Добавить привычку"   : "Add habit"
    static let maxHabits = isRu ? "Максимум 10 привычек" : "Maximum 10 habits"
    static let newHabit  = isRu ? "Новая привычка"      : "New habit"
    static let editHabit = isRu ? "Редактировать"       : "Edit habit"
    static let name      = isRu ? "Название"            : "Name"
    static let cancel    = isRu ? "Отмена"              : "Cancel"
    static let add       = isRu ? "Добавить"            : "Add"
    static let save      = isRu ? "Сохранить"           : "Save"
    static let delete    = isRu ? "Удалить"             : "Delete"

    static func habitsCount(_ n: Int) -> String {
        isRu ? "\(n) из 10" : "\(n) of 10"
    }

    // MARK: - Settings

    static let settings         = isRu ? "Настройки"    : "Settings"
    static let darkTheme        = isRu ? "Тёмная тема"  : "Dark theme"
    static let appearance       = isRu ? "Внешний вид"  : "Appearance"
    static let aboutProject     = isRu ? "О проекте"    : "About"
    static let feedback         = isRu ? "Обратная связь" : "Feedback"
    static let writeAuthor      = isRu ? "Написать автору" : "Contact author"
    static let bugsIdeas        = isRu ? "Баги, идеи, предложения" : "Bugs, ideas, suggestions"
    static let links            = isRu ? "Ссылки"       : "Links"
    static let telegramChannel  = isRu ? "Telegram-канал" : "Telegram channel"
    static let telegramSubtitle = isRu ? "Разработка LifeTrack в реальном времени" : "LifeTrack development in real time"
    static let youtubeSubtitle  = isRu ? "Канал автора"  : "Author's channel"
    static let version          = isRu ? "Версия"       : "Version"

    static let aboutDescription = isRu
        ? "LifeTrack — минималистичный трекер привычек. Отмечай вчерашний день за 5 секунд, смотри прогресс на тепловой карте. Без оценок, без стресса — просто делал или не делал."
        : "LifeTrack is a minimalist habit tracker. Log yesterday in 5 seconds, see your progress on a heat map. No ratings, no stress — just did or didn't."

    static let aboutMVP = isRu
        ? "Это MVP — приложение создаётся открыто, вместе с сообществом. Весь процесс в Telegram-канале."
        : "This is an MVP — the app is being built openly, with the community. Follow the process on Telegram."

    static let aboutAuthor = isRu
        ? "Автор — OneZee, инди-разработчик."
        : "Made by OneZee, indie developer."

    static let footerMVP = isRu
        ? "LifeTrack Native MVP — сделано с душой ♥"
        : "LifeTrack Native MVP — made with love ♥"

    // MARK: - Progress

    static let progress = isRu ? "Прогресс" : "Progress"
    static let month    = isRu ? "Месяц"    : "Month"
    static let year     = isRu ? "Год"      : "Year"
    static let week     = isRu ? "Неделя"   : "Week"
    static let all      = isRu ? "Все"      : "All"

    // MARK: - Day progress

    static let awaitingCheckIn = isRu ? "Ожидает чек-ина"  : "Awaiting check-in"
    static let allDone         = isRu ? "Все выполнено!"    : "All done!"
    static let partial         = isRu ? "Частично"          : "Partial"
    static let notDone         = isRu ? "Не выполнено"      : "Not done"

    // MARK: - Month progress

    static let bestStreak    = isRu ? "Лучшая серия"  : "Best streak"
    static let currentStreak = isRu ? "Текущая серия"  : "Current streak"

    // MARK: - Week progress

    static let weekTotal = isRu ? "Итог недели" : "Week total"

    // MARK: - Year progress

    static let completed = isRu ? "Выполнено" : "Completed"
    static let tracked   = isRu ? "Затрекано" : "Tracked"
    static let missed    = isRu ? "Пропуск"   : "Missed"
    static let today     = isRu ? "Сегодня"   : "Today"

    // MARK: - Date arrays

    static let monthsFull: [String] = isRu
        ? ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
           "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
        : ["January", "February", "March", "April", "May", "June",
           "July", "August", "September", "October", "November", "December"]

    static let monthsShort: [String] = isRu
        ? ["Янв", "Фев", "Мар", "Апр", "Май", "Июн",
           "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"]
        : ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    static let monthsGenitive: [String] = isRu
        ? ["января", "февраля", "марта", "апреля", "мая", "июня",
           "июля", "августа", "сентября", "октября", "ноября", "декабря"]
        : ["January", "February", "March", "April", "May", "June",
           "July", "August", "September", "October", "November", "December"]

    static let weekdaysFull: [String] = isRu
        ? ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
        : ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    static let weekdaysShort: [String] = isRu
        ? ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

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

    static func yesterdayLabel() -> String {
        let d = yesterday()
        let day = Calendar.current.component(.day, from: d)
        let monthIdx = Calendar.current.component(.month, from: d) - 1
        let wdIdx = weekdayIndex(d)
        if isRu {
            return "\(day) \(monthsGenitive[monthIdx]), \(weekdaysFull[wdIdx].lowercased())"
        } else {
            return "\(weekdaysFull[wdIdx]), \(monthsGenitive[monthIdx]) \(day)"
        }
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

    static let defaultHabits: [(String, String)] = isRu
        ? [("🛌", "Сон"), ("🚴", "Активность"), ("🥗", "Питание"),
           ("🧠", "Ментальное"), ("💻", "Проекты")]
        : [("🛌", "Sleep"), ("🚴", "Activity"), ("🥗", "Nutrition"),
           ("🧠", "Mental"), ("💻", "Projects")]
}
