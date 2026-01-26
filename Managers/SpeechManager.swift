//
//  SpeechManager.swift
//  AI跑步教练
//
//  语音播报管理器 - 使用AVSpeechSynthesizer实现语音反馈
//

import Foundation
import AVFoundation

// MARK: - Speech Priority

/// 语音播报优先级
enum SpeechPriority: Int, Comparable {
    case low = 0       // 低优先级（一般提示）
    case normal = 1    // 普通优先级（常规反馈）
    case high = 2      // 高优先级（重要提醒）
    case urgent = 3    // 紧急（立即播报）

    static func < (lhs: SpeechPriority, rhs: SpeechPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Speech Item

/// 语音播报项
private struct SpeechItem {
    let text: String
    let priority: SpeechPriority
    let timestamp: Date

    init(text: String, priority: SpeechPriority) {
        self.text = text
        self.priority = priority
        self.timestamp = Date()
    }
}

// MARK: - SpeechManager

@MainActor
final class SpeechManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = SpeechManager()

    // MARK: - Published Properties

    @Published var isSpeaking = false
    @Published var isEnabled = true
    @Published var volume: Float = 1.0
    @Published var rate: Float = 0.5  // 0.0 - 1.0, 默认中等速度

    // MARK: - Private Properties

    private let synthesizer = AVSpeechSynthesizer()
    private var speechQueue: [SpeechItem] = []
    private var isProcessingQueue = false

    // 语音配置
    private var voiceIdentifier = "com.apple.voice.compact.zh-CN.Tingting"

    // MARK: - Initialization

    private override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
        print("SpeechManager 初始化完成")
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // 使用 playback 模式，允许与其他音频混合
            try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.mixWithOthers, .duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("❌ 音频会话设置失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Public Methods

    /// 播报文本
    /// - Parameters:
    ///   - text: 要播报的文本
    ///   - priority: 优先级
    func speak(_ text: String, priority: SpeechPriority = .normal) {
        guard isEnabled else { return }
        guard !text.isEmpty else { return }

        let item = SpeechItem(text: text, priority: priority)

        // 紧急优先级立即播报
        if priority == .urgent {
            stopCurrentSpeech()
            speechQueue.insert(item, at: 0)
        } else {
            // 按优先级插入队列
            insertByPriority(item)
        }

        processQueue()
    }

    /// 停止当前播报
    func stopCurrentSpeech() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    /// 停止所有播报并清空队列
    func stopAll() {
        speechQueue.removeAll()
        stopCurrentSpeech()
        isSpeaking = false
    }

    /// 暂停播报
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
        }
    }

    /// 继续播报
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }

    // MARK: - Predefined Messages

    /// 播报里程提示
    func announceDistance(_ distanceKm: Double) {
        let text: String
        if distanceKm < 1 {
            let meters = Int(distanceKm * 1000)
            text = "已跑\(meters)米"
        } else {
            text = String(format: "已跑%.1f公里", distanceKm)
        }
        speak(text, priority: .normal)
    }

    /// 播报配速
    func announcePace(_ paceMinPerKm: Double) {
        let minutes = Int(paceMinPerKm)
        let seconds = Int((paceMinPerKm - Double(minutes)) * 60)
        let text = "当前配速\(minutes)分\(seconds)秒"
        speak(text, priority: .normal)
    }

    /// 播报时间
    func announceDuration(_ seconds: TimeInterval) {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let text: String
        if mins > 0 {
            text = "已跑\(mins)分\(secs)秒"
        } else {
            text = "已跑\(secs)秒"
        }
        speak(text, priority: .low)
    }

    /// 播报开始跑步
    func announceStart() {
        speak("开始跑步，加油！", priority: .high)
    }

    /// 播报暂停
    func announcePause() {
        speak("跑步已暂停", priority: .normal)
    }

    /// 播报继续
    func announceResume() {
        speak("继续跑步", priority: .normal)
    }

    /// 播报结束
    func announceFinish(distance: Double, duration: TimeInterval) {
        let distanceText = String(format: "%.2f公里", distance / 1000.0)
        let mins = Int(duration) / 60
        let text = "跑步结束，本次跑了\(distanceText)，用时\(mins)分钟，辛苦了！"
        speak(text, priority: .high)
    }

    // MARK: - Private Methods

    /// 按优先级插入队列
    private func insertByPriority(_ item: SpeechItem) {
        // 找到第一个优先级低于当前项的位置
        if let index = speechQueue.firstIndex(where: { $0.priority < item.priority }) {
            speechQueue.insert(item, at: index)
        } else {
            speechQueue.append(item)
        }

        // 限制队列大小，移除最旧的低优先级项
        while speechQueue.count > 5 {
            if let lowIndex = speechQueue.lastIndex(where: { $0.priority == .low }) {
                speechQueue.remove(at: lowIndex)
            } else {
                speechQueue.removeLast()
            }
        }
    }

    /// 处理语音队列
    private func processQueue() {
        guard !isProcessingQueue else { return }
        guard !speechQueue.isEmpty else {
            isSpeaking = false
            return
        }
        guard !synthesizer.isSpeaking else { return }

        isProcessingQueue = true
        isSpeaking = true

        let item = speechQueue.removeFirst()
        speakText(item.text)

        isProcessingQueue = false
    }

    /// 执行语音播报
    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)

        // 设置中文语音
        if let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        }

        // 设置语音参数
        utterance.volume = volume
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rate
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1

        synthesizer.speak(utterance)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechManager: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            // 继续处理队列中的下一项
            self.processQueue()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.processQueue()
        }
    }
}
