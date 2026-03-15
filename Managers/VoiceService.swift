// VoiceService.swift
import Foundation
import AVFoundation
import UIKit

class VoiceService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = VoiceService()
    private let supabaseURL = URL(string: "https://aisgbqzksfzdlbjdcwpn.supabase.co/functions/v1/tts-coach")!
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    /// TTS 请求发出到播放结束全程为 true，防止下载期间被预录音频打断
    @Published var isPending = false

    // 冷却管理
    private var lastSpeechTime: Date = Date.distantPast
    private let globalCooldown: TimeInterval = 15.0  // 全局最小冷却 15 秒

    // TTS 音频预缓存
    private var audioCache: [String: Data] = [:]

    // MARK: - 声音路由（教练风格 × 语言）

    /// 根据教练风格和语言返回 Qwen3-TTS 声音 ID
    static func voiceId(for coachStyle: CoachStyle, language: String) -> String {
        switch (language, coachStyle) {
        case ("en", .strict):       return "Aiden"     // 英文磁性男声
        case ("en", _):             return "Katerina"  // 英文温柔女声
        case (_, .strict):          return "Kai"       // 中文磁性男声
        default:                    return "Cherry"    // 中文温柔女声（API名，控制台显示为"千悦"）
        }
    }

    override init() {
        super.init()
        configureAudioSession()
    }

    // 检查是否可以说话
    func canSpeakNow(minimumInterval: TimeInterval = 0) -> Bool {
        let requiredInterval = max(globalCooldown, minimumInterval)
        let timeSinceLast = Date().timeIntervalSince(lastSpeechTime)
        return timeSinceLast > requiredInterval
    }

    // 重置冷却（开始新跑步时调用）
    func resetCooldown() {
        lastSpeechTime = Date.distantPast
        print("🔄 语音冷却已重置")
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // 设置为播放类别，确保即使静音开关打开也能播放
            try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
            // 激活会话，允许与其他音频共存
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ 音频会话配置成功")
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
    }

    /// 预缓存 TTS 音频（只下载不播放、不触发冷却）
    func prefetch(cacheKey: String, text: String, voice: String, language: String) async {
        let hasCached = await MainActor.run { self.audioCache[cacheKey] != nil }
        guard !hasCached else { return }

        let bgTaskId = await MainActor.run {
            UIApplication.shared.beginBackgroundTask(withName: "TTS-Prefetch") {}
        }
        defer {
            Task { @MainActor in
                if bgTaskId != .invalid { UIApplication.shared.endBackgroundTask(bgTaskId) }
            }
        }
        do {
            var request = URLRequest(url: supabaseURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "text": text, "voice": voice, "lang": language
            ])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count > 1000 else { return }
            await MainActor.run { self.audioCache[cacheKey] = data }
            print("✅ 预缓存: \(cacheKey) (\(data.count) bytes)")
        } catch {
            print("⚠️ 预缓存失败: \(cacheKey)")
        }
    }

    /// 清除预缓存
    func clearCache() {
        audioCache.removeAll()
    }

    func speak(text: String, voice: String = "cherry", language: String = "zh-Hans", scriptCooldown: TimeInterval = 0, cacheKey: String? = nil) async -> Bool {
        DebugLogger.shared.log("TTS请求: voice=\(voice) lang=\(language) text=\(text.prefix(20))", category: "VOICE")

        // 检查冷却
        guard canSpeakNow(minimumInterval: scriptCooldown) else {
            let timeSinceLast = Date().timeIntervalSince(lastSpeechTime)
            print("⏸️ 语音冷却中（距上次 \(String(format: "%.1f", timeSinceLast))秒，需要 \(max(globalCooldown, scriptCooldown))秒），跳过播放")
            return false
        }

        // 停止之前的播放
        await MainActor.run {
            self.stop()
        }

        // 缓存命中 → 直接播放，跳过网络下载
        if let key = cacheKey {
            let cachedData = await MainActor.run { self.audioCache[key] }
            if let data = cachedData {
                print("🎯 缓存命中: \(key)")
                return await MainActor.run {
                    do {
                        let player = try AVAudioPlayer(data: data)
                        player.delegate = self
                        player.volume = 1.0
                        guard player.prepareToPlay() else { return false }
                        guard player.play() else { return false }
                        self.audioPlayer = player
                        self.isPlaying = true
                        self.lastSpeechTime = Date()
                        return true
                    } catch { return false }
                }
            }
        }

        // 缓存未命中：走原有网络下载路径（后台任务保护，防止熄屏中断）
        await MainActor.run { self.isPending = true }
        let bgTaskId = await MainActor.run {
            UIApplication.shared.beginBackgroundTask(withName: "TTS-Download") {}
        }
        defer {
            Task { @MainActor in
                self.isPending = false
                if bgTaskId != .invalid { UIApplication.shared.endBackgroundTask(bgTaskId) }
            }
        }
        do {
            // 1. 发送请求
            var request = URLRequest(url: supabaseURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30  // 增加超时时间
            request.httpBody = try JSONSerialization.data(withJSONObject: ["text": text, "voice": voice, "lang": language])

            // 2. 下载音频数据
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 无效的响应")
                return false
            }

            DebugLogger.shared.log("响应: \(httpResponse.statusCode) \(data.count)字节", category: httpResponse.statusCode == 200 ? "SUCCESS" : "ERROR")

            guard httpResponse.statusCode == 200 else {
                print("❌ HTTP 错误: \(httpResponse.statusCode)")
                if let errorText = String(data: data, encoding: .utf8) {
                    print("错误详情: \(errorText)")
                }
                return false
            }

            guard data.count > 1000 else {
                print("❌ 音频数据太小: \(data.count) 字节")
                return false
            }

            // 3. 在主线程配置和播放音频
            return await MainActor.run {
                do {
                    // 创建播放器（音频会话已在 init 时激活）
                    let player = try AVAudioPlayer(data: data)
                    player.delegate = self
                    player.volume = 1.0

                    // 预加载音频
                    guard player.prepareToPlay() else {
                        print("❌ prepareToPlay 失败")
                        return false
                    }

                    print("✅ 音频准备完成，时长: \(player.duration)秒")

                    // 开始播放
                    guard player.play() else {
                        print("❌ play() 失败")
                        return false
                    }

                    self.audioPlayer = player
                    self.isPlaying = true

                    // 播放成功后更新冷却时间
                    self.lastSpeechTime = Date()

                    print("🎵 开始播放")
                    return true

                } catch {
                    print("❌ 音频播放器创建失败: \(error)")
                    return false
                }
            }

        } catch {
            print("❌ TTS 请求失败: \(error)")
            await MainActor.run {
                self.isPlaying = false
            }
            return false
        }
    }

    // MARK: - 里程碑/完成/应急语音专用（绕过所有冷却）

    /// 等待当前播放完成后立即播放，绕过冷却，适用于里程碑/完成/应急语音
    func speakImmediate(text: String, voice: String, language: String, cacheKey: String? = nil) async -> Bool {
        print("🔊 [speakImmediate] \(text.prefix(20))...")

        // 等待当前播放完成（最多 15s）
        let waitStart = Date()
        while await MainActor.run(body: { self.isPlaying }) && Date().timeIntervalSince(waitStart) < 15 {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        // 强制停止残留播放
        await MainActor.run { self.stop() }

        // 缓存命中 → 即时播放
        if let key = cacheKey {
            let cachedData = await MainActor.run { self.audioCache[key] }
            if let data = cachedData {
                print("🎯 [speakImmediate] 缓存命中: \(key)")
                return await MainActor.run {
                    do {
                        let player = try AVAudioPlayer(data: data)
                        player.delegate = self
                        player.volume = 1.0
                        guard player.prepareToPlay() else { return false }
                        guard player.play() else { return false }
                        self.audioPlayer = player
                        self.isPlaying = true
                        self.lastSpeechTime = Date()
                        return true
                    } catch { return false }
                }
            }
        }

        // 缓存未命中：走网络下载（后台任务保护，防止熄屏中断）
        let bgTaskId = await MainActor.run {
            UIApplication.shared.beginBackgroundTask(withName: "TTS-Immediate") {}
        }
        defer {
            Task { @MainActor in
                if bgTaskId != .invalid { UIApplication.shared.endBackgroundTask(bgTaskId) }
            }
        }
        do {
            var request = URLRequest(url: supabaseURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "text": text, "voice": voice, "lang": language
            ])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count > 1000 else {
                print("❌ [speakImmediate] 网络响应异常")
                return false
            }

            // 缓存下载结果（供后续复用）
            if let key = cacheKey {
                await MainActor.run { self.audioCache[key] = data }
            }

            return await MainActor.run {
                do {
                    let player = try AVAudioPlayer(data: data)
                    player.delegate = self
                    player.volume = 1.0
                    guard player.prepareToPlay() else { return false }
                    guard player.play() else { return false }
                    self.audioPlayer = player
                    self.isPlaying = true
                    self.lastSpeechTime = Date()
                    print("🎵 [speakImmediate] 开始播放")
                    return true
                } catch {
                    print("❌ [speakImmediate] 播放器创建失败: \(error)")
                    return false
                }
            }
        } catch {
            print("❌ [speakImmediate] 网络请求失败: \(error)")
            return false
        }
    }

    /// 等待当前播放完成
    func waitForFinish() async {
        while await MainActor.run(body: { self.isPlaying }) {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        isPending = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print(flag ? "✅ 播放完成" : "❌ 播放中断")
        DispatchQueue.main.async {
            self.isPlaying = false
            self.audioPlayer = nil
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ 解码错误: \(error?.localizedDescription ?? "未知错误")")
        DispatchQueue.main.async {
            self.isPlaying = false
            self.audioPlayer = nil
        }
    }
}
