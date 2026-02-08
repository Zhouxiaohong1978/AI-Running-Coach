//
//  AchievementTestView.swift
//  AIRunningCoach
//
//  Created by Claude Code
//  成就系统测试界面
//

import SwiftUI

struct AchievementTestView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @StateObject private var runDataManager = RunDataManager.shared
    @State private var showAchievementSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 成就统计
                        statsCard

                        // 测试按钮
                        testButtons

                        // 最近解锁的成就
                        if !achievementManager.recentlyUnlocked.isEmpty {
                            recentlyUnlockedSection
                        }

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("成就系统测试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAchievementSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                            Text("查看成就")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                    }
                }
            }
            .sheet(isPresented: $showAchievementSheet) {
                AchievementSheetView()
            }
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("成就统计")
                    .font(.system(size: 18, weight: .bold))

                Spacer()

                Text("\(achievementManager.unlockedCount)/\(achievementManager.totalCount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                        .frame(width: geometry.size.width * CGFloat(achievementManager.unlockedCount) / CGFloat(achievementManager.totalCount))
                }
            }
            .frame(height: 12)

            HStack {
                Text("已解锁")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(Double(achievementManager.unlockedCount) / Double(achievementManager.totalCount) * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Test Buttons

    private var testButtons: some View {
        VStack(spacing: 12) {
            Text("模拟跑步记录")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)

            // 短距离跑步（1km，触发距离成就）
            Button {
                simulateRun(distance: 1000, duration: 300, calories: 60)
            } label: {
                HStack {
                    Image(systemName: "figure.walk")
                    Text("模拟1公里跑步")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }

            // 5公里跑步（触发距离+燃脂成就）
            Button {
                simulateRun(distance: 5000, duration: 1800, calories: 350)
            } label: {
                HStack {
                    Image(systemName: "figure.run")
                    Text("模拟5公里跑步（燃脂300+）")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.orange)
                .cornerRadius(12)
            }

            // 10公里跑步（触发更多成就）
            Button {
                simulateRun(distance: 10000, duration: 3600, calories: 600)
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("模拟10公里跑步（燃脂500+）")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .cornerRadius(12)
            }

            // 晨跑（触发特殊成就）
            Button {
                simulateMorningRun()
            } label: {
                HStack {
                    Image(systemName: "sunrise.fill")
                    Text("模拟晨跑（7:00，触发晨跑成就）")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.purple)
                .cornerRadius(12)
            }

            // 重置成就
            Button {
                resetAchievements()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("重置所有成就")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Recently Unlocked Section

    private var recentlyUnlockedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏆 最近解锁")
                .font(.system(size: 18, weight: .bold))

            ForEach(achievementManager.recentlyUnlocked.prefix(5)) { achievement in
                HStack(spacing: 12) {
                    Image(systemName: achievement.icon)
                        .font(.system(size: 32))
                        .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(achievement.title)
                            .font(.system(size: 16, weight: .semibold))

                        Text(achievement.description)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Helper Methods

    /// 模拟跑步记录
    private func simulateRun(distance: Double, duration: TimeInterval, calories: Double) {
        let record = RunRecord(
            distance: distance,
            duration: duration,
            pace: (duration / 60) / (distance / 1000),
            calories: calories,
            startTime: Date(),
            endTime: Date().addingTimeInterval(duration),
            routeCoordinates: []
        )

        Task {
            await runDataManager.addRunRecord(record)
        }
    }

    /// 模拟晨跑（7:00开始）
    private func simulateMorningRun() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0

        let morningDate = calendar.date(from: components) ?? Date()

        let record = RunRecord(
            distance: 3000,
            duration: 1200,
            pace: 6.67,
            calories: 200,
            startTime: morningDate,
            endTime: morningDate.addingTimeInterval(1200),
            routeCoordinates: []
        )

        Task {
            await runDataManager.addRunRecord(record)
        }
    }

    /// 重置所有成就
    private func resetAchievements() {
        achievementManager.achievements = Achievement.allAchievements
        achievementManager.saveAchievements()
        achievementManager.clearRecentlyUnlocked()
    }
}

#Preview {
    AchievementTestView()
}
