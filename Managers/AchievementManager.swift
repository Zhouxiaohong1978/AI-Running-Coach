//
//  AchievementManager.swift
//  AIRunningCoach
//
//  Created by Claude Code
//

import Foundation
import Combine
import Supabase

@MainActor
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    // MARK: - Published Properties

    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: [Achievement] = [] // 最近解锁的成就（用于显示横幅）

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "user_achievements"

    // MARK: - Initialization

    private init() {
        loadAchievements()
    }

    // MARK: - Public Methods

    /// 加载成就数据
    func loadAchievements() {
        if let data = userDefaults.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        } else {
            // 首次启动，初始化预定义成就
            achievements = Achievement.allAchievements
            saveAchievements()
        }
    }

    /// 保存成就数据到本地
    func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            userDefaults.set(encoded, forKey: achievementsKey)
        }
    }

    /// 检查并更新成就（从RunRecord触发）
    func checkAchievements(from runRecord: RunRecord, allRecords: [RunRecord]) {
        // 最小有效距离：100米以下的记录不触发任何成就
        guard runRecord.distance >= 100 else {
            print("⚠️ 跑步距离不足100米，跳过成就检查")
            return
        }

        var newlyUnlocked: [Achievement] = []

        // 1. 检查距离成就（单次距离）
        for index in achievements.indices where achievements[index].category == .distance {
            if !achievements[index].isUnlocked {
                achievements[index].currentValue = runRecord.distance
                if achievements[index].currentValue >= achievements[index].targetValue {
                    unlockAchievement(at: index)
                    newlyUnlocked.append(achievements[index])
                }
            }
        }

        // 2. 检查时长成就（累计时长）
        let totalDuration = allRecords.reduce(0) { $0 + $1.duration }
        for index in achievements.indices where achievements[index].category == .duration {
            achievements[index].currentValue = totalDuration
            if !achievements[index].isUnlocked && achievements[index].currentValue >= achievements[index].targetValue {
                unlockAchievement(at: index)
                newlyUnlocked.append(achievements[index])
            }
        }

        // 3. 检查频率成就（连续天数）
        let consecutiveDays = calculateConsecutiveDays(from: allRecords)
        for index in achievements.indices where achievements[index].category == .frequency {
            achievements[index].currentValue = Double(consecutiveDays)
            if !achievements[index].isUnlocked && achievements[index].currentValue >= achievements[index].targetValue {
                unlockAchievement(at: index)
                newlyUnlocked.append(achievements[index])
            }
        }

        // 4. 检查燃脂成就（单次 + 累计卡路里）
        let totalCalories = allRecords.reduce(0) { $0 + $1.calories }
        for index in achievements.indices where achievements[index].category == .calories {
            let achievementId = achievements[index].id

            // 单次燃脂成就
            if achievementId.contains("calories_300") || achievementId.contains("calories_500") || achievementId.contains("calories_1000") {
                achievements[index].currentValue = runRecord.calories
            }
            // 累计燃脂成就
            else if achievementId.contains("total") {
                achievements[index].currentValue = totalCalories
            }

            if !achievements[index].isUnlocked && achievements[index].currentValue >= achievements[index].targetValue {
                unlockAchievement(at: index)
                newlyUnlocked.append(achievements[index])
            }
        }

        // 5. 检查配速成就（最快配速，值越小越好）
        // 配速为0表示无效数据（距离为0或时间为0），跳过检查
        if runRecord.pace > 0 {
            for index in achievements.indices where achievements[index].category == .pace {
                let currentPace = runRecord.pace * 60 // 转换为秒/公里
                if currentPace < achievements[index].currentValue {
                    achievements[index].currentValue = currentPace
                }

                if !achievements[index].isUnlocked && achievements[index].currentValue <= achievements[index].targetValue {
                    unlockAchievement(at: index)
                    newlyUnlocked.append(achievements[index])
                }
            }
        }

        // 6. 检查特殊成就（晨跑、夜跑、雨天）
        for index in achievements.indices where achievements[index].category == .special {
            let achievementId = achievements[index].id

            if achievementId.contains("morning") {
                // 晨跑（5:00-8:00）
                let hour = Calendar.current.component(.hour, from: runRecord.startTime)
                if hour >= 5 && hour < 8 {
                    achievements[index].currentValue += 1
                }
            } else if achievementId.contains("night") {
                // 夜跑（20:00-23:00）
                let hour = Calendar.current.component(.hour, from: runRecord.startTime)
                if hour >= 20 && hour < 23 {
                    achievements[index].currentValue += 1
                }
            }
            // 雨天跑步需要天气API，暂时跳过
            // TODO: 集成天气API检测雨天

            if !achievements[index].isUnlocked && achievements[index].currentValue >= achievements[index].targetValue {
                unlockAchievement(at: index)
                newlyUnlocked.append(achievements[index])
            }
        }

        // 7. 检查里程碑成就（累计距离）
        let totalDistance = allRecords.reduce(0) { $0 + $1.distance }
        for index in achievements.indices where achievements[index].category == .milestone {
            achievements[index].currentValue = totalDistance
            if !achievements[index].isUnlocked && achievements[index].currentValue >= achievements[index].targetValue {
                unlockAchievement(at: index)
                newlyUnlocked.append(achievements[index])
            }
        }

        // 保存更新
        saveAchievements()

        // 更新最近解锁列表
        if !newlyUnlocked.isEmpty {
            recentlyUnlocked = newlyUnlocked
        }
    }

    /// 解锁成就
    private func unlockAchievement(at index: Int) {
        achievements[index].isUnlocked = true
        achievements[index].unlockedAt = Date()

        // 播放AI语音庆祝
        let message = achievements[index].celebrationMessage
        SpeechManager.shared.speak(message, priority: .high)

        print("🏆 成就解锁: \(achievements[index].title)")
    }

    /// 计算连续跑步天数
    private func calculateConsecutiveDays(from records: [RunRecord]) -> Int {
        guard !records.isEmpty else { return 0 }

        // 按日期排序
        let sortedRecords = records.sorted { $0.startTime > $1.startTime }

        var consecutiveDays = 1
        var lastDate = Calendar.current.startOfDay(for: sortedRecords[0].startTime)

        for i in 1..<sortedRecords.count {
            let currentDate = Calendar.current.startOfDay(for: sortedRecords[i].startTime)
            let dayDifference = Calendar.current.dateComponents([.day], from: currentDate, to: lastDate).day ?? 0

            if dayDifference == 1 {
                consecutiveDays += 1
                lastDate = currentDate
            } else if dayDifference > 1 {
                break // 不连续，停止计算
            }
        }

        return consecutiveDays
    }

    /// 清空最近解锁列表（用户查看后调用）
    func clearRecentlyUnlocked() {
        recentlyUnlocked.removeAll()
    }

    /// 按类别获取成就
    func achievements(for category: AchievementCategory) -> [Achievement] {
        return achievements.filter { $0.category == category }
    }

    /// 获取已解锁的成就数量
    var unlockedCount: Int {
        return achievements.filter { $0.isUnlocked }.count
    }

    /// 获取总成就数量
    var totalCount: Int {
        return achievements.count
    }

    /// 增加成就分享次数
    func incrementShareCount(for achievementId: String) {
        if let index = achievements.firstIndex(where: { $0.id == achievementId }) {
            // 本地不存储分享次数，仅在云端记录
            // TODO: 同步到Supabase
            print("📤 成就分享: \(achievements[index].title)")
        }
    }

    // MARK: - Reset & Recalculate

    /// 重置所有成就并根据真实跑步记录重新计算
    func resetAndRecalculate(allRecords: [RunRecord]) {
        // 1. 重置为初始状态
        achievements = Achievement.allAchievements
        recentlyUnlocked.removeAll()

        // 2. 用每条真实记录重新计算
        for record in allRecords {
            checkAchievements(from: record, allRecords: allRecords)
        }

        saveAchievements()
        print("🔄 成就已重置并根据 \(allRecords.count) 条真实记录重新计算")
    }

    /// 清理云端成就数据
    func clearCloudAchievements() async {
        guard let userId = AuthManager.shared.currentUserId else { return }

        do {
            try await supabase
                .from("user_achievements")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()
            print("✅ 云端成就数据已清除")
        } catch {
            print("❌ 清除云端成就失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Supabase 云同步

    /// 同步成就到云端
    func syncToCloud() async {
        guard let userId = AuthManager.shared.currentUserId else {
            print("⚠️ 用户未登录，跳过成就云同步")
            return
        }

        do {
            // 遍历所有成就，逐个同步
            for achievement in achievements {
                let dto = AchievementDTO(
                    id: UUID(), // Supabase会生成新ID
                    userId: userId,
                    achievementId: achievement.id,
                    currentValue: achievement.currentValue,
                    isUnlocked: achievement.isUnlocked,
                    unlockedAt: achievement.unlockedAt,
                    sharedCount: 0,
                    createdAt: Date(),
                    updatedAt: Date()
                )

                // 检查是否已存在
                let existing: [AchievementDTO] = try await supabase
                    .from("user_achievements")
                    .select()
                    .eq("user_id", value: userId.uuidString)
                    .eq("achievement_id", value: achievement.id)
                    .execute()
                    .value

                if existing.isEmpty {
                    // 插入新记录
                    try await supabase
                        .from("user_achievements")
                        .insert(dto)
                        .execute()
                } else {
                    // 更新现有记录
                    try await supabase
                        .from("user_achievements")
                        .update(dto)
                        .eq("user_id", value: userId.uuidString)
                        .eq("achievement_id", value: achievement.id)
                        .execute()
                }
            }

            print("✅ 成就已同步到云端")
        } catch {
            print("❌ 成就云同步失败: \(error.localizedDescription)")
        }
    }

    /// 从云端拉取成就
    func fetchFromCloud() async {
        guard let userId = AuthManager.shared.currentUserId else {
            print("⚠️ 用户未登录，跳过成就云拉取")
            return
        }

        do {
            let cloudAchievements: [AchievementDTO] = try await supabase
                .from("user_achievements")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            // 合并云端数据到本地
            for cloudAchievement in cloudAchievements {
                if let index = achievements.firstIndex(where: { $0.id == cloudAchievement.achievementId }) {
                    // 使用云端数据更新本地（云端优先）
                    achievements[index].currentValue = cloudAchievement.currentValue
                    achievements[index].isUnlocked = cloudAchievement.isUnlocked
                    achievements[index].unlockedAt = cloudAchievement.unlockedAt
                }
            }

            saveAchievements()
            print("✅ 成就已从云端拉取")
        } catch {
            print("❌ 成就云拉取失败: \(error.localizedDescription)")
        }
    }

    /// 增加分享次数并同步到云端
    func incrementShareCountAndSync(for achievementId: String) async {
        guard let userId = AuthManager.shared.currentUserId else {
            print("⚠️ 用户未登录，跳过分享统计")
            return
        }

        do {
            // 云端增加分享次数
            try await supabase
                .from("user_achievements")
                .update(["shared_count": 1]) // 使用increment语法
                .eq("user_id", value: userId.uuidString)
                .eq("achievement_id", value: achievementId)
                .execute()

            print("📤 成就分享已记录到云端")
        } catch {
            print("❌ 分享统计失败: \(error.localizedDescription)")
        }
    }
}
