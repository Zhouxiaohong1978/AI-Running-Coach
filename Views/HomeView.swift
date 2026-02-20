//
//  HomeView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI

// MARK: - Color Tokens

private extension Color {
    static let greenPrimary = Color(red: 0.49, green: 0.84, blue: 0.11)  // #7CD61D
    static let bgDark = Color(red: 0.02, green: 0.02, blue: 0.02)       // #050505
    static let textSecondary = Color(red: 0.65, green: 0.66, blue: 0.68) // #A7A8AD
    static let textSecondary2 = Color(red: 0.64, green: 0.64, blue: 0.65) // #A3A3A7
    static let cardBg = Color(red: 0.96, green: 0.96, blue: 0.96)       // #F4F4F6
    static let textPrimary = Color(red: 0.07, green: 0.07, blue: 0.07)  // #121212
    static let trackBg = Color(red: 0.85, green: 0.85, blue: 0.87)      // #D9D9DE
    static let tabBg = Color(red: 0.98, green: 0.98, blue: 0.99)        // #FBFBFC
    static let tabLine = Color(red: 0.91, green: 0.91, blue: 0.93)      // #E8E8EC
    static let tabInactive = Color(red: 0.60, green: 0.61, blue: 0.64)  // #9A9CA3
    static let ringOuter = Color(red: 0.06, green: 0.13, blue: 0.04)    // #102109
    static let ringMiddle = Color(red: 0.18, green: 0.31, blue: 0.05)   // #2E4F0C
}

