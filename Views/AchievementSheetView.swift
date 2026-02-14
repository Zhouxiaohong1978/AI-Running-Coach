//
//  AchievementSheetView.swift
//  AIRunningCoach
//
//  Created by Claude Code
//

import SwiftUI

struct AchievementSheetView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var achievementManager = AchievementManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var expandedCategories: Set<AchievementCategory> = Set(AchievementCategory.allCases)
    @State private var showShareSheet = false
    @State private var showPaywall = false
    @State private var selectedAchievement: Achievement?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 成就统计卡片
                        achievementSummaryCard

                        // 按类别显示成就
                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            achievementSection(for: category)
                        }

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("我的成就")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 清空最近解锁列表
                        achievementManager.clearRecentlyUnlocked()
                        dismiss()
                    } label: {
                        Text("完成")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                    }
                }
            }
            .sheet(item: $selectedAchievement) { achievement in
                AchievementShareView(achievement: achievement)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Achievement Summary Card

    private var achievementSummaryCard: some View {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("\(achievementManager.unlockedCount)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))

                Text("已解锁")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 60)

            VStack(spacing: 8) {
                Text("\(achievementManager.totalCount)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.purple)

                Text("总成就")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: CGFloat(achievementManager.unlockedCount) / CGFloat(achievementManager.totalCount))
                    .stroke(Color(red: 0.5, green: 0.8, blue: 0.1), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(Double(achievementManager.unlockedCount) / Double(achievementManager.totalCount) * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Achievement Section

    private func achievementSection(for category: AchievementCategory) -> some View {
        let achievements = achievementManager.achievements(for: category)

        return VStack(alignment: .leading, spacing: 12) {
            // 分类标题（可折叠）
            Button {
                withAnimation {
                    if expandedCategories.contains(category) {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.primary)

                    Text(category.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: expandedCategories.contains(category) ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)

            // 成就列表
            if expandedCategories.contains(category) {
                VStack(spacing: 12) {
                    ForEach(achievements) { achievement in
                        let isLocked = !subscriptionManager.isPro && !subscriptionManager.isAchievementFree(achievement.id)
                        AchievementCard(
                            achievement: achievement,
                            onShare: { selectedAchievement = achievement },
                            isProLocked: isLocked,
                            onProTap: { showPaywall = true }
                        )
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    let onShare: () -> Void
    var isProLocked: Bool = false
    var onProTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(isProLocked ? Color.orange.opacity(0.1) : (achievement.isUnlocked ? Color(red: 0.5, green: 0.8, blue: 0.1).opacity(0.2) : Color.gray.opacity(0.1)))
                    .frame(width: 50, height: 50)

                if isProLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: achievement.icon)
                        .font(.system(size: 24))
                        .foregroundColor(achievement.isUnlocked ? Color(red: 0.5, green: 0.8, blue: 0.1) : .gray)
                        .grayscale(achievement.isUnlocked ? 0 : 0.99)
                }
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(achievement.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isProLocked ? .secondary : (achievement.isUnlocked ? .primary : .secondary))

                    if isProLocked {
                        Text("Pro")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }

                Text(achievement.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if isProLocked {
                    Text("升级 Pro 解锁")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                } else if !achievement.isUnlocked {
                    // 进度条
                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                                    .frame(width: geometry.size.width * achievement.progress, height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text(achievement.progressText)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                } else if let unlockedDate = achievement.unlockedAt {
                    Text("解锁于 \(formatDate(unlockedDate))")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                }
            }

            Spacer()

            // 分享按钮（仅已解锁成就可分享）
            if achievement.isUnlocked && !isProLocked {
                Button {
                    onShare()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                        .padding(8)
                        .background(Color(red: 0.5, green: 0.8, blue: 0.1).opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .opacity(isProLocked ? 0.7 : 1.0)
        .onTapGesture {
            if isProLocked {
                onProTap?()
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

#Preview {
    AchievementSheetView()
}
