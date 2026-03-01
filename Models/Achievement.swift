//
//  Achievement.swift
//  AIRunningCoach
//
//  Created by Claude Code
//

import Foundation

// MARK: - 成就类型

enum AchievementCategory: String, Codable, CaseIterable {
    case distance = "distance"           // 距离成就
    case duration = "duration"           // 时长成就
    case frequency = "frequency"         // 频率成就
    case calories = "calories"           // 燃脂成就 🔥
    case pace = "pace"                   // 配速成就
    case special = "special"             // 特殊成就
    case milestone = "milestone"         // 里程碑成就

    var displayName: String {
        switch self {
        case .distance: return "距离成就"
        case .duration: return "时长成就"
        case .frequency: return "频率成就"
        case .calories: return "燃脂成就"
        case .pace: return "配速成就"
        case .special: return "特殊成就"
        case .milestone: return "里程碑成就"
        }
    }

    var icon: String {
        switch self {
        case .distance: return "figure.run"
        case .duration: return "clock.fill"
        case .frequency: return "flame.fill"
        case .calories: return "flame.circle.fill"
        case .pace: return "bolt.fill"
        case .special: return "star.fill"
        case .milestone: return "trophy.fill"
        }
    }
}

// MARK: - 成就模型

struct Achievement: Identifiable, Codable {
    var id: String                           // 唯一标识符
    var category: AchievementCategory        // 类别
    var title: String                        // 标题（中文）
    var description: String                  // 描述（中文）
    var icon: String                         // SF Symbol 图标
    var targetValue: Double                  // 目标值
    var currentValue: Double                 // 当前进度值
    var isUnlocked: Bool                     // 是否已解锁
    var unlockedAt: Date?                    // 解锁时间
    var celebrationMessage: String           // AI语音庆祝文本
    var titleEn: String = ""                 // 英文标题
    var descriptionEn: String = ""           // 英文描述

    // 本地化标题/描述（按 App 语言自动选择）
    var localizedTitle: String {
        let isEN = LanguageManager.shared.currentLocale == "en"
        return (isEN && !titleEn.isEmpty) ? titleEn : title
    }
    var localizedDescription: String {
        let isEN = LanguageManager.shared.currentLocale == "en"
        return (isEN && !descriptionEn.isEmpty) ? descriptionEn : description
    }

    // 计算属性：进度百分比
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        if category == .pace {
            guard currentValue > 0, currentValue < 999 else { return 0 }
            return min(targetValue / currentValue, 1.0)
        }
        return min(currentValue / targetValue, 1.0)
    }

    // 计算属性：进度描述
    var progressText: String {
        if isUnlocked {
            return LanguageManager.shared.currentLocale == "en" ? "Completed" : "已完成"
        }

        let isEN = LanguageManager.shared.currentLocale == "en"
        switch category {
        case .distance:
            return String(format: "%.1f/%.0f \(isEN ? "km" : "公里")", currentValue / 1000, targetValue / 1000)
        case .duration:
            return String(format: "%.1f/%.0f \(isEN ? "hrs" : "小时")", currentValue / 3600, targetValue / 3600)
        case .frequency:
            return String(format: "%.0f/%.0f \(isEN ? "days" : "天")", currentValue, targetValue)
        case .calories:
            return String(format: "%.0f/%.0f \(isEN ? "kcal" : "卡")", currentValue, targetValue)
        case .pace:
            let targetPace = Int(targetValue / 60)
            if currentValue >= 999 {
                return "-- / \(targetPace)'00\""
            }
            let currentPace = Int(currentValue / 60)
            let currentSec = Int(currentValue.truncatingRemainder(dividingBy: 60))
            return String(format: "%d'%02d\" / %d'00\"", currentPace, currentSec, targetPace)
        case .special:
            return String(format: "%.0f/%.0f \(isEN ? "times" : "次")", currentValue, targetValue)
        case .milestone:
            return String(format: "%.0f/%.0f \(isEN ? "km" : "公里")", currentValue / 1000, targetValue / 1000)
        }
    }
}

// MARK: - 预定义成就数据

