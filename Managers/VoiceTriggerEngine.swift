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

    func start(for mode: RunMode) {
        print("🚀 开始跑步，模式: \(mode)")
        currentMode = mode
        scriptManager.reset()
        context = RunContext() // 重置上下文
        isSpeaking = false
        voiceService.stop()
        startTimer()
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

        // 获取所有满足条件的脚本，按 order 排序
        let scripts = scriptManager.scripts(for: currentMode)
            .filter { scriptManager.shouldTrigger(script: $0, context: context) }
            .sorted { $0.order < $1.order }

        // 每次只触发第一个（优先级最高的）
        guard let script = scripts.first else {
            return
        }

        print("🎯 触发脚本 #\(script.order): \(script.id)")
        print("   内容: \(script.text.prefix(30))...")
        trigger(script)
    }

    private func trigger(_ script: VoiceScript) {
        scriptManager.markAsPlayed(script.id)
        isSpeaking = true
        let text = script.resolvedText(with: context)

        print("📢 准备播放: \(text.prefix(30))...")

        Task { @MainActor in
            let success = await voiceService.speak(text: text, voice: script.voice)

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
