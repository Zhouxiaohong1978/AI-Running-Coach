//
//  AchievementShareView.swift
//  AIRunningCoach
//
//  Created by Claude Code
//  成就分享卡片生成器 - 支持分享到微信/朋友圈/微博/小红书
//

import SwiftUI

struct AchievementShareView: View {
    @Environment(\.dismiss) var dismiss
    let achievement: Achievement
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 成就卡片（用于生成图片）
                        achievementCardView
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        // 分享按钮
                        shareButtons
                            .padding(.horizontal, 20)

                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationTitle("分享成就")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("关闭")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    // 只分享图片，避免某些App（如飞书）只接收文本
                    ShareSheet(items: [image])
                }
            }
        }
    }

    // MARK: - Achievement Card View（卡片样式）

    private var achievementCardView: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [Color.purple, Color.purple.opacity(0.7), Color(red: 0.5, green: 0.8, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(20)

            VStack(spacing: 24) {
                // 顶部标题
                HStack {
                    Text("🏆 成就解锁")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()
                }

                // 成就图标（大）
                Image(systemName: achievement.icon)
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .padding(30)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                    )

                // 成就标题
                Text(achievement.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // 成就描述
                Text(achievement.description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                // 解锁时间
                if let unlockedDate = achievement.unlockedAt {
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 40)

                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))

                        Text("解锁于 \(formatDate(unlockedDate))")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }

                // 底部应用名称
                HStack {
                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 14))

                        Text("AIRunningCoach")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.7))

                    Spacer()
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.75, contentMode: .fit)
    }

    // MARK: - Share Buttons

    private var shareButtons: some View {
        VStack(spacing: 16) {
            Text("分享成就卡片")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            Text("生成图片后，可分享到微信、朋友圈、微博、小红书等平台")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // 主分享按钮
            Button {
                generateImageAndShare()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 24))

                    Text("生成并分享")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.5, green: 0.8, blue: 0.1), Color(red: 0.3, green: 0.7, blue: 0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color(red: 0.5, green: 0.8, blue: 0.1).opacity(0.4), radius: 8, y: 4)
            }

            // 提示文本
            HStack(spacing: 4) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                Text("在分享面板中选择目标应用（如微信、小红书等）")
                    .font(.system(size: 12))
            }
            .foregroundColor(.secondary.opacity(0.8))
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Helper Methods

    /// 生成成就卡片图片并分享
    private func generateImageAndShare() {
        let renderer = ImageRenderer(content: achievementCardView)
        renderer.scale = 3.0 // 3x分辨率

        if let image = renderer.uiImage {
            shareImage = image
            showShareSheet = true

            // 记录分享次数到云端
            Task {
                await AchievementManager.shared.incrementShareCountAndSync(for: achievement.id)
            }
        }
    }

    /// 分享文本内容
    private var shareText: String {
        """
        🏆 成就解锁！
        【\(achievement.title)】
        \(achievement.description)

        #AIRunningCoach #跑步成就 #坚持就是胜利
        """
    }

    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - Share Platform Button

struct SharePlatformButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(color)
                    .cornerRadius(12)

                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - UIKit Share Sheet（系统分享面板）

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    AchievementShareView(achievement: Achievement.allAchievements[0])
}
