// SimpleConditionCheck.swift
import Foundation

/**
 极简条件量化器 - 只实现最核心的两个模糊条件
 原则：用可测量数据替代主观判断，不影响现有稳定逻辑
 */
class SimpleConditionCheck {

    // MARK: - 疲劳检测（替代"疲劳=高"）

    /// 基于客观数据判断是否处于高疲劳状态
    /// 规则：长时间（>20分钟）+ （高心率或长距离）
    static func isFatigueHigh(context: RunContext, userMaxHeartRate: Int = 185) -> Bool {
        // 必要条件：跑步时间超过20分钟
        guard context.duration > 1200 else { return false } // 20分钟 = 1200秒

        // 计算心率强度（相对于最大心率的百分比）
        let heartRateIntensity = Double(context.heartRate) / Double(userMaxHeartRate)

        // 满足以下任一条件即判定为高疲劳：
        // 1. 心率强度 > 85%
        // 2. 距离 > 5公里
        // 3. 持续时间 > 40分钟（极度疲劳）
        let condition1 = heartRateIntensity > 0.85  // 心率超过85%
        let condition2 = context.distance > 5.0      // 距离超过5公里
        let condition3 = context.duration > 2400     // 超过40分钟

        // 记录判断依据（用于调试）
        print("[疲劳检测] 时长:\(Int(context.duration))秒, 心率:\(context.heartRate)(\(Int(heartRateIntensity*100))%), 距离:\(context.distance)km")
        print("[疲劳检测] 条件: 高心率=\(condition1), 长距离=\(condition2), 超长时间=\(condition3)")

        return condition1 || condition2 || condition3
    }

    // MARK: - 心率区间检测（替代"心率区间=最佳"）

    /// 判断是否处于最佳燃脂心率区间（60-70%最大心率）
    static func isInFatBurnZone(heartRate: Int, userMaxHeartRate: Int = 185) -> Bool {
        let minFatBurn = Int(Double(userMaxHeartRate) * 0.60)  // 60%最大心率
        let maxFatBurn = Int(Double(userMaxHeartRate) * 0.70)  // 70%最大心率

        let isInZone = heartRate >= minFatBurn && heartRate <= maxFatBurn

        // 调试信息
        if isInZone {
            print("[心率区间] \(heartRate)bpm 在燃脂区间(\(minFatBurn)-\(maxFatBurn)bpm)")
        }

        return isInZone
    }

    // MARK: - 辅助方法：获取用户最大心率（简化版）

    /// 获取用户最大心率（默认值185，实际应从用户档案获取）
    static func getUserMaxHeartRate() -> Int {
        // 这里可以从UserDefaults或用户档案获取
        // 暂时返回默认值，实际应用中应个性化
        return UserDefaults.standard.integer(forKey: "user_max_heart_rate") > 0 ?
               UserDefaults.standard.integer(forKey: "user_max_heart_rate") : 185
    }
}

// 为 RunContext 添加扩展，方便调用
extension RunContext {
    /// 快速检查是否疲劳
    func isFatigueHigh() -> Bool {
        return SimpleConditionCheck.isFatigueHigh(context: self)
    }

    /// 快速检查是否在燃脂区间
    func isInFatBurnZone() -> Bool {
        return SimpleConditionCheck.isInFatBurnZone(heartRate: self.heartRate)
    }
}
