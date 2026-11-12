import SwiftUI
import HealthKit
import MapKit
import Observation

struct HealthDay: Identifiable {
    let date: Date
    var steps: Double?
    var id: Date { date }
}
struct WalkingRoute: Identifiable {
    let id: UUID
    let date: Date
    let points: [CLLocationCoordinate2D]
}

@MainActor @Observable final class HealthStore {
    private let store = HKHealthStore()
    var steps: Double?
    var energy: Double?
    var sleep: Double?
    var workoutCount = 0
    var days: [HealthDay] = []
    var routes: [WalkingRoute] = []
    var status = "Подключите Apple Health для личной сводки"
    var loading = false
    var requested = UserDefaults.standard.bool(forKey: "sportlog.health.requested")

    func connect() async {
        guard HKHealthStore.isHealthDataAvailable() else { status = "Apple Health недоступен на этом устройстве"; return }
        do {
            let types: Set<HKObjectType> = [HKQuantityType(.stepCount), HKQuantityType(.activeEnergyBurned), HKCategoryType(.sleepAnalysis), HKObjectType.workoutType(), HKSeriesType.workoutRoute()]
            try await store.requestAuthorization(toShare: [], read: types)
            requested = true
            UserDefaults.standard.set(true, forKey: "sportlog.health.requested")
            await refresh()
        } catch { status = "Не удалось подключить Health: \(error.localizedDescription)" }
    }
    private func quantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async throws -> Double? {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: HKQuantityType(id), quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate), options: .cumulativeSum) { _, result, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: unit)) }
            }
            store.execute(query)
        }
    }
    private func samples(_ type: HKSampleType, predicate: NSPredicate?, limit: Int = HKObjectQueryNoLimit) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            store.execute(HKSampleQuery(sampleType: type, predicate: predicate, limit: limit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, results, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: results ?? []) }
            })
        }
    }
    private func coordinates(_ route: HKWorkoutRoute) async throws -> [CLLocationCoordinate2D] {
        try await withCheckedThrowingContinuation { continuation in
            var points: [CLLocationCoordinate2D] = []
            store.execute(HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let error { continuation.resume(throwing: error); return }
                points.append(contentsOf: (locations ?? []).map(\.coordinate))
                if done { continuation.resume(returning: points) }
            })
        }
    }
    func refresh() async {
        guard requested, !loading else { return }
        loading = true
        defer { loading = false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        do {
            steps = try await quantity(.stepCount, unit: .count(), start: today, end: Date())
            energy = try await quantity(.activeEnergyBurned, unit: .kilocalorie(), start: today, end: Date())
            var week: [HealthDay] = []
            for offset in (-6)...0 {
                let start = calendar.date(byAdding: .day, value: offset, to: today)!
                let end = calendar.date(byAdding: .day, value: 1, to: start)!
                week.append(HealthDay(date: start, steps: try await quantity(.stepCount, unit: .count(), start: start, end: end)))
            }
            days = week
            let sleepStart = calendar.date(byAdding: .hour, value: -12, to: today)!
            let sleepSamples = try await samples(HKCategoryType(.sleepAnalysis), predicate: HKQuery.predicateForSamples(withStart: sleepStart, end: Date())) as? [HKCategorySample] ?? []
            // Merge overlapping samples from Watch and other sources to avoid double counting.
            let intervals = sleepSamples.filter { [1, 3, 4, 5].contains($0.value) }.map { (max($0.startDate, sleepStart), min($0.endDate, Date())) }.sorted { $0.0 < $1.0 }
            var merged: [(Date, Date)] = []
            for interval in intervals where interval.1 > interval.0 {
                if let last = merged.last, interval.0 <= last.1 { merged[merged.count - 1].1 = max(last.1, interval.1) }
                else { merged.append(interval) }
            }
            sleep = merged.isEmpty ? nil : merged.reduce(0) { $0 + $1.1.timeIntervalSince($1.0) } / 3600
            let workouts = try await samples(HKObjectType.workoutType(), predicate: HKQuery.predicateForSamples(withStart: today, end: Date()))
            workoutCount = workouts.count
            status = "Обновлено сейчас · нет значений? Проверьте доступ в Здоровье"
        } catch { status = "Не удалось обновить данные: \(error.localizedDescription)" }
    }
    func loadRoutes() async {
        guard requested else { return }
        loading = true
        defer { loading = false }
        do {
            let start = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let workouts = try await samples(HKObjectType.workoutType(), predicate: HKQuery.predicateForSamples(withStart: start, end: Date()), limit: 50)
            var loaded: [WalkingRoute] = []
            for case let workout as HKWorkout in workouts {
                let samples = try await samples(HKSeriesType.workoutRoute(), predicate: HKQuery.predicateForObjects(from: workout))
                for case let route as HKWorkoutRoute in samples {
                    let points = try await coordinates(route)
                    if !points.isEmpty { loaded.append(WalkingRoute(id: route.uuid, date: route.startDate, points: points)) }
                }
            }
            routes = loaded
        } catch { status = "Ошибка чтения маршрутов: \(error.localizedDescription)" }
    }
}
