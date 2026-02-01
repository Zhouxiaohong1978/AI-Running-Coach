// VoiceScript.swift
import Foundation

enum TriggerType: String, Codable {
    case distance, calories, heartRate, time, state, fatigue, pace, heartRateZone
}

enum RunMode: String, Codable {
    case beginner, fatburn
}

struct VoiceScript: Codable, Identifiable {
    let id: String
    let mode: RunMode
    let triggerType: TriggerType
    let triggerValue: Double
    let text: String
    let voice: String
    let order: Int
    let cooldown: TimeInterval  // 冷却时间（秒），防止语音轰炸

    // 自定义初始化器，提供 cooldown 默认值
    init(id: String, mode: RunMode, triggerType: TriggerType, triggerValue: Double,
         text: String, voice: String, order: Int, cooldown: TimeInterval = 15.0) {
        self.id = id
        self.mode = mode
        self.triggerType = triggerType
        self.triggerValue = triggerValue
        self.text = text
        self.voice = voice
        self.order = order
        self.cooldown = cooldown
    }

    func resolvedText(with context: RunContext) -> String {
        var resolved = text
        if resolved.contains("[时间]") {
            resolved = resolved.replacingOccurrences(of: "[时间]", with: context.formattedTime)
        }
        if resolved.contains("[距离]") {
            resolved = resolved.replacingOccurrences(of: "[距离]", with: String(format: "%.1f公里", context.distance))
        }
        return resolved
    }
}

struct RunContext {
    var distance: Double = 0
    var calories: Double = 0
    var heartRate: Int = 0
    var duration: TimeInterval = 0
    var pace: Double = 0
    var isWalking = false
    var isFinished = false
    var fatigueLevel = "low"
    var heartRateZone = "warmup"

    var formattedTime: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)分\(seconds)秒"
    }
}
