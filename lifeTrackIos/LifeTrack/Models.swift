import Foundation
import SwiftUI

// MARK: - Safe Array Decoding

/// Одна битая запись не убивает весь массив.
struct SafeDecodable<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try? container.decode(T.self)
    }
}

extension Array where Element: Decodable {
    static func safeDecoded(from data: Data) -> [Element] {
        guard let wrappers = try? JSONDecoder().decode([SafeDecodable<Element>].self, from: data) else {
            return []
        }
        return wrappers.compactMap(\.value)
    }
}

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

    init(type: ExtendedFieldType, unit: String? = nil, minValue: Double? = nil,
         maxValue: Double? = nil, step: Double? = nil, inputStyle: NumericInputStyle? = nil) {
        self.type = type
        self.unit = unit
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step
        self.inputStyle = inputStyle
    }

    enum CodingKeys: String, CodingKey {
        case type, unit, minValue, maxValue, step, inputStyle
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type       = try c.decode(ExtendedFieldType.self, forKey: .type)
        unit       = try c.decodeIfPresent(String.self, forKey: .unit)
        minValue   = try c.decodeIfPresent(Double.self, forKey: .minValue)
        maxValue   = try c.decodeIfPresent(Double.self, forKey: .maxValue)
        step       = try c.decodeIfPresent(Double.self, forKey: .step)
        inputStyle = try c.decodeIfPresent(NumericInputStyle.self, forKey: .inputStyle)
    }
}

struct CheckinExtra: Codable, Equatable {
    var numericValue: Double?
    var textValue: String?
    var ratingValue: Int?

    init(numericValue: Double? = nil, textValue: String? = nil, ratingValue: Int? = nil) {
        self.numericValue = numericValue
        self.textValue = textValue
        self.ratingValue = ratingValue
    }

    enum CodingKeys: String, CodingKey {
        case numericValue, textValue, ratingValue
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        numericValue = try c.decodeIfPresent(Double.self, forKey: .numericValue)
        textValue    = try c.decodeIfPresent(String.self, forKey: .textValue)
        ratingValue  = try c.decodeIfPresent(Int.self, forKey: .ratingValue)
    }
}

// MARK: - Habit

struct Habit: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var emoji: String
    var sortOrder: Int
    var createdAt: Date
    var deletedAt: Date?
    var extendedField: ExtendedFieldConfig?

    var isDeleted: Bool { deletedAt != nil }

    init(
        id: String = UUID().uuidString,
        name: String,
        emoji: String,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        deletedAt: Date? = nil,
        extendedField: ExtendedFieldConfig? = nil
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.extendedField = extendedField
    }

    enum CodingKeys: String, CodingKey {
        case id, name, emoji, sortOrder, createdAt, deletedAt, extendedField
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(String.self, forKey: .id)
        name          = try c.decode(String.self, forKey: .name)
        emoji         = try c.decode(String.self, forKey: .emoji)
        sortOrder     = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        createdAt     = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .distantPast
        deletedAt     = try c.decodeIfPresent(Date.self, forKey: .deletedAt)
        extendedField = try c.decodeIfPresent(ExtendedFieldConfig.self, forKey: .extendedField)
    }
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
