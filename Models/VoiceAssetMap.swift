//
//  VoiceAssetMap.swift
//  AI跑步教练
//
//  语音资源映射 - 25条预录制语音的触发规则
//

import Foundation

// MARK: - Voice Trigger Type

/// 语音触发类型
enum VoiceTriggerType {
    case onStart              // 开始跑步时
    case onDistance(Double)   // 达到指定距离（km）
    case onComplete           // 完成3km
    case onAchievement(String) // 解锁成就时
    case onEmergency          // 异常情况
    case onEarlyStop          // 提前结束
}

// MARK: - Voice Asset

/// 语音资源
struct VoiceAsset {
    let fileName: String          // 文件名（不含扩展名）
    let triggerType: VoiceTriggerType
    let gender: String            // female 或 male
    let description: String       // 描述
    let priority: AudioPriority   // 优先级

    init(fileName: String, triggerType: VoiceTriggerType, gender: String, description: String, priority: AudioPriority = .normal) {
        self.fileName = fileName
        self.triggerType = triggerType
        self.gender = gender
        self.description = description
        self.priority = priority
    }
}

// MARK: - Voice Asset Map

/// 语音资源映射管理器
class VoiceAssetMap {
    static let shared = VoiceAssetMap()

    // MARK: - 女声语音（11条）

    private let femaleVoices: [VoiceAsset] = [
        // 跑前
        VoiceAsset(fileName: "跑前_01", triggerType: .onStart, gender: "female",
                  description: "我们轻轻开始，跟着自己的节奏就好，完成比完美更重要。", priority: .high),

        // 跑后
        VoiceAsset(fileName: "跑后_01", triggerType: .onComplete, gender: "female",
                  description: "3公里完成啦，慢慢走一会儿，让心跳平稳下来。", priority: .high),

        VoiceAsset(fileName: "跑后_02", triggerType: .onComplete, gender: "female",
                  description: "点击结束，解锁你的专属跑步成就徽章吧！", priority: .high),

        // 应急
        VoiceAsset(fileName: "应急_01", triggerType: .onEmergency, gender: "female",
                  description: "状态不太好没关系，能开始就赢了80%的人，累了就走一走。", priority: .urgent),

        VoiceAsset(fileName: "应急_02", triggerType: .onEarlyStop, gender: "female",
                  description: "想提前结束完全可以，今天跑的每一步都是进步。", priority: .urgent),

        // 新手成就（3条）
        VoiceAsset(fileName: "新手成就_01", triggerType: .onAchievement("初露锋芒"), gender: "female",
                  description: "恭喜解锁初露锋芒成就！正式成为3公里跑者啦！", priority: .high),

        VoiceAsset(fileName: "新手成就_02", triggerType: .onAchievement("节奏大师"), gender: "female",
                  description: "解锁节奏大师！跑步超稳，节奏感拉满。", priority: .high),

        VoiceAsset(fileName: "新手成就_03", triggerType: .onAchievement("风雨无阻"), gender: "female",
                  description: "解锁风雨无阻！天气挡不住你，这才是跑者精神。", priority: .high),

        // 减肥成就（3条）
        VoiceAsset(fileName: "减肥成就_01", triggerType: .onAchievement("脂肪杀手"), gender: "female",
                  description: "解锁脂肪杀手！单次燃脂500大卡，脂肪瑟瑟发抖。", priority: .high),

        VoiceAsset(fileName: "减肥成就_02", triggerType: .onAchievement("代谢达人"), gender: "female",
                  description: "解锁代谢达人！连续燃脂跑，身体变成高效燃脂机。", priority: .high),

        VoiceAsset(fileName: "减肥成就_03", triggerType: .onAchievement("斤斤计较"), gender: "female",
                  description: "解锁斤斤计较！减重1公斤，历史性突破！", priority: .high),
    ]

    // MARK: - 男声语音（14条）

