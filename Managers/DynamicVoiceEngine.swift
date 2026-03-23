//
//  DynamicVoiceEngine.swift
//  AI跑步教练
//
//  动态语音引擎：防刷屏控制 + 触发检测 + 变量替换 + TTS 播报
//
//  防刷屏规则：
//  1. 全局最短间隔 18 秒
//  2. playOncePerRun：里程碑类事件每次跑步只触发一次
//  3. 同事件冷却：心率/配速类重复触发有间隔限制
//  4. 5分钟滑动窗口：最多播放 3 条

import Foundation

@MainActor
class DynamicVoiceEngine: ObservableObject {
    static let shared = DynamicVoiceEngine()

    // MARK: - Published（供 ActiveRunView 绑定气泡）

    @Published var bubbleText: String = ""
    @Published var showBubble: Bool = false

    // 免费用户锁定气泡
    @Published var lockedBubbleText: String = ""
    @Published var showLockedBubble: Bool = false

    // 本次跑步跳过的Pro播报次数（供结束页展示）
    @Published var skippedProCount: Int = 0

    // MARK: - 防刷屏参数

    private let globalCooldown: TimeInterval = 18
    private let slidingWindowDuration: TimeInterval = 300  // 5 分钟
    private let slidingWindowMaxCount: Int = 3

    // MARK: - 防刷屏状态

    private var lastSpeakTime: Date = .distantPast
    private var recentSpeakTimes: [Date] = []
    private var eventLastTriggeredAt: [VoiceTriggerEvent: Date] = [:]
    private var triggeredThisRun: Set<VoiceTriggerEvent> = []

    // MARK: - 触发条件追踪

    // 配速变化：记录最近读数，取滑动平均
    private var paceReadings: [(timestamp: Date, pace: Double)] = []

    // 心率
    private var highHRStartTime: Date?
    private var hasEnteredFatBurnZone = false

    // 个人记录
    private var personalBestDistanceKm: Double = 0
    private var prAnnounced = false

    // 今日目标是否已完成
    private var goalCompleted = false

    // 防变体重复：记录每个事件上次使用的变体索引
    private var lastVariantIndex: [VoiceTriggerEvent: Int] = [:]

    private init() {}

    // MARK: - 跑步开始时重置

    func reset(personalBestDistanceKm: Double) {
        triggeredThisRun.removeAll()
        eventLastTriggeredAt.removeAll()
        lastSpeakTime = .distantPast
        recentSpeakTimes.removeAll()
        paceReadings.removeAll()
        highHRStartTime = nil
        hasEnteredFatBurnZone = false
        self.personalBestDistanceKm = personalBestDistanceKm
        prAnnounced = false
        goalCompleted = false
        skippedProCount = 0
        lastVariantIndex.removeAll()
        print("🔄 DynamicVoiceEngine 已重置，历史最佳: \(String(format: "%.2f", personalBestDistanceKm))km")
    }

    // MARK: - 主入口

    /// 今日目标达成时由 ActiveRunView 调用，停止后续动态语音触发
    func markGoalCompleted() {
        goalCompleted = true
    }

    /// ActiveRunView 在距离/时间变化时调用（每 ~5s 或每次 GPS 更新）
    func update(context: EnrichedRunContext) {
        let isPro = SubscriptionManager.shared.isPro
        guard context.distanceKm > 0.1 else { return }  // 100m 后才开始
        guard !goalCompleted else { return }  // 目标完成后停止触发

        // 收集本轮可触发的事件，按优先级取最高的
        var pending: [(event: VoiceTriggerEvent, text: String)] = []
        var lockedPending: [(event: VoiceTriggerEvent, text: String)] = []

        if let e = checkTimeMilestones(context)    { pending.append(e) }
        if let e = checkGoalProgress(context)      { pending.append(e) }  // 50%/80% 免费，90% Pro
        if isPro {
            if let e = checkDistanceMilestones(context) { pending.append(e) }
            if let e = checkHeartRate(context)          { pending.append(e) }
            if let e = checkCalories(context)           { pending.append(e) }
            if let e = checkPaceChange(context)         { pending.append(e) }
            if let e = checkPersonalRecord(context)     { pending.append(e) }
        } else {
            // 免费用户：检测Pro触发器但不播音，改为显示锁定气泡
            if let e = checkHeartRate(context)      { lockedPending.append(e) }
            if let e = checkCalories(context)       { lockedPending.append(e) }
            if let e = checkPaceChange(context)     { lockedPending.append(e) }
            if let e = checkPersonalRecord(context) { lockedPending.append(e) }
        }

        // 播放优先级最高的事件
        if let best = pending.max(by: { $0.event.priority < $1.event.priority }) {
            trySpeak(event: best.event, text: best.text)
        }

        // 免费用户：取第一条显示锁定气泡（有音频播放时跳过，避免干扰）
        if !isPro, !AudioPlayerManager.shared.isPlaying, !VoiceService.shared.isPlaying,
           let locked = lockedPending.first {
            showLockedFeature(event: locked.event, text: locked.text)
        }
    }

