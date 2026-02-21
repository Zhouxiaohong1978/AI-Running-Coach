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
    case subscriptionRequired

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
        case .subscriptionRequired:
            return "需要升级 Pro 会员"
        }
    }
}

// MARK: - Request/Response Models

/// 训练偏好设置
struct TrainingPreferences: Codable {
    let weeklyFrequency: Int           // 每周训练次数（3-5）
    let preferredDays: [Int]           // 偏好训练日（1-7，周一到周日）
    let intensityLevel: String         // 强度等级："easy" | "balanced" | "intense"
}

/// 训练计划生成请求
struct GeneratePlanRequest: Codable {
    let goal: String
    let avgPace: Double?
    let maxDistance: Double?
    let weeklyRuns: Int
    let durationWeeks: Int
    let currentPlan: TrainingPlanData?     // 用户修改后的当前计划，用于重新生成时参考
    let preferences: TrainingPreferences?  // 用户偏好设置
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
    let kmSplits: [Double]?
    let trainingType: String?
    let goalName: String?
    let language: String?  // "en" or "zh-Hans"
}

/// 反馈三段结构
struct FeedbackParagraphs: Codable {
    let summary: String
    let analysis: String
    let suggestion: String
}

/// 教练反馈响应
struct CoachFeedbackResponse: Codable {
    let success: Bool
    let feedback: String?
    let paragraphs: FeedbackParagraphs?
    let scene: String?
    let error: String?
    let timestamp: String?
}

/// 教练反馈结果（供 UI 使用）
struct CoachFeedbackResult {
    let feedback: String
    let paragraphs: FeedbackParagraphs?
    let scene: String?
}

// MARK: - Training Plan Data Models

/// 训练计划数据
struct TrainingPlanData: Codable {
    let goal: String
    let durationWeeks: Int
    let difficulty: String
    var weeklyPlans: [WeekPlanData]  // 改为 var 以支持编辑
    var tips: [String]  // 改为 var 以支持编辑
    var preferences: TrainingPreferences?  // 保留用户偏好，重新生成时复用
}

/// 周计划数据
struct WeekPlanData: Codable {
    let weekNumber: Int
    var theme: String  // 改为 var 以支持编辑
    var dailyTasks: [DailyTaskData]  // 改为 var 以支持编辑
}

/// 每日任务数据
struct DailyTaskData: Codable {
    var dayOfWeek: Int  // 改为 var 以支持编辑
    var type: String  // 改为 var 以支持编辑
    var targetDistance: Double?  // 改为 var 以支持编辑
    var targetPace: String?  // 改为 var 以支持编辑
    var description: String  // 改为 var 以支持编辑

    /// 根据 type 和 targetDistance 实时生成的 locale-aware 描述（不依赖存储的 description 字符串）
    var localizedDescription: String {
        let isEN = LanguageManager.shared.currentLocale == "en"
        let dist = targetDistance ?? 0
        let distStr = String(format: "%.1f", dist)
        switch type {
        case "easy_run":
            return isEN ? "Easy run \(distStr) km, comfortable pace" : "轻松跑\(distStr)公里，保持舒适配速"
        case "tempo_run":
            return isEN ? "Tempo run \(distStr) km, comfortably hard" : "节奏跑\(distStr)公里，稍有挑战但可持续"
        case "long_run":
            return isEN ? "Long run \(distStr) km, slow and steady" : "长距离跑\(distStr)公里，慢慢跑完"
        case "interval":
            return isEN ? "Interval \(distStr) km, alternate fast & slow" : "间歇跑\(distStr)公里，快慢交替"
        case "rest":
            return isEN ? "Rest Day" : "休息日"
        case "cross_training":
            return isEN ? "Cross training \(distStr) km" : "交叉训练\(distStr)公里"
        default:
            return isEN ? "Run \(distStr) km" : "跑步\(distStr)公里"
        }
    }
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
    @Published var isAIOptimizing = false      // 后台AI优化进行中
    @Published var isGeneratingFeedback = false
    @Published var lastFeedback: String?
    @Published var coachStyle: CoachStyle = .encouraging

    // MARK: - Private Properties

