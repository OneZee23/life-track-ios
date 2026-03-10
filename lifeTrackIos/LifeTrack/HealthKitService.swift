import Foundation
import HealthKit

final class HealthKitService {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        let workoutType = HKObjectType.workoutType()
        do {
            try await store.requestAuthorization(toShare: [], read: [workoutType])
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
