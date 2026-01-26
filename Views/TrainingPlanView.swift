//
//  TrainingPlanView.swift
//  AI跑步教练
//
//  训练计划主界面
//

import SwiftUI

struct TrainingPlanView: View {
    @StateObject private var aiManager = AIManager.shared
    @StateObject private var dataManager = RunDataManager.shared

    @State private var currentPlan: TrainingPlanData?
    @State private var showGoalSelection = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedWeek: Int = 1

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    loadingView
                } else if let plan = currentPlan {
                    planDetailView(plan: plan)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("训练计划")
            .sheet(isPresented: $showGoalSelection) {
                GoalSelectionView(onPlanGenerated: { plan in
                    currentPlan = plan
                    showGoalSelection = false
                })
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("AI正在生成训练计划...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.6))

            Text("还没有训练计划")
                .font(.title2)
                .fontWeight(.semibold)

            Text("让AI教练为你制定个性化训练计划\n科学提升跑步能力")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showGoalSelection = true }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("创建训练计划")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding()
    }

    // MARK: - Plan Detail View

    private func planDetailView(plan: TrainingPlanData) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // 计划概览卡片
                planOverviewCard(plan: plan)

                // 周选择器
                weekSelector(plan: plan)

                // 当前周任务列表
                if let weekPlan = plan.weeklyPlans.first(where: { $0.weekNumber == selectedWeek }) {
                    weekTasksView(weekPlan: weekPlan)
                }

                // 训练建议
                tipsCard(tips: plan.tips)

                // 重新生成按钮
                Button(action: { showGoalSelection = true }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重新制定计划")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.top, 10)
            }
            .padding()
        }
    }

    // MARK: - Plan Overview Card

    private func planOverviewCard(plan: TrainingPlanData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.orange)
                Text(plan.goal)
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text(difficultyText(plan.difficulty))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor(plan.difficulty).opacity(0.2))
                    .foregroundColor(difficultyColor(plan.difficulty))
                    .cornerRadius(8)
            }

            Divider()

            HStack(spacing: 30) {
                VStack {
                    Text("\(plan.durationWeeks)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("周")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(plan.weeklyPlans.flatMap { $0.dailyTasks }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("训练日")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("第\(selectedWeek)周")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("当前进度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    // MARK: - Week Selector

    private func weekSelector(plan: TrainingPlanData) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(1...plan.durationWeeks, id: \.self) { week in
                    Button(action: { selectedWeek = week }) {
                        Text("第\(week)周")
                            .font(.subheadline)
                            .fontWeight(selectedWeek == week ? .bold : .regular)
                            .foregroundColor(selectedWeek == week ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedWeek == week ? Color.blue : Color(.systemGray6))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Week Tasks View

    private func weekTasksView(weekPlan: WeekPlanData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(weekPlan.theme)
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(weekPlan.dailyTasks, id: \.dayOfWeek) { task in
                taskRow(task: task)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    // MARK: - Task Row

    private func taskRow(task: DailyTaskData) -> some View {
        HStack(spacing: 12) {
            // 星期
            Text(task.dayOfWeek.dayOfWeekName)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 40)

            // 任务类型图标
            Image(systemName: taskIcon(task.type))
                .foregroundColor(taskColor(task.type))
                .frame(width: 24)

            // 任务详情
            VStack(alignment: .leading, spacing: 2) {
                Text(task.description)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let distance = task.targetDistance {
                        Text("\(String(format: "%.1f", distance))km")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let pace = task.targetPace {
                        Text(pace)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Tips Card

    private func tipsCard(tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("训练建议")
                    .font(.headline)
            }

            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.blue)
                    Text(tip)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    // MARK: - Helper Methods

    private func difficultyText(_ difficulty: String) -> String {
        switch difficulty {
        case "beginner": return "入门"
        case "intermediate": return "进阶"
        case "advanced": return "高级"
        default: return difficulty
        }
    }

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }

    private func taskIcon(_ type: String) -> String {
        switch type {
        case "easy_run": return "figure.walk"
        case "tempo_run": return "figure.run"
        case "interval": return "bolt.fill"
        case "long_run": return "figure.run.circle.fill"
        case "rest": return "bed.double.fill"
        case "cross_training": return "figure.mixed.cardio"
        default: return "figure.run"
        }
    }

    private func taskColor(_ type: String) -> Color {
        switch type {
        case "easy_run": return .green
        case "tempo_run": return .orange
        case "interval": return .red
        case "long_run": return .blue
        case "rest": return .gray
        case "cross_training": return .purple
        default: return .blue
        }
    }
}

#Preview {
    TrainingPlanView()
}