    private init() {
        // 从UserDefaults加载用户选择的教练风格
        if let styleString = UserDefaults.standard.string(forKey: "coach_style"),
           let style = CoachStyle(rawValue: styleString) {
            coachStyle = style
            print("✅ AIManager 加载教练风格: \(styleString)")
        } else {
            print("✅ AIManager 使用默认教练风格: encouraging")
        }
    }

    // MARK: - Training Plan Generation

    /// 同步生成训练计划（模板立即返回 + 后台AI优化）
    /// 完全同步，无需 async/await，无 spinner 等待
    func generateInstantPlan(
        goal: String,
        runHistory: [RunRecord],
        durationWeeks: Int = 8,
        currentPlan: TrainingPlanData? = nil,
        preferences: TrainingPreferences? = nil
    ) -> Result<TrainingPlanData, AIManagerError> {

        guard AuthManager.shared.currentUser != nil else {
            return .failure(.notAuthenticated)
        }

        guard SubscriptionManager.shared.canGeneratePlan() else {
            return .failure(.subscriptionRequired)
        }

        let avgPace = calculateAveragePace(from: runHistory)
        let maxDistance = runHistory.map { $0.distance / 1000.0 }.max()
        let weeklyRuns = calculateWeeklyRuns(from: runHistory)

        print("🤖 同步模板生成开始")

        // 同步生成模板（纯计算，<10ms）
        let plan = generateSmartTemplate(
            goal: goal,
            durationWeeks: durationWeeks,
            preferences: preferences,
            avgPace: avgPace,
            maxDistance: maxDistance
        )

        print("✅ 模板生成完成，后台AI优化启动")

        SubscriptionManager.shared.incrementPlanCount()

        // 后台AI优化（不阻塞当前线程）
        let capturedGoal = goal
        let capturedDurationWeeks = durationWeeks
        let capturedCurrentPlan = currentPlan
        let capturedPreferences = preferences
        Task {
            await optimizePlanWithAI(
                goal: capturedGoal,
                avgPace: avgPace,
                maxDistance: maxDistance,
                weeklyRuns: weeklyRuns,
                durationWeeks: capturedDurationWeeks,
                currentPlan: capturedCurrentPlan,
                preferences: capturedPreferences
            )
        }

        return .success(plan)
    }

    /// 重新优化已有计划（保持用户编辑的结构，只启动后台AI优化）
    /// 不重建本地模板，不改变训练天数/距离，只让AI优化描述/配速
    func triggerReoptimize(plan: TrainingPlanData, runHistory: [RunRecord]) {
        guard AuthManager.shared.currentUser != nil else { return }
        guard SubscriptionManager.shared.canGeneratePlan() else { return }

        SubscriptionManager.shared.incrementPlanCount()

        let avgPace = calculateAveragePace(from: runHistory)
        let maxDistance = runHistory.map { $0.distance / 1000.0 }.max()
        let weeklyRuns = calculateWeeklyRuns(from: runHistory)

        print("🔁 触发重新优化（保持用户计划结构不变）")

        Task {
            await optimizePlanWithAI(
                goal: plan.goal,
                avgPace: avgPace,
                maxDistance: maxDistance,
                weeklyRuns: weeklyRuns,
                durationWeeks: plan.durationWeeks,
                currentPlan: plan,
                preferences: plan.preferences
            )
        }
    }

    /// 异步生成训练计划（供重新生成使用，保留现有逻辑）
    func generateTrainingPlan(
        goal: String,
        runHistory: [RunRecord],
        durationWeeks: Int = 8,
        currentPlan: TrainingPlanData? = nil,
        preferences: TrainingPreferences? = nil
    ) async throws -> TrainingPlanData {
        guard AuthManager.shared.currentUser != nil else {
            throw AIManagerError.notAuthenticated
        }

        guard SubscriptionManager.shared.canGeneratePlan() else {
            throw AIManagerError.subscriptionRequired
        }

        isGeneratingPlan = true
        defer { isGeneratingPlan = false }

        let avgPace = calculateAveragePace(from: runHistory)
        let maxDistance = runHistory.map { $0.distance / 1000.0 }.max()
        let weeklyRuns = calculateWeeklyRuns(from: runHistory)

        let plan = generateSmartTemplate(
            goal: goal,
            durationWeeks: durationWeeks,
            preferences: preferences,
            avgPace: avgPace,
            maxDistance: maxDistance
        )

        SubscriptionManager.shared.incrementPlanCount()

        Task {
            await optimizePlanWithAI(
                goal: goal,
                avgPace: avgPace,
                maxDistance: maxDistance,
                weeklyRuns: weeklyRuns,
                durationWeeks: durationWeeks,
                currentPlan: currentPlan,
                preferences: preferences
            )
        }

        return plan
    }

