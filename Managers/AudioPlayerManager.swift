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
            try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.mixWithOthers, .duckOthers])
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
    func play(_ fileName: String, priority: AudioPriority = .normal, allowRepeat: Bool = false) {
        guard isEnabled else {
            print("🔇 音频已禁用，跳过播放: \(fileName)")
            return
        }

        // 检查是否已播放过
        if !allowRepeat && playedAudios.contains(fileName) {
            print("⏭️ 音频已播放过，跳过: \(fileName)")
            return
        }

        print("🎵 添加到播放队列: \(fileName), priority: \(priority)")

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
            } else {
                print("❌ 播放失败: \(fileName)")
                processQueue()
            }
        } catch {
            print("❌ 加载音频失败: \(fileName), error: \(error.localizedDescription)")
            processQueue()
        }
    }

    /// 查找音频文件
    private func findAudioFile(_ fileName: String) -> URL? {
        // 方案1：从Assets中查找
        if let asset = NSDataAsset(name: fileName) {
            // 将数据写入临时文件
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).m4a")
            try? asset.data.write(to: tempURL)
            return tempURL
        }

        // 方案2：从Bundle中查找
        if let path = Bundle.main.path(forResource: fileName, ofType: "m4a") {
            return URL(fileURLWithPath: path)
        }

        // 方案3：从voice目录查找（male/female子目录）
        for subdir in ["female", "male"] {
            if let path = Bundle.main.path(forResource: fileName, ofType: "m4a", inDirectory: "voice/\(subdir)") {
                return URL(fileURLWithPath: path)
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
