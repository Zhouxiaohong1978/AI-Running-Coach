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

    /// 减肥燃脂跑中语音（9条，支持 a/b/c 风格变体）
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

        VoiceAsset(fileName: "减肥跑中_07", triggerType: .onDistance(5.0), gender: "male",
                  description: "5公里，脂肪分解正全速进行，坚持就是在改变身体。",
                  descriptionEn: "Five kilometers — fat is breaking down at full speed. Keep going and your body is changing."),

        VoiceAsset(fileName: "减肥跑中_08", triggerType: .onDistance(5.5), gender: "male",
                  description: "超过5公里了，你的身体正在用存脂供能，这就是燃脂的感觉。",
                  descriptionEn: "Past five-five — your body is running on stored fat. This is exactly what fat-burning feels like."),

        VoiceAsset(fileName: "减肥跑中_09", triggerType: .onDistance(6.0), gender: "male",
                  description: "6公里达成！坚持到这里的人，减脂效果是普通人的2倍。",
                  descriptionEn: "Six kilometers! People who make it this far burn fat at twice the rate of an average workout.",
                  priority: .high),
    ]

    /// 减肥燃脂专属跑前/跑后语音（支持 a/b/c 风格变体）
    private let fatburnFemaleVoices: [VoiceAsset] = [
        VoiceAsset(fileName: "减肥跑前_01", triggerType: .onStart, gender: "female",
                  description: "今天又来跑步了！坚持本身就是最好的减脂药，我们开始吧。",
                  descriptionEn: "You showed up again! Consistency is the best fat-loss medicine — let's get moving.",
                  priority: .high),

        VoiceAsset(fileName: "减肥跑后_01", triggerType: .onComplete, gender: "female",
                  description: "完成！今天消耗的热量，正在悄悄改变你的身材曲线。",
                  descriptionEn: "Done! The calories you just burned are quietly reshaping your body right now.",
                  priority: .high),

        VoiceAsset(fileName: "减肥跑后_02", triggerType: .onComplete, gender: "female",
                  description: "记得补水，拉伸5分钟，让肌肉在恢复中继续燃脂。",
                  descriptionEn: "Hydrate and stretch for five minutes — your muscles keep burning fat while they recover.",
                  priority: .high),
    ]

    // MARK: - Public Methods

    /// 获取开始语音（减肥目标使用专属跑前语音 + 风格变体）
    func getStartVoice(goal: TrainingGoal = .threeK, coachStyle: CoachStyle = .encouraging) -> VoiceAsset? {
        if goal == .weightLoss {
            if let base = fatburnFemaleVoices.first(where: { if case .onStart = $0.triggerType { return true }; return false }) {
                let styledName = fatburnStyledName(base.fileName, style: coachStyle)
                return styledName == base.fileName ? base :
                    VoiceAsset(fileName: styledName, triggerType: base.triggerType,
                               gender: base.gender, description: base.description,
                               descriptionEn: base.descriptionEn, priority: base.priority)
            }
        }
        return femaleVoices.first { if case .onStart = $0.triggerType { return true }; return false }
    }

    /// 获取跑中距离语音（支持教练风格 a/b/c 变体）
    func getDistanceVoice(distance: Double, goal: TrainingGoal, targetKm: Double = 3.0, coachStyle: CoachStyle = .encouraging) -> VoiceAsset? {

        // 1. 通用跑中_00（0.3km，全目标，优先触发）
        if distance >= 0.3 && distance < 0.35 {
            return universalVoice(index: "00", km: 0.3, style: coachStyle)
        }

        // 2. 目标专属语音（减肥 / 新手）带风格变体
        let voices = goal == .weightLoss ? fatburnMaleVoices : beginnerMaleVoices
        let threeKOnly: Set<String> = ["新手跑中_03", "新手跑中_06", "新手跑中_07", "新手跑中_08"]

        if let voice = voices.first(where: { v in
            guard case .onDistance(let d) = v.triggerType else { return false }
            if threeKOnly.contains(v.fileName) && abs(targetKm - 3.0) > 0.05 { return false }
            let delta = distance - d
            return delta >= 0 && delta < 0.05
        }) {
            // 减肥/新手跑中系列均支持风格变体
            let styledName: String
            if voice.fileName.hasPrefix("新手跑中") {
                styledName = newbieStyledName(voice.fileName, style: coachStyle)
            } else if voice.fileName.hasPrefix("减肥跑中") {
                styledName = fatburnStyledName(voice.fileName, style: coachStyle)
            } else {
                return voice
            }
            return styledName == voice.fileName ? voice :
                VoiceAsset(fileName: styledName, triggerType: voice.triggerType,
                           gender: voice.gender, description: voice.description,
                           descriptionEn: voice.descriptionEn, priority: voice.priority)
        }

        // 3. 通用跑中（填补非专属距离的空缺）
        return checkUniversalVoice(distance: distance, targetKm: targetKm, goal: goal, style: coachStyle)
    }

    // MARK: - 风格变体辅助

    /// 通用跑中文件名（a/b/c，_10c 未录制时降级到 _10a）
    private func universalStyledName(_ base: String, style: CoachStyle) -> String {
        let suffix: String
        switch style {
        case .encouraging: suffix = "a"
        case .strict:      suffix = "b"
        case .calm:        suffix = (base == "通用跑中_10") ? "a" : "c"  // _10c 未录制
        }
        return base + suffix
    }

    /// 新手跑中变体（严格型用原始文件，鼓励/温和用带后缀文件）
    private func newbieStyledName(_ base: String, style: CoachStyle) -> String {
        switch style {
        case .encouraging: return base + "a"
        case .strict:      return base        // 原始文件在 voice/male/
        case .calm:        return base + "c"
        }
    }

    /// 减肥跑中/跑前/跑后变体（_01/_03/_04 缺少 b，严格型降级到 a）
    private func fatburnStyledName(_ base: String, style: CoachStyle) -> String {
        let missingB: Set<String> = ["减肥跑中_01", "减肥跑中_03", "减肥跑中_04"]
        switch style {
        case .encouraging: return base + "a"
        case .strict:      return missingB.contains(base) ? base + "a" : base + "b"
        case .calm:        return base + "c"
        }
    }

    /// 构造通用跑中 VoiceAsset
    private func universalVoice(index: String, km: Double, style: CoachStyle) -> VoiceAsset {
        let base = "通用跑中_\(index)"
        let fileName = universalStyledName(base, style: style)
        return VoiceAsset(fileName: fileName, triggerType: .onDistance(km),
                         gender: "neutral", description: base, priority: .normal)
    }

    /// 通用跑中路由（按距离+目标条件匹配）
    private func checkUniversalVoice(distance: Double, targetKm: Double, goal: TrainingGoal, style: CoachStyle) -> VoiceAsset? {
        struct Rule {
            let km: Double; let index: String
            let match: (Double, TrainingGoal) -> Bool
        }
        let rules: [Rule] = [
            // 1.5km：非3km目标 + 非减肥（减肥有减肥跑中_03）
            Rule(km: 1.5, index: "12") { t, g in abs(t - 3.0) > 0.05 && g != .weightLoss },
            // 2.5/2.8/3.0km：非3km目标 + 非减肥
            Rule(km: 2.5, index: "01") { t, g in t >= 3.2 && g != .weightLoss },
            Rule(km: 2.8, index: "02") { t, g in t >= 3.2 && g != .weightLoss },
            Rule(km: 3.0, index: "03") { t, g in abs(t - 3.0) > 0.05 && g != .weightLoss },
            // 3.5km~6.5km：全目标（减肥超出3km后也需要）
            Rule(km: 3.5, index: "04") { t, _ in t >= 3.5 },   // 内容已改为通用里程碑，无上限
            Rule(km: 4.0, index: "05") { t, _ in t >= 4.0 },
            Rule(km: 4.5, index: "06") { t, _ in t >= 4.5 },   // 内容已改为通用里程碑，无上限
            // 10km 专属
            Rule(km: 5.5, index: "11") { t, _ in abs(t - 10.0) < 0.5 },
            Rule(km: 6.0, index: "07") { t, _ in abs(t - 10.0) < 0.5 },
            Rule(km: 7.0, index: "08") { t, _ in abs(t - 10.0) < 0.5 },
            Rule(km: 8.0, index: "09") { t, _ in abs(t - 10.0) < 0.5 },
            Rule(km: 9.0, index: "10") { t, _ in abs(t - 10.0) < 0.5 },
        ]
        for rule in rules {
            guard rule.match(targetKm, goal) else { continue }
            let delta = distance - rule.km
            guard delta >= 0 && delta < 0.05 else { continue }
            return universalVoice(index: rule.index, km: rule.km, style: style)
        }
        return nil
    }

    /// 获取完成语音（减肥目标使用专属跑后语音 + 风格变体）
    func getCompleteVoices(goal: TrainingGoal = .threeK, coachStyle: CoachStyle = .encouraging) -> [VoiceAsset] {
        if goal == .weightLoss {
            return fatburnFemaleVoices
                .filter { if case .onComplete = $0.triggerType { return true }; return false }
                .map { base in
                    let styledName = fatburnStyledName(base.fileName, style: coachStyle)
                    return styledName == base.fileName ? base :
                        VoiceAsset(fileName: styledName, triggerType: base.triggerType,
                                   gender: base.gender, description: base.description,
                                   descriptionEn: base.descriptionEn, priority: base.priority)
                }
        }
        return femaleVoices.filter { if case .onComplete = $0.triggerType { return true }; return false }
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

    /// 获取跑步中所有可能触发的语音（用于 EN 模式预缓存）
    func getAllRunVoices(goal: TrainingGoal, coachStyle: CoachStyle = .encouraging) -> [VoiceAsset] {
        var voices: [VoiceAsset] = []
        if let start = getStartVoice(goal: goal, coachStyle: coachStyle) { voices.append(start) }
        voices.append(contentsOf: goal == .weightLoss ? fatburnMaleVoices : beginnerMaleVoices)
        voices.append(contentsOf: getCompleteVoices(goal: goal, coachStyle: coachStyle))
        if let emergency = getEmergencyVoice() { voices.append(emergency) }
        if let earlyStop = getEarlyStopVoice() { voices.append(earlyStop) }
        return voices
    }
}
