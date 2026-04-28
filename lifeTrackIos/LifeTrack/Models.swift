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

    // Required: Swift does not synthesize CodingKeys when init(from:) is custom
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

    static var sleepDefault: ExtendedFieldConfig {
        ExtendedFieldConfig(type: .numeric, unit: L10n.isRu ? "мин" : "min",
                            minValue: 0, maxValue: 1440, step: 15, inputStyle: .stepper)
    }

    static var stepsDefault: ExtendedFieldConfig {
        ExtendedFieldConfig(type: .numeric, minValue: 0, maxValue: 100000,
                            step: 1000, inputStyle: .stepper)
    }
}

struct CheckinExtra: Codable, Equatable {
    var numericValue: Double?
    var textValue: String?
    var ratingValue: Int?
    /// Free-form note for the day, independent of extendedField. Lets users add
    /// context (e.g. "had half a cigarette" / "long hike instead") without
    /// requiring a habit to have a text-type extended field.
    var noteValue: String?

    init(numericValue: Double? = nil, textValue: String? = nil, ratingValue: Int? = nil, noteValue: String? = nil) {
        self.numericValue = numericValue
        self.textValue = textValue
        self.ratingValue = ratingValue
        self.noteValue = noteValue
    }

    // Required: Swift does not synthesize CodingKeys when init(from:) is custom
    enum CodingKeys: String, CodingKey {
        case numericValue, textValue, ratingValue, noteValue
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        numericValue = try c.decodeIfPresent(Double.self, forKey: .numericValue)
        textValue    = try c.decodeIfPresent(String.self, forKey: .textValue)
        ratingValue  = try c.decodeIfPresent(Int.self, forKey: .ratingValue)
        noteValue    = try c.decodeIfPresent(String.self, forKey: .noteValue)
    }
}

// MARK: - Workout Type (HealthKit sync)

enum WorkoutType: String, Codable, CaseIterable {
    case cycling
    case running
    case walking
    case swimming
    case yoga
    case strengthTraining
    case hiking
    case dance
    case martialArts
    case pilates

    /// Workout types that record distance in Apple Health.
    var hasDistance: Bool {
        switch self {
        case .cycling, .running, .walking, .swimming, .hiking: return true
        case .yoga, .strengthTraining, .dance, .martialArts, .pilates: return false
        }
    }
}

enum NumericPreset: String, CaseIterable {
    case time, count, money, custom
}

// MARK: - HealthKit Metric Type (sleep / steps)

enum HealthKitMetricType: String, Codable, CaseIterable {
    case sleep
    case steps
}

// MARK: - Habit Reminder

struct HabitReminder: Codable, Equatable, Hashable {
    var startHour: Int
    var endHour: Int
    var intervalMinutes: Int
    var weekdays: Set<Int>   // ISO 8601: 1=Mon … 7=Sun

    init(startHour: Int = 9, endHour: Int = 17,
         intervalMinutes: Int = 60, weekdays: Set<Int> = Set(1...7)) {
        self.startHour = startHour
        self.endHour = endHour
        self.intervalMinutes = intervalMinutes
        self.weekdays = weekdays
    }

    enum CodingKeys: String, CodingKey {
        case startHour, endHour, intervalMinutes, weekdays
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        startHour       = try c.decodeIfPresent(Int.self, forKey: .startHour) ?? 9
        endHour         = try c.decodeIfPresent(Int.self, forKey: .endHour) ?? 17
        intervalMinutes = try c.decodeIfPresent(Int.self, forKey: .intervalMinutes) ?? 60
        weekdays        = try c.decodeIfPresent(Set<Int>.self, forKey: .weekdays) ?? Set(1...7)
    }

    var scheduledHours: [Int] {
        let step = max(1, intervalMinutes / 60)
        var result: [Int] = []
        var h = startHour
        while h <= endHour {
            result.append(h)
            h += step
        }
        return result
    }

    var notificationCount: Int {
        scheduledHours.count * weekdays.count
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
    var healthKitWorkoutType: String?
    var healthKitMetricType: String?
    var reminder: HabitReminder?
    var targetPerDay: Int?

    var isDeleted: Bool { deletedAt != nil }
    var isSleep: Bool { healthKitMetricType == HealthKitMetricType.sleep.rawValue }
    var isHealthKitLinked: Bool { healthKitWorkoutType != nil || healthKitMetricType != nil }
    var isNew: Bool {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 99 <= 1
    }
    var effectiveTarget: Int { targetPerDay ?? 1 }
    var isCountBased: Bool { effectiveTarget > 1 }

    init(
        id: String = UUID().uuidString,
        name: String,
        emoji: String,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        deletedAt: Date? = nil,
        extendedField: ExtendedFieldConfig? = nil,
        healthKitWorkoutType: String? = nil,
        healthKitMetricType: String? = nil,
        reminder: HabitReminder? = nil,
        targetPerDay: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.extendedField = extendedField
        self.healthKitWorkoutType = healthKitWorkoutType
        self.healthKitMetricType = healthKitMetricType
        self.reminder = reminder
        self.targetPerDay = targetPerDay
    }

    enum CodingKeys: String, CodingKey {
        case id, name, emoji, sortOrder, createdAt, deletedAt, extendedField,
             healthKitWorkoutType, healthKitMetricType, reminder, targetPerDay
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                   = try c.decode(String.self, forKey: .id)
        name                 = try c.decode(String.self, forKey: .name)
        emoji                = try c.decode(String.self, forKey: .emoji)
        sortOrder            = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        createdAt            = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .distantPast
        deletedAt            = try c.decodeIfPresent(Date.self, forKey: .deletedAt)
        extendedField        = try c.decodeIfPresent(ExtendedFieldConfig.self, forKey: .extendedField)
        healthKitWorkoutType = try c.decodeIfPresent(String.self, forKey: .healthKitWorkoutType)
        healthKitMetricType  = try c.decodeIfPresent(String.self, forKey: .healthKitMetricType)
        reminder             = try c.decodeIfPresent(HabitReminder.self, forKey: .reminder)
        targetPerDay         = try c.decodeIfPresent(Int.self, forKey: .targetPerDay)
    }
}

// MARK: - Emoji validation

extension String {
    /// True if string is exactly one grapheme cluster representing an emoji.
    var isSingleEmoji: Bool {
        guard count == 1, let first = first else { return false }
        let scalars = first.unicodeScalars
        // 0x238C is the last ASCII-range scalar that Unicode flags as isEmoji
        // (digits, #, * etc.). Above it or as part of a multi-scalar cluster
        // (flags, skin-tone, ZWJ sequences) → real emoji.
        return scalars.contains { scalar in
            scalar.properties.isEmoji && (scalar.value > 0x238C || scalars.count > 1)
        }
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
        case .low:    return Color(UIColor.systemGreen).opacity(0.20)
        case .medium: return Color(UIColor.systemGreen).opacity(0.45)
        case .high:   return Color(UIColor.systemGreen).opacity(0.70)
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
