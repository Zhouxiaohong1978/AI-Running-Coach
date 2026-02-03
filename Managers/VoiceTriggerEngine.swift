// VoiceTriggerEngine.swift
import Foundation

class VoiceTriggerEngine: ObservableObject {
    static let shared = VoiceTriggerEngine()
    private let voiceService = VoiceService.shared
    let scriptManager = VoiceScriptManager.shared  // 改为 public，方便 UI 访问
    private let logger = DebugLogger.shared  // 日志记录器
    private var timer: Timer?
    private var isSpeaking = false
    @Published var currentMode: RunMode = .beginner
    @Published var context = RunContext()

    // 防止连续触发
    private var lastTriggerTime: Date = Date.distantPast
    private let minTriggerInterval: TimeInterval = 2.0  // 触发检查最小间隔

    // 记录上次距离，用于增量触发检查
    private var lastDistance: Double = 0.0

    func start(for mode: RunMode) {
        print("\n")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎯 VoiceTriggerEngine.start() 被调用了！")
        print("🚀 开始跑步，模式: \(mode)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        logger.log("🚀 开始跑步 - 模式: \(mode == .beginner ? "新手3公里" : "减肥燃脂")", category: "START")

        currentMode = mode
        scriptManager.reset()
        context = RunContext() // 重置上下文
        isSpeaking = false
        voiceService.stop()

        // 重置冷却和距离
        print("🔄 正在重置语音冷却...")
        voiceService.resetCooldown()
        lastTriggerTime = Date.distantPast
        lastDistance = 0.0

        print("⏰ 启动定时器...")
        startTimer()
        print("✅ VoiceTriggerEngine 启动完成！\n")
        logger.log("✅ 触发引擎启动完成", category: "START")
    }

    func stop() {
        print("🛑 停止跑步")
        timer?.invalidate()
        timer = nil
        voiceService.stop()
        isSpeaking = false

        // 如果距离 >= 3km，触发完成语音
        if context.distance >= 3.0 {
            context.isFinished = true
            print("🎉 触发完成状态")
            // 立即触发完成相关的语音
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await triggerCompletionVoices()
            }
        }
    }

    func updateContext(distance: Double? = nil, calories: Double? = nil,
                      heartRate: Int? = nil, duration: TimeInterval? = nil) {
        if let d = distance {
            lastDistance = context.distance  // 记录旧距离
            context.distance = d
            logger.log("📍 距离更新: \(String(format: "%.2f", d))km", category: "DATA")
        }
        if let c = calories { context.calories = c }
        if let hr = heartRate {
            context.heartRate = hr
            logger.log("💓 心率更新: \(hr) BPM", category: "DATA")
        }
        if let t = duration {
            context.duration = t
            logger.log("⏱️ 时长更新: \(Int(t/60))分钟", category: "DATA")
        }
        if context.duration > 1200 { context.fatigueLevel = "high" }
        else if context.duration > 600 { context.fatigueLevel = "medium" }
    }