struct HomeView: View {
    @State private var selectedTab = 0
    @State private var showPaywall = false
    @State private var hasShownAutoPaywall = false
    @State private var hasTrainingPlan = false
    @State private var showActiveRun = false
    @StateObject private var dataManager = RunDataManager.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var weatherManager = WeatherManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        ZStack {
            // Tab Content
            switch selectedTab {
            case 0:
                homeContent
            case 1:
                planContent
            case 2:
                HistoryView()
            case 3:
                SettingsView()
            default:
                homeContent
            }

            // Bottom Tab Bar
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    TabBarItem(icon: "house.fill", label: "开始", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }

                    TabBarItem(icon: "calendar", label: "计划", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }

                    TabBarItem(icon: "clock", label: "历史", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }

                    TabBarItem(icon: "person", label: "我的", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                }
                .padding(.vertical, 8)
                .background(Color.tabBg)
                .overlay(
                    Rectangle()
                        .fill(Color.tabLine)
                        .frame(height: 1),
                    alignment: .top
                )
            }
        }
        // ActiveRunView 挂在根层级，Tab 切换无法触及
        .fullScreenCover(isPresented: $showActiveRun) {
            ActiveRunView()
        }
    }

    // MARK: - Run Start Button Label

    private var runStartButtonLabel: some View {
        ZStack {
            Circle()
                .fill(Color.ringOuter)
                .frame(width: 230, height: 230)
            Circle()
                .fill(Color.ringMiddle)
                .frame(width: 196, height: 196)
            ZStack {
                Circle()
                    .fill(Color.greenPrimary)
                    .frame(width: 166, height: 166)
                VStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.white)
                    Text("开始跑步")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Home Content

    private var homeContent: some View {
        NavigationView {
            ZStack {
                Color.bgDark
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Main Content
                    ScrollView {
                        VStack(spacing: 0) {
                            // Weather and Greeting
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 6) {
                                    Text(todayDateText)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.textSecondary2)
                                    Text(getWeatherEmoji())
                                        .font(.system(size: 18))
                                    Text(getWeatherText())
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.textSecondary2)
                                }

                                HStack(spacing: 8) {
                                    Text(getUserName())
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.greenPrimary)

                                    if subscriptionManager.isPro {
                                        Text("Pro")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.greenPrimary)
                                            .cornerRadius(6)
                                    }
                                }
                                .padding(.top, 14)

                                Text(todayGreeting)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.textSecondary)
                                    .frame(maxWidth: 320, alignment: .leading)
                                    .lineSpacing(4)
                                    .padding(.top, 10)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                            // 开始 Run Button（新用户引导：无训练计划时跳转到创建计划页面）
                            Group {
                                if hasTrainingPlan {
                                    // 有计划：fullScreenCover，Tab 切换不会中断跑步
                                    Button(action: { showActiveRun = true }) {
                                        runStartButtonLabel
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    // 无计划：引导去创建训练计划
                                    NavigationLink(destination: GoalSelectionView(onPlanGenerated: { plan in
                                        if let encoded = try? JSONEncoder().encode(plan) {
                                            UserDefaults.standard.set(encoded, forKey: "saved_training_plan")
                                            var cal = Calendar.current
                                            cal.firstWeekday = 2
                                            var comp = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
                                            comp.weekday = 2
                                            let monday = cal.date(from: comp) ?? Date()
                                            UserDefaults.standard.set(monday, forKey: "training_plan_start_date")
                                        }
                                        hasTrainingPlan = true
                                    })) {
                                        runStartButtonLabel
                                    }
                                }
                            }
                            .padding(.top, 16)

                            // 免费用户剩余次数提示
                            if !subscriptionManager.isPro {
                                let runsUsed = dataManager.runRecords.count
                                let runsLeft = max(0, 3 - runsUsed)
                                if runsLeft > 0 {
                                    Text("免费体验剩余 \(runsLeft) 次")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.textSecondary)
                                } else {
                                    Text("免费次数已用完，升级 Pro 继续跑步")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.orange)
                                }
                            }

                            Spacer().frame(height: 20)

                            // 每周目标 Card
                            WeeklyGoalCard(dataManager: dataManager)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 80)
                        }
                    }
                }

                // Help Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {}) {
                            ZStack {
                                Circle()
                                    .fill(Color.bgDark)
                                    .frame(width: 54, height: 54)

                                Text("?")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                // 检查是否存在训练计划
                if let data = UserDefaults.standard.data(forKey: "saved_training_plan"),
                   let _ = try? JSONDecoder().decode(TrainingPlanData.self, from: data) {
                    hasTrainingPlan = true
                    print("✅ [HomeView] 检测到训练计划")
                } else {
                    hasTrainingPlan = false
                    print("⚠️ [HomeView] 未检测到训练计划，将引导用户创建")
                }

                // 检查是否应该弹出 PaywallView（第3次跑步后，仅一次）
                if !hasShownAutoPaywall && subscriptionManager.shouldShowPaywallAfterRun(runCount: dataManager.runRecords.count) {
                    hasShownAutoPaywall = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showPaywall = true
                    }
                }
                // 获取天气（位置已在 LocationManager init 中自动请求）
                print("🏠 [HomeView] onAppear - lastLocation: \(locationManager.lastLocation?.coordinate.latitude ?? 0), \(locationManager.lastLocation?.coordinate.longitude ?? 0)")
                Task {
                    if let location = locationManager.lastLocation {
                        print("🏠 [HomeView] 开始获取天气...")
                        await weatherManager.fetchWeather(for: location)
                    } else {
                        print("⚠️ [HomeView] 位置为空，无法获取天气")
                    }
                }
            }
            .onChange(of: locationManager.lastLocation) { newLocation in
                // 位置更新后获取天气
                print("🏠 [HomeView] onChange - 位置更新: \(newLocation?.coordinate.latitude ?? 0), \(newLocation?.coordinate.longitude ?? 0)")
                if let location = newLocation {
                    Task {
                        await weatherManager.fetchWeather(for: location)
                    }
                }
            }
        }
    }

    // MARK: - Plan Content

    private var planContent: some View {
        TrainingPlanView()
    }

    // MARK: - Helper Functions

    private func getUserName() -> String {
        // 从用户数据中获取用户名
        // 优先级：Supabase user_metadata > UserDefaults > 默认"跑友"

        // 1. 从Supabase user_metadata获取用户名（云端存储，重装App后仍可恢复）
        if let userName = authManager.currentUserName, !userName.isEmpty {
            // 同步到本地缓存
            UserDefaults.standard.set(userName, forKey: "user_name")
            print("🏠 [HomeView] 从云端读取用户名: \(userName)")
            return userName
        }

        // 2. 从UserDefaults获取用户名（本地缓存）
        if let userName = UserDefaults.standard.string(forKey: "user_name"), !userName.isEmpty {
            print("🏠 [HomeView] 从本地缓存读取用户名: \(userName)")
            return userName
        }

        // 3. 默认显示兜底名
        let fallback = LanguageManager.shared.currentLocale == "en" ? "Runner" : "跑友"
        print("🏠 [HomeView] 使用默认名称: \(fallback)")
        return fallback
    }

    private var todayDateText: String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLocale)
        formatter.dateFormat = "M/d(EEE)"
        return formatter.string(from: now)
    }

    private func getWeatherEmoji() -> String {
        return weatherManager.currentWeather?.emoji ?? "☀️"
    }

    private func getWeatherText() -> String {
        let fallback = LanguageManager.shared.currentLocale == "en" ? "Loading weather..." : "获取天气中..."
        return weatherManager.currentWeather?.displayText ?? fallback
    }

    // MARK: - 今日招呼语

    private var todayGreeting: String {
        let defaults = UserDefaults.standard

        // 1. 读取训练计划
        guard let data = defaults.data(forKey: "saved_training_plan"),
              let plan = try? JSONDecoder().decode(TrainingPlanData.self, from: data) else {
            return LanguageManager.shared.currentLocale == "en"
                ? "Ready for today's run?"
                : "准备好今天的跑步了吗？"
        }

        let isEN = LanguageManager.shared.currentLocale == "en"

        // 2. 计算当前是第几周
        var weekNumber = 1
        if let startDate = defaults.object(forKey: "training_plan_start_date") as? Date {
            let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
            weekNumber = max(1, days / 7 + 1)
        }

        // 3. 超出范围用最后一周
        let clampedWeek = min(weekNumber, plan.weeklyPlans.count)
        guard let weekPlan = plan.weeklyPlans.first(where: { $0.weekNumber == clampedWeek }) else {
            return isEN ? "Ready for today's run?" : "准备好今天的跑步了吗？"
        }

        // 4. 获取今天是周几（1=周一 ... 7=周日）
        let weekday = Calendar.current.component(.weekday, from: Date()) // 1=周日
        let dow = weekday == 1 ? 7 : weekday - 1

        // 5. 查找今天的任务
        guard let task = weekPlan.dailyTasks.first(where: { $0.dayOfWeek == dow }),
              task.type != "rest" else {
            // 休息日
            let restMessages = isEN ? [
                "Rest day — stretch and recover",
                "Rest well, keep pushing tomorrow!",
                "Rest is part of training, recharge your mind and body"
            ] : [
                "今天是休息日，做做拉伸放松一下吧",
                "好好休息，明天继续加油！",
                "休息也是训练的一部分，放松身心吧"
            ]
            return restMessages[Calendar.current.component(.day, from: Date()) % restMessages.count]
        }

        // 6. 有训练任务
        let typeName = TaskType(rawValue: task.type)?.displayName ?? task.type
        if let distance = task.targetDistance, distance > 0 {
            let dist = String(format: "%.1f", distance)
            return isEN
                ? "Today's goal: \(typeName) \(dist) km\nReady? Tap start!"
                : "今天的目标是\(typeName)\(dist)公里，\n准备好就点击开始吧！"
        } else {
            return isEN
                ? "Today's plan: \(typeName). Let's go!"
                : "今天的计划是\(typeName)，准备好就开始吧！"
        }
    }
}

