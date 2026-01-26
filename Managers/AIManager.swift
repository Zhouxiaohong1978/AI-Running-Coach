//
//  AIManager.swift
//  AI跑步教练
//
//  AI服务管理器 - 调用Edge Function实现训练计划生成和实时教练反馈
//

import Foundation
import Supabase

// MARK: - Error Types

enum AIManagerError: LocalizedError {
    case notAuthenticated
    case networkError(String)
    case invalidResponse
    case aiGenerationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "用户未登录"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .invalidResponse:
            return "AI响应格式错误"
        case .aiGenerationFailed(let message):
            return "AI生成失败: \(message)"
        }
    }
}

// MARK: - Request/Response Models

/// 训练计划生成请求
struct GeneratePlanRequest: Codable {
    let goal: String
    let avgPace: Double?
    let maxDistance: Double?
    let weeklyRuns: Int
    let durationWeeks: Int
}

/// 训练计划生成响应
struct GeneratePlanResponse: Codable {
    let success: Bool
    let plan: TrainingPlanData?
    let error: String?
    let timestamp: String?
}

/// 教练反馈请求
struct CoachFeedbackRequest: Codable {
    let currentPace: Double
    let targetPace: Double?
    let distance: Double
    let totalDistance: Double?
    let duration: Double
    let heartRate: Int?
    let coachStyle: String?
}

/// 教练反馈响应
struct CoachFeedbackResponse: Codable {
    let success: Bool
    let feedback: String?
    let error: String?
    let timestamp: String?
}

// MARK: - Training Plan Data Models

/// 训练计划数据
struct TrainingPlanData: Codable {
    let goal: String
    let durationWeeks: Int
    let difficulty: String
    let weeklyPlans: [WeekPlanData]
    let tips: [String]
}

/// 周计划数据
struct WeekPlanData: Codable {
    let weekNumber: Int
    let theme: String
    let dailyTasks: [DailyTaskData]
}

/// 每日任务数据
struct DailyTaskData: Codable {
    let dayOfWeek: Int
    let type: String
    let targetDistance: Double?
    let targetPace: String?
    let description: String
}

// MARK: - Coach Style

/// 教练风格
enum CoachStyle: String, CaseIterable {
    case encouraging = "encouraging"  // 鼓励型
    case strict = "strict"            // 严格型
    case calm = "calm"                // 温和型

    var displayName: String {
        switch self {
        case .encouraging: return "鼓励型"
        case .strict: return "严格型"
        case .calm: return "温和型"
        }
    }
}

// MARK: - AIManager

@MainActor
final class AIManager: ObservableObject {

    // MARK: - Singleton

    static let shared = AIManager()

    // MARK: - Published Properties

    @Published var isGeneratingPlan = false
    @Published var isGeneratingFeedback = false
    @Published var lastFeedback: String?
    @Published var coachStyle: CoachStyle = .encouraging

    // MARK: - Private Properties

    private init() {
        print("AIManager 初始化完成")
    }

    // MARK: - Training Plan Generation

    /// 生成训练计划
    /// - Parameters:
    ///   - goal: 训练目标（如"5km入门"、"10km进阶"、"减肥"）
    ///   - runHistory: 用户历史跑步记录
    ///   - durationWeeks: 计划周期（周）
    /// - Returns: 生成的训练计划数据
    func generateTrainingPlan(
        goal: String,
        runHistory: [RunRecord],
        durationWeeks: Int = 8
    ) async throws -> TrainingPlanData {
        guard AuthManager.shared.currentUser != nil else {
            throw AIManagerError.notAuthenticated
        }

        isGeneratingPlan = true
        defer { isGeneratingPlan = false }

        // 计算用户历史数据
        let avgPace = calculateAveragePace(from: runHistory)
        let maxDistance = runHistory.map { $0.distance / 1000.0 }.max()
        let weeklyRuns = calculateWeeklyRuns(from: runHistory)

        print("🤖 开始生成训练计划: \(goal)")
        print("   平均配速: \(avgPace ?? 0), 最长距离: \(maxDistance ?? 0)km, 每周跑步: \(weeklyRuns)次")

        // 构建请求
        let request = GeneratePlanRequest(
            goal: goal,
            avgPace: avgPace,
            maxDistance: maxDistance,
            weeklyRuns: weeklyRuns,
            durationWeeks: durationWeeks
        )

        do {
            // 调用 Edge Function
            let response: GeneratePlanResponse = try await supabase.functions
                .invoke(
                    "generate-training-plan",
                    options: FunctionInvokeOptions(body: request)
                )

            // 检查响应
            guard response.success, let plan = response.plan else {
                let errorMsg = response.error ?? "未知错误"
                print("❌ 训练计划生成失败: \(errorMsg)")
                throw AIManagerError.aiGenerationFailed(errorMsg)
            }

            print("✅ 训练计划生成成功: \(plan.durationWeeks)周计划")
            return plan

        } catch let error as AIManagerError {
            throw error
        } catch {
            print("❌ 训练计划生成网络错误: \(error.localizedDescription)")
            throw AIManagerError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Coach Feedback

    /// 获取实时教练反馈
    /// - Parameters:
    ///   - currentPace: 当前配速（分钟/公里）
    ///   - targetPace: 目标配速（可选）
    ///   - distance: 已跑距离（公里）
    ///   - totalDistance: 总目标距离（可选）
    ///   - duration: 已跑时长（秒）
    ///   - heartRate: 心率（可选）
    /// - Returns: 教练反馈文本
    func getCoachFeedback(
        currentPace: Double,
        targetPace: Double? = nil,
        distance: Double,
        totalDistance: Double? = nil,
        duration: TimeInterval,
        heartRate: Int? = nil
    ) async throws -> String {
        guard AuthManager.shared.currentUser != nil else {
            throw AIManagerError.notAuthenticated
        }

        isGeneratingFeedback = true
        defer { isGeneratingFeedback = false }

        // 构建请求
        let request = CoachFeedbackRequest(
            currentPace: currentPace,
            targetPace: targetPace,
            distance: distance,
            totalDistance: totalDistance,
            duration: duration,
            heartRate: heartRate,
            coachStyle: coachStyle.rawValue
        )

        do {
            // 调用 Edge Function
            let response: CoachFeedbackResponse = try await supabase.functions
                .invoke(
                    "coach-feedback",
                    options: FunctionInvokeOptions(body: request)
                )

            // 检查响应
            guard response.success, let feedback = response.feedback else {
                let errorMsg = response.error ?? "未知错误"
                throw AIManagerError.aiGenerationFailed(errorMsg)
            }

            lastFeedback = feedback
            return feedback

        } catch let error as AIManagerError {
            throw error
        } catch {
            throw AIManagerError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Helper Methods

    /// 计算平均配速
    private func calculateAveragePace(from records: [RunRecord]) -> Double? {
        let validRecords = records.filter { $0.distance > 0 && $0.duration > 0 }
        guard !validRecords.isEmpty else { return nil }

        let totalPace = validRecords.reduce(0.0) { $0 + $1.pace }
        return totalPace / Double(validRecords.count)
    }

    /// 计算每周跑步次数
    private func calculateWeeklyRuns(from records: [RunRecord]) -> Int {
        guard !records.isEmpty else { return 3 } // 默认3次

        // 计算最近30天的跑步次数
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentRuns = records.filter { $0.startTime >= thirtyDaysAgo }

        if recentRuns.isEmpty { return 3 }

        // 换算成每周
        let weeksCount = max(1, recentRuns.count > 0 ? 4 : 1)
        return max(1, recentRuns.count / weeksCount)
    }
}