    // MARK: - 触发检测

    private func checkTimeMilestones(_ ctx: EnrichedRunContext) -> (VoiceTriggerEvent, String)? {
        let minutes = ctx.elapsedMinutes
        let milestones: [(threshold: Double, event: VoiceTriggerEvent)] = [
            // 基础（所有目标）
            (5,   .time5min),  (10,  .time10min), (20, .time20min), (30, .time30min),
            // 长跑扩展（半马 / 全马用户）
            (45,  .time45min), (60,  .time1hour), (90, .time90min),
            (120, .time2hour), (180, .time3hour), (240, .time4hour), (300, .time5hour)
        ]

        for milestone in milestones {
            // 到达阈值后 30 秒内触发（update 不一定精确到整分钟）
            if minutes >= milestone.threshold && minutes < milestone.threshold + 0.5 {
                if canTrigger(milestone.event) {
                    let isEN = LanguageManager.shared.currentLocale == "en"
                    let text = resolved(
                        VoiceTemplateMap.shared.template(for: milestone.event).variant(forGoal: ctx.goal, isEN: isEN),
                        ctx: ctx, isEN: isEN
                    )
                    return (milestone.event, text)
                }
            }
        }
        return nil
    }

    private func checkHeartRate(_ ctx: EnrichedRunContext) -> (VoiceTriggerEvent, String)? {
        guard ctx.heartRate > 0 else { return nil }
        let hr = ctx.heartRate
        let isEN = LanguageManager.shared.currentLocale == "en"

        // 心率过高：> 170 持续至少 10 秒
        if hr > 170 {
            if highHRStartTime == nil { highHRStartTime = Date() }
            if let start = highHRStartTime,
               Date().timeIntervalSince(start) >= 10,
               canTrigger(.hrTooHigh) {
                let result = VoiceTemplateMap.shared.template(for: .hrTooHigh)
                    .randomVariant(isEN: isEN, excludingIndex: lastVariantIndex[.hrTooHigh])
                lastVariantIndex[.hrTooHigh] = result.index
                let text = resolved(result.text, ctx: ctx, isEN: isEN)
                return (.hrTooHigh, text)
            }
        } else {
            highHRStartTime = nil
        }

        // 首次进入燃脂区 120-150 BPM
        if hr >= 120 && hr <= 150 && !hasEnteredFatBurnZone && canTrigger(.hrFatBurnZone) {
            hasEnteredFatBurnZone = true
            let text = resolved(
                VoiceTemplateMap.shared.template(for: .hrFatBurnZone).randomVariant(isEN: isEN),
                ctx: ctx, isEN: isEN
            )
            return (.hrFatBurnZone, text)
        }

        return nil
    }

    private func checkCalories(_ ctx: EnrichedRunContext) -> (VoiceTriggerEvent, String)? {
        let cal = ctx.calories
        let isEN = LanguageManager.shared.currentLocale == "en"

        // 卡路里触发窗口：±10 大卡内（防止频繁匹配）
        let milestones: [(threshold: Double, event: VoiceTriggerEvent)] = [
            (150, .cal150), (300, .cal300)
        ]

        for milestone in milestones {
            if cal >= milestone.threshold && cal < milestone.threshold + 10 && canTrigger(milestone.event) {
                let text = resolved(
                    VoiceTemplateMap.shared.template(for: milestone.event).randomVariant(isEN: isEN),
                    ctx: ctx, isEN: isEN
                )
                return (milestone.event, text)
            }
        }
        return nil
    }

