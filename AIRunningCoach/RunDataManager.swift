//
//  RunDataManager.swift
//  AI跑步教练
//
//  Created by Claude Code
//  支持本地存储和云端同步的跑步数据管理器

import Foundation
import Supabase
import Combine

@MainActor
class RunDataManager: ObservableObject {
    static let shared = RunDataManager()

    @Published var runRecords: [RunRecord] = []
    @Published var isLoading = false
    @Published var isSyncing = false

    private let localStorageKey = "RunRecords"
    private let authManager = AuthManager.shared

    private init() {
        loadLocalRecords()
    }

    // MARK: - Local Storage

    /// 从本地加载跑步记录
    private func loadLocalRecords() {
        guard let data = UserDefaults.standard.data(forKey: localStorageKey),
              let records = try? JSONDecoder().decode([RunRecord].self, from: data) else {
            runRecords = []
            return
        }
        runRecords = records.sorted { $0.startTime > $1.startTime }
    }

    /// 保存跑步记录到本地
    private func saveToLocal() {
        guard let data = try? JSONEncoder().encode(runRecords) else {
            print("Failed to encode run records")
            return
        }
        UserDefaults.standard.set(data, forKey: localStorageKey)
    }

    // MARK: - CRUD Operations

    /// 添加新的跑步记录
    func addRunRecord(_ record: RunRecord) async {
        var newRecord = record
        newRecord.userId = authManager.currentUserId

        // 保存到本地
        runRecords.insert(newRecord, at: 0)
        saveToLocal()

        // 如果用户已登录，同步到云端
        if authManager.isAuthenticated {
            await syncToCloud(newRecord)
        }
    }

    /// 删除跑步记录
    func deleteRunRecord(_ record: RunRecord) async {
        // 从本地删除
        runRecords.removeAll { $0.id == record.id }
        saveToLocal()

        // 如果已同步到云端，也从云端删除
        if authManager.isAuthenticated && record.syncedToCloud {
            await deleteFromCloud(record.id)
        }
    }

    /// 更新跑步记录
    func updateRunRecord(_ record: RunRecord) async {
        guard let index = runRecords.firstIndex(where: { $0.id == record.id }) else {
            return
        }

        var updatedRecord = record
        updatedRecord.updatedAt = Date()

        // 更新本地
        runRecords[index] = updatedRecord
        saveToLocal()

        // 如果用户已登录，同步到云端
        if authManager.isAuthenticated {
            await syncToCloud(updatedRecord)
        }
    }

    // MARK: - Cloud Sync

    /// 同步单条记录到云端
    private func syncToCloud(_ record: RunRecord) async {
        guard let userId = authManager.currentUserId else { return }

        do {
            let dto = RunRecordDTO(from: record, userId: userId)

            // 检查记录是否已存在
            let existing: [RunRecordDTO] = try await supabase
                .from("run_records")
                .select()
                .eq("id", value: record.id.uuidString)
                .execute()
                .value

            if existing.isEmpty {
                // 插入新记录
                try await supabase
                    .from("run_records")
                    .insert(dto)
                    .execute()
            } else {
                // 更新现有记录
                try await supabase
                    .from("run_records")
                    .update(dto)
                    .eq("id", value: record.id.uuidString)
                    .execute()
            }

            // 标记为已同步
            if let index = runRecords.firstIndex(where: { $0.id == record.id }) {
                runRecords[index].syncedToCloud = true
                saveToLocal()
            }

            print("✅ Synced record \(record.id) to cloud")
        } catch {
            print("❌ Failed to sync to cloud: \(error.localizedDescription)")
        }
    }

    /// 从云端删除记录
    private func deleteFromCloud(_ recordId: UUID) async {
        do {
            try await supabase
                .from("run_records")
                .delete()
                .eq("id", value: recordId.uuidString)
                .execute()

            print("✅ Deleted record \(recordId) from cloud")
        } catch {
            print("❌ Failed to delete from cloud: \(error.localizedDescription)")
        }
    }

    /// 同步所有未同步的记录到云端
    func syncAllToCloud() async {
        guard authManager.isAuthenticated else {
            print("⚠️ User not authenticated, skipping cloud sync")
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        let unsyncedRecords = runRecords.filter { !$0.syncedToCloud }

        for record in unsyncedRecords {
            await syncToCloud(record)
        }

        print("✅ Synced \(unsyncedRecords.count) records to cloud")
    }

    /// 从云端拉取所有记录
    func fetchFromCloud() async {
        guard authManager.isAuthenticated,
              let userId = authManager.currentUserId else {
            print("⚠️ User not authenticated, skipping cloud fetch")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let cloudRecords: [RunRecordDTO] = try await supabase
                .from("run_records")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("start_time", ascending: false)
                .execute()
                .value

            // 合并云端和本地数据
            let cloudRunRecords = cloudRecords.map { $0.toRunRecord() }
            mergeRecords(cloudRunRecords)

            print("✅ Fetched \(cloudRecords.count) records from cloud")
        } catch {
            print("❌ Failed to fetch from cloud: \(error.localizedDescription)")
        }
    }

    /// 合并云端和本地记录（避免重复）
    private func mergeRecords(_ cloudRecords: [RunRecord]) {
        var mergedRecords = runRecords

        for cloudRecord in cloudRecords {
            if let index = mergedRecords.firstIndex(where: { $0.id == cloudRecord.id }) {
                // 如果本地已有，使用更新时间较新的版本
                if cloudRecord.updatedAt > mergedRecords[index].updatedAt {
                    mergedRecords[index] = cloudRecord
                }
            } else {
                // 如果本地没有，添加云端记录
                mergedRecords.append(cloudRecord)
            }
        }

        runRecords = mergedRecords.sorted { $0.startTime > $1.startTime }
        saveToLocal()
    }

    // MARK: - Query

    /// 获取指定日期范围的记录
    func getRecords(from startDate: Date, to endDate: Date) -> [RunRecord] {
        return runRecords.filter { record in
            record.startTime >= startDate && record.startTime <= endDate
        }
    }

    /// 获取本周的记录
    func getThisWeekRecords() -> [RunRecord] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return []
        }
        return getRecords(from: weekStart, to: now)
    }

    /// 获取本月的记录
    func getThisMonthRecords() -> [RunRecord] {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else {
            return []
        }
        return getRecords(from: monthStart, to: now)
    }

    // MARK: - Statistics

    /// 计算总距离
    func getTotalDistance() -> Double {
        return runRecords.reduce(0) { $0 + $1.distance }
    }

    /// 计算总时长
    func getTotalDuration() -> TimeInterval {
        return runRecords.reduce(0) { $0 + $1.duration }
    }

    /// 计算平均配速
    func getAveragePace() -> Double {
        guard !runRecords.isEmpty else { return 0 }
        let totalPace = runRecords.reduce(0) { $0 + $1.pace }
        return totalPace / Double(runRecords.count)
    }
}
