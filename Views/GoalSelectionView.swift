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

    private func goalCard(goal: TrainingGoal) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedGoal = goal
                customWeeks = goal.recommendedWeeks
            }
        }) {
            VStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.system(size: 32))
                    .foregroundColor(selectedGoal == goal ? .white : .blue)

                Text(goal.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(selectedGoal == goal ? .white : .primary)

                Text(goal.description)
                    .font(.caption)
                    .foregroundColor(selectedGoal == goal ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedGoal == goal ? Color.blue : Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedGoal == goal ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
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
                let plan = try await aiManager.generateTrainingPlan(
                    goal: goal.displayName,
                    runHistory: dataManager.runRecords,
                    durationWeeks: customWeeks
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
