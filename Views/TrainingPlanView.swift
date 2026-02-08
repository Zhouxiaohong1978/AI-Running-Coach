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
    @State private var viewMode: PlanViewMode = .week
    @State private var selectedTask: (task: DailyTaskData, weekNumber: Int)?
    @State private var showQuickActions = false
    @State private var isRegenerating = false

    /// 快速编辑操作
    enum QuickEditAction {
        case toggleRest       // 切换休息日/训练日
        case decreaseDistance // 减少距离 -0.5km
        case increaseDistance // 增加距离 +0.5km
    }

    // UserDefaults key for saving plan
    private let planStorageKey = "saved_training_plan"

    // 视图模式
    enum PlanViewMode: String, CaseIterable {
        case week = "周视图"
        case calendar = "月历"
        case overview = "月概览"
    }

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
            .onAppear {
                loadSavedPlan()
            }
            .sheet(isPresented: $showGoalSelection) {
                GoalSelectionView(onPlanGenerated: { plan in
                    currentPlan = plan
                    savePlan(plan)
                    showGoalSelection = false
                })
            }
            .confirmationDialog(
                selectedTask?.task.type == "rest" ? "添加训练" : "调整训练",
                isPresented: $showQuickActions,
                titleVisibility: .visible
            ) {
                if let task = selectedTask?.task, let weekNumber = selectedTask?.weekNumber {
                    quickActionButtons(for: task, weekNumber: weekNumber)
                }
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .overlay {
                if isRegenerating {
                    regeneratingOverlay
                }
            }
        }
    }

    // MARK: - Regenerating Overlay

    private var regeneratingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("AI正在重新生成训练计划...")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("根据你的修改优化中")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(Color(.systemGray5).opacity(0.9))
            .cornerRadius(20)
        }
    }

    // MARK: - Persistence

    /// 加载保存的训练计划
    private func loadSavedPlan() {
        guard currentPlan == nil else { return }
        if let data = UserDefaults.standard.data(forKey: planStorageKey),
           let plan = try? JSONDecoder().decode(TrainingPlanData.self, from: data) {
            currentPlan = plan
        }
    }

    /// 保存训练计划
    private func savePlan(_ plan: TrainingPlanData) {
        if let data = try? JSONEncoder().encode(plan) {
            UserDefaults.standard.set(data, forKey: planStorageKey)
        }
    }

    /// 更新任务
    private func updateTask(_ updatedTask: DailyTaskData, weekNumber: Int) {
        guard var plan = currentPlan else { return }

        // 找到对应的周计划
        if let weekIndex = plan.weeklyPlans.firstIndex(where: { $0.weekNumber == weekNumber }) {
            var weekPlan = plan.weeklyPlans[weekIndex]

            if let taskIndex = weekPlan.dailyTasks.firstIndex(where: { $0.dayOfWeek == updatedTask.dayOfWeek }) {
                // 已有该天的任务，直接更新
                weekPlan.dailyTasks[taskIndex] = updatedTask
            } else {
                // 该天原本是补充的休息日（不在 dailyTasks 中），需要插入
                weekPlan.dailyTasks.append(updatedTask)
            }

            plan.weeklyPlans[weekIndex] = weekPlan
            currentPlan = plan
            savePlan(plan)
        }
    }

    /// 快速操作按钮
    @ViewBuilder
    private func quickActionButtons(for task: DailyTaskData, weekNumber: Int) -> some View {
        let isRest = task.type == "rest"

        if isRest {
            // 休息日：改为训练
            Button("改为轻松跑") {
                var newTask = task
                newTask.type = "easy_run"
                newTask.targetDistance = 3.0
                newTask.targetPace = "7'00\""
                newTask.description = "轻松跑3公里"
                updateTask(newTask, weekNumber: weekNumber)
            }
        } else {
            // 训练日：调整距离或改为休息
            Button("减少 0.5km") {
                var newTask = task
                if let distance = task.targetDistance, distance > 0.5 {
                    newTask.targetDistance = distance - 0.5
                    newTask.description = task.description.replacingOccurrences(
                        of: String(format: "%.1f", distance),
                        with: String(format: "%.1f", distance - 0.5)
                    )
                    updateTask(newTask, weekNumber: weekNumber)
                }
            }

            Button("增加 0.5km") {
                var newTask = task
                if let distance = task.targetDistance, distance < 15.0 {
                    newTask.targetDistance = distance + 0.5
                    newTask.description = task.description.replacingOccurrences(
                        of: String(format: "%.1f", distance),
                        with: String(format: "%.1f", distance + 0.5)
                    )
                    updateTask(newTask, weekNumber: weekNumber)
                }
            }

            Button("改为休息日", role: .destructive) {
                var newTask = task
                newTask.type = "rest"
                newTask.targetDistance = nil
                newTask.targetPace = nil
                newTask.description = "休息日"
                updateTask(newTask, weekNumber: weekNumber)
            }
        }

        Button("取消", role: .cancel) {}
    }

    /// 根据用户修改重新生成计划
    private func regeneratePlan() {
        guard let plan = currentPlan else { return }

        isRegenerating = true

        Task {
            do {
                let newPlan = try await aiManager.generateTrainingPlan(
                    goal: plan.goal,
                    runHistory: dataManager.runRecords,
                    durationWeeks: plan.durationWeeks,
                    currentPlan: plan  // 传入用户修改后的计划作为参考
                )

                await MainActor.run {
                    currentPlan = newPlan
                    savePlan(newPlan)
                    isRegenerating = false
                }
            } catch {
                await MainActor.run {
                    isRegenerating = false
                    errorMessage = "重新生成失败: \(error.localizedDescription)"
                }
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
        VStack(spacing: 0) {
            // 视图模式切换
            viewModePicker

            ScrollView {
                VStack(spacing: 20) {
                    // 计划概览卡片
                    planOverviewCard(plan: plan)

                    // 根据视图模式显示不同内容
                    switch viewMode {
                    case .week:
                        weekSelector(plan: plan)
                        if let weekPlan = plan.weeklyPlans.first(where: { $0.weekNumber == selectedWeek }) {
                            weekTasksView(weekPlan: weekPlan)
                        }
                    case .calendar:
                        monthCalendarView(plan: plan)
                    case .overview:
                        monthOverviewView(plan: plan)
                    }

                    // 训练建议
                    tipsCard(tips: plan.tips)
                }
                .padding()
                .padding(.bottom, 20)
            }

            // 固定在底部的按钮组
            VStack(spacing: 0) {
                Divider()

                HStack(spacing: 12) {
                    // 重新生成计划按钮
                    Button(action: { regeneratePlan() }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("重新生成计划")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.5, green: 0.8, blue: 0.1))
                        .cornerRadius(10)
                    }

                    // 更换目标按钮
                    Button(action: { showGoalSelection = true }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("更换目标")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
            .padding(.bottom, 50)  // 留出 TabBar 空间
        }
    }

    // MARK: - View Mode Picker

    private var viewModePicker: some View {
        Picker("视图模式", selection: $viewMode) {
            ForEach(PlanViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Month Calendar View

    private func monthCalendarView(plan: TrainingPlanData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 按月份分组显示
            let months = groupWeeksByMonth(plan: plan)
            ForEach(Array(months.keys.sorted()), id: \.self) { monthIndex in
                if let weeks = months[monthIndex] {
                    monthCalendarCard(monthIndex: monthIndex, weeks: weeks)
                }
            }
        }
    }

    private func monthCalendarCard(monthIndex: Int, weeks: [WeekPlanData]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("第 \(monthIndex) 月")
                .font(.headline)
                .foregroundColor(.blue)

            // 星期标题
            HStack(spacing: 4) {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日历格子
            ForEach(weeks, id: \.weekNumber) { week in
                HStack(spacing: 4) {
                    ForEach(1...7, id: \.self) { dayOfWeek in
                        if let task = week.dailyTasks.first(where: { $0.dayOfWeek == dayOfWeek }) {
                            calendarDayCell(task: task, weekNumber: week.weekNumber)
                        } else {
                            // 休息日
                            calendarRestCell(weekNumber: week.weekNumber, dayOfWeek: dayOfWeek)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private func calendarDayCell(task: DailyTaskData, weekNumber: Int) -> some View {
        VStack(spacing: 2) {
            Image(systemName: taskIcon(task.type))
                .font(.system(size: 14))
                .foregroundColor(taskColor(task.type))
            Text("W\(weekNumber)")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(taskColor(task.type).opacity(0.1))
        .cornerRadius(8)
    }

    private func calendarRestCell(weekNumber: Int, dayOfWeek: Int) -> some View {
        VStack(spacing: 2) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.5))
            Text("W\(weekNumber)")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Month Overview View

    private func monthOverviewView(plan: TrainingPlanData) -> some View {
        VStack(spacing: 16) {
            let months = groupWeeksByMonth(plan: plan)
            ForEach(Array(months.keys.sorted()), id: \.self) { monthIndex in
                if let weeks = months[monthIndex] {
                    monthOverviewCard(monthIndex: monthIndex, weeks: weeks)
                }
            }
        }
    }

    private func monthOverviewCard(monthIndex: Int, weeks: [WeekPlanData]) -> some View {
        let allTasks = weeks.flatMap { $0.dailyTasks }
        let totalDistance = allTasks.compactMap { $0.targetDistance }.reduce(0, +)
        let trainingDays = allTasks.filter { $0.type != "rest" }.count

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("第 \(monthIndex) 月")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("第\(weeks.first?.weekNumber ?? 0)-\(weeks.last?.weekNumber ?? 0)周")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 月度统计
            HStack(spacing: 20) {
                VStack {
                    Text("\(weeks.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("周")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(trainingDays)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("训练日")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text(String(format: "%.0f", totalDistance))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("公里")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            // 每周主题列表
            VStack(alignment: .leading, spacing: 8) {
                ForEach(weeks, id: \.weekNumber) { week in
                    HStack {
                        Text("第\(week.weekNumber)周")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .leading)
                        Text(week.theme)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    // MARK: - Helper: Group Weeks by Month

    private func groupWeeksByMonth(plan: TrainingPlanData) -> [Int: [WeekPlanData]] {
        var result: [Int: [WeekPlanData]] = [:]
        for week in plan.weeklyPlans {
            let monthIndex = (week.weekNumber - 1) / 4 + 1  // 每4周算一个月
            if result[monthIndex] == nil {
                result[monthIndex] = []
            }
            result[monthIndex]?.append(week)
        }
        return result
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
        // 补全7天：有任务的用AI生成的，没有的补充为休息日
        let fullWeekTasks: [DailyTaskData] = (1...7).map { day in
            if let existingTask = weekPlan.dailyTasks.first(where: { $0.dayOfWeek == day }) {
                return existingTask
            }
            return DailyTaskData(dayOfWeek: day, type: "rest", targetDistance: nil, targetPace: nil, description: "休息日")
        }

        return VStack(alignment: .leading, spacing: 12) {
            Text(weekPlan.theme)
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(fullWeekTasks, id: \.dayOfWeek) { task in
                taskRow(task: task)
                    .onTapGesture {
                        selectedTask = (task: task, weekNumber: weekPlan.weekNumber)
                        showQuickActions = true
                    }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    // MARK: - Task Row

    private func taskRow(task: DailyTaskData) -> some View {
        let isRest = task.type == "rest"

        return HStack(spacing: 12) {
            // 星期
            Text(task.dayOfWeek.dayOfWeekName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isRest ? .secondary : .primary)
                .frame(width: 40)

            // 任务类型图标
            Image(systemName: taskIcon(task.type))
                .foregroundColor(taskColor(task.type))
                .frame(width: 24)

            // 任务详情
            VStack(alignment: .leading, spacing: 2) {
                Text(task.description)
                    .font(.subheadline)
                    .foregroundColor(isRest ? .secondary : .primary)
                    .lineLimit(2)

                if isRest {
                    Text("点击可添加训练")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                } else {
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
            }

            Spacer()

            // 编辑图标
            Image(systemName: isRest ? "plus.circle.fill" : "pencil.circle.fill")
                .foregroundColor(isRest ? Color(red: 0.5, green: 0.8, blue: 0.1).opacity(0.6) : Color(red: 0.5, green: 0.8, blue: 0.1))
                .font(.system(size: 20))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isRest ? Color(.systemGray6).opacity(0.3) : Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            isRest ? RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [4])) : nil
        )
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

// MARK: - 简化的任务编辑已集成到主视图中
// 使用 confirmationDialog 提供快速操作，无需复杂的编辑器

#Preview {
    TrainingPlanView()
}