    private func startTimer() {
        // 每 5 秒检查一次，避免触发太频繁
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkTriggers()
        }
        RunLoop.current.add(timer!, forMode: .common)
        print("⏰ 触发引擎定时器已启动（每 5 秒检查）")
    }

    private func checkTriggers() {
        guard !isSpeaking else {
            return
        }

        // 防止频繁触发：如果正在播放，跳过
        guard !voiceService.isPlaying else {
            return
        }

        // 检查触发间隔
        let timeSinceLastCheck = Date().timeIntervalSince(lastTriggerTime)
        guard timeSinceLastCheck >= minTriggerInterval else {
            return
        }

        print("🔍 检查触发条件（距离=\(context.distance)km, 热量=\(Int(context.calories))大卡）")

        // 获取所有满足条件的脚本，并增加距离增量检查
        let scripts = scriptManager.scripts(for: currentMode)
            .filter { scriptManager.shouldTrigger(script: $0, context: context) }
            .filter { script in
                // 对于距离触发的脚本，只触发"刚刚到达"的里程碑
                if script.triggerType == .distance {
                    // 特殊处理：triggerValue = 0（开场语音）只在距离 = 0 时触发
                    if script.triggerValue == 0 {
                        return context.distance == 0
                    }

                    // 普通里程碑：lastDistance < triggerValue <= currentDistance
                    let justReached = lastDistance < script.triggerValue && script.triggerValue <= context.distance
                    if !justReached {
                        print("  ⏩ 跳过 \(script.id)（未刚到达：上次=\(lastDistance)km, 触发值=\(script.triggerValue)km, 当前=\(context.distance)km）")
                    }
                    return justReached
                }
                return true  // 非距离触发的脚本保持原逻辑
            }

        print("   满足条件的脚本数量：\(scripts.count)")

        // 按优先级排序（完成状态 > 安全预警 > 里程碑 > 普通指导）
        let sortedScripts = scripts.sorted { script1, script2 in
            let priority1 = getPriority(for: script1)
            let priority2 = getPriority(for: script2)
            if priority1 != priority2 {
                return priority1 > priority2  // 优先级高的在前
            }
            return script1.order < script2.order  // 优先级相同，按 order 排序
        }

        // 每次只触发第一个（优先级最高的）
        guard let script = sortedScripts.first else {
            print("   ⚠️ 没有满足条件的脚本")
            return
        }

        print("───────────────────────────────────────")
        print("🎯 触发脚本：\(script.id)")
        print("   优先级：\(getPriority(for: script))")
        print("   内容：\(script.text.prefix(30))...")
        print("   冷却时间：\(script.cooldown)秒")
        print("───────────────────────────────────────")

        lastTriggerTime = Date()

        // 如果是距离触发的脚本，更新 lastDistance 为当前触发的里程碑
        // 这样下次检查时，已触发的里程碑不会再满足条件
        if script.triggerType == .distance {
            lastDistance = script.triggerValue
            print("   📍 更新 lastDistance → \(lastDistance)km")
        }

        trigger(script)
    }

    // 计算脚本优先级
    private func getPriority(for script: VoiceScript) -> Int {
        switch script.triggerType {
        case .state where script.triggerValue == 2:
            return 100  // 完成状态最高优先级
        case .heartRate where script.triggerValue >= 170:
            return 90   // 高心率预警
        case .distance where script.triggerValue.truncatingRemainder(dividingBy: 1.0) == 0:
            return 80   // 整公里里程碑
        case .calories where script.triggerValue.truncatingRemainder(dividingBy: 100) == 0:
            return 70   // 整百大卡里程碑
        case .time where script.triggerValue >= 900:
            return 65   // 时间里程碑
        default:
            return 50   // 普通指导
        }
    }

    private func trigger(_ script: VoiceScript) {
        // 如果是疲劳或心率区间相关的语音，打印检测结果
        if script.triggerType == .fatigue || script.triggerType == .heartRateZone {
            print("[触发检查] 脚本: \(script.id), 类型: \(script.triggerType)")
        }

        scriptManager.markAsPlayed(script.id)
        isSpeaking = true
        let text = script.resolvedText(with: context)

        print("📢 准备播放: \(text.prefix(30))... (冷却: \(script.cooldown)秒)")
        logger.log("🎯 触发语音: \(script.id) - \(text.prefix(50))...", category: "VOICE")

        Task { @MainActor in
            let success = await voiceService.speak(
                text: text,
                voice: script.voice,
                scriptCooldown: script.cooldown  // 传入脚本特定冷却时间
            )

            if success {
                print("✅ 语音播放成功")
                self.logger.log("✅ 播放成功: \(script.id)", category: "VOICE")
            } else {
                print("❌ 语音播放失败")
                self.logger.log("❌ 播放失败: \(script.id)", category: "ERROR")
            }

            // 等待一小段时间，确保语音完全播放完
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

            isSpeaking = false
        }
    }

    func triggerManual(_ scriptId: String) async -> Bool {
        guard let script = scriptManager.allScripts.first(where: { $0.id == scriptId }) else {
            return false
        }
        let text = script.resolvedText(with: context)
        return await voiceService.speak(text: text, voice: script.voice)
    }

    private func triggerCompletionVoices() async {
        // 触发完成和庆祝相关的语音（state = 2 的脚本）
        let completionScripts = scriptManager.scripts(for: currentMode)
            .filter { $0.triggerType == .state && $0.triggerValue == 2 }
            .filter { !scriptManager.playedScripts.contains($0.id) }

        print("📢 找到 \(completionScripts.count) 条完成语音")

        for script in completionScripts {
            scriptManager.markAsPlayed(script.id)
            let text = script.resolvedText(with: context)
            print("🎊 播放完成语音: \(script.id)")

            _ = await voiceService.speak(text: text, voice: script.voice)

            // 等待播放完成
            while voiceService.isPlaying {
                try? await Task.sleep(nanoseconds: 500_000_000)
            }

            // 语音之间间隔 1 秒
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