    /// 生成智能模板计划（根据用户偏好定制）
    private func generateSmartTemplate(
        goal: String,
        durationWeeks: Int,
        preferences: TrainingPreferences?,
        avgPace: Double?,
        maxDistance: Double?
    ) -> TrainingPlanData {
        // 根据目标确定基础距离和难度
        let (baseDistance, difficulty, targetPace) = determineBaseParameters(
            goal: goal,
            avgPace: avgPace,
            maxDistance: maxDistance
        )

        // 根据偏好确定训练日
        let trainingDays = preferences?.preferredDays ?? [1, 3, 5] // 默认周一、三、五
        let weeklyFrequency = preferences?.weeklyFrequency ?? 3

        var weeklyPlans: [WeekPlanData] = []

        for week in 1...durationWeeks {
            let theme = determineWeekTheme(week: week, totalWeeks: durationWeeks)
            let progressFactor = Double(week - 1) / Double(durationWeeks)

            var dailyTasks: [DailyTaskData] = []

            // 根据用户偏好生成每周训练任务
            for (index, day) in trainingDays.prefix(weeklyFrequency).enumerated() {
                let taskType = determineTaskType(
                    dayIndex: index,
                    weeklyFrequency: weeklyFrequency,
                    week: week,
                    intensity: preferences?.intensityLevel ?? "balanced"
                )

                let distance = calculateDistance(
                    baseDistance: baseDistance,
                    taskType: taskType,
                    progressFactor: progressFactor,
                    dayIndex: index,
                    weeklyFrequency: weeklyFrequency
                )

                dailyTasks.append(DailyTaskData(
                    dayOfWeek: day,
                    type: taskType,
                    targetDistance: distance,
                    targetPace: targetPace,
                    description: generateTaskDescription(type: taskType, distance: distance)
                ))
            }

            weeklyPlans.append(WeekPlanData(
                weekNumber: week,
                theme: theme,
                dailyTasks: dailyTasks
            ))
        }

        return TrainingPlanData(
            goal: goal,
            durationWeeks: durationWeeks,
            difficulty: difficulty,
            weeklyPlans: weeklyPlans,
            tips: generateSmartTips(goal: goal, difficulty: difficulty),
            preferences: preferences
        )
    }

