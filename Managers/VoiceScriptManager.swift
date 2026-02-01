// VoiceScriptManager.swift
import Foundation

class VoiceScriptManager: ObservableObject {
    static let shared = VoiceScriptManager()
    @Published var allScripts: [VoiceScript] = []
    @Published var playedScripts = Set<String>()

    init() {
        loadAllScripts()
    }

    private func loadAllScripts() {
        // 50条语音脚本数据 - 基于用户提供的设计
        allScripts = [
            // ========== 新手模式 30条 ==========
            VoiceScript(id: "beginner_01_start", mode: .beginner, triggerType: .distance, triggerValue: 0,
                       text: "我们轻轻开始，像饭后散步一样。今天的目标很简单：完成比完美更重要。",
                       voice: "cherry", order: 1),
            VoiceScript(id: "beginner_02_body_awareness", mode: .beginner, triggerType: .distance, triggerValue: 0.1,
                       text: "注意感受脚掌落地再弹起的感觉，像在弹簧床上轻轻跳。",
                       voice: "cherry", order: 2),
            VoiceScript(id: "beginner_03_warmup", mode: .beginner, triggerType: .distance, triggerValue: 0.2,
                       text: "前500米是用来让身体'打招呼'的，不用着急。",
                       voice: "cherry", order: 3),
            VoiceScript(id: "beginner_04_500m", mode: .beginner, triggerType: .distance, triggerValue: 0.5,
                       text: "500米了！身体开始热起来了。注意呼吸，尝试'鼻子吸气，嘴巴呼气'。",
                       voice: "cherry", order: 4),
            VoiceScript(id: "beginner_05_rhythm", mode: .beginner, triggerType: .distance, triggerValue: 0.7,
                       text: "很好！找到节奏了吗？就像听一首喜欢的歌，让身体跟着节奏走。",
                       voice: "cherry", order: 5),
            VoiceScript(id: "beginner_06_1km", mode: .beginner, triggerType: .distance, triggerValue: 1.0,
                       text: "1公里！第一个里程碑。你知道吗，80%的人从没跑过这么远。",
                       voice: "cherry", order: 6),
            VoiceScript(id: "beginner_07_walk_ok", mode: .beginner, triggerType: .heartRate, triggerValue: 160,
                       text: "如果感觉呼吸急促，很正常。我们走30秒调整一下，这很聪明。",
                       voice: "cherry", order: 7),
            VoiceScript(id: "beginner_08_keep_moving", mode: .beginner, triggerType: .state, triggerValue: 1,
                       text: "走的时候也别停，保持脚步移动。想象在机场快步赶飞机。",
                       voice: "cherry", order: 8),
            VoiceScript(id: "beginner_09_1_5km", mode: .beginner, triggerType: .distance, triggerValue: 1.5,
                       text: "1.5公里，已经过半了！剩下的路都是下坡心理。",
                       voice: "cherry", order: 9),
            VoiceScript(id: "beginner_10_relax", mode: .beginner, triggerType: .distance, triggerValue: 1.6,
                       text: "注意肩膀是否紧绷？耸耸肩，让紧张像水流走。",
                       voice: "cherry", order: 10),
            VoiceScript(id: "beginner_11_2km", mode: .beginner, triggerType: .distance, triggerValue: 2.0,
                       text: "2公里！新手毕业的门槛就在眼前。",
                       voice: "cherry", order: 11),
            VoiceScript(id: "beginner_12_reframe_fatigue", mode: .beginner, triggerType: .fatigue, triggerValue: 1,
                       text: "感到累了？这是身体在说'我正在变强'。把累重新定义为进步信号。",
                       voice: "cherry", order: 12),
            VoiceScript(id: "beginner_13_game", mode: .beginner, triggerType: .fatigue, triggerValue: 1,
                       text: "我们来玩个游戏：找到前面第3棵树，跑到那里就可以走10步。",
                       voice: "cherry", order: 13),
            VoiceScript(id: "beginner_14_mindfulness", mode: .beginner, triggerType: .fatigue, triggerValue: 1,
                       text: "如果脑子里有'放弃'的念头，轻轻对它说：'我看到你了，但我选择继续'。",
                       voice: "cherry", order: 14),
            VoiceScript(id: "beginner_15_2_5km", mode: .beginner, triggerType: .distance, triggerValue: 2.5,
                       text: "2.5公里！最后500米。想象终点线有冰淇淋在等你。",
                       voice: "cherry", order: 15),
            VoiceScript(id: "beginner_16_final_500m", mode: .beginner, triggerType: .distance, triggerValue: 2.5,
                       text: "最后500米！你已经跑了83%，剩下的17%只是锦上添花。",
                       voice: "cherry", order: 16),
            VoiceScript(id: "beginner_17_choice", mode: .beginner, triggerType: .distance, triggerValue: 2.6,
                       text: "可以慢慢加速，像汽车平稳换挡。或者保持节奏，用你最舒服的方式。",
                       voice: "cherry", order: 17),
            VoiceScript(id: "beginner_18_count_steps", mode: .beginner, triggerType: .distance, triggerValue: 2.7,
                       text: "最后300米！数90步，每步都离终点更近。",
                       voice: "cherry", order: 18),
            VoiceScript(id: "beginner_19_final_100m", mode: .beginner, triggerType: .distance, triggerValue: 2.9,
                       text: "最后100米！感受心脏有力的跳动，这是生命的鼓点。",
                       voice: "cherry", order: 19),
            VoiceScript(id: "beginner_20_countdown", mode: .beginner, triggerType: .distance, triggerValue: 3.0,
                       text: "3…2…1…完成！3公里达成！",
                       voice: "cherry", order: 20),
            VoiceScript(id: "beginner_21_cooldown", mode: .beginner, triggerType: .state, triggerValue: 2,
                       text: "慢慢停下，不要立刻静止。走一会儿，让心跳平稳回落。",
                       voice: "cherry", order: 21),
            VoiceScript(id: "beginner_22_congrats", mode: .beginner, triggerType: .state, triggerValue: 2,
                       text: "恭喜！你刚刚完成了人生第一个3公里。从今天起，你就是'3公里跑者'了。",
                       voice: "cherry", order: 22),
            VoiceScript(id: "beginner_23_data_recap", mode: .beginner, triggerType: .state, triggerValue: 2,
                       text: "看看你的数据：3公里，[时间]。这是你能力的全新基准线。",
                       voice: "cherry", order: 23),
            VoiceScript(id: "beginner_24_body_feelings", mode: .beginner, triggerType: .state, triggerValue: 2,
                       text: "感受一下此刻的身体：肌肉的微热、呼吸的深度、心里的成就感。",
                       voice: "cherry", order: 24),
            VoiceScript(id: "beginner_25_achievement", mode: .beginner, triggerType: .state, triggerValue: 2,
                       text: "这个成就属于你。无论今天发生了什么，这一刻你赢了。",
                       voice: "cherry", order: 25),
            VoiceScript(id: "beginner_26_heart_rate_high", mode: .beginner, triggerType: .heartRate, triggerValue: 170,
                       text: "心率有点快？我们走1分钟，专注深呼吸：吸气4秒，屏住2秒，呼气6秒。",
                       voice: "cherry", order: 26),
            VoiceScript(id: "beginner_27_low_state", mode: .beginner, triggerType: .state, triggerValue: 3,
                       text: "今天状态不太好？没关系。能开始就已经赢了80%的人。",
                       voice: "cherry", order: 27),
            VoiceScript(id: "beginner_28_early_stop", mode: .beginner, triggerType: .state, triggerValue: 4,
                       text: "想提前结束？完全可以。今天跑了[距离]，已经是进步。倾听身体最重要。",
                       voice: "cherry", order: 28),
            VoiceScript(id: "beginner_29_slow_pace", mode: .beginner, triggerType: .pace, triggerValue: 1,
                       text: "配速比上次慢？看看周围，今天有风/温度高/你昨晚没睡好。环境因素很重要。",
                       voice: "cherry", order: 29),
            VoiceScript(id: "beginner_30_memory_anchor", mode: .beginner, triggerType: .state, triggerValue: 2,
                       text: "记住这种感觉。下次当你不想跑时，回忆此刻的成就感。",
                       voice: "cherry", order: 30),

            // ========== 减肥模式 20条 ==========
            VoiceScript(id: "fatburn_01_start", mode: .fatburn, triggerType: .distance, triggerValue: 0,
                       text: "燃脂模式启动！今天的目标：让脂肪高效燃烧。保持能轻松交谈的心率。",
                       voice: "ethan", order: 1),
            VoiceScript(id: "fatburn_02_education", mode: .fatburn, triggerType: .distance, triggerValue: 0.2,
                       text: "减肥的关键不是跑多快，而是让身体进入'燃脂区间'。我们来找这个甜蜜点。",
                       voice: "ethan", order: 2),
            VoiceScript(id: "fatburn_03_metaphor", mode: .fatburn, triggerType: .distance, triggerValue: 0.3,
                       text: "想象你是一辆混合动力车：前10分钟烧糖，之后开始高效烧脂。我们为长远而跑。",
                       voice: "ethan", order: 3),
            VoiceScript(id: "fatburn_04_100cal", mode: .fatburn, triggerType: .calories, triggerValue: 100,
                       text: "一百大卡达成！相当于一个苹果派的热量被燃烧了。",
                       voice: "ethan", order: 4),
            VoiceScript(id: "fatburn_05_hr_zone", mode: .fatburn, triggerType: .heartRateZone, triggerValue: 1,
                       text: "完美！心率正处在最佳燃脂区间，百分之六十到七十最大心率。脂肪正在高效代谢。",
                       voice: "ethan", order: 5),
            VoiceScript(id: "fatburn_06_200cal", mode: .fatburn, triggerType: .calories, triggerValue: 200,
                       text: "二百大卡！这需要普通人散步五十分钟，而你用跑步二十分钟就做到了。",
                       voice: "ethan", order: 6),
            VoiceScript(id: "fatburn_07_oxygen", mode: .fatburn, triggerType: .heartRate, triggerValue: 150,
                       text: "注意呼吸，脂肪燃烧需要充足的氧气。深吸慢呼，给脂肪'通风'。",
                       voice: "ethan", order: 7),
            VoiceScript(id: "fatburn_08_300cal", mode: .fatburn, triggerType: .calories, triggerValue: 300,
                       text: "三百大卡里程碑！这相当于昨天晚餐多余热量的总和。",
                       voice: "ethan", order: 8),
            VoiceScript(id: "fatburn_09_efficiency_score", mode: .fatburn, triggerType: .calories, triggerValue: 250,
                       text: "燃脂效率评分：八十五分！你正处在'黄金燃烧带'。",
                       voice: "ethan", order: 9),
            VoiceScript(id: "fatburn_10_poetic", mode: .fatburn, triggerType: .distance, triggerValue: 1.5,
                       text: "每跑一步，都在和过去的体重说再见。脚步越轻盈，身体越轻盈。",
                       voice: "ethan", order: 10),
            VoiceScript(id: "fatburn_11_visualization", mode: .fatburn, triggerType: .fatigue, triggerValue: 1,
                       text: "感到辛苦时，想象脂肪细胞正在缩小，像漏气的气球。",
                       voice: "ethan", order: 11),
            VoiceScript(id: "fatburn_12_reframe", mode: .fatburn, triggerType: .fatigue, triggerValue: 1,
                       text: "减肥不是惩罚，而是给自己的礼物。跑步是拆礼物的过程。",
                       voice: "ethan", order: 12),
            VoiceScript(id: "fatburn_13_afterburn", mode: .fatburn, triggerType: .time, triggerValue: 900,
                       text: "你已经连续运动十五分钟，新陈代谢率正在提升，意味着后续二十四小时都在多燃脂。",
                       voice: "ethan", order: 13),
            VoiceScript(id: "fatburn_14_scale_imagine", mode: .fatburn, triggerType: .fatigue, triggerValue: 2,
                       text: "想象体重秤的数字正在因为你此刻的努力而跳动下降。",
                       voice: "ethan", order: 14),
            VoiceScript(id: "fatburn_15_weekly_progress", mode: .fatburn, triggerType: .calories, triggerValue: 1200,
                       text: "本周累计燃烧：一千二百，目标二千大卡，完成度百分之六十。保持这个节奏，周目标稳稳达成。",
                       voice: "ethan", order: 15),
            VoiceScript(id: "fatburn_16_fat_grams", mode: .fatburn, triggerType: .calories, triggerValue: 800,
                       text: "根据你的体重和速度，预计本次跑步可减脂约二十克。这周累计已超一百克。",
                       voice: "ethan", order: 16),
            VoiceScript(id: "fatburn_17_efficiency_gain", mode: .fatburn, triggerType: .state, triggerValue: 1,
                       text: "燃脂效率比上次提升百分之十五，身体正在学习更高效地燃烧脂肪。",
                       voice: "ethan", order: 17),
            VoiceScript(id: "fatburn_18_continuing_burn", mode: .fatburn, triggerType: .state, triggerValue: 2,
                       text: "跑步结束！但燃脂还在继续。未来二十四小时，你的代谢率都比平时高。",
                       voice: "ethan", order: 18),
            VoiceScript(id: "fatburn_19_calorie_deficit", mode: .fatburn, triggerType: .state, triggerValue: 2,
                       text: "今天你创造了五百大卡的热量缺口。如果饮食配合，这相当于每周减重零点五公斤的进度。",
                       voice: "ethan", order: 19),
            VoiceScript(id: "fatburn_20_metabolic_fire", mode: .fatburn, triggerType: .state, triggerValue: 2,
                       text: "记住今天高效燃脂的感觉。这种'代谢火力'会随着每次跑步越来越强。",
                       voice: "ethan", order: 20)
        ]
    }