    private func checkPaceChange(_ ctx: EnrichedRunContext) -> (VoiceTriggerEvent, String)? {
        guard ctx.currentPace > 0 && ctx.currentPace < 20 else { return nil }
        guard ctx.distanceKm > 0.5 else { return nil }  // 500m 后才检测配速变化

        let now = Date()
        let isEN = LanguageManager.shared.currentLocale == "en"

        // 记录配速读数，保留近 2 分钟
        paceReadings.append((now, ctx.currentPace))
        paceReadings = paceReadings.filter { now.timeIntervalSince($0.timestamp) < 120 }

        // 需要至少 6 次读数才判断（约 30-60 秒数据）
        guard paceReadings.count >= 6 else { return nil }

        let recent = Array(paceReadings.suffix(3)).map { $0.pace }
        let older  = Array(paceReadings.prefix(3)).map { $0.pace }
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg  = older.reduce(0, +) / Double(older.count)

        // delta > 0 表示配速提升（数值变小 = 跑得更快）
        let delta = olderAvg - recentAvg

        if delta > 0.5 && canTrigger(.paceImproved) {   // 提升超过 30 秒/公里
            let result = VoiceTemplateMap.shared.template(for: .paceImproved)
                .randomVariant(isEN: isEN, excludingIndex: lastVariantIndex[.paceImproved])
            lastVariantIndex[.paceImproved] = result.index
            let text = resolved(result.text, ctx: ctx, isEN: isEN)
            return (.paceImproved, text)
        }

        if delta < -0.75 && canTrigger(.paceDropped) {  // 下降超过 45 秒/公里
            let result = VoiceTemplateMap.shared.template(for: .paceDropped)
                .randomVariant(isEN: isEN, excludingIndex: lastVariantIndex[.paceDropped])
            lastVariantIndex[.paceDropped] = result.index
            let text = resolved(result.text, ctx: ctx, isEN: isEN)
            return (.paceDropped, text)
        }

        return nil
    }

    private func checkPersonalRecord(_ ctx: EnrichedRunContext) -> (VoiceTriggerEvent, String)? {
        guard personalBestDistanceKm > 0.5 else { return nil }  // 需要有历史记录
        guard !prAnnounced else { return nil }
        guard ctx.distanceKm > personalBestDistanceKm else { return nil }
        guard canTrigger(.personalDistanceRecord) else { return nil }

        prAnnounced = true
        let isEN = LanguageManager.shared.currentLocale == "en"
        let text = resolved(
            VoiceTemplateMap.shared.template(for: .personalDistanceRecord).randomVariant(isEN: isEN),
            ctx: ctx, isEN: isEN
        )
        return (.personalDistanceRecord, text)
    }

    private func checkDistanceMilestones(_ ctx: EnrichedRunContext) -> (VoiceTriggerEvent, String)? {
        // 距离里程碑：按目标过滤，只在相关跑者身上触发
        struct DistMilestone {
            let km: Double
            let event: VoiceTriggerEvent
            let goals: [TrainingGoal]
        }
        let milestones: [DistMilestone] = [
            // 早期鼓励：所有目标均适用
            DistMilestone(km: 0.3,  event: .dist300m, goals: TrainingGoal.allCases),
            DistMilestone(km: 5,    event: .dist5km,  goals: [.fiveK, .tenK, .halfMarathon, .fullMarathon]),
            DistMilestone(km: 10,   event: .dist10km, goals: [.tenK, .halfMarathon, .fullMarathon]),
            DistMilestone(km: 21.1, event: .dist21km, goals: [.halfMarathon, .fullMarathon]),
            DistMilestone(km: 30,   event: .dist30km, goals: [.fullMarathon]),
            DistMilestone(km: 40,   event: .dist40km, goals: [.fullMarathon]),
        ]
        let isEN = LanguageManager.shared.currentLocale == "en"
        for m in milestones {
            guard m.goals.contains(ctx.goal) else { continue }
            guard ctx.distanceKm >= m.km else { continue }   // playOncePerRun 保证只播一次
            guard canTrigger(m.event) else { continue }
            // dist300m 按教练风格选文案，其余按训练目标
            let text: String
            if m.event == .dist300m {
                text = resolved(
                    VoiceTemplateMap.shared.template(for: m.event)
                        .variant(forCoachStyle: effectiveCoachStyle, isEN: isEN),
                    ctx: ctx, isEN: isEN
                )
            } else {
                text = resolved(
                    VoiceTemplateMap.shared.template(for: m.event).variant(forGoal: ctx.goal, isEN: isEN),
                    ctx: ctx, isEN: isEN
                )
            }
            return (m.event, text)
        }
        return nil
    }