    /// 后台AI优化（异步，不阻塞UI）
    private func optimizePlanWithAI(
        goal: String,
        avgPace: Double?,
        maxDistance: Double?,
        weeklyRuns: Int,
        durationWeeks: Int,
        currentPlan: TrainingPlanData?,
        preferences: TrainingPreferences?
    ) async {
        print("🔄 后台开始AI优化...")
        await MainActor.run { isAIOptimizing = true }
        defer {
            Task { @MainActor in isAIOptimizing = false }
        }

        let request = GeneratePlanRequest(
            goal: goal,
            avgPace: avgPace,
            maxDistance: maxDistance,
            weeklyRuns: weeklyRuns,
            durationWeeks: durationWeeks,
            currentPlan: currentPlan,
            preferences: preferences
        )

        do {
            let response: GeneratePlanResponse = try await supabase.functions
                .invoke(
                    "generate-training-plan",
                    options: FunctionInvokeOptions(body: request)
                )

            guard response.success, var plan = response.plan else {
                print("❌ AI优化失败，保持使用模板计划")
                return
            }

            plan.preferences = preferences

            // 发送通知：AI优化完成
            await MainActor.run {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AIOptimizationComplete"),
                    object: nil,
                    userInfo: ["plan": plan]
                )
            }

            print("✅ AI优化完成，已通知更新")

        } catch {
            print("❌ AI优化失败: \(error.localizedDescription)，保持使用模板计划")
        }
    }

    // MARK: - 模板生成辅助函数

    private func determineBaseParameters(goal: String, avgPace: Double?, maxDistance: Double?) -> (Double, String, String) {
        switch goal {
        case let g where g.contains("3km") || g.contains("3公里"):
            return (2.5, "beginner", "7'00\"")
        case let g where g.contains("5km") || g.contains("5公里"):
            return (3.0, "intermediate", "6'30\"")
        case let g where g.contains("10km") || g.contains("10公里"):
            return (4.0, "intermediate", "6'00\"")
        case let g where g.contains("半马") || g.contains("21km"):
            return (6.0, "advanced", "5'45\"")
        case let g where g.contains("全马") || g.contains("42km"):
            return (8.0, "advanced", "5'30\"")
        case let g where g.contains("减肥") || g.contains("燃脂"):
            return (3.0, "beginner", "7'30\"")
        default:
            return (3.0, "beginner", "7'00\"")
        }
    }

    private func determineWeekTheme(week: Int, totalWeeks: Int) -> String {
        let progress = Double(week) / Double(totalWeeks)
        if progress < 0.25 {
            return "适应期 - 建立习惯"
        } else if progress < 0.5 {
            return "基础期 - 打好基础"
        } else if progress < 0.75 {
            return "提高期 - 增强能力"
        } else {
            return "巩固期 - 稳定提升"
        }
    }

    private func determineTaskType(dayIndex: Int, weeklyFrequency: Int, week: Int, intensity: String) -> String {
        // 最后一天通常是长距离跑
        if dayIndex == weeklyFrequency - 1 {
            return "long_run"
        }

        // 根据强度和周次决定训练类型
        if intensity == "easy" {
            return "easy_run"
        } else if intensity == "intense" && week > 2 {
            return dayIndex == 1 ? "tempo_run" : "easy_run"
        } else {
            return dayIndex == 0 ? "easy_run" : (dayIndex == 1 ? "tempo_run" : "easy_run")
        }
    }

    private func calculateDistance(baseDistance: Double, taskType: String, progressFactor: Double, dayIndex: Int, weeklyFrequency: Int) -> Double {
        var distance = baseDistance

        // 根据训练类型调整距离
        switch taskType {
        case "long_run":
            distance *= 1.5 // 长距离跑是基础距离的1.5倍
        case "tempo_run":
            distance *= 1.2
        default:
            break
        }

        // 根据进度递增（前几周增长慢，中期增长快，后期稳定）
        let growthRate = 0.5 * progressFactor
        distance *= (1 + growthRate)

        return (distance * 10).rounded() / 10 // 保留1位小数
    }

    private func generateTaskDescription(type: String, distance: Double) -> String {
        let distStr = String(format: "%.1f", distance)
        switch type {
        case "easy_run":
            return "轻松跑\(distStr)公里，保持舒适配速"
        case "tempo_run":
            return "节奏跑\(distStr)公里，稍有挑战但可持续"
        case "long_run":
            return "长距离跑\(distStr)公里，慢慢跑完"
        case "interval":
            return "间歇跑\(distStr)公里，快慢交替"
        default:
            return "跑步\(distStr)公里"
        }
    }

    private func generateSmartTips(goal: String, difficulty: String) -> [String] {
        var tips = [
            "每次跑步前做5-10分钟热身",
            "跑后拉伸很重要，预防受伤",
            "循序渐进，不要急于求成"
        ]

        if difficulty == "beginner" {
            tips.append("新手优先关注完成，而非速度")
        } else if difficulty == "advanced" {
            tips.append("注意监控心率，避免过度训练")
        }

        if goal.contains("减肥") || goal.contains("燃脂") {
            tips.append("配合饮食控制效果更佳")
        }

        return tips
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
        heartRate: Int? = nil,
        kmSplits: [Double]? = nil,
        trainingType: String? = nil,
        goalName: String? = nil
    ) async throws -> CoachFeedbackResult {
        guard AuthManager.shared.currentUser != nil else {
            throw AIManagerError.notAuthenticated
        }

        guard SubscriptionManager.shared.canGetFeedback() else {
            throw AIManagerError.subscriptionRequired
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
            coachStyle: coachStyle.rawValue,
            kmSplits: kmSplits,
            trainingType: trainingType,
            goalName: goalName,
            language: LanguageManager.shared.currentLocale
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
            SubscriptionManager.shared.incrementFeedbackCount()
            return CoachFeedbackResult(
                feedback: feedback,
                paragraphs: response.paragraphs,
                scene: response.scene
            )

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
