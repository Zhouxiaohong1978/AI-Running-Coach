//
//  VoiceTemplate.swift
//  AI跑步教练
//
//  动态语音模板：触发事件枚举 + 模板数据结构

import Foundation

// MARK: - 触发事件

enum VoiceTriggerEvent: String, Hashable {
    // 时间里程碑
    case time5min  = "time_5min"
    case time10min = "time_10min"
    case time20min = "time_20min"
    case time30min = "time_30min"

    // 心率区间
    case hrFatBurnZone = "hr_fat_burn_zone"
    case hrTooHigh     = "hr_too_high"

    // 卡路里里程碑
    case cal150 = "cal_150"
    case cal300 = "cal_300"

    // 配速变化
    case paceImproved = "pace_improved"
    case paceDropped  = "pace_dropped"

    // 个人记录
    case personalDistanceRecord = "personal_distance_record"

    // 扩展时间里程碑（半马 / 全马长跑专用）
    case time45min = "time_45min"
    case time1hour = "time_1hour"
    case time90min = "time_90min"
    case time2hour = "time_2hour"
    case time3hour = "time_3hour"
    case time4hour = "time_4hour"
    case time5hour = "time_5hour"

    // 距离里程碑（5 / 10 / 21.1 / 30 / 40km）
    case dist5km  = "dist_5km"
    case dist10km = "dist_10km"
    case dist21km = "dist_21km"
    case dist30km = "dist_30km"
    case dist40km = "dist_40km"

    /// 每次跑步只触发一次
    var playOncePerRun: Bool {
        switch self {
        case .time5min, .time10min, .time20min, .time30min:                         return true
        case .time45min, .time1hour, .time90min, .time2hour,
             .time3hour, .time4hour, .time5hour:                                    return true
        case .cal150, .cal300, .personalDistanceRecord:                             return true
        case .dist5km, .dist10km, .dist21km, .dist30km, .dist40km:                 return true
        case .hrFatBurnZone:                                                        return true
        case .hrTooHigh, .paceImproved, .paceDropped:                              return false
        }
    }

    /// 同一事件的最短触发间隔（秒）
    var perTriggerCooldown: TimeInterval {
        switch self {
        case .time5min, .time10min, .time20min, .time30min:                         return 0
        case .time45min, .time1hour, .time90min, .time2hour,
             .time3hour, .time4hour, .time5hour:                                    return 0
        case .cal150, .cal300, .personalDistanceRecord:                             return 0
        case .dist5km, .dist10km, .dist21km, .dist30km, .dist40km:                 return 0
        case .hrFatBurnZone:                                                        return 0
        case .hrTooHigh:                                                            return 90
        case .paceImproved:                                                         return 120
        case .paceDropped:                                                          return 120
        }
    }

    /// 播放优先级（越高越优先）
    var priority: Int {
        switch self {
        case .personalDistanceRecord:                           return 95
        case .hrTooHigh:                                        return 90
        case .dist40km, .dist21km:                             return 88  // 终点冲刺 / 半马达成
        case .dist30km:                                         return 82  // 马拉松墙
        case .dist10km:                                         return 75
        case .dist5km:                                          return 68
        case .time5min, .time10min, .time20min, .time30min,
             .time45min, .time1hour, .time90min, .time2hour,
             .time3hour, .time4hour, .time5hour:               return 65
        case .cal150, .cal300:                                  return 60
        case .hrFatBurnZone:                                    return 55
        case .paceImproved:                                     return 50
        case .paceDropped:                                      return 45
        }
    }
}

// MARK: - 语音模板

struct VoiceTemplate {
    let event: VoiceTriggerEvent
    let variants: [String]      // 中文变体（3条）
    let variantsEn: [String]    // 英文变体（3条）

    /// 随机选取一条变体（保证每次听到不同内容）
    func randomVariant(isEN: Bool) -> String {
        let pool = isEN ? variantsEn : variants
        guard !pool.isEmpty else { return "" }
        return pool.randomElement() ?? pool[0]
    }

    /// 根据训练目标选取最合适的变体
    /// 减肥燃脂目标：优先返回含 {calories}/{food} 占位符的变体，强化燃脂感知
    /// 其他目标：随机返回
    func variant(forGoal goal: TrainingGoal, isEN: Bool) -> String {
        let pool = isEN ? variantsEn : variants
        guard !pool.isEmpty else { return "" }
        if goal == .weightLoss,
           let calorieVariant = pool.first(where: { $0.contains("{calories}") || $0.contains("{food}") }) {
            return calorieVariant
        }
        return pool.randomElement() ?? pool[0]
    }
}