    func scripts(for mode: RunMode) -> [VoiceScript] {
        allScripts.filter { $0.mode == mode }.sorted { $0.order < $1.order }
    }

    func shouldTrigger(script: VoiceScript, context: RunContext) -> Bool {
        if playedScripts.contains(script.id) {
            return false
        }

        let shouldTrigger: Bool
        switch script.triggerType {
        case .distance:
            // 距离触发：只要当前距离 >= 触发值即可
            // 允许回溯触发（如果跳过了某个点）
            shouldTrigger = context.distance >= script.triggerValue
        case .calories:
            // 热量触发：当前热量 >= 触发值
            shouldTrigger = context.calories >= script.triggerValue
        case .heartRate:
            // 心率触发：当前心率 >= 触发值
            shouldTrigger = context.heartRate >= Int(script.triggerValue)
        case .time:
            // 时间触发：当前时长 >= 触发值
            shouldTrigger = context.duration >= script.triggerValue
        case .state:
            // 状态触发：
            // 0 = 开始，1 = 行走中，2 = 完成，3 = 状态不佳，4 = 提前结束
            if script.triggerValue == 0 {
                shouldTrigger = context.distance <= 0.05 // 刚开始（容错范围 50米）
            } else if script.triggerValue == 1 {
                shouldTrigger = context.isWalking
            } else if script.triggerValue == 2 {
                shouldTrigger = context.isFinished
            } else {
                shouldTrigger = false
            }
        case .fatigue:
            shouldTrigger = context.fatigueLevel == "high"
        case .pace:
            shouldTrigger = context.pace > 0 && context.pace < script.triggerValue
        case .heartRateZone:
            shouldTrigger = context.heartRateZone == "optimal"
        }

        if shouldTrigger {
            print("✓ 触发条件满足: \(script.id) (\(script.triggerType)=\(script.triggerValue), 当前:\(getCurrentValue(for: script.triggerType, context: context)))")
        }

        return shouldTrigger
    }

    private func getCurrentValue(for type: TriggerType, context: RunContext) -> String {
        switch type {
        case .distance: return "\(context.distance)km"
        case .calories: return "\(Int(context.calories))卡"
        case .heartRate: return "\(context.heartRate)BPM"
        case .time: return "\(Int(context.duration))秒"
        case .state: return context.isFinished ? "已完成" : "进行中"
        case .fatigue: return context.fatigueLevel
        case .pace: return "\(context.pace)"
        case .heartRateZone: return context.heartRateZone
        }
    }

    func markAsPlayed(_ id: String) { playedScripts.insert(id) }
    func reset() { playedScripts.removeAll() }
}
