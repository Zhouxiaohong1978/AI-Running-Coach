//
//  VoiceTemplateMap.swift
//  AI跑步教练
//
//  动态语音模板库：11种触发场景 × 3条变体 × 双语
//  变量占位符：{pace} {hr} {calories} {distance} {duration}
//             {runCount} {totalKm} {monthKm} {monthRuns}
//             {food} {remaining} {hrZone} {streak}

import Foundation

class VoiceTemplateMap {
    static let shared = VoiceTemplateMap()
    private init() {}

    private lazy var templates: [VoiceTriggerEvent: VoiceTemplate] = buildTemplates()

    func template(for event: VoiceTriggerEvent) -> VoiceTemplate {
        return templates[event] ?? fallbackTemplate(event)
    }

    // MARK: - 模板构建

    private func buildTemplates() -> [VoiceTriggerEvent: VoiceTemplate] {
        var map: [VoiceTriggerEvent: VoiceTemplate] = [:]

        // ─── 时间里程碑 ──────────────────────────────────────────

        map[.time5min] = VoiceTemplate(
            event: .time5min,
            variants: [
                "5分钟了！身体正在热起来，鼻子吸气嘴巴呼气，找到自己的节奏！",
                "跑了5分钟，热身完成！接下来的每一步都是在为你的健康投资。",
                "5分钟了，已消耗{calories}大卡，迈出舒服的步伐继续吧！"
            ],
            variantsEn: [
                "Five minutes in! Your body is heating up — breathe in through your nose, out through your mouth. Find your rhythm!",
                "Five-minute mark, warm-up done! Every step from here is an investment in your health.",
                "Five minutes down, {calories} calories burned — settle into a comfortable stride and keep going!"
            ]
        )

        map[.time10min] = VoiceTemplate(
            event: .time10min,
            variants: [
                "10分钟达成！身体已经完全热开了，现在是最佳燃脂时机，保持节奏！",
                "跑了10分钟，配速{pace}，你的状态不错，继续保持这个强度！",
                "10分钟了，已烧掉{calories}大卡——相当于{food}，出色！"
            ],
            variantsEn: [
                "Ten minutes strong! Body fully warmed up — prime fat-burning time starts now. Keep the rhythm!",
                "Ten-minute mark! Pace at {pace} — you're looking great, maintain this intensity!",
                "Ten minutes in, {calories} calories gone — that's {food} worth of energy. Outstanding!"
            ]
        )

        map[.time20min] = VoiceTemplate(
            event: .time20min,
            variants: [
                "跑了20分钟！已消耗约{calories}大卡，脂肪正在高效燃烧，大多数人早已放弃，你还在！",
                "20分钟里程碑！本月已跑{monthKm}公里，越来越强！",
                "20分钟了，配速{pace}，今天状态真不错，继续冲！"
            ],
            variantsEn: [
                "Twenty minutes in! {calories} calories burned — fat burning is in full swing. Most people quit long before this — you're still here!",
                "Twenty-minute milestone! {monthKm} km this month and rising — you're getting stronger!",
                "Twenty minutes in at pace {pace} — you're having a great run today. Keep charging!"
            ]
        )

        map[.time30min] = VoiceTemplate(
            event: .time30min,
            variants: [
                "30分钟了！今天已消耗约{calories}大卡，30分钟有氧跑是教科书级别的健身！",
                "跑了半小时！本月你已经跑了{monthRuns}次，运动习惯正在悄悄形成。",
                "30分钟里程碑！今天跑了{distance}公里，你的心肺正在变强。"
            ],
            variantsEn: [
                "Thirty minutes! {calories} calories burned. A 30-minute aerobic run is textbook fitness — incredible!",
                "Half an hour! {monthRuns} runs this month — the habit is quietly taking root. Amazing.",
                "Thirty-minute milestone! {distance} km today — your cardio is getting stronger with every run."
            ]
        )

        // ─── 心率区间 ──────────────────────────────────────────

        map[.hrFatBurnZone] = VoiceTemplate(
            event: .hrFatBurnZone,
            variants: [
                "心率进入燃脂区了！现在{hr}跳，正是脂肪燃烧的黄金地带，保持这个强度！",
                "完美！心率{hr}跳，燃脂区命中。深吸慢呼，让脂肪充分氧化！",
                "进入{hrZone}！{hr}跳，这个区间坚持20分钟，效果超棒！"
            ],
            variantsEn: [
                "Fat-burn zone reached! At {hr} BPM, you're in the golden zone for fat oxidation — hold this intensity!",
                "Perfect! {hr} BPM — fat-burn zone locked in. Deep, slow breaths maximize fat burning!",
                "{hrZone} hit! {hr} BPM — stay here for 20 minutes and the results will amaze you!"
            ]
        )

        map[.hrTooHigh] = VoiceTemplate(
            event: .hrTooHigh,
            variants: [
                "心率{hr}有点高了，放慢脚步，深呼吸，让心率降到160以下再提速。",
                "注意！心率已达{hr}，稍微走两步，保护心脏最重要！",
                "心率{hr}偏高，减速到能说话的强度，这才是持续跑步的秘诀。"
            ],
            variantsEn: [
                "Heart rate at {hr} — a bit high. Slow down, breathe deeply, bring it below 160 before picking back up.",
                "Heads up! {hr} BPM — take a couple of walk steps. Protecting your heart is the top priority!",
                "Heart rate at {hr} — ease to a conversational pace. That's the secret to sustainable running."
            ]
        )

        // ─── 卡路里里程碑 ─────────────────────────────────────

        map[.cal150] = VoiceTemplate(
            event: .cal150,
            variants: [
                "已消耗{calories}大卡！相当于{food}，你的身体正在消耗储备能量！",
                "燃掉{calories}大卡了——相当于{food}的热量，继续加油！",
                "{calories}大卡达成！今天的每一步都记在你的健康账户里。"
            ],
            variantsEn: [
                "{calories} calories burned! That's {food} worth of energy — your body is digging into reserves!",
                "You've torched {calories} calories — that's {food} gone! Keep it up!",
                "{calories}-calorie milestone! Every step today is going straight into your health account."
            ]
        )

        map[.cal300] = VoiceTemplate(
            event: .cal300,
            variants: [
                "已消耗{calories}大卡！超过散步一小时的量，今天的跑步效率超高！",
                "{calories}大卡里程碑！本月第{runCount}次燃脂，坚持就有效果！",
                "燃掉{calories}大卡，今天的跑步让你全天的能量代谢都在提速！"
            ],
            variantsEn: [
                "{calories} calories! You've surpassed an hour of walking in efficiency — today's run is outstanding!",
                "{calories}-calorie milestone! Run number {runCount} this month — consistency is paying off!",
                "{calories} calories burned — today's run is boosting your metabolism for the entire day!"
            ]
        )

        // ─── 配速变化 ──────────────────────────────────────────

        map[.paceImproved] = VoiceTemplate(
            event: .paceImproved,
            variants: [
                "配速提升到{pace}了！你找到节奏了，步幅稳、呼吸匀，就这么跑！",
                "加速到{pace}！身体在告诉你还有余力，享受这种感觉！",
                "配速{pace}！又快又稳，这才是进步该有的感觉！"
            ],
            variantsEn: [
                "Pace up to {pace}! You've found your groove — steady stride, even breath, just like this!",
                "Picked up to {pace}! Your body is saying it has more to give — enjoy this feeling!",
                "Pace {pace}! Smooth and fast — this is exactly what progress feels like!"
            ]
        )

        map[.paceDropped] = VoiceTemplate(
            event: .paceDropped,
            variants: [
                "配速降到{pace}了，还有{remaining}，深呼吸，小步幅跑，找回节奏！",
                "节奏慢下来了，配速{pace}，这很正常，调整呼吸，继续前行！",
                "配速{pace}，感觉累了？走30秒然后重新起跑，聪明的跑者懂得调整！"
            ],
            variantsEn: [
                "Pace dropped to {pace} with {remaining} to go. Deep breath, shorten your stride, find the rhythm again!",
                "Slowing to {pace} — totally normal. Adjust your breathing and just keep moving forward!",
                "Pace at {pace}, feeling tired? Walk 30 seconds then restart — smart runners know when to adjust!"
            ]
        )

        // ─── 扩展时间里程碑（半马 / 全马）────────────────────────

        map[.time45min] = VoiceTemplate(
            event: .time45min,
            variants: [
                "45分钟了！身体完全打开，现在是最佳状态，保持节奏继续！",
                "跑了45分钟，已消耗{calories}大卡，你的耐力正在提升！",
                "45分钟里程碑！配速{pace}，按这个节奏你会跑出好成绩！"
            ],
            variantsEn: [
                "Forty-five minutes strong! Body fully open, you're in peak form — keep the rhythm!",
                "Forty-five minutes in! {calories} calories burned — your endurance is building!",
                "Forty-five-minute milestone! Pace {pace} — hold this rhythm and you'll nail your target!"
            ]
        )

        map[.time1hour] = VoiceTemplate(
            event: .time1hour,
            variants: [
                "跑了整整1小时！你已经超过了大多数人的极限，这才是真正的跑者！",
                "1小时达成！已消耗{calories}大卡，相当于{food}，继续保持这个状态！",
                "1小时里程碑！本月已跑{monthKm}公里，今天又在积累你的成绩！"
            ],
            variantsEn: [
                "One full hour running! You've surpassed most people's limit — this is what a real runner looks like!",
                "One hour in! {calories} calories gone — that's {food} worth of energy. Keep this up!",
                "One-hour milestone! {monthKm} km this month and today's adding more to your story!"
            ]
        )

        map[.time90min] = VoiceTemplate(
            event: .time90min,
            variants: [
                "90分钟了！你已经跑了将近半程马拉松的时间，状态依然强劲！",
                "一个半小时！已消耗约{calories}大卡，你的心肺越来越强大！",
                "90分钟里程碑！配速{pace}，你正在完成很多人想都不敢想的事！"
            ],
            variantsEn: [
                "Ninety minutes in! You've run nearly a half marathon's worth of time — still going strong!",
                "Hour and a half! {calories} calories burned — your cardio is getting seriously powerful!",
                "Ninety-minute milestone! Pace {pace} — you're doing what most people only dream about!"
            ]
        )

        map[.time2hour] = VoiceTemplate(
            event: .time2hour,
            variants: [
                "2小时了！你已经超越了大多数跑者的极限，全马完赛就在前方，冲！",
                "跑了两个小时！已消耗约{calories}大卡，你的意志力是最强的装备！",
                "2小时里程碑！每一步都在书写你自己的马拉松故事！"
            ],
            variantsEn: [
                "Two hours in! You've pushed past most runners' limits — the finish line is ahead. Charge!",
                "Two full hours running! {calories} calories burned — your willpower is your strongest gear!",
                "Two-hour milestone! Every step is writing your own marathon story!"
            ]
        )

        map[.time3hour] = VoiceTemplate(
            event: .time3hour,
            variants: [
                "3小时了！你已经征服了马拉松最艰难的部分，后半段靠意志力！",
                "跑了3小时！已消耗约{calories}大卡，你的身体在极限中不断生长！",
                "3小时里程碑！放松肩膀，小步幅，一步一步向终点迈进！"
            ],
            variantsEn: [
                "Three hours in! You've conquered the hardest stretch — the rest is pure willpower!",
                "Three hours running! {calories} calories burned — your body is growing stronger at its limit!",
                "Three-hour milestone! Relax your shoulders, shorten your stride — one step at a time!"
            ]
        )

        map[.time4hour] = VoiceTemplate(
            event: .time4hour,
            variants: [
                "4小时了！你就是今天最了不起的跑者！终点就在不远处，别放弃！",
                "跑了4小时！已消耗约{calories}大卡，今天的你，超越了昨天的自己！",
                "4小时里程碑！深呼吸，放松跑，你一定能到达终点！"
            ],
            variantsEn: [
                "Four hours in! You are the most incredible runner out here today — the finish is close. Don't stop!",
                "Four hours running! {calories} calories burned — today's you has surpassed yesterday's you!",
                "Four-hour milestone! Deep breath, relax and run — you WILL reach that finish line!"
            ]
        )

        map[.time5hour] = VoiceTemplate(
            event: .time5hour,
            variants: [
                "5小时了！你是真正的勇士！每一步都是对自己的承诺，终点见！",
                "跑了5小时！已消耗约{calories}大卡，这份坚持将成为你一生的骄傲！",
                "5小时里程碑！不管多慢，每一步都算数，终点线在等你！"
            ],
            variantsEn: [
                "Five hours in! You are a true warrior — every step is a promise to yourself. See you at the finish!",
                "Five hours running! {calories} calories torched — this perseverance will be your pride for life!",
                "Five-hour milestone! No matter how slow, every step counts — the finish line is waiting for you!"
            ]
        )

        // ─── 距离里程碑 ────────────────────────────────────────

        map[.dist5km] = VoiceTemplate(
            event: .dist5km,
            variants: [
                "5公里达成！热身完成，身体进入最佳状态，保持节奏继续冲！",
                "5公里！已消耗约{calories}大卡，相当于{food}，跑步效率超高！",
                "5公里里程碑！配速{pace}，按这个节奏你会跑出好成绩！"
            ],
            variantsEn: [
                "Five kilometers done! Warm-up complete — body is in peak form. Keep the rhythm!",
                "Five km! {calories} calories burned — that's {food}. Running efficiency at its finest!",
                "Five-kilometer milestone! Pace {pace} — hold this rhythm and you'll nail your target!"
            ]
        )

        map[.dist10km] = VoiceTemplate(
            event: .dist10km,
            variants: [
                "10公里达成！正式进入长跑模式，专注节奏，享受这份跑步的自由！",
                "10公里！已消耗约{calories}大卡，相当于{food}，你今天超厉害！",
                "10公里里程碑！配速{pace}，身体已经完全适应，继续冲！"
            ],
            variantsEn: [
                "Ten kilometers done! Long-run mode activated — focus on rhythm, enjoy the freedom of running!",
                "Ten km! {calories} calories burned — that's {food}. You're absolutely crushing it today!",
                "Ten-kilometer milestone! Pace {pace} — body fully adapted. Keep charging!"
            ]
        )

        map[.dist21km] = VoiceTemplate(
            event: .dist21km,
            variants: [
                "21公里！半程马拉松完成！你已经跑完了全马的一半，太了不起了！",
                "21公里里程碑！已消耗约{calories}大卡，半程完成，后半段靠意志力！",
                "21.1公里！你刚刚完成了一个半程马拉松的距离！不管结果如何，你已经是英雄！"
            ],
            variantsEn: [
                "Twenty-one kilometers! Half marathon done — you've completed half a full marathon. Absolutely incredible!",
                "Twenty-one-kilometer milestone! {calories} calories burned — halfway done, the second half is all heart!",
                "21.1 kilometers! You just ran a half marathon's distance! Whatever happens, you're already a hero!"
            ]
        )

        map[.dist30km] = VoiceTemplate(
            event: .dist30km,
            variants: [
                "30公里！马拉松最难的阶段开始了，这是真正的考验，你能行！",
                "30公里达成！只剩{remaining}，深呼吸，小步幅，一步一步向前！",
                "30公里里程碑！你已经触碰到了马拉松的灵魂，终点在等你！"
            ],
            variantsEn: [
                "Thirty kilometers! The hardest stretch of the marathon begins now — this is the real test. You've got this!",
                "Thirty km done! Just {remaining} to go — deep breath, shorten your stride, one step at a time!",
                "Thirty-kilometer milestone! You've touched the soul of marathon running — the finish line is waiting!"
            ]
        )

        map[.dist40km] = VoiceTemplate(
            event: .dist40km,
            variants: [
                "40公里！只剩{remaining}！你已经跑完了95%，全力冲刺，终点就在眼前！",
                "40公里达成！最后{remaining}，用尽你所有的力气，你会成功的！",
                "40公里里程碑！终点线正在向你走来，你是今天最了不起的人！"
            ],
            variantsEn: [
                "Forty kilometers! Just {remaining} left — you've done 95%. Sprint everything you have — the finish is RIGHT THERE!",
                "Forty km done! Final {remaining} — give every last bit of energy. You are going to make it!",
                "Forty-kilometer milestone! The finish line is coming to meet you — you are the most incredible person today!"
            ]
        )

        // ─── 个人记录 ──────────────────────────────────────────

        map[.personalDistanceRecord] = VoiceTemplate(
            event: .personalDistanceRecord,
            variants: [
                "你刚刚打破了个人最远距离记录！今天跑了{distance}公里，超越了自己！",
                "{distance}公里！历史新纪录！你越来越强，每次跑步都在重写自己的极限！",
                "恭喜！{distance}公里，个人最佳！你已经超越了历史上的自己，继续冲！"
            ],
            variantsEn: [
                "You just broke your personal distance record! {distance} km today — you've surpassed yourself!",
                "{distance} km! All-time personal best! You're getting stronger, rewriting your own limits every run!",
                "Congratulations! {distance} km — personal best! You've just beaten the old you. Keep going!"
            ]
        )

        return map
    }

    // MARK: - 兜底模板（防止 key 缺失崩溃）

    private func fallbackTemplate(_ event: VoiceTriggerEvent) -> VoiceTemplate {
        VoiceTemplate(
            event: event,
            variants: ["继续加油，你做得很棒！"],
            variantsEn: ["Keep going, you're doing great!"]
        )
    }
}
