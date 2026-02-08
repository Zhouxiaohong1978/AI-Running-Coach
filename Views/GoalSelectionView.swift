//
//  GoalSelectionView.swift
//  AI跑步教练
//
//  训练目标选择界面
//

import SwiftUI

struct GoalSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var aiManager = AIManager.shared
    @StateObject private var dataManager = RunDataManager.shared

    @State private var selectedGoal: TrainingGoal?
    @State private var customWeeks: Int = 8
    @State private var isGenerating = false
    @State private var errorMessage: String?

    // 用户偏好设置
    @State private var weeklyFrequency: Int = 3
    @State private var preferredDays: Set<Int> = [1, 3, 5]  // 默认周一、三、五
    @State private var intensityLevel: String = "balanced"  // "easy" | "balanced" | "intense"

    var onPlanGenerated: (TrainingPlanData) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题说明
                    headerSection

                    // 目标选择
                    goalSelectionSection

                    // 周期设置
                    if let goal = selectedGoal {
                        durationSection(goal: goal)

                        // 偏好设置
                        preferencesSection
                    }

                    // 生成按钮
                    if selectedGoal != nil {
                        generateButton
                    }
                }
                .padding()
            }
            .navigationTitle("选择训练目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("生成失败", isPresented: .constant(errorMessage != nil)) {
                Button("确定") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .disabled(isGenerating)
            .overlay {
                if isGenerating {
                    generatingOverlay
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.blue)

            Text("AI将根据你的跑步历史")
                .font(.headline)

            Text("为你量身定制训练计划")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }

    // MARK: - Goal Selection Section

    private var goalSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择你的目标")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(TrainingGoal.allCases) { goal in
                    goalCard(goal: goal)
                }
            }
        }
    }

    // MARK: - Goal Card

    @ViewBuilder
    private func goalCard(goal: TrainingGoal) -> some View {
        let isUnlocked = isGoalUnlocked(goal)
        let isSelected = selectedGoal == goal

        Button(action: {
            guard isUnlocked else { return }
            withAnimation(.spring(response: 0.3)) {
                selectedGoal = goal
                customWeeks = goal.recommendedWeeks
            }
        }) {
            VStack(spacing: 12) {
                // 锁定图标或目标图标
                ZStack {
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                    } else {
                        Image(systemName: goal.icon)
                            .font(.system(size: 32))
                            .foregroundColor(isSelected ? .white : .blue)
                    }
                }

                Text(goal.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? (isSelected ? .white : .primary) : .gray)

                if !isUnlocked {
                    // 显示解锁条件
                    if let prerequisite = goal.prerequisite {
                        Text("完成\(prerequisite.displayName)解锁")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isUnlocked ? (isSelected ? Color.blue : Color(.systemGray6)) : Color(.systemGray5))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isUnlocked ? (isSelected ? Color.blue : Color.clear) : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .opacity(isUnlocked ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    // MARK: - Goal Unlock Logic

    /// 检查目标是否已解锁
    private func isGoalUnlocked(_ goal: TrainingGoal) -> Bool {
        // 没有前置条件的目标默认解锁（3km新手 和 减肥燃脂）
        guard goal.prerequisite != nil else {
            return true
        }

        // 检查用户跑步历史：只要跑过目标所需的最低距离就自动解锁
        let maxDistance = dataManager.runRecords.map { $0.distance }.max() ?? 0
        return maxDistance >= goal.requiredDistance
    }

    // MARK: - Duration Section

    private func durationSection(goal: TrainingGoal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("训练周期")
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Text("计划时长")
                    Spacer()
                    Text("\(customWeeks) 周")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }

                Slider(
                    value: Binding(
                        get: { Double(customWeeks) },
                        set: { customWeeks = Int($0) }
                    ),
                    in: 4...16,
                    step: 1
                )
                .tint(.blue)

                HStack {
                    Text("4周")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("推荐: \(goal.recommendedWeeks)周")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                    Text("16周")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("训练偏好")
                .font(.headline)

            VStack(spacing: 16) {
                // 1. 每周训练次数
                VStack(alignment: .leading, spacing: 8) {
                    Text("每周训练几次？")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("每周训练次数", selection: $weeklyFrequency) {
                        Text("3次").tag(3)
                        Text("4次").tag(4)
                        Text("5次").tag(5)
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                // 2. 偏好训练日
                VStack(alignment: .leading, spacing: 8) {
                    Text("偏好哪些日子训练？")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 45))], spacing: 8) {
                        ForEach(1...7, id: \.self) { day in
                            dayButton(day: day)
                        }
                    }
                }

                Divider()

                // 3. 训练强度
                VStack(alignment: .leading, spacing: 8) {
                    Text("训练强度？")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("训练强度", selection: $intensityLevel) {
                        Text("轻松为主").tag("easy")
                        Text("平衡").tag("balanced")
                        Text("追求突破").tag("intense")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // 日期按钮
    private func dayButton(day: Int) -> some View {
        let dayNames = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        let isSelected = preferredDays.contains(day)

        return Button(action: {
            if isSelected {
                preferredDays.remove(day)
            } else {
                preferredDays.insert(day)
            }
        }) {
            Text(dayNames[day - 1])
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 45, height: 32)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: generatePlan) {
            HStack {
                Image(systemName: "sparkles")
                Text("生成训练计划")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding(.top, 20)
    }

    // MARK: - Generating Overlay

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("AI正在生成训练计划...")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("这可能需要几秒钟")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(Color(.systemGray5).opacity(0.9))
            .cornerRadius(20)
        }
    }

    // MARK: - Generate Plan

    private func generatePlan() {
        guard let goal = selectedGoal else { return }

        isGenerating = true

        Task {
            do {
                // 构建用户偏好
                let preferences = TrainingPreferences(
                    weeklyFrequency: weeklyFrequency,
                    preferredDays: Array(preferredDays).sorted(),
                    intensityLevel: intensityLevel
                )

                let plan = try await aiManager.generateTrainingPlan(
                    goal: goal.displayName,
                    runHistory: dataManager.runRecords,
                    durationWeeks: customWeeks,
                    preferences: preferences
                )

                await MainActor.run {
                    isGenerating = false
                    onPlanGenerated(plan)
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    GoalSelectionView { _ in }
}