// MARK: - Weekly Goal Card

struct WeeklyGoalCard: View {
    @ObservedObject var dataManager: RunDataManager

    private var weeklyStats: (current: Double, goal: Double, progress: Double, message: String) {
        // 获取本周的开始和结束日期（周一到周日）
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 确保一周从周一开始
        let now = Date()

        // 获取本周周一
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // 周一
        let startOfWeek = calendar.date(from: components) ?? now

        // 获取本周周日结束
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? now

        // 计算本周跑步总距离（米转公里）
        let weeklyDistance = dataManager.runRecords
            .filter { $0.startTime >= startOfWeek && $0.startTime < endOfWeek }
            .reduce(0.0) { $0 + $1.distance }

        let currentKm = weeklyDistance / 1000.0

        // 从训练计划获取本周目标
        let goalKm = Self.weeklyGoalFromPlan(weekStart: startOfWeek)

        // 计算进度
        let progress = min(currentKm / goalKm, 1.0)

        // 生成提示信息
        let remaining = goalKm - currentKm
        let isEN = LanguageManager.shared.currentLocale == "en"
        let message: String
        if currentKm >= goalKm {
            let excess = currentKm - goalKm
            message = isEN
                ? String(format: "You're %.1f km ahead of goal!", excess)
                : String(format: "你已超前完成%.1f公里！", excess)
        } else if remaining > 0 {
            message = isEN
                ? String(format: "%.1f km left to reach your goal", remaining)
                : String(format: "还需跑%.1f公里完成目标", remaining)
        } else {
            message = isEN ? "Keep going!" : "继续加油！"
        }

        return (currentKm, goalKm, progress, message)
    }

