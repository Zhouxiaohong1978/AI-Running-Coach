//
//  HealthKitManager.swift
//  AIRunningCoach
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()
    private var query: HKAnchoredObjectQuery?

    @Published var heartRate: Int = 0          // 0 = 未获取到
    @Published var isAuthorized: Bool = false

    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

    private init() {}

    // MARK: - 请求授权

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        store.requestAuthorization(toShare: [], read: [heartRateType]) { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = success
            }
        }
    }

    // MARK: - 开始实时监听心率

    func startHeartRateMonitoring() {
        guard HKHealthStore.isHealthDataAvailable(), isAuthorized else { return }
        stopHeartRateMonitoring()

        // 只读取最近 10 秒内的心率，避免显示旧数据
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-10),
            end: nil,
            options: .strictStartDate
        )

        let q = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        // 实时更新 handler
        q.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        store.execute(q)
        self.query = q
    }

    // MARK: - 停止监听

    func stopHeartRateMonitoring() {
        if let q = query {
            store.stop(q)
            query = nil
        }
        DispatchQueue.main.async { self.heartRate = 0 }
    }

    // MARK: - 解析心率样本

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], let latest = samples.last else { return }
        let bpm = Int(latest.quantity.doubleValue(for: .init(from: "count/min")))
        DispatchQueue.main.async { self.heartRate = bpm }
    }
}
