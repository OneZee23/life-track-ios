import Foundation
import HealthKit

final class HealthKitService {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        let types: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.stepCount)
        ]
        do {
            try await store.requestAuthorization(toShare: [], read: types)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Fetch workouts

    /// Returns set of HKWorkoutActivityType.rawValue for workouts in the given date range.
    func fetchWorkoutTypes(from startDate: Date, to endDate: Date) async -> Set<UInt> {
        guard isAvailable else { return [] }

        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                var types = Set<UInt>()
                if let workouts = samples as? [HKWorkout] {
                    for workout in workouts {
                        types.insert(workout.workoutActivityType.rawValue)
                    }
                }
                continuation.resume(returning: types)
            }
            store.execute(query)
        }
    }

    // MARK: - Fetch sleep duration

    /// Returns total sleep duration in minutes for the given date range, or nil if no data.
    /// Filters to actual sleep stages (not "inBed").
    func fetchSleepDuration(from startDate: Date, to endDate: Date) async -> Double? {
        guard isAvailable else { return nil }

        let sleepType = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, results, _ in
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }

        // Filter to actual sleep values (not inBed/awake)
        let sleepValues: Set<Int> = {
            var values: Set<Int> = [
                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
            ]
            if #available(iOS 16.0, *) {
                values.insert(HKCategoryValueSleepAnalysis.asleepCore.rawValue)
                values.insert(HKCategoryValueSleepAnalysis.asleepDeep.rawValue)
                values.insert(HKCategoryValueSleepAnalysis.asleepREM.rawValue)
            }
            return values
        }()

        let sleepSamples = samples.filter { sleepValues.contains($0.value) }
        guard !sleepSamples.isEmpty else { return nil }

        // Merge overlapping intervals to avoid double-counting
        let intervals = sleepSamples.map { (start: $0.startDate, end: $0.endDate) }
            .sorted { $0.start < $1.start }

        var merged: [(start: Date, end: Date)] = []
        for interval in intervals {
            if let last = merged.last, interval.start <= last.end {
                merged[merged.count - 1] = (start: last.start, end: max(last.end, interval.end))
            } else {
                merged.append(interval)
            }
        }

        let totalSeconds = merged.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
        let minutes = totalSeconds / 60.0
        return minutes > 0 ? minutes : nil
    }

    // MARK: - Fetch step count

    /// Returns cumulative step count for the given date range, or nil if no data.
    func fetchStepCount(from startDate: Date, to endDate: Date) async -> Double? {
        guard isAvailable else { return nil }

        let stepType = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let count = statistics?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: count)
            }
            store.execute(query)
        }
    }

    // MARK: - Fetch workout distance

    /// Returns total distance in km for workouts of the given type in the date range, or nil if no data.
    func fetchWorkoutDistance(type: HKWorkoutActivityType, from startDate: Date, to endDate: Date) async -> Double? {
        guard isAvailable else { return nil }

        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let workouts: [HKWorkout] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }

        let matching = workouts.filter { $0.workoutActivityType == type }
        guard !matching.isEmpty else { return nil }

        let totalKm = matching.reduce(0.0) { sum, workout in
            sum + (workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0)
        }
        return totalKm > 0 ? totalKm : nil
    }

    // MARK: - Type mapping

    static func hkActivityType(for workoutType: WorkoutType) -> HKWorkoutActivityType {
        switch workoutType {
        case .cycling:          return .cycling
        case .running:          return .running
        case .walking:          return .walking
        case .swimming:         return .swimming
        case .yoga:             return .yoga
        case .strengthTraining: return .traditionalStrengthTraining
        case .hiking:           return .hiking
        case .dance:            return .dance
        case .martialArts:      return .martialArts
        case .pilates:          return .pilates
        }
    }
}
