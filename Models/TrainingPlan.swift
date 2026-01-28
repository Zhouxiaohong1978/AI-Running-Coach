//
//  TrainingPlan.swift
//  AI跑步教练
//
//  训练计划数据模型
//

import Foundation

// MARK: - Training Plan

/// 训练计划
struct TrainingPlan: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let goal: String
    let planJson: TrainingPlanData
    let durationWeeks: Int
    let difficulty: String
    var isActive: Bool
    var progress: TrainingProgress
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case goal
        case planJson = "plan_json"
        case durationWeeks = "duration_weeks"
        case difficulty
        case isActive = "is_active"
        case progress
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Training Progress

/// 训练进度
struct TrainingProgress: Codable {
    var completedWeeks: Int
    var completedTasks: [String: Bool]  // taskId -> completed
    var lastCompletedDate: Date?

    init() {
        self.completedWeeks = 0
        self.completedTasks = [:]
        self.lastCompletedDate = nil
    }

    init(completedWeeks: Int, completedTasks: [String: Bool], lastCompletedDate: Date?) {
        self.completedWeeks = completedWeeks
        self.completedTasks = completedTasks
        self.lastCompletedDate = lastCompletedDate
    }
}

// MARK: - Training Goal

/// 训练目标类型
enum TrainingGoal: String, CaseIterable, Identifiable {
    case threeK = "3km新手"
    case weightLoss = "减肥燃脂"
    case fiveK = "5km入门"
    case tenK = "10km进阶"
    case halfMarathon = "半程马拉松"
    case fullMarathon = "全程马拉松"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .threeK:
            return "零基础新手，6周完成首个3公里"
        case .fiveK:
            return "适合跑步新手，8周完成首个5公里"
        case .tenK:
            return "适合有基础的跑者，10周突破10公里"
        case .halfMarathon:
            return "挑战21.1公里，12周系统训练"
        case .fullMarathon:
            return "完成42.195公里梦想，16周专业训练"
        case .weightLoss:
            return "科学燃脂，8周养成跑步习惯"
        }
    }

    var recommendedWeeks: Int {
        switch self {
        case .threeK: return 6
        case .fiveK: return 8
        case .tenK: return 10
        case .halfMarathon: return 12
        case .fullMarathon: return 16
        case .weightLoss: return 8
        }
    }

    var icon: String {
        switch self {
        case .threeK: return "figure.walk"
        case .fiveK: return "figure.run"
        case .tenK: return "figure.run.circle"
        case .halfMarathon: return "trophy"
        case .fullMarathon: return "trophy.fill"
        case .weightLoss: return "flame"
        }
    }

    /// 前置目标（需要完成哪个目标才能解锁）
    var prerequisite: TrainingGoal? {
        switch self {
        case .threeK, .weightLoss:
            return nil  // 默认解锁
        case .fiveK:
            return .threeK  // 需要完成3km或减肥燃脂
        case .tenK:
            return .fiveK   // 需要完成5km
        case .halfMarathon:
            return .tenK    // 需要完成10km
        case .fullMarathon:
            return .halfMarathon  // 需要完成半马
        }
    }

    /// 解锁所需的最低跑步距离（米）- 用户只要跑过该距离就自动解锁
    var requiredDistance: Double {
        switch self {
        case .threeK, .weightLoss:
            return 0  // 默认解锁
        case .fiveK:
            return 3000  // 跑过3km即可解锁
        case .tenK:
            return 5000  // 跑过5km即可解锁
        case .halfMarathon:
            return 10000  // 跑过10km即可解锁
        case .fullMarathon:
            return 21095  // 跑过半马即可解锁
        }
    }

    /// 解锁顺序
    var unlockOrder: Int {
        switch self {
        case .threeK: return 0
        case .weightLoss: return 0
        case .fiveK: return 1
        case .tenK: return 2
        case .halfMarathon: return 3
        case .fullMarathon: return 4
        }
    }
}

// MARK: - Task Type

/// 训练任务类型
enum TaskType: String, Codable {
    case easyRun = "easy_run"       // 轻松跑
    case tempoRun = "tempo_run"     // 节奏跑
    case interval = "interval"       // 间歇跑
    case longRun = "long_run"       // 长距离跑
    case rest = "rest"              // 休息日
    case crossTraining = "cross_training"  // 交叉训练

    var displayName: String {
        switch self {
        case .easyRun: return "轻松跑"
        case .tempoRun: return "节奏跑"
        case .interval: return "间歇跑"
        case .longRun: return "长距离跑"
        case .rest: return "休息"
        case .crossTraining: return "交叉训练"
        }
    }

    var icon: String {
        switch self {
        case .easyRun: return "figure.walk"
        case .tempoRun: return "figure.run"
        case .interval: return "bolt.fill"
        case .longRun: return "figure.run.circle.fill"
        case .rest: return "bed.double.fill"
        case .crossTraining: return "figure.mixed.cardio"
        }
    }

    var color: String {
        switch self {
        case .easyRun: return "green"
        case .tempoRun: return "orange"
        case .interval: return "red"
        case .longRun: return "blue"
        case .rest: return "gray"
        case .crossTraining: return "purple"
        }
    }
}

// MARK: - Difficulty

/// 难度等级
enum Difficulty: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    var displayName: String {
        switch self {
        case .beginner: return "入门"
        case .intermediate: return "进阶"
        case .advanced: return "高级"
        }
    }
}

// MARK: - Day of Week Extension

extension Int {
    /// 星期几的中文名称
    var dayOfWeekName: String {
        switch self {
        case 1: return "周一"
        case 2: return "周二"
        case 3: return "周三"
        case 4: return "周四"
        case 5: return "周五"
        case 6: return "周六"
        case 7: return "周日"
        default: return "未知"
        }
    }
}