    private var weekDateRange: String {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 确保一周从周一开始
        let now = Date()

        // 获取本周周一
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // 周一
        let startOfWeek = calendar.date(from: components) ?? now

        // 获取本周周日
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now

        let formatter = DateFormatter()
        let isEN = LanguageManager.shared.currentLocale == "en"
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLocale)
        formatter.dateFormat = isEN ? "MMM d" : "M月d日"

        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }

    var body: some View {
        let stats = weeklyStats

        VStack(alignment: .leading, spacing: 0) {
            // Title and date
            Text("每周目标")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.textPrimary)

            Text(weekDateRange)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.15)) // #202226
                .padding(.top, 6)

            // Distance values
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(String(format: "%.1f", stats.current))
                    .font(.system(size: 50, weight: .heavy))
                    .foregroundColor(.textPrimary)
                Text("/ \(String(format: "%.1f", stats.goal)) km")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            .padding(.top, 10)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.trackBg)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.greenPrimary)
                        .frame(width: geometry.size.width * stats.progress, height: 8)
                }
            }
            .frame(height: 8)
            .padding(.top, 12)

            // Message
            Text(stats.message)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.13)) // #1E1E22
                .padding(.top, 10)
        }
        .padding(22)
        .background(Color.cardBg)
        .cornerRadius(22)
    }

    // MARK: - 从训练计划获取本周目标距离(公里)

    private static func weeklyGoalFromPlan(weekStart: Date) -> Double {
        let defaults = UserDefaults.standard
        // 读取训练计划
        guard let data = defaults.data(forKey: "saved_training_plan"),
              let plan = try? JSONDecoder().decode(TrainingPlanData.self, from: data) else {
            return 20.0 // 无计划时默认20km
        }

        // 计算当前是第几周
        var weekNumber = 1
        if let startDate = defaults.object(forKey: "training_plan_start_date") as? Date {
            let days = Calendar.current.dateComponents([.day], from: startDate, to: weekStart).day ?? 0
            weekNumber = max(1, days / 7 + 1)
        }

        // 找到对应周计划，超出范围用最后一周
        let clampedWeek = min(weekNumber, plan.weeklyPlans.count)
        guard let weekPlan = plan.weeklyPlans.first(where: { $0.weekNumber == clampedWeek }) else {
            return 20.0
        }

        // 汇总该周所有任务的目标距离(km)
        let totalKm = weekPlan.dailyTasks.reduce(0.0) { $0 + ($1.targetDistance ?? 0) }
        return totalKm > 0 ? totalKm : 20.0
    }
}

// MARK: - Tab Bar Item

struct TabBarItem: View {
    let icon: String
    let label: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .greenPrimary : .tabInactive)

                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .greenPrimary : .tabInactive)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    HomeView()
}