    private func checkGoalProgress(_ ctx: EnrichedRunContext) -> (VoiceTriggerEvent, String)? {
        guard ctx.goalDistanceKm > 0.5 else { return nil }
        let isPro = SubscriptionManager.shared.isPro
        let pct = ctx.progressPercent  // 0-100
        let isEN = LanguageManager.shared.currentLocale == "en"

        // [threshold%, event, proOnly] — 窗口 ±2.5% 内触发一次
        let milestones: [(threshold: Double, event: VoiceTriggerEvent, proOnly: Bool)] = [
            (50, .goalHalfway, false),
            (80, .goal80pct,   false),
            (90, .goal90pct,   true),
        ]

        for m in milestones {
            guard pct >= m.threshold && pct < m.threshold + 5 else { continue }
            guard !m.proOnly || isPro else { continue }
            guard canTrigger(m.event) else { continue }
            let text = resolved(
                VoiceTemplateMap.shared.template(for: m.event)
                    .variant(forCoachStyle: effectiveCoachStyle, isEN: isEN),
                ctx: ctx, isEN: isEN
            )
            return (m.event, text)
        }
        return nil
    }

    // MARK: - 防刷屏检查

    private func canTrigger(_ event: VoiceTriggerEvent) -> Bool {
        let now = Date()

        // 1. 本次跑步是否已触发过（playOncePerRun）
        if event.playOncePerRun && triggeredThisRun.contains(event) {
            return false
        }

        // 2. 全局冷却
        let sinceLastSpeak = now.timeIntervalSince(lastSpeakTime)
        if sinceLastSpeak < globalCooldown {
            return false
        }

        // 3. 任一播放器正在播放或 TTS 正在下载时不打断
        if AudioPlayerManager.shared.isPlaying || VoiceService.shared.isPlaying || VoiceService.shared.isPending {
            return false
        }

        // 4. 同事件冷却
        if event.perTriggerCooldown > 0,
           let lastTime = eventLastTriggeredAt[event] {
            let sinceEvent = now.timeIntervalSince(lastTime)
            if sinceEvent < event.perTriggerCooldown {
                return false
            }
        }

        // 5. 5 分钟滑动窗口（最多 3 条）
        // 时间里程碑（5/10/20/30min 等）是一次性事件，不受窗口限制，确保准时播报
        recentSpeakTimes = recentSpeakTimes.filter { now.timeIntervalSince($0) < slidingWindowDuration }
        if !event.isTimeEvent && recentSpeakTimes.count >= slidingWindowMaxCount {
            DebugLogger.shared.log("[\(event.rawValue)] 5分钟窗口上限", category: "WARN")
            return false
        }

        return true
    }

    // MARK: - 教练风格（免费用户锁定鼓励型）

    private var effectiveCoachStyle: CoachStyle {
        SubscriptionManager.shared.isPro ? AIManager.shared.coachStyle : .encouraging
    }

    // MARK: - 播放

