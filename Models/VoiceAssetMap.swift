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
    let description: String       // 中文描述（气泡文字 + 中文TTS文本）
    let descriptionEn: String     // 英文描述（英文TTS文本）
    let priority: AudioPriority   // 优先级

    init(fileName: String, triggerType: VoiceTriggerType, gender: String,
         description: String, descriptionEn: String = "", priority: AudioPriority = .normal) {
        self.fileName = fileName
        self.triggerType = triggerType
        self.gender = gender
        self.description = description
        self.descriptionEn = descriptionEn
        self.priority = priority
    }

    /// 当前语言的播报文本
    var localizedText: String {
        let isEN = LanguageManager.shared.currentLocale == "en"
        return (isEN && !descriptionEn.isEmpty) ? descriptionEn : description
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
                  description: "我们轻轻开始，跟着自己的节奏就好，完成比完美更重要。",
                  descriptionEn: "Let's start gently, just follow your own rhythm. Today, completion beats perfection.",
                  priority: .high),

        // 跑后
        VoiceAsset(fileName: "跑后_01", triggerType: .onComplete, gender: "female",
                  description: "3公里完成啦，慢慢走一会儿，让心跳平稳下来。",
                  descriptionEn: "Three kilometers done! Walk for a moment and let your heart rate settle.",
                  priority: .high),

        VoiceAsset(fileName: "跑后_02", triggerType: .onComplete, gender: "female",
                  description: "点击结束，解锁你的专属跑步成就徽章吧！",
                  descriptionEn: "Tap finish and unlock your exclusive running achievement badges!",
                  priority: .high),

        // 应急
        VoiceAsset(fileName: "应急_01", triggerType: .onEmergency, gender: "female",
                  description: "状态不太好没关系，能开始就赢了80%的人，累了就走一走。",
                  descriptionEn: "Not feeling great? That's okay — starting puts you ahead of 80% of people. Walk it out when you need to.",
                  priority: .urgent),

        VoiceAsset(fileName: "应急_02", triggerType: .onEarlyStop, gender: "female",
                  description: "想提前结束完全可以，今天跑的每一步都是进步。",
                  descriptionEn: "Finishing early is completely fine. Every step you ran today is progress.",
                  priority: .urgent),

        // 新手成就（3条）
        VoiceAsset(fileName: "新手成就_01", triggerType: .onAchievement("初露锋芒"), gender: "female",
                  description: "恭喜解锁初露锋芒成就！正式成为3公里跑者啦！",
                  descriptionEn: "First Steps unlocked! You're officially a 3K runner!",
                  priority: .high),

        VoiceAsset(fileName: "新手成就_02", triggerType: .onAchievement("节奏大师"), gender: "female",
                  description: "解锁节奏大师！跑步超稳，节奏感拉满。",
                  descriptionEn: "Rhythm Master unlocked! Your pace is rock solid — you've got the groove.",
                  priority: .high),

        VoiceAsset(fileName: "新手成就_03", triggerType: .onAchievement("风雨无阻"), gender: "female",
                  description: "解锁风雨无阻！天气挡不住你，这才是跑者精神。",
                  descriptionEn: "Rain or Shine unlocked! Nothing stops a true runner — that's the spirit!",
                  priority: .high),

        // 减肥成就（3条）
        VoiceAsset(fileName: "减肥成就_01", triggerType: .onAchievement("脂肪杀手"), gender: "female",
                  description: "解锁脂肪杀手！单次燃脂500大卡，脂肪瑟瑟发抖。",
                  descriptionEn: "Fat Burner unlocked! 500 calories torched in one run — fat doesn't stand a chance.",
                  priority: .high),

        VoiceAsset(fileName: "减肥成就_02", triggerType: .onAchievement("代谢达人"), gender: "female",
                  description: "解锁代谢达人！连续燃脂跑，身体变成高效燃脂机。",
                  descriptionEn: "Metabolism Pro unlocked! Your body is becoming a high-efficiency fat-burning machine.",
                  priority: .high),

        VoiceAsset(fileName: "减肥成就_03", triggerType: .onAchievement("斤斤计较"), gender: "female",
                  description: "解锁斤斤计较！减重1公斤，历史性突破！",
                  descriptionEn: "Every Gram Counts unlocked! One kilogram down — a historic milestone!",
                  priority: .high),
    ]

    // MARK: - 男声语音（14条）

    /// 新手3公里跑中语音（8条）
    private let beginnerMaleVoices: [VoiceAsset] = [
        VoiceAsset(fileName: "新手跑中_01", triggerType: .onDistance(0.5), gender: "male",
                  description: "身体热起来啦，鼻子吸气嘴巴呼气，找到舒服的节奏。",
                  descriptionEn: "Body's warming up! Try breathing in through your nose and out through your mouth. Find your comfortable rhythm."),

        VoiceAsset(fileName: "新手跑中_02", triggerType: .onDistance(1.0), gender: "male",
                  description: "1公里达成！80%的人都没跑过这么远，你超棒的！",
                  descriptionEn: "One kilometer done! 80% of people have never run this far — you're absolutely crushing it!"),

        VoiceAsset(fileName: "新手跑中_03", triggerType: .onDistance(1.5), gender: "male",
                  description: "已经过半啦，肩膀耸耸肩放松下，剩下的路越跑越轻松。",
                  descriptionEn: "Halfway there! Roll your shoulders to release the tension. The rest only gets easier from here."),

        VoiceAsset(fileName: "新手跑中_04", triggerType: .onDistance(2.0), gender: "male",
                  description: "2公里了！新手毕业线就在眼前，再坚持一下。",
                  descriptionEn: "Two kilometers! The beginner finish line is right in sight — hold on just a little longer."),

        VoiceAsset(fileName: "新手跑中_05", triggerType: .onDistance(2.2), gender: "male",
                  description: "累了就走30秒，这不是放弃，是聪明的调整。",
                  descriptionEn: "Need a break? Walk for 30 seconds — that's not giving up, that's smart training."),

        VoiceAsset(fileName: "新手跑中_06", triggerType: .onDistance(2.5), gender: "male",
                  description: "最后500米！你已经跑了83%，冲就完事了！",
                  descriptionEn: "Final 500 meters! You've already done 83% — just go for it!"),

        VoiceAsset(fileName: "新手跑中_07", triggerType: .onDistance(2.8), gender: "male",
                  description: "最后200米，感受心跳，为自己加油！",
                  descriptionEn: "Last 200 meters — feel that heartbeat and cheer yourself on!"),

        VoiceAsset(fileName: "新手跑中_08", triggerType: .onDistance(3.0), gender: "male",
                  description: "搞定！3公里达成，你太棒了！",
                  descriptionEn: "Done it! 3 kilometers complete — you are absolutely amazing!",
                  priority: .high),
    ]

    /// 减肥燃脂跑中语音（6条）
    private let fatburnMaleVoices: [VoiceAsset] = [
        VoiceAsset(fileName: "减肥跑中_01", triggerType: .onDistance(0.5), gender: "male",
                  description: "燃脂模式启动，保持轻松交谈的心率，脂肪正在慢慢烧。",
                  descriptionEn: "Fat-burn mode activated! Stay at a conversational pace — your fat is slowly melting away."),

        VoiceAsset(fileName: "减肥跑中_02", triggerType: .onDistance(1.0), gender: "male",
                  description: "1公里+100大卡！相当于1个小蛋糕，轻松干掉。",
                  descriptionEn: "One kilometer, 100 calories gone! That's a small cupcake — wiped out just like that."),

        VoiceAsset(fileName: "减肥跑中_03", triggerType: .onDistance(1.5), gender: "male",
                  description: "心率超棒，正处黄金燃脂区，深吸慢呼，给脂肪通风。",
                  descriptionEn: "Heart rate is perfect — you're in the golden fat-burning zone. Deep slow breaths keep the burn going."),

        VoiceAsset(fileName: "减肥跑中_04", triggerType: .onDistance(2.0), gender: "male",
                  description: "2公里达成！散步1小时的量，你轻松搞定，超高效！",
                  descriptionEn: "Two kilometers done! You just matched an hour of walking — ridiculously efficient!"),

        VoiceAsset(fileName: "减肥跑中_05", triggerType: .onDistance(2.5), gender: "male",
                  description: "最后500米，冲刺燃脂！累计300大卡，离目标更近一步。",
                  descriptionEn: "Final 500 meters — sprint into the fat-burn finish! 300 calories in, one step closer to your goal."),

        VoiceAsset(fileName: "减肥跑中_06", triggerType: .onDistance(3.0), gender: "male",
                  description: "燃脂跑完成！今天的热量缺口，正在帮你悄悄变瘦。",
                  descriptionEn: "Fat-burn run complete! Today's calorie deficit is quietly and steadily making you leaner.",
                  priority: .high),
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
        // 燃脂语音专属减肥目标；其他目标（含进阶/马拉松）复用通用热身语音
        let voices = goal == .weightLoss ? fatburnMaleVoices : beginnerMaleVoices

        return voices.first { voice in
            if case .onDistance(let targetDistance) = voice.triggerType {
                let delta = distance - targetDistance
                return delta >= 0 && delta < 0.05  // 到达后50米内触发（单向）
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
