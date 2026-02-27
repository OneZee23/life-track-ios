import Foundation
import SwiftUI

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
