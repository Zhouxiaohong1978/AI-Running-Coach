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
    @State private var editingTask: DailyTaskData?
    @State private var editingWeekNumber: Int?
    @State private var showTaskEditor = false

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
            .sheet(isPresented: $showTaskEditor) {
                if let task = editingTask, let weekNumber = editingWeekNumber {
                    TaskEditorView(
                        task: task,
                        weekNumber: weekNumber,
                        onSave: { updatedTask in
                            updateTask(updatedTask, weekNumber: weekNumber)
                            showTaskEditor = false
                        }
                    )
                }
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
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

            // 找到对应的任务
            if let taskIndex = weekPlan.dailyTasks.firstIndex(where: { $0.dayOfWeek == updatedTask.dayOfWeek }) {
                // 更新任务
                weekPlan.dailyTasks[taskIndex] = updatedTask
                plan.weeklyPlans[weekIndex] = weekPlan

                // 保存更新后的计划
                currentPlan = plan
                savePlan(plan)
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

            // 固定在底部的重新生成按钮
            VStack(spacing: 0) {
                Divider()
                Button(action: { showGoalSelection = true }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重新制定计划")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
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
        VStack(alignment: .leading, spacing: 12) {
            Text(weekPlan.theme)
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(weekPlan.dailyTasks, id: \.dayOfWeek) { task in
                taskRow(task: task)
                    .onTapGesture {
                        editingTask = task
                        editingWeekNumber = weekPlan.weekNumber
                        showTaskEditor = true
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

            // 编辑图标
            Image(systemName: "pencil.circle.fill")
                .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                .font(.system(size: 20))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
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

// MARK: - Task Editor View

struct TaskEditorView: View {
    @Environment(\.dismiss) var dismiss
    let weekNumber: Int
    let onSave: (DailyTaskData) -> Void

    @State private var selectedDayOfWeek: Int
    @State private var selectedTaskType: String
    @State private var targetDistance: Double
    @State private var targetPace: String
    @State private var taskDescription: String

    init(task: DailyTaskData, weekNumber: Int, onSave: @escaping (DailyTaskData) -> Void) {
        self.weekNumber = weekNumber
        self.onSave = onSave

        _selectedDayOfWeek = State(initialValue: task.dayOfWeek)
        _selectedTaskType = State(initialValue: task.type)
        _targetDistance = State(initialValue: task.targetDistance ?? 5.0)
        _targetPace = State(initialValue: task.targetPace ?? "6'30\"")
        _taskDescription = State(initialValue: task.description)
    }

    var body: some View {
        NavigationView {
            Form {
                // 星期选择
                Section(header: Text("训练日期")) {
                    Picker("星期", selection: $selectedDayOfWeek) {
                        ForEach(1...7, id: \.self) { day in
                            Text(day.dayOfWeekName).tag(day)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // 任务类型
                Section(header: Text("训练类型")) {
                    Picker("类型", selection: $selectedTaskType) {
                        ForEach(taskTypes, id: \.value) { type in
                            Label(type.name, systemImage: type.icon)
                                .tag(type.value)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 目标距离
                Section(header: Text("目标距离")) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("距离")
                            Spacer()
                            Text(String(format: "%.1f km", targetDistance))
                                .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                                .fontWeight(.semibold)
                        }

                        Slider(value: $targetDistance, in: 1...50, step: 0.5)
                            .tint(Color(red: 0.5, green: 0.8, blue: 0.1))
                    }
                }

                // 目标配速
                Section(header: Text("目标配速")) {
                    TextField("如：6'30\"", text: $targetPace)
                        .keyboardType(.asciiCapable)
                }

                // 任务描述
                Section(header: Text("任务描述")) {
                    TextEditor(text: $taskDescription)
                        .frame(height: 100)
                }
            }
            .navigationTitle("编辑训练任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                }
            }
        }
    }

    private var taskTypes: [(name: String, value: String, icon: String)] {
        [
            ("轻松跑", "easy_run", "figure.walk"),
            ("节奏跑", "tempo_run", "figure.run"),
            ("间歇跑", "interval", "bolt.fill"),
            ("长距离跑", "long_run", "figure.run.circle.fill"),
            ("休息", "rest", "bed.double.fill"),
            ("交叉训练", "cross_training", "figure.mixed.cardio")
        ]
    }

    private func saveTask() {
        let updatedTask = DailyTaskData(
            dayOfWeek: selectedDayOfWeek,
            type: selectedTaskType,
            targetDistance: selectedTaskType == "rest" ? nil : targetDistance,
            targetPace: selectedTaskType == "rest" ? nil : targetPace,
            description: taskDescription
        )

        onSave(updatedTask)
        dismiss()
    }
}

#Preview {
    TrainingPlanView()
}
