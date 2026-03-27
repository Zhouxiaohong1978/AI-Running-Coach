//
//  AudioPlayerManager.swift
//  AI跑步教练
//
//  音频播放管理器 - 播放预录制的.m4a语音文件
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Audio Priority

/// 音频播放优先级
enum AudioPriority: Int, Comparable {
    case normal = 0    // 普通（跑中提醒）
    case high = 1      // 高优先级（成就、完成）
    case urgent = 2    // 紧急（应急）

    static func < (lhs: AudioPriority, rhs: AudioPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Audio Item

/// 音频播放项
private struct AudioItem {
    let fileName: String
    let priority: AudioPriority
    let timestamp: Date

    init(fileName: String, priority: AudioPriority) {
        self.fileName = fileName
        self.priority = priority
        self.timestamp = Date()
    }
}

// MARK: - AudioPlayerManager

@MainActor
final class AudioPlayerManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = AudioPlayerManager()
    private let logger = DebugLogger.shared

    // MARK: - Published Properties

    @Published var isPlaying = false
    @Published var isEnabled = true
    @Published var volume: Float = 1.0

    // MARK: - Private Properties

    private var audioPlayer: AVAudioPlayer?
    private var audioQueue: [AudioItem] = []
    private var isProcessingQueue = false
    private var playedAudios = Set<String>()  // 防止重复播放

    // MARK: - Initialization

    private override init() {
        super.init()
        setupAudioSession()
        print("✅ AudioPlayerManager 初始化完成")
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // 使用 playback 模式，允许与其他音频混合
            try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
            try audioSession.setActive(true)
            print("✅ 音频会话配置成功")
        } catch {
            print("❌ 音频会话设置失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Public Methods

    /// 播放音频文件
    /// - Parameters:
    ///   - fileName: 音频文件名（不含扩展名），例如 "跑前_01"
    ///   - priority: 优先级
    ///   - allowRepeat: 是否允许重复播放（默认false）
    @discardableResult
    func play(_ fileName: String, priority: AudioPriority = .normal, allowRepeat: Bool = false) -> Bool {
        guard isEnabled else {
            print("🔇 音频已禁用，跳过播放: \(fileName)")
            logger.log("🔇 音频已禁用，跳过: \(fileName)", category: "WARN")
            return false
        }

        // 检查是否已播放过（静默跳过，不打日志避免spam）
        if !allowRepeat && playedAudios.contains(fileName) {
            return false
        }

        print("🎵 添加到播放队列: \(fileName), priority: \(priority)")
        logger.log("🎵 添加到队列: \(fileName)", category: "VOICE")

        let item = AudioItem(fileName: fileName, priority: priority)

        // 紧急优先级立即播放
        if priority == .urgent {
            stopCurrentAudio()
            audioQueue.insert(item, at: 0)
        } else {
            // 按优先级插入队列
            insertByPriority(item)
        }

        processQueue()
        return true
    }

    /// 检查是否已播放过（供 EN 模式语音路由使用）
    func hasPlayed(_ fileName: String) -> Bool {
        return playedAudios.contains(fileName)
    }

    /// 标记为已播放（供 EN 模式语音路由使用）
    func markPlayed(_ fileName: String) {
        playedAudios.insert(fileName)
    }

    /// 停止当前播放
    func stopCurrentAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    /// 停止所有播放并清空队列
    func stopAll() {
        audioQueue.removeAll()
        stopCurrentAudio()
        print("🛑 停止所有音频播放")
    }

    /// 重置已播放记录（新跑步开始时调用）
    func reset() {
        playedAudios.removeAll()
        audioQueue.removeAll()
        stopCurrentAudio()
        print("🔄 重置音频播放状态")
    }

    // MARK: - Private Methods

    /// 按优先级插入队列
    private func insertByPriority(_ item: AudioItem) {
        // 找到第一个优先级低于当前项的位置
        if let index = audioQueue.firstIndex(where: { $0.priority < item.priority }) {
            audioQueue.insert(item, at: index)
        } else {
            audioQueue.append(item)
        }

        // 限制队列大小，移除最旧的低优先级项
        while audioQueue.count > 10 {
            if let lowIndex = audioQueue.lastIndex(where: { $0.priority == .normal }) {
                audioQueue.remove(at: lowIndex)
            } else {
                audioQueue.removeLast()
            }
        }
    }

    /// 处理音频队列
    private func processQueue() {
        guard !isProcessingQueue else { return }
        guard !audioQueue.isEmpty else {
            isPlaying = false
            return
        }
        guard audioPlayer == nil || !(audioPlayer?.isPlaying ?? false) else {
            return
        }

        isProcessingQueue = true

        let item = audioQueue.removeFirst()
        playAudioFile(item.fileName)

        // 标记为已播放
        playedAudios.insert(item.fileName)

        isProcessingQueue = false
    }

    /// 执行音频文件播放
    private func playAudioFile(_ fileName: String) {
        // 查找音频文件路径
        guard let audioPath = findAudioFile(fileName) else {
            print("❌ 找不到音频文件: \(fileName)")
            logger.log("❌ 找不到音频文件: \(fileName)", category: "ERROR")
            // 继续播放下一个
            processQueue()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioPath)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()

            let success = audioPlayer?.play() ?? false
            if success {
                isPlaying = true
                print("🔊 正在播放: \(fileName)")
                logger.log("🔊 开始播放: \(fileName)", category: "VOICE")
            } else {
                print("❌ 播放失败: \(fileName)")
                logger.log("❌ 播放失败: \(fileName)", category: "ERROR")
                processQueue()
            }
        } catch {
            print("❌ 加载音频失败: \(fileName), error: \(error.localizedDescription)")
            logger.log("❌ 加载失败: \(fileName) - \(error.localizedDescription)", category: "ERROR")
            processQueue()
        }
    }

    /// 查找音频文件
    private func findAudioFile(_ fileName: String) -> URL? {
        print("🔍 查找音频文件: \(fileName)")

        // 方案1：从Assets中查找
        if let asset = NSDataAsset(name: fileName) {
            print("✅ 从Assets找到: \(fileName)")
            // 将数据写入临时文件
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).m4a")
            try? asset.data.write(to: tempURL)
            return tempURL
        }

        // 方案2：从Bundle中查找
        if let path = Bundle.main.path(forResource: fileName, ofType: "m4a") {
            print("✅ 从Bundle根目录找到: \(fileName)")
            return URL(fileURLWithPath: path)
        }

        // 方案3：从voice目录查找（所有子目录）
        for subdir in ["female", "male", "通用跑中", "新手跑中", "减肥跑"] {
            if let path = Bundle.main.path(forResource: fileName, ofType: "m4a", inDirectory: "voice/\(subdir)") {
                print("✅ 从voice/\(subdir)找到: \(fileName)")
                return URL(fileURLWithPath: path)
            }
        }

        print("❌ 所有方案都失败: \(fileName)")
        // 调试：列出Bundle中的资源
        if let resourcePath = Bundle.main.resourcePath {
            print("📦 Bundle资源路径: \(resourcePath)")
            if let voicePath = Bundle.main.path(forResource: nil, ofType: nil, inDirectory: "voice") {
                print("📂 voice目录存在: \(voicePath)")
            } else {
                print("❌ voice目录不存在于Bundle中")
            }
        }

        return nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerManager: AVAudioPlayerDelegate {

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            print("✅ 音频播放完成")
            self.isPlaying = false
            self.audioPlayer = nil

            // 继续播放队列中的下一个
            self.processQueue()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            print("❌ 音频解码错误: \(error?.localizedDescription ?? "unknown")")
            self.isPlaying = false
            self.audioPlayer = nil

            // 继续播放下一个
            self.processQueue()
        }
    }
}
