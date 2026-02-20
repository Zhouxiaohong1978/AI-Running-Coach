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

    @State private var region: MKCoordinateRegion
    @State private var showAchievementSheet = false
    @State private var aiSuggestion: String = ""
    @State private var isLoadingAI: Bool = false
    @State private var aiParagraphs: FeedbackParagraphs? = nil
    @State private var aiScene: String? = nil

    init(runRecord: RunRecord? = nil) {
        self.runRecord = runRecord

        let center = runRecord?.routeCoordinates.first?.toCLLocationCoordinate2D()
            ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        _region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Map Header
                    ZStack(alignment: .topLeading) {
                        let coords = runRecord?.routeCoordinates ?? []
                        if coords.isEmpty {
                            // 无 GPS 轨迹时显示 placeholder
                            Rectangle()
                                .fill(Color(UIColor.systemGray5))
                                .frame(height: 180)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "map.slash")
                                            .font(.system(size: 28))
                                            .foregroundColor(.gray)
                                        Text("无 GPS 路线数据")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                )
                        } else {
                            HistoryMapView(coordinates: coords, region: $region)
                                .frame(height: 180)
                        }

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

                            Text("AI教练分析")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.1))

                            Spacer()

                            if let scene = aiScene {
                                Text(scene)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(sceneColor(scene))
                                    .cornerRadius(8)
                            }
                        }

                        if isLoadingAI {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("AI教练分析中...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        } else if let p = aiParagraphs {
                            // 三段式展示
                            VStack(alignment: .leading, spacing: 10) {
                                // P1 表现总结
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                        .frame(width: 20)
                                    Text(p.summary)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.black)
                                        .lineSpacing(4)
                                }

                                // P2 原因分析
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                        .frame(width: 20)
                                    Text(p.analysis)
                                        .font(.system(size: 14))
                                        .foregroundColor(.black.opacity(0.8))
                                        .lineSpacing(4)
                                }

                                // P3 下次建议
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.2))
                                        .frame(width: 20)
                                    Text(p.suggestion)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.15, green: 0.55, blue: 0.15))
                                        .lineSpacing(4)
                                }
                            }
                        } else if aiSuggestion.isEmpty {
                            Text("暂无AI建议")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        } else {
                            // Fallback: 原始文本
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

                    // 每公里配速柱状图
                    VStack(alignment: .leading, spacing: 16) {
                        Text("每公里配速")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)

                        if let splits = runRecord?.kmSplits, !splits.isEmpty {
                            let avgPace = splits.reduce(0, +) / Double(splits.count)
                            let maxPace = splits.max() ?? 1

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .bottom, spacing: 12) {
                                    ForEach(Array(splits.enumerated()), id: \.offset) { index, pace in
                                        PaceBar(
                                            pace: pace,
                                            kmLabel: "第\(index + 1)公里",
                                            maxPace: maxPace,
                                            avgPace: avgPace
                                        )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            .frame(height: 220)
                        } else {
                            Text("暂无分段数据")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
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
            generateAISuggestion()
        }
        .sheet(isPresented: $showAchievementSheet) {
            AchievementSheetView()
        }
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
        let isEN = LanguageManager.shared.currentLocale == "en"
        guard let record = runRecord else {
            aiSuggestion = isEN ? "No run data" : "无跑步数据"
            return
        }

        // 如果距离太短，不调用AI
        if record.distance < 100 {
            aiSuggestion = isEN ? "Run too short for analysis" : "跑步距离太短，暂无建议"
            return
        }

        isLoadingAI = true

        Task {
            do {
                // 加载训练计划上下文
                let (trainingType, targetPace) = loadTodayTask()
                let goalName = loadGoalName()

                let result = try await aiManager.getCoachFeedback(
                    currentPace: record.pace,
                    targetPace: targetPace,
                    distance: record.distance,
                    totalDistance: record.distance,
                    duration: record.duration,
                    heartRate: nil,
                    kmSplits: record.kmSplits,
                    trainingType: trainingType,
                    goalName: goalName
                )

                await MainActor.run {
                    aiSuggestion = result.feedback
                    aiParagraphs = result.paragraphs
                    aiScene = result.scene
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

    /// 加载今日训练任务的类型和目标配速
    private func loadTodayTask() -> (trainingType: String?, targetPace: Double?) {
        let defaults = UserDefaults.standard

        guard let data = defaults.data(forKey: "saved_training_plan"),
              let plan = try? JSONDecoder().decode(TrainingPlanData.self, from: data) else {
            return (nil, nil)
        }

        // 计算当前是第几周
        var weekNumber = 1
        if let startDate = defaults.object(forKey: "training_plan_start_date") as? Date {
            let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
            weekNumber = max(1, days / 7 + 1)
        }

        let clampedWeek = min(weekNumber, plan.weeklyPlans.count)
        guard let weekPlan = plan.weeklyPlans.first(where: { $0.weekNumber == clampedWeek }) else {
            return (nil, nil)
        }

        // 今天是周几（1=周一 ... 7=周日）
        let weekday = Calendar.current.component(.weekday, from: Date())
        let dow = weekday == 1 ? 7 : weekday - 1

        guard let task = weekPlan.dailyTasks.first(where: { $0.dayOfWeek == dow }) else {
            return (nil, nil)
        }

        let targetPace = parseTargetPace(task.targetPace)
        return (task.type, targetPace)
    }

    /// 加载训练目标名称
    private func loadGoalName() -> String? {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "saved_training_plan"),
              let plan = try? JSONDecoder().decode(TrainingPlanData.self, from: data) else {
            return nil
        }
        return plan.goal
    }

    /// 解析配速字符串（如 "7'00""）为分钟数（如 7.0）
    private func parseTargetPace(_ paceString: String?) -> Double? {
        guard let str = paceString else { return nil }
        // 匹配 "7'00"" 或 "6'30"" 格式
        let pattern = #"(\d+)'(\d+)"?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)),
              let minRange = Range(match.range(at: 1), in: str),
              let secRange = Range(match.range(at: 2), in: str),
              let minutes = Double(str[minRange]),
              let seconds = Double(str[secRange]) else {
            return nil
        }
        return minutes + seconds / 60.0
    }

    /// 场景标签颜色
    private func sceneColor(_ scene: String) -> Color {
        switch scene {
        case "稳定达标": return .green
        case "前快后崩": return .red
        case "波动大": return .orange
        case "全程偏快风险高": return .blue
        case "全程偏慢但稳定": return .purple
        case "恢复跑": return .gray
        default: return .gray
        }
    }

    private func formatRunDate(_ date: Date) -> String {
        let locale = Locale(identifier: LanguageManager.shared.currentLocale)
        let formatter = DateFormatter()
        formatter.locale = locale

        let weekday = formatter.weekdaySymbols[Calendar.current.component(.weekday, from: date) - 1]
        let hour = Calendar.current.component(.hour, from: date)
        let isEN = LanguageManager.shared.currentLocale == "en"
        let timeOfDay: String
        if hour < 6 {
            timeOfDay = isEN ? "Late Night Run" : "凌晨跑"
        } else if hour < 12 {
            timeOfDay = isEN ? "Morning Run" : "晨跑"
        } else if hour < 18 {
            timeOfDay = isEN ? "Afternoon Run" : "午后跑"
        } else {
            timeOfDay = isEN ? "Evening Run" : "晚跑"
        }

        formatter.dateFormat = LanguageManager.shared.currentLocale == "en" ? "MMM d" : "M月d日"
        let dateStr = formatter.string(from: date)

        return "\(weekday) \(timeOfDay) · \(dateStr)"
    }

} // struct RunSummaryView

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let label: LocalizedStringKey
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

// MARK: - Pace Bar (每公里配速柱状图)

struct PaceBar: View {
    let pace: Double // 秒/公里
    let kmLabel: String
    let maxPace: Double // 最慢配速，用于归一化高度
    let avgPace: Double // 平均配速，用于颜色判断

    private var barHeight: CGFloat {
        let maxHeight: CGFloat = 160.0
        let minHeight: CGFloat = 30.0
        guard maxPace > 0 else { return minHeight }
        let ratio = CGFloat(pace / maxPace)
        return max(ratio * maxHeight, minHeight)
    }

    private var barColor: Color {
        pace <= avgPace
            ? Color(red: 0.3, green: 0.8, blue: 0.3) // 绿色=快
            : Color.orange // 橙色=慢
    }

    private var paceText: String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return "\(minutes)'\(String(format: "%02d", seconds))\""
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(paceText)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(barColor)

            RoundedRectangle(cornerRadius: 6)
                .fill(barColor)
                .frame(width: 36, height: barHeight)

            Text(kmLabel)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 52)
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
