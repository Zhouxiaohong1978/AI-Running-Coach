//
//  HomeView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI

struct HomeView: View {
    @State private var selectedTab = 0
    @StateObject private var dataManager = RunDataManager.shared
    @StateObject private var authManager = AuthManager.shared

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
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: -2)
            }
        }
    }

    // MARK: - Home Content

    private var homeContent: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Main Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Weather and Greeting
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Text(getWeatherEmoji())
                                        .font(.title3)
                                    Text(getWeatherText())
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                HStack(spacing: 0) {
                                    Text("准备好今天的跑步了吗，")
                                        .font(.system(size: 32, weight: .bold))
                                    Text(getUserName())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                                    Text("?")
                                        .font(.system(size: 32, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                            // 开始 Run Button
                            NavigationLink(destination: ActiveRunView()) {
                                ZStack {
                                    // Outer glow rings
                                    Circle()
                                        .fill(Color(red: 0.5, green: 0.8, blue: 0.1).opacity(0.1))
                                        .frame(width: 240, height: 240)

                                    Circle()
                                        .fill(Color(red: 0.5, green: 0.8, blue: 0.1).opacity(0.15))
                                        .frame(width: 200, height: 200)

                                    // Main button
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                                            .frame(width: 160, height: 160)

                                        VStack(spacing: 8) {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(.white)

                                            Text("开始跑步")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 20)

                            // 每周目标 Card
                            WeeklyGoalCard(dataManager: dataManager)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 20)
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
                                    .fill(Color.black)
                                    .frame(width: 48, height: 48)

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
        }
    }

    // MARK: - Plan Content

    private var planContent: some View {
        TrainingPlanView()
    }

    // MARK: - Helper Functions

    private func getUserName() -> String {
        // 从用户数据中获取名字
        // TODO: 添加用户设置真实姓名的功能
        // 暂时使用"跑友"作为默认称呼
        if let email = authManager.currentUser?.email {
            // 如果有用户自定义昵称，使用昵称
            if let nickname = UserDefaults.standard.string(forKey: "user_nickname"), !nickname.isEmpty {
                return nickname
            }
        }
        return "跑友"
    }

    private func getWeatherEmoji() -> String {
        // TODO: 集成真实天气 API
        // 暂时返回晴天图标
        return "☀️"
    }

    private func getWeatherText() -> String {
        // TODO: 集成真实天气 API (高德/和风天气)
        // 暂时显示固定天气
        return "晴天, 24°C"
    }
}

// MARK: - Weekly Goal Card

struct WeeklyGoalCard: View {
    @ObservedObject var dataManager: RunDataManager

    private var weeklyStats: (current: Double, goal: Double, progress: Double, message: String) {
        // 获取本周的开始和结束日期（周一到周日）
        let calendar = Calendar.current
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

        // 周目标（公里），TODO: 从训练计划获取
        let goalKm = 20.0

        // 计算进度
        let progress = min(currentKm / goalKm, 1.0)

        // 生成提示信息
        let remaining = goalKm - currentKm
        let message: String
        if currentKm >= goalKm {
            let excess = currentKm - goalKm
            message = String(format: "你已超前完成%.1f公里！", excess)
        } else if remaining > 0 {
            message = String(format: "还需跑%.1f公里完成目标", remaining)
        } else {
            message = "继续加油！"
        }

        return (currentKm, goalKm, progress, message)
    }

    private var weekDateRange: String {
        let calendar = Calendar.current
        let now = Date()

        // 获取本周周一
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // 周一
        let startOfWeek = calendar.date(from: components) ?? now

        // 获取本周周日
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now

        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"

        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }

    var body: some View {
        let stats = weeklyStats

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("每周目标")
                        .font(.system(size: 18, weight: .semibold))
                    Text(weekDateRange)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
            }

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", stats.current))
                    .font(.system(size: 48, weight: .bold))
                Text("/ \(Int(stats.goal)) km")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                        .frame(width: geometry.size.width * stats.progress, height: 8)
                }
            }
            .frame(height: 8)

            Text(stats.message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            // 周一到周日的日期栏
            weekDaysView
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }

    // 周一到周日日期显示
    private var weekDaysView: some View {
        HStack(spacing: 0) {
            ForEach(0..<7) { index in
                VStack(spacing: 4) {
                    Text(getWeekdayShort(index: index))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.black)  // 改为黑色，更清晰

                    Text(getDayOfMonth(index: index))
                        .font(.system(size: 10))
                        .foregroundColor(.black.opacity(0.8))  // 改为黑色，更清晰
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
    }

    // 获取周几的简写（周一、周二...）
    private func getWeekdayShort(index: Int) -> String {
        let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        return weekdays[index]
    }

    // 获取对应日期的几号
    private func getDayOfMonth(index: Int) -> String {
        let calendar = Calendar.current
        let now = Date()

        // 获取本周周一
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // 周一
        guard let startOfWeek = calendar.date(from: components) else { return "" }

        // 计算对应日期
        guard let targetDate = calendar.date(byAdding: .day, value: index, to: startOfWeek) else { return "" }

        let day = calendar.component(.day, from: targetDate)
        return "\(day)"
    }
}

// MARK: - Tab Bar Item

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(red: 0.5, green: 0.8, blue: 0.1) : .gray)

                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? Color(red: 0.5, green: 0.8, blue: 0.1) : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    HomeView()
}
