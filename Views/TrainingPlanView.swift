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
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    @State private var currentPlan: TrainingPlanData?
    @State private var showGoalSelection = false
    @State private var showPaywall = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedWeek: Int = 1
    @State private var viewMode: PlanViewMode = .week
    @State private var selectedTask: (task: DailyTaskData, weekNumber: Int)?
    @State private var showQuickActions = false
    @State private var showAIUpgraded = false     // AI优化完成提示
    @State private var lastEditTime: Date? = nil  // 记录最后一次用户手动编辑时间
    @State private var reoptimizeTriggerTime: Date? = nil  // 记录触发AI优化的时间

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
        case calendar = "日历"
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
                    // 新计划：清除旧开始日期，savePlan 会重新设为本周一
                    UserDefaults.standard.removeObject(forKey: "training_plan_start_date")
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AIOptimizationComplete"))) { notification in
                guard let plan = notification.userInfo?["plan"] as? TrainingPlanData else { return }

                // 若用户在AI运行期间做了新编辑，则放弃AI结果，避免覆盖用户意图
                if let triggerTime = reoptimizeTriggerTime,
                   let editTime = lastEditTime,
                   editTime > triggerTime {
                    print("⚠️ AI优化结果被丢弃：用户在AI运行期间进行了手动编辑")
                    return
                }

                withAnimation(.easeInOut(duration: 0.4)) {
                    currentPlan = plan
                }
                savePlan(plan)
                showAIUpgraded = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showAIUpgraded = false
                }
            }
        }
    }

    // MARK: - AI Optimizing Banner

    /// 顶部小横幅：AI后台优化中 / 优化完成
    @ViewBuilder
    private var aiStatusBanner: some View {
        let isEN = LanguageManager.shared.currentLocale == "en"
        if showAIUpgraded {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(isEN ? "AI plan upgraded" : "AI已优化计划")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color.green.opacity(0.12))
            .cornerRadius(20)
            .transition(.move(edge: .top).combined(with: .opacity))
        } else if aiManager.isAIOptimizing {
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.65)
                Text(isEN ? "AI optimizing..." : "AI优化中...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            .transition(.opacity)
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
        // 首次保存时记录计划开始日期（本周一）
        if UserDefaults.standard.object(forKey: "training_plan_start_date") == nil {
            var cal = Calendar.current
            cal.firstWeekday = 2
            var comp = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
            comp.weekday = 2
            if let monday = cal.date(from: comp) {
                UserDefaults.standard.set(monday, forKey: "training_plan_start_date")
            }
        }
    }

    /// 更新单周某天的任务（用于距离调整）
    private func updateTask(_ updatedTask: DailyTaskData, weekNumber: Int) {
        guard var plan = currentPlan else { return }

        if let weekIndex = plan.weeklyPlans.firstIndex(where: { $0.weekNumber == weekNumber }) {
            var weekPlan = plan.weeklyPlans[weekIndex]

            if let taskIndex = weekPlan.dailyTasks.firstIndex(where: { $0.dayOfWeek == updatedTask.dayOfWeek }) {
                weekPlan.dailyTasks[taskIndex] = updatedTask
            } else {
                weekPlan.dailyTasks.append(updatedTask)
            }

            plan.weeklyPlans[weekIndex] = weekPlan
            currentPlan = plan
            savePlan(plan)
            lastEditTime = Date()
        }
    }

    /// 添加/删除训练日，应用到所有周（训练日安排是全局意图）
    private func applyScheduleChangeToAllWeeks(dayOfWeek: Int, makeTraining: Bool) {
        guard var plan = currentPlan else { return }

        for weekIndex in plan.weeklyPlans.indices {
            var weekPlan = plan.weeklyPlans[weekIndex]
            let taskIndex = weekPlan.dailyTasks.firstIndex(where: { $0.dayOfWeek == dayOfWeek })

            if makeTraining {
                // 该天改为训练：如果已存在且不是rest，保留；否则添加轻松跑
                if let idx = taskIndex, weekPlan.dailyTasks[idx].type != "rest" {
                    // 已是训练日，无需改动
                } else if let idx = taskIndex {
                    // 存在但是rest类型，更新为训练
                    weekPlan.dailyTasks[idx] = DailyTaskData(
                        dayOfWeek: dayOfWeek, type: "easy_run",
                        targetDistance: 3.0, targetPace: "7'00\"",
                        description: "轻松跑3.0公里"
                    )
                } else {
                    // 不存在，插入
                    weekPlan.dailyTasks.append(DailyTaskData(
                        dayOfWeek: dayOfWeek, type: "easy_run",
                        targetDistance: 3.0, targetPace: "7'00\"",
                        description: "轻松跑3.0公里"
                    ))
                }
            } else {
                // 该天改为休息：从 dailyTasks 移除（或置为rest）
                if let idx = taskIndex {
                    weekPlan.dailyTasks.remove(at: idx)
                }
            }

            plan.weeklyPlans[weekIndex] = weekPlan
        }

        currentPlan = plan
        savePlan(plan)
        lastEditTime = Date()
    }

    /// 快速操作按钮
    @ViewBuilder
    private func quickActionButtons(for task: DailyTaskData, weekNumber: Int) -> some View {
        let isRest = task.type == "rest"

        if isRest {
            // 休息日→训练日：应用到所有周
            Button("改为轻松跑（所有周）") {
                applyScheduleChangeToAllWeeks(dayOfWeek: task.dayOfWeek, makeTraining: true)
            }
        } else {
            // 训练日：距离调整仅当前周，改为休息日应用所有周
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

            Button("改为休息日（所有周）", role: .destructive) {
                applyScheduleChangeToAllWeeks(dayOfWeek: task.dayOfWeek, makeTraining: false)
            }
        }

        Button("取消", role: .cancel) {}
    }

    /// 根据用户修改重新生成计划（混合模式）
    /// 保留用户编辑后的计划结构（天数/距离不变），只让AI后台优化描述/配速
    private func regeneratePlan() {
        guard let plan = currentPlan else { return }

        guard subscriptionManager.canGeneratePlan() else {
            showPaywall = true
            return
        }

        // 记录触发时间，用于判断AI结果是否要应用（若期间用户有新编辑则丢弃）
        reoptimizeTriggerTime = Date()

        // 不重建本地模板，直接用用户当前计划启动后台AI优化
        // AI收到 currentPlan 后会严格保留训练天数和用户设置的距离
        aiManager.triggerReoptimize(plan: plan, runHistory: dataManager.runRecords)
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

            Button(action: {
                if subscriptionManager.canGeneratePlan() {
                    showGoalSelection = true
                } else {
                    showPaywall = true
                }
            }) {
                HStack {
                    if !subscriptionManager.canGeneratePlan() {
                        Image(systemName: "lock.fill")
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(subscriptionManager.canGeneratePlan() ? "创建训练计划" : "升级 Pro 解锁无限计划")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(subscriptionManager.canGeneratePlan() ? Color.blue : Color.orange)
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

            // AI状态横幅（优化中 / 优化完成）
            aiStatusBanner
                .animation(.easeInOut(duration: 0.3), value: aiManager.isAIOptimizing)
                .animation(.easeInOut(duration: 0.3), value: showAIUpgraded)
                .padding(.top, 4)

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
                        realCalendarView(plan: plan)
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
                    Button(action: {
                        if subscriptionManager.canGeneratePlan() {
                            regeneratePlan()
                        } else {
                            showPaywall = true
                        }
                    }) {
                        HStack {
                            Image(systemName: subscriptionManager.canGeneratePlan() ? "sparkles" : "lock.fill")
                            Text(subscriptionManager.canGeneratePlan() ? "重新生成计划" : "升级 Pro")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(subscriptionManager.canGeneratePlan() ? Color(red: 0.5, green: 0.8, blue: 0.1) : Color.orange)
                        .cornerRadius(10)
                    }

                    // 更换目标按钮
                    Button(action: {
                        if subscriptionManager.canGeneratePlan() {
                            showGoalSelection = true
                        } else {
                            showPaywall = true
                        }
                    }) {
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
                Text(LocalizedStringKey(mode.rawValue)).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Real Calendar View（月历 + 月概览 合并）

    private func realCalendarView(plan: TrainingPlanData) -> some View {
        let dateTaskMap = buildDateTaskMap(plan: plan)
        let months = calendarMonths(from: dateTaskMap)

        return VStack(spacing: 20) {
            if months.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("无法显示日历")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("计划开始日期未记录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ForEach(months, id: \.self) { monthStart in
                    realMonthCard(monthStart: monthStart, dateTaskMap: dateTaskMap)
                }
            }
        }
    }

    /// 将训练计划周/天 映射到真实日期
    private func buildDateTaskMap(plan: TrainingPlanData) -> [Date: DailyTaskData] {
        guard let startDate = UserDefaults.standard.object(forKey: "training_plan_start_date") as? Date else {
            return [:]
        }

        var result: [Date: DailyTaskData] = [:]
        let cal = Calendar.current

        for week in plan.weeklyPlans {
            // 先把7天全部标记为休息日
            for dayOfWeek in 1...7 {
                let offset = (week.weekNumber - 1) * 7 + (dayOfWeek - 1)
                if let date = cal.date(byAdding: .day, value: offset, to: startDate) {
                    let key = cal.startOfDay(for: date)
                    result[key] = DailyTaskData(
                        dayOfWeek: dayOfWeek, type: "rest",
                        targetDistance: nil, targetPace: nil, description: "休息日"
                    )
                }
            }
            // 再用实际训练任务覆盖
            for task in week.dailyTasks {
                let offset = (week.weekNumber - 1) * 7 + (task.dayOfWeek - 1)
                if let date = cal.date(byAdding: .day, value: offset, to: startDate) {
                    let key = cal.startOfDay(for: date)
                    result[key] = task
                }
            }
        }
        return result
    }

    /// 从日期-任务表中提取所有涉及的自然月（每月1日 Date）
    private func calendarMonths(from map: [Date: DailyTaskData]) -> [Date] {
        guard !map.isEmpty else { return [] }
        let cal = Calendar.current
        var months = Set<Date>()
        for date in map.keys {
            let comps = cal.dateComponents([.year, .month], from: date)
            if let monthStart = cal.date(from: comps) {
                months.insert(monthStart)
            }
        }
        return months.sorted()
    }

    /// 渲染单个自然月的日历卡片
    private func realMonthCard(monthStart: Date, dateTaskMap: [Date: DailyTaskData]) -> some View {
        let cal = Calendar.current
        let year = cal.component(.year, from: monthStart)
        let month = cal.component(.month, from: monthStart)
        let daysInMonth = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30

        // 月度统计
        var trainingDays = 0
        var totalKm = 0.0
        for day in 1...daysInMonth {
            if let date = cal.date(from: DateComponents(year: year, month: month, day: day)) {
                let key = cal.startOfDay(for: date)
                if let task = dateTaskMap[key], task.type != "rest" {
                    trainingDays += 1
                    totalKm += task.targetDistance ?? 0
                }
            }
        }

        // 第1天是周几（转为周一=0）
        let firstDay = cal.date(from: DateComponents(year: year, month: month, day: 1))!
        let weekday = cal.component(.weekday, from: firstDay) // 1=Sun
        let offset = (weekday - 2 + 7) % 7  // Mon=0, Tue=1, ..., Sun=6

        let totalCells = offset + daysInMonth
        let rows = Int(ceil(Double(totalCells) / 7.0))

        return VStack(alignment: .leading, spacing: 12) {
            // 月份标题 + 统计
            HStack {
                Text("\(year)年\(month)月")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                HStack(spacing: 12) {
                    Label("\(trainingDays)天", systemImage: "figure.run")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Label(String(format: "%.0fkm", totalKm), systemImage: "road.lanes")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Divider()

            // 星期标题行
            HStack(spacing: 4) {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { d in
                    Text(d)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日历格子
            VStack(spacing: 4) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { col in
                            let day = row * 7 + col - offset + 1
                            if day < 1 || day > daysInMonth {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                            } else {
                                let date = cal.date(from: DateComponents(year: year, month: month, day: day))!
                                let key = cal.startOfDay(for: date)
                                let task = dateTaskMap[key]
                                let isToday = cal.isDateInToday(date)
                                realDayCell(day: day, task: task, isToday: isToday)
                            }
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

    /// 单个日期格子
    private func realDayCell(day: Int, task: DailyTaskData?, isToday: Bool) -> some View {
        let isTraining = task != nil && task?.type != "rest"
        let color = task.map { taskColor($0.type) } ?? .gray
        let distText: String = {
            if let d = task?.targetDistance, isTraining {
                return String(format: "%.1f", d)
            }
            return ""
        }()

        return VStack(spacing: 2) {
            // 日期数字
            Text("\(day)")
                .font(.system(size: 13, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .white : (isTraining ? .primary : .secondary))
                .frame(width: 24, height: 24)
                .background(isToday ? Color.blue : Color.clear)
                .clipShape(Circle())

            // 训练距离 or 空
            if isTraining {
                Text(distText.isEmpty ? "训练" : "\(distText)k")
                    .font(.system(size: 9))
                    .foregroundColor(color)
                    .lineLimit(1)
            } else {
                Spacer().frame(height: 12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(isTraining ? color.opacity(0.12) : Color.clear)
        .cornerRadius(8)
    }

    // MARK: - Plan Overview Card

    /// 将存储的目标名（rawValue，如"减肥燃脂"）转换为当前语言显示名
    private func localizedGoalName(_ stored: String) -> String {
        return TrainingGoal.allCases.first { $0.rawValue == stored }?.displayName ?? stored
    }

    private func planOverviewCard(plan: TrainingPlanData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.orange)
                Text(localizedGoalName(plan.goal))
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("进行中")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
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
            Text(LocalizedStringKey(weekPlan.theme))
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
            Text(LocalizedStringKey(task.dayOfWeek.dayOfWeekName))
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
                // 用 localizedDescription 实时生成 locale-aware 描述
                if isRest {
                    Text(task.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text(task.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

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
                    Text(LocalizedStringKey(tip))
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
