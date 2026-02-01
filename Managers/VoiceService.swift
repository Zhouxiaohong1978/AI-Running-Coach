// VoiceService.swift
import Foundation
import AVFoundation

class VoiceService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = VoiceService()
    private let supabaseURL = URL(string: "https://aisgbqzksfzdlbjdcwpn.supabase.co/functions/v1/tts-coach")!
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false

    // 冷却管理
    private var lastSpeechTime: Date = Date.distantPast
    private let globalCooldown: TimeInterval = 15.0  // 全局最小冷却 15 秒

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
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
    }

    func speak(text: String, voice: String = "cherry", scriptCooldown: TimeInterval = 0) async -> Bool {
        print("🔊 开始 TTS 请求: \(text.prefix(20))...")

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

        do {
            // 1. 发送请求
            var request = URLRequest(url: supabaseURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30  // 增加超时时间
            request.httpBody = try JSONSerialization.data(withJSONObject: ["text": text, "voice": voice])

            // 2. 下载音频数据
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 无效的响应")
                return false
            }

            print("📥 收到响应: \(httpResponse.statusCode), 大小: \(data.count) 字节")

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
                    // 重新激活音频会话
                    try AVAudioSession.sharedInstance().setActive(true)

                    // 创建播放器
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

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
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