    private func trySpeak(event: VoiceTriggerEvent, text: String) {
        let now = Date()
        guard canTrigger(event) else { return }

        // 更新防刷屏状态
        if event.playOncePerRun { triggeredThisRun.insert(event) }
        eventLastTriggeredAt[event] = now
        lastSpeakTime = now
        recentSpeakTimes.append(now)

        // TTS 播放（气泡等语音真正开始播才显示，保持同步）
        let isEN = LanguageManager.shared.currentLocale == "en"
        let language = isEN ? "en" : "zh-Hans"
        let voiceId = VoiceService.voiceId(for: effectiveCoachStyle, language: language)

        let log = DebugLogger.shared
        log.log("触发: \(event.rawValue) | voice=\(voiceId) lang=\(language)", category: "VOICE")
        log.log("文本: \(text)", category: "VOICE")

        Task {
            let success = await VoiceService.shared.speak(
                text: text,
                voice: voiceId,
                language: language,
                scriptCooldown: 0
            )
            if success {
                log.log("播放成功: \(event.rawValue)", category: "SUCCESS")
                // 语音开始播放时才显示气泡
                await MainActor.run {
                    self.bubbleText = text
                    self.showBubble = true
                }
                // 固定 8 秒后隐藏气泡（覆盖最长语音时长，18s全局冷却确保下条不会立即跟上）
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                await MainActor.run { self.showBubble = false }
            } else {
                // 播放失败，不显示气泡
                guard event.isTimeEvent else {
                    log.log("播放失败: \(event.rawValue)，数据类事件不重试", category: "ERROR")
                    return
                }
                log.log("播放失败: \(event.rawValue)，10s后重试", category: "ERROR")
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                let retrySuccess = await VoiceService.shared.speak(
                    text: text,
                    voice: voiceId,
                    language: language,
                    scriptCooldown: 0
                )
                if retrySuccess {
                    log.log("重试成功: \(event.rawValue)", category: "SUCCESS")
                    await MainActor.run {
                        self.bubbleText = text
                        self.showBubble = true
                    }
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    await MainActor.run { self.showBubble = false }
                } else {
                    log.log("重试失败: \(event.rawValue)", category: "ERROR")
                }
            }
        }
    }

    // MARK: - 免费用户锁定气泡

    private func showLockedFeature(event: VoiceTriggerEvent, text: String) {
        let now = Date()
        guard canTrigger(event) else { return }

        // 复用同一套防刷屏状态，避免重复触发
        if event.playOncePerRun { triggeredThisRun.insert(event) }
        eventLastTriggeredAt[event] = now
        lastSpeakTime = now
        recentSpeakTimes.append(now)

        skippedProCount += 1

        let isEN = LanguageManager.shared.currentLocale == "en"
        lockedBubbleText = isEN ? "🔒 Pro: \(text)" : "🔒 Pro 功能：\(text)"
        showLockedBubble = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.showLockedBubble = false
        }
    }

    // MARK: - 变量替换

    private func resolved(_ template: String, ctx: EnrichedRunContext, isEN: Bool) -> String {
        var s = template
        s = s.replacingOccurrences(of: "{pace}",      with: ctx.formattedPace)
        s = s.replacingOccurrences(of: "{hr}",        with: "\(ctx.heartRate)")
        s = s.replacingOccurrences(of: "{calories}",  with: ctx.formattedCalories)
        s = s.replacingOccurrences(of: "{distance}",  with: ctx.formattedDistance)
        s = s.replacingOccurrences(of: "{duration}",  with: isEN ? ctx.formattedDurationEn : ctx.formattedDuration)
        s = s.replacingOccurrences(of: "{runCount}",  with: "\(ctx.totalRunCount)")
        s = s.replacingOccurrences(of: "{totalKm}",   with: ctx.formattedTotalKm)
        s = s.replacingOccurrences(of: "{monthKm}",   with: ctx.formattedMonthlyKm)
        s = s.replacingOccurrences(of: "{monthRuns}", with: "\(ctx.monthlyRunCount)")
        s = s.replacingOccurrences(of: "{food}",      with: isEN ? ctx.foodEquivalentEn : ctx.foodEquivalent)
        s = s.replacingOccurrences(of: "{remaining}", with: isEN ? ctx.formattedRemainingEn : ctx.formattedRemaining)
        s = s.replacingOccurrences(of: "{hrZone}",    with: isEN ? ctx.heartRateZoneEn : ctx.heartRateZone)
        s = s.replacingOccurrences(of: "{streak}",    with: "\(ctx.currentStreak)")
        return s
    }
}
