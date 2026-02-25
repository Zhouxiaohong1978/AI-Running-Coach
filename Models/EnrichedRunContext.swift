//
//  EnrichedRunContext.swift
//  AI跑步教练
//
//  动态语音播报的富上下文：实时跑步数据 + 历史统计

import Foundation

struct EnrichedRunContext {

    // MARK: - 实时数据

    let distanceKm: Double
    let durationSeconds: TimeInterval
    let currentPace: Double        // 分钟/公里，0 = 未知
    let calories: Double
    let heartRate: Int             // BPM，0 = 无心率数据
    let goal: TrainingGoal
    let goalDistanceKm: Double

    // MARK: - 历史数据（不含本次跑步）

    let totalRunCount: Int         // 历史总次数（含本次）
    let personalBestPace: Double   // 历史最佳配速（最小值），0 = 无记录
    let lastRunPace: Double        // 上次配速，0 = 无记录
    let lastRunDistanceKm: Double  // 上次距离（km），0 = 无记录
    let totalLifetimeKm: Double    // 历史累计公里（含本次）
    let monthlyKm: Double          // 本月累计公里（含本次）
    let monthlyRunCount: Int       // 本月跑步次数（含本次）
    let currentStreak: Int         // 连续跑步天数

    // MARK: - 计算属性

    var elapsedMinutes: Double { durationSeconds / 60.0 }

    var remainingKm: Double { max(0, goalDistanceKm - distanceKm) }

    var progressPercent: Double {
        guard goalDistanceKm > 0 else { return 0 }
        return min(100, distanceKm / goalDistanceKm * 100)
    }

    var formattedPace: String {
        guard currentPace > 0 && currentPace < 30 else { return "--" }
        let minutes = Int(currentPace)
        let seconds = Int((currentPace - Double(minutes)) * 60)
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    var formattedDistance: String { String(format: "%.1f", distanceKm) }

    var formattedCalories: String { String(Int(calories)) }

    var formattedDuration: String {
        let minutes = Int(durationSeconds / 60)
        return "\(minutes)分钟"
    }

    var formattedDurationEn: String {
        let minutes = Int(durationSeconds / 60)
        return "\(minutes) min"
    }

    var formattedTotalKm: String { String(format: "%.0f", totalLifetimeKm) }

    var formattedMonthlyKm: String { String(format: "%.0f", monthlyKm) }

    var formattedRemaining: String { String(format: "%.1f公里", remainingKm) }

    var formattedRemainingEn: String { String(format: "%.1f km", remainingKm) }

    /// 消耗卡路里对应的食物（中文）
    var foodEquivalent: String {
        switch calories {
        case ..<100: return "1杯奶茶"
        case ..<200: return "半包薯片"
        case ..<300: return "1碗米饭"
        case ..<400: return "1个汉堡"
        default:     return "1顿快餐"
        }
    }

    /// 消耗卡路里对应的食物（英文）
    var foodEquivalentEn: String {
        switch calories {
        case ..<100: return "a large bubble tea"
        case ..<200: return "half a bag of chips"
        case ..<300: return "a bowl of rice"
        case ..<400: return "a burger"
        default:     return "a fast food meal"
        }
    }

    /// 心率区间名称（中文）
    var heartRateZone: String {
        switch heartRate {
        case 0:      return "未知区"
        case ..<120: return "热身区"
        case ..<140: return "燃脂区"
        case ..<160: return "有氧区"
        case ..<180: return "无氧区"
        default:     return "极限区"
        }
    }

    /// 心率区间名称（英文）
    var heartRateZoneEn: String {
        switch heartRate {
        case 0:      return "unknown"
        case ..<120: return "warm-up zone"
        case ..<140: return "fat-burn zone"
        case ..<160: return "aerobic zone"
        case ..<180: return "anaerobic zone"
        default:     return "max-effort zone"
        }
    }
}
