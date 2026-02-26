import Foundation

// MARK: - Habit

struct Habit: Identifiable, Codable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var emoji: String
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var deletedAt: Date? = nil

    var isDeleted: Bool { deletedAt != nil }
}

// MARK: - DayStatus

enum DayStatus: Equatable {
    case all      // все привычки выполнены
    case partial  // часть привычек выполнена
    case none     // ничего не выполнено
}
