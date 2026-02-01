// VoiceTriggerEngine.swift
import Foundation

class VoiceTriggerEngine: ObservableObject {
    static let shared = VoiceTriggerEngine()
    private let voiceService = VoiceService.shared
    let scriptManager = VoiceScriptManager.shared  // 改为 public，方便 UI 访问
    private var timer: Timer?
    private var isSpeaking = false
    @Published var currentMode: RunMode = .beginner
    @Published var context = RunContext()

    // 防止连续触发
    private var lastTriggerTime: Date = Date.distantPast
    private let minTriggerInterval: TimeInterval = 2.0  // 触发检查最小间隔

    func start(for mode: RunMode) {
        print("\n")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎯 VoiceTriggerEngine.start() 被调用了！")
        print("🚀 开始跑步，模式: \(mode)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        currentMode = mode
        scriptManager.reset()
        context = RunContext() // 重置上下文
        isSpeaking = false
        voiceService.stop()

        // 重置冷却
        print("🔄 正在重置语音冷却...")
        voiceService.resetCooldown()
        lastTriggerTime = Date.distantPast

        print("⏰ 启动定时器...")
        startTimer()
        print("✅ VoiceTriggerEngine 启动完成！\n")
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
        if let d = distance { context.distance = d }
        if let c = calories { context.calories = c }
        if let hr = heartRate { context.heartRate = hr }
        if let t = duration { context.duration = t }
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

        // 获取所有满足条件的脚本
        let scripts = scriptManager.scripts(for: currentMode)
            .filter { scriptManager.shouldTrigger(script: $0, context: context) }

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
        scriptManager.markAsPlayed(script.id)
        isSpeaking = true
        let text = script.resolvedText(with: context)

        print("📢 准备播放: \(text.prefix(30))... (冷却: \(script.cooldown)秒)")

        Task { @MainActor in
            let success = await voiceService.speak(
                text: text,
                voice: script.voice,
                scriptCooldown: script.cooldown  // 传入脚本特定冷却时间
            )

            if success {
                print("✅ 语音播放成功")
            } else {
                print("❌ 语音播放失败")
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
