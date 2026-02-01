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
