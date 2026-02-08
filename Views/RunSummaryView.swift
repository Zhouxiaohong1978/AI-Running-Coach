//
//  RunSummaryView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI
import MapKit

struct RunSummaryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var dataManager = RunDataManager.shared
    @StateObject private var achievementManager = AchievementManager.shared
    @StateObject private var audioPlayerManager = AudioPlayerManager.shared  // MVP 1.0: 成就语音
    @StateObject private var aiManager = AIManager.shared  // AI建议生成
    var runRecord: RunRecord?

    private let voiceMap = VoiceAssetMap.shared

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var weeklyStats: [WeeklyRunStats] = []
    @State private var showAchievementSheet = false
    @State private var aiSuggestion: String = ""
    @State private var isLoadingAI: Bool = false

    init(runRecord: RunRecord? = nil) {
        self.runRecord = runRecord

        if let record = runRecord,
           let firstCoord = record.routeCoordinates.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: firstCoord.toCLLocationCoordinate2D(),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Map Header
                    ZStack(alignment: .topLeading) {
                        Map(coordinateRegion: $region)
                            .frame(height: 180)

                        // 跑步完成标题（左上角）
                        VStack(alignment: .leading, spacing: 4) {
                            Text("跑步完成！")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.black)

                            Text(formatRunDate(runRecord?.startTime ?? Date()))
                                .font(.system(size: 14))
                                .foregroundColor(.black.opacity(0.6))
                        }
                        .padding(20)
                    }

                    // Achievement Banner（地图下方）
                    VStack(spacing: 12) {
                        if !achievementManager.recentlyUnlocked.isEmpty {
                            // 有新成就：显示成就卡片（点击播放语音）
                            ForEach(achievementManager.recentlyUnlocked.prefix(3)) { achievement in
                                Button(action: {
                                    playAchievementVoice(achievement: achievement)
                                }) {
                                    AchievementBanner(achievement: achievement)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } else {
                            // 没有新成就：显示鼓励横幅
                            Button(action: {
                                showAchievementSheet = true
                            }) {
                                HStack(spacing: 16) {
                                    // 左侧奖杯（立体效果）
                                    ZStack {
                                        // 外圈光晕
                                        Circle()
                                            .fill(Color.yellow.opacity(0.3))
                                            .frame(width: 68, height: 68)

                                        // 内圈背景
                                        Circle()
                                            .fill(Color.yellow.opacity(0.5))
                                            .frame(width: 60, height: 60)

                                        // 奖杯图标
                                        Text("🏆")
                                            .font(.system(size: 36))
                                    }

                                    // 中间文字
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("暂无新成就")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.black)

                                        Text("继续加油，再接再厉！")
                                            .font(.system(size: 14))
                                            .foregroundColor(.black.opacity(0.7))
                                    }

                                    Spacer()

                                    // 右侧箭头
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.5))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color.purple.opacity(0.85),
                                            Color.purple.opacity(0.7)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.purple.opacity(0.5), radius: 12, y: 6)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -40)

                    // Stats Grid
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            StatCard(
                                icon: "location.fill",
                                iconColor: .blue,
                                label: "距离",
                                value: String(format: "%.2f", (runRecord?.distance ?? 0) / 1000.0),
                                unit: "km"
                            )

                            StatCard(
                                icon: "clock.fill",
                                iconColor: .orange,
                                label: "时间",
                                value: formatDuration(runRecord?.duration ?? 0),
                                unit: ""
                            )
                        }

                        HStack(spacing: 12) {
                            StatCard(
                                icon: "bolt.fill",
                                iconColor: .purple,
                                label: "平均配速",
                                value: formatPace(runRecord?.pace ?? 0),
                                unit: "/km"
                            )

                            StatCard(
                                icon: "flame.fill",
                                iconColor: .red,
                                label: "卡路里",
                                value: String(format: "%.0f", runRecord?.calories ?? 0),
                                unit: "kcal"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // AI Coach Insight
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                                .frame(width: 8, height: 8)

                            Text("AI教练建议")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.1))
                        }

                        if isLoadingAI {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("AI教练分析中...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        } else if aiSuggestion.isEmpty {
                            Text("暂无AI建议")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        } else {
                            Text(aiSuggestion)
                                .font(.system(size: 15))
                                .foregroundColor(.black)
                                .lineSpacing(6)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.96, green: 0.98, blue: 0.88))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // 每周跑步里程柱状图
                    VStack(alignment: .leading, spacing: 16) {
                        Text("每周跑步里程")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)

                        if weeklyStats.isEmpty {
                            Text("暂无数据")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            HStack(alignment: .bottom, spacing: 12) {
                                ForEach(Array(weeklyStats.enumerated()), id: \.offset) { index, stat in
                                    WeekBar(
                                        distance: stat.totalDistance,
                                        weekLabel: ["第一周", "第二周", "第三周", "第四周", "第五周"][index]
                                    )
                                }
                            }
                            .frame(height: 220)
                        }
                    }
                    .padding(20)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer()
                        .frame(height: 160)
                }
            }

            // Bottom Buttons（固定在底部）
            VStack {
                Spacer()

                HStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                            Text("关闭")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.7))
                        .cornerRadius(16)
                    }

                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                            Text("分享")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.5, green: 0.8, blue: 0.1), Color(red: 0.4, green: 0.7, blue: 0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            calculateWeeklyStats()
            generateAISuggestion()
        }
        .sheet(isPresented: $showAchievementSheet) {
            AchievementSheetView()
        }
    }

    // MARK: - Weekly Stats Calculation

    /// 计算每周跑步统计
    private func calculateWeeklyStats() {
        let calendar = Calendar.current
        let now = Date()

        // 获取所有跑步记录
        let allRecords = dataManager.runRecords

        // 按周分组
        var weeklyData: [Int: Double] = [:]

        for record in allRecords {
            let weekOfYear = calendar.component(.weekOfYear, from: record.startTime)
            let year = calendar.component(.year, from: record.startTime)
            let weekKey = year * 100 + weekOfYear  // 组合年份和周数作为key

            weeklyData[weekKey, default: 0] += record.distance
        }

        // 获取当前周数
        let currentWeek = calendar.component(.weekOfYear, from: now)
        let currentYear = calendar.component(.year, from: now)

        // 生成最近5周的数据（包括当前周）
        var stats: [WeeklyRunStats] = []
        for i in 0..<5 {
            let targetWeek = currentWeek - (4 - i)
            let weekKey = currentYear * 100 + targetWeek

            let totalDistance = weeklyData[weekKey] ?? 0
            stats.append(WeeklyRunStats(
                weekNumber: targetWeek,
                totalDistance: totalDistance / 1000.0  // 转换为公里
            ))
        }

        weeklyStats = stats
    }

    // MARK: - Formatting

    private func formatPace(_ pace: Double) -> String {
        guard pace > 0, pace.isFinite else { return "0'00\"" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return "\(minutes)'\(String(format: "%02d", seconds))\""
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// 播放成就语音（用户点击成就徽章时）
    private func playAchievementVoice(achievement: Achievement) {
        // 先清空TTS队列，确保播放的是用户点击的那条
        SpeechManager.shared.stopAll()

        // 优先使用预录音频
        if let voice = voiceMap.getAchievementVoice(achievementName: achievement.title) {
            audioPlayerManager.play(voice.fileName, priority: voice.priority, allowRepeat: true)
            print("🎙️ 播放成就语音: \(voice.fileName)")
        } else {
            // 无预录音频时，使用TTS朗读庆祝语
            SpeechManager.shared.speak(achievement.celebrationMessage, priority: .high)
            print("🎙️ TTS播放成就庆祝语: \(achievement.title)")
        }
    }

    /// 生成AI建议
    private func generateAISuggestion() {
        guard let record = runRecord else {
            aiSuggestion = "无跑步数据"
            return
        }

        // 如果距离太短，不调用AI
        if record.distance < 100 {
            aiSuggestion = "跑步距离太短，暂无建议"
            return
        }

        isLoadingAI = true

        Task {
            do {
                let suggestion = try await aiManager.getCoachFeedback(
                    currentPace: record.pace,
                    targetPace: nil,
                    distance: record.distance,
                    totalDistance: record.distance,
                    duration: record.duration,
                    heartRate: nil
                )

                await MainActor.run {
                    aiSuggestion = suggestion
                    isLoadingAI = false
                }
            } catch {
                await MainActor.run {
                    aiSuggestion = "AI建议生成失败：\(error.localizedDescription)"
                    isLoadingAI = false
                }
                print("❌ AI建议生成失败: \(error)")
            }
        }
    }

    private func formatRunDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        let weekday = formatter.weekdaySymbols[Calendar.current.component(.weekday, from: date) - 1]
        let hour = Calendar.current.component(.hour, from: date)
        let timeOfDay: String
        if hour < 6 {
            timeOfDay = "凌晨跑"
        } else if hour < 12 {
            timeOfDay = "晨跑"
        } else if hour < 18 {
            timeOfDay = "午后跑"
        } else {
            timeOfDay = "晚跑"
        }

        formatter.dateFormat = "M月d日"
        let dateStr = formatter.string(from: date)

        return "\(weekday) \(timeOfDay) · \(dateStr)"
    }

} // struct RunSummaryView

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 图标 + 标签（白底黑字）
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)

                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
            }

            // 数值和单位（绿色）
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Weekly Stats

/// 每周跑步统计
struct WeeklyRunStats {
    let weekNumber: Int
    let totalDistance: Double  // 公里
}

// MARK: - Week Bar (绿色柱状图)

struct WeekBar: View {
    let distance: Double  // 公里
    let weekLabel: String

    private var barHeight: CGFloat {
        // 根据距离计算柱高，最大20km对应180pt
        let maxDistance: Double = 20.0
        let maxHeight: CGFloat = 180.0
        let height = CGFloat(min(distance / maxDistance, 1.0)) * maxHeight
        return max(height, 20)  // 最小高度20pt
    }

    var body: some View {
        VStack(spacing: 8) {
            // 柱状图上方显示距离（绿色，带单位）
            Text(String(format: "%.1f公里", distance))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))

            // 绿色柱状图
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                .frame(height: barHeight)

            // 周标签（紫色）
            Text(weekLabel)
                .font(.system(size: 12))
                .foregroundColor(.purple)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Achievement Banner

struct AchievementBanner: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.system(size: 28))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("🏆 成就解锁！")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Text("\(achievement.title)：\(achievement.description)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            // 语音播放图标
            VStack(spacing: 4) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)

                Text("点击听语音")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 8)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.purple, Color.purple.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    RunSummaryView()
}
