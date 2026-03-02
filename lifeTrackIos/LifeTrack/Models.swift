import Foundation
import SwiftUI

// MARK: - Extended Check-in Types

enum ExtendedFieldType: String, Codable {
    case numeric
    case text
    case rating
}

enum NumericInputStyle: String, Codable {
    case slider
    case stepper
}

struct ExtendedFieldConfig: Codable, Equatable, Hashable {
    var type: ExtendedFieldType
    var unit: String?                    // numeric only, max 6 chars
    var minValue: Double?                // numeric only, >= 0
    var maxValue: Double?                // numeric only, <= 10000
    var step: Double?                    // numeric only, default 1
    var inputStyle: NumericInputStyle?   // numeric only, default .slider
}

struct CheckinExtra: Codable, Equatable {
    var numericValue: Double?
    var textValue: String?
    var ratingValue: Int?
}

// MARK: - Habit

struct Habit: Identifiable, Codable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var emoji: String
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var deletedAt: Date? = nil
    var extendedField: ExtendedFieldConfig? = nil

    var isDeleted: Bool { deletedAt != nil }
}

// MARK: - DayStatus

enum DayStatus: Int, Equatable, Comparable {
    case none   = 0  // 0%
    case low    = 1  // 1-25%
    case medium = 2  // 26-50%
    case high   = 3  // 51-75%
    case full   = 4  // 76-100%

    static func < (lhs: DayStatus, rhs: DayStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var level: Int { rawValue }

    var color: Color {
        switch self {
        case .none:   return Color(UIColor.systemGray5)
        case .low:    return Color(UIColor.systemGreen).opacity(0.25)
        case .medium: return Color(UIColor.systemGreen).opacity(0.50)
        case .high:   return Color(UIColor.systemGreen).opacity(0.75)
        case .full:   return Color(UIColor.systemGreen)
        }
    }

    var needsWhiteText: Bool {
        self >= .medium
    }
}

// MARK: - Analytics Stats

struct HabitStat {
    let habit: Habit
    let done: Int
    let tracked: Int
    let rate: Double
}

struct MonthlyStat {
    let month: Int
    let done: Int
    let tracked: Int
    let rate: Double
}