extension Achievement {
    static let allAchievements: [Achievement] = [
        // ===== 1. 距离成就（单次距离）=====
        Achievement(
            id: "distance_3km",
            category: .distance,
            title: "初露锋芒",
            description: "完成3公里跑步",
            icon: "figure.walk",
            targetValue: 3000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "恭喜解锁初露锋芒成就！正式成为3公里跑者啦！",
            titleEn: "First Stride",
            descriptionEn: "Complete a 3km run"
        ),
        Achievement(
            id: "distance_5km",
            category: .distance,
            title: "进阶挑战",
            description: "完成5公里跑步",
            icon: "figure.run",
            targetValue: 5000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "太棒了！解锁成就【进阶挑战】！完成5公里，你已经进入跑者的行列！",
            titleEn: "Level Up",
            descriptionEn: "Complete a 5km run"
        ),
        Achievement(
            id: "distance_10km",
            category: .distance,
            title: "半马征程",
            description: "完成10公里跑步",
            icon: "figure.run.circle",
            targetValue: 10000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "不可思议！解锁成就【半马征程】！完成10公里，你的耐力令人敬佩！",
            titleEn: "10K Journey",
            descriptionEn: "Complete a 10km run"
        ),
        Achievement(
            id: "distance_21km",
            category: .distance,
            title: "全马英雄",
            description: "完成21公里跑步",
            icon: "medal.fill",
            targetValue: 21000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "震撼全场！解锁成就【全马英雄】！完成半程马拉松21公里，你是真正的跑者！",
            titleEn: "Half Marathon Hero",
            descriptionEn: "Complete a 21km run"
        ),
        Achievement(
            id: "distance_42km",
            category: .distance,
            title: "极限挑战",
            description: "完成42公里跑步",
            icon: "trophy.fill",
            targetValue: 42000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "传奇诞生！解锁成就【极限挑战】！完成全程马拉松42公里，你已经突破人类极限！",
            titleEn: "Marathon Legend",
            descriptionEn: "Complete a full 42km marathon"
        ),

        // ===== 2. 时长成就（累计时间）=====
        Achievement(
            id: "duration_5hours",
            category: .duration,
            title: "时光起步",
            description: "累计跑步5小时",
            icon: "clock",
            targetValue: 5 * 3600,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "恭喜你！解锁成就【时光起步】！累计跑步5小时，时间见证你的坚持！",
            titleEn: "Time Starter",
            descriptionEn: "5 hours cumulative running"
        ),
        Achievement(
            id: "duration_10hours",
            category: .duration,
            title: "持之以恒",
            description: "累计跑步10小时",
            icon: "clock.fill",
            targetValue: 10 * 3600,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "太棒了！解锁成就【持之以恒】！累计跑步10小时，你的毅力无人能敌！",
            titleEn: "Persistence",
            descriptionEn: "10 hours cumulative running"
        ),
        Achievement(
            id: "duration_50hours",
            category: .duration,
            title: "马拉松精神",
            description: "累计跑步50小时",
            icon: "hourglass",
            targetValue: 50 * 3600,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "不可思议！解锁成就【马拉松精神】！累计跑步50小时，你已经成为跑步专家！",
            titleEn: "Marathon Spirit",
            descriptionEn: "50 hours cumulative running"
        ),
        Achievement(
            id: "duration_100hours",
            category: .duration,
            title: "时间征服者",
            description: "累计跑步100小时",
            icon: "clock.badge.checkmark",
            targetValue: 100 * 3600,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "传奇成就！解锁【时间征服者】！累计跑步100小时，你已经用时间书写了传奇！",
            titleEn: "Time Conqueror",
            descriptionEn: "100 hours cumulative running"
        ),

        // ===== 3. 频率成就（连续天数）=====
        Achievement(
            id: "frequency_3days",
            category: .frequency,
            title: "三日连跑",
            description: "连续跑步3天",
            icon: "flame",
            targetValue: 3,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "恭喜你！解锁成就【三日连跑】！连续跑步3天，习惯的种子已经发芽！",
            titleEn: "3-Day Streak",
            descriptionEn: "Run 3 days in a row"
        ),
        Achievement(
            id: "frequency_7days",
            category: .frequency,
            title: "坚持不懈",
            description: "连续跑步7天",
            icon: "flame.fill",
            targetValue: 7,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "太棒了！解锁成就【坚持不懈】！连续跑步7天，你已经养成了跑步习惯！",
            titleEn: "Relentless",
            descriptionEn: "Run 7 days in a row"
        ),
        Achievement(
            id: "frequency_30days",
            category: .frequency,
            title: "铁人意志",
            description: "连续跑步30天",
            icon: "flame.circle.fill",
            targetValue: 30,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "不可思议！解锁成就【铁人意志】！连续跑步30天，你的意志力如钢铁般坚韧！",
            titleEn: "Iron Will",
            descriptionEn: "Run 30 days in a row"
        ),
        Achievement(
            id: "frequency_100days",
            category: .frequency,
            title: "跑步狂人",
            description: "连续跑步100天",
            icon: "bolt.heart.fill",
            targetValue: 100,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "传奇诞生！解锁成就【跑步狂人】！连续跑步100天，你已经成为跑步界的传奇人物！",
            titleEn: "Running Fanatic",
            descriptionEn: "Run 100 days in a row"
        ),

        // ===== 4. 🔥 燃脂成就（卡路里消耗）=====
        Achievement(
            id: "calories_300",
            category: .calories,
            title: "初见成效",
            description: "单次跑步燃烧300卡",
            icon: "flame",
            targetValue: 300,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "恭喜你！解锁成就【初见成效】！单次跑步燃烧300卡路里，减肥之路开了个好头！坚持下去，你会看到更大的改变！",
            titleEn: "First Results",
            descriptionEn: "Burn 300 cal in a single run"
        ),
        Achievement(
            id: "calories_500",
            category: .calories,
            title: "脂肪杀手",
            description: "单次跑步燃烧500卡",
            icon: "flame.fill",
            targetValue: 500,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "解锁脂肪杀手！单次燃脂500大卡，脂肪瑟瑟发抖。",
            titleEn: "Fat Slayer",
            descriptionEn: "Burn 500 cal in a single run"
        ),
        Achievement(
            id: "calories_1000",
            category: .calories,
            title: "燃脂狂魔",
            description: "单次跑步燃烧1000卡",
            icon: "bolt.fill",
            targetValue: 1000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "不可思议！解锁成就【燃脂狂魔】！单次燃烧1000卡，这是超高强度训练，你的毅力令人震撼！",
            titleEn: "Calorie Beast",
            descriptionEn: "Burn 1,000 cal in a single run"
        ),
        Achievement(
            id: "calories_total_5k",
            category: .calories,
            title: "代谢达人",
            description: "累计燃烧5,000卡",
            icon: "flame.circle",
            targetValue: 5000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "解锁代谢达人！连续燃脂跑，身体变成高效燃脂机。",
            titleEn: "Metabolism Master",
            descriptionEn: "5,000 cal burned total"
        ),
        Achievement(
            id: "calories_total_7700",
            category: .calories,
            title: "斤斤计较",
            description: "累计燃烧7,700卡（约减1公斤脂肪）",
            icon: "scalemass.fill",
            targetValue: 7700,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "解锁斤斤计较！减重1公斤，历史性突破！",
            titleEn: "Fat Fighter",
            descriptionEn: "7,700 cal burned (≈1 kg fat)"
        ),
        Achievement(
            id: "calories_total_10k",
            category: .calories,
            title: "卡路里杀手",
            description: "累计燃烧10,000卡",
            icon: "flame.circle",
            targetValue: 10000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "恭喜你！解锁成就【卡路里杀手】！累计燃烧1万卡，相当于减掉约1.3公斤脂肪，你的身体正在发生质变！",
            titleEn: "Calorie Killer",
            descriptionEn: "10,000 cal burned total"
        ),
        Achievement(
            id: "calories_total_50k",
            category: .calories,
            title: "减肥战士",
            description: "累计燃烧50,000卡",
            icon: "flame.circle.fill",
            targetValue: 50000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "太棒了！解锁成就【减肥战士】！累计燃烧5万卡，相当于减掉约6.5公斤脂肪，你已经是真正的减肥战士！",
            titleEn: "Weight Loss Warrior",
            descriptionEn: "50,000 cal burned total"
        ),
        Achievement(
            id: "calories_total_100k",
            category: .calories,
            title: "脂肪克星",
            description: "累计燃烧100,000卡",
            icon: "bolt.heart.fill",
            targetValue: 100000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "传奇诞生！解锁成就【脂肪克星】！累计燃烧10万卡路里，相当于减重13公斤的脂肪！你已经是真正的脂肪克星了！",
            titleEn: "Fat Destroyer",
            descriptionEn: "100,000 cal burned total"
        ),

        // ===== 5. 配速成就（最快配速）=====
        Achievement(
            id: "pace_7min",
            category: .pace,
            title: "节奏大师",
            description: "最快配速达到 7'00\"/公里",
            icon: "metronome",
            targetValue: 7 * 60,
            currentValue: 999,
            isUnlocked: false,
            celebrationMessage: "解锁节奏大师！跑步超稳，节奏感拉满。",
            titleEn: "Rhythm Master",
            descriptionEn: "Best pace within 7'00\"/km"
        ),
        Achievement(
            id: "pace_6min",
            category: .pace,
            title: "速度觉醒",
            description: "最快配速达到 6'00\"/公里",
            icon: "hare",
            targetValue: 6 * 60,
            currentValue: 999,
            isUnlocked: false,
            celebrationMessage: "恭喜你！解锁成就【速度觉醒】！配速突破6分钟每公里，速度觉醒了！",
            titleEn: "Speed Awakened",
            descriptionEn: "Best pace within 6'00\"/km"
        ),
        Achievement(
            id: "pace_5min",
            category: .pace,
            title: "飞毛腿",
            description: "最快配速达到 5'00\"/公里",
            icon: "hare.fill",
            targetValue: 5 * 60,
            currentValue: 999,
            isUnlocked: false,
            celebrationMessage: "太棒了！解锁成就【飞毛腿】！配速突破5分钟每公里，你的速度如同飞毛腿！",
            titleEn: "Swift Feet",
            descriptionEn: "Best pace within 5'00\"/km"
        ),
        Achievement(
            id: "pace_4min",
            category: .pace,
            title: "闪电侠",
            description: "最快配速达到 4'00\"/公里",
            icon: "bolt.fill",
            targetValue: 4 * 60,
            currentValue: 999,
            isUnlocked: false,
            celebrationMessage: "不可思议！解锁成就【闪电侠】！配速突破4分钟每公里，你就是闪电侠！",
            titleEn: "Lightning Bolt",
            descriptionEn: "Best pace within 4'00\"/km"
        ),

        // ===== 6. 特殊成就（时间段）=====
        Achievement(
            id: "special_morning_5times",
            category: .special,
            title: "早起的鸟儿",
            description: "完成5次晨跑（5:00-8:00）",
            icon: "sunrise.fill",
            targetValue: 5,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "恭喜你！解锁成就【早起的鸟儿】！完成5次晨跑，你的自律令人敬佩！",
            titleEn: "Early Bird",
            descriptionEn: "5 morning runs (5:00–8:00 AM)"
        ),
        Achievement(
            id: "special_night_5times",
            category: .special,
            title: "夜跑勇士",
            description: "完成5次夜跑（20:00-23:00）",
            icon: "moon.stars.fill",
            targetValue: 5,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "太棒了！解锁成就【夜跑勇士】！完成5次夜跑，你是夜晚的勇士！",
            titleEn: "Night Warrior",
            descriptionEn: "5 night runs (8:00–11:00 PM)"
        ),
        Achievement(
            id: "special_rainy_1time",
            category: .special,
            title: "风雨无阻",
            description: "在雨天完成跑步",
            icon: "cloud.rain.fill",
            targetValue: 1,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "不可思议！解锁成就【风雨无阻】！在雨天完成跑步，你的意志力坚如磐石！",
            titleEn: "Rain Runner",
            descriptionEn: "Complete a run in the rain"
        ),

        // ===== 7. 里程碑成就（累计距离）=====
        Achievement(
            id: "milestone_100km",
            category: .milestone,
            title: "环球旅行",
            description: "累计跑步100公里",
            icon: "globe.asia.australia",
            targetValue: 100000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "恭喜你！解锁成就【环球旅行】！累计跑步100公里，你已经开启环球旅行！",
            titleEn: "Century Runner",
            descriptionEn: "100 km total distance"
        ),
        Achievement(
            id: "milestone_500km",
            category: .milestone,
            title: "横跨中国",
            description: "累计跑步500公里",
            icon: "map.fill",
            targetValue: 500000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "太棒了！解锁成就【横跨中国】！累计跑步500公里，足以横跨中国！",
            titleEn: "Cross the Nation",
            descriptionEn: "500 km total distance"
        ),
        Achievement(
            id: "milestone_1000km",
            category: .milestone,
            title: "绕地球一圈",
            description: "累计跑步1000公里",
            icon: "globe",
            targetValue: 1000000,
            currentValue: 0,
            isUnlocked: false,
            celebrationMessage: "传奇诞生！解锁成就【绕地球一圈】！累计跑步1000公里，相当于绕地球赤道的1/40！你已经是跑步界的传奇！",
            titleEn: "Earth Orbiter",
            descriptionEn: "1,000 km total distance"
        )
    ]
}

// MARK: - Supabase 数据库模型

struct AchievementDTO: Codable {
    var id: UUID
    var userId: UUID
    var achievementId: String
    var currentValue: Double
    var isUnlocked: Bool
    var unlockedAt: Date?
    var sharedCount: Int
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case achievementId = "achievement_id"
        case currentValue = "current_value"
        case isUnlocked = "is_unlocked"
        case unlockedAt = "unlocked_at"
        case sharedCount = "shared_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