    /// 新手3公里跑中语音（8条）
    private let beginnerMaleVoices: [VoiceAsset] = [
        VoiceAsset(fileName: "新手跑中_01", triggerType: .onDistance(0.5), gender: "male",
                  description: "身体热起来啦，鼻子吸气嘴巴呼气，找到舒服的节奏。"),

        VoiceAsset(fileName: "新手跑中_02", triggerType: .onDistance(1.0), gender: "male",
                  description: "1公里达成！80%的人都没跑过这么远，你超棒的！"),

        VoiceAsset(fileName: "新手跑中_03", triggerType: .onDistance(1.5), gender: "male",
                  description: "已经过半啦，肩膀耸耸肩放松下，剩下的路越跑越轻松。"),

        VoiceAsset(fileName: "新手跑中_04", triggerType: .onDistance(2.0), gender: "male",
                  description: "2公里了！新手毕业线就在眼前，再坚持一下。"),

        VoiceAsset(fileName: "新手跑中_05", triggerType: .onDistance(2.2), gender: "male",
                  description: "累了就走30秒，这不是放弃，是聪明的调整。"),

        VoiceAsset(fileName: "新手跑中_06", triggerType: .onDistance(2.5), gender: "male",
                  description: "最后500米！你已经跑了83%，冲就完事了！"),

        VoiceAsset(fileName: "新手跑中_07", triggerType: .onDistance(2.8), gender: "male",
                  description: "最后200米，感受心跳，为自己加油！"),

        VoiceAsset(fileName: "新手跑中_08", triggerType: .onDistance(3.0), gender: "male",
                  description: "搞定！3公里达成，你太棒了！", priority: .high),
    ]

    /// 减肥燃脂跑中语音（6条）
    private let fatburnMaleVoices: [VoiceAsset] = [
        VoiceAsset(fileName: "减肥跑中_01", triggerType: .onDistance(0.5), gender: "male",
                  description: "燃脂模式启动，保持轻松交谈的心率，脂肪正在慢慢烧。"),

        VoiceAsset(fileName: "减肥跑中_02", triggerType: .onDistance(1.0), gender: "male",
                  description: "1公里+100大卡！相当于1个小蛋糕，轻松干掉。"),

        VoiceAsset(fileName: "减肥跑中_03", triggerType: .onDistance(1.5), gender: "male",
                  description: "心率超棒，正处黄金燃脂区，深吸慢呼，给脂肪通风。"),

        VoiceAsset(fileName: "减肥跑中_04", triggerType: .onDistance(2.0), gender: "male",
                  description: "2公里达成！散步1小时的量，你轻松搞定，超高效！"),

        VoiceAsset(fileName: "减肥跑中_05", triggerType: .onDistance(2.5), gender: "male",
                  description: "最后500米，冲刺燃脂！累计300大卡，离目标更近一步。"),

        VoiceAsset(fileName: "减肥跑中_06", triggerType: .onDistance(3.0), gender: "male",
                  description: "燃脂跑完成！今天的热量缺口，正在帮你悄悄变瘦。", priority: .high),
    ]

    // MARK: - Public Methods

    /// 获取开始语音
    func getStartVoice() -> VoiceAsset? {
        return femaleVoices.first { voice in
            if case .onStart = voice.triggerType {
                return true
            }
            return false
        }
    }

    /// 获取跑中距离语音
    func getDistanceVoice(distance: Double, goal: TrainingGoal) -> VoiceAsset? {
        let voices = goal == .threeK ? beginnerMaleVoices : fatburnMaleVoices

        return voices.first { voice in
            if case .onDistance(let targetDistance) = voice.triggerType {
                return abs(distance - targetDistance) < 0.05  // 50米容差
            }
            return false
        }
    }

    /// 获取完成语音（返回2条：跑后_01 和 跑后_02）
    func getCompleteVoices() -> [VoiceAsset] {
        return femaleVoices.filter { voice in
            if case .onComplete = voice.triggerType {
                return true
            }
            return false
        }
    }

    /// 获取成就语音
    func getAchievementVoice(achievementName: String) -> VoiceAsset? {
        return femaleVoices.first { voice in
            if case .onAchievement(let name) = voice.triggerType {
                return achievementName.contains(name)
            }
            return false
        }
    }

    /// 获取应急语音
    func getEmergencyVoice() -> VoiceAsset? {
        return femaleVoices.first { voice in
            if case .onEmergency = voice.triggerType {
                return true
            }
            return false
        }
    }

    /// 获取提前结束语音
    func getEarlyStopVoice() -> VoiceAsset? {
        return femaleVoices.first { voice in
            if case .onEarlyStop = voice.triggerType {
                return true
            }
            return false
        }
    }
}
