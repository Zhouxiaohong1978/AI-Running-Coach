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
    @StateObject private var aiManager = AIManager.shared  // AI建议生成
    var runRecord: RunRecord?

    @State private var region: MKCoordinateRegion
    @State private var showAchievementSheet = false
    @State private var aiSuggestion: String = ""
    @State private var isLoadingAI: Bool = false
    @State private var aiParagraphs: FeedbackParagraphs? = nil
    @State private var aiScene: String? = nil
    @State private var hasAutoPlayedAchievement = false
    @State private var loadingAchievementId: String? = nil
    @State private var showAIConsent = false
    @AppStorage("ai_data_consent_granted") private var aiConsentGranted = false

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
                                    AchievementBanner(
                                        achievement: achievement,
                                        isLoading: loadingAchievementId == achievement.id
                                    )
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
                                Text(LocalizedStringKey(scene))
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

                HStack {
                    Spacer()
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
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.gray.opacity(0.7))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            generateAISuggestion()
            VoiceService.shared.resetCooldown()  // 跑步结束后重置冷却，确保成就语音能播放
            scheduleAchievementVoices()
        }
        .sheet(isPresented: $showAchievementSheet) {
            AchievementSheetView()
        }
        .sheet(isPresented: $showAIConsent) {
            AIDataConsentView(
                onAgree: {
                    if let record = runRecord {
                        executeAISuggestion(record: record)
                    }
                },
                onDecline: {}
            )
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

    // MARK: - 成就语音系统（个性化TTS）

    /// RunSummaryView 出现时自动播报新解锁的成就（最多3条，每隔5秒）
    private func scheduleAchievementVoices() {
        let unlocked = achievementManager.recentlyUnlocked
        guard !unlocked.isEmpty, !hasAutoPlayedAchievement else { return }
        hasAutoPlayedAchievement = true

        for (index, achievement) in unlocked.prefix(3).enumerated() {
            let delay = 1.5 + Double(index) * 5.0  // 首条1.5s后，后续每隔5s
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                playAchievementVoice(achievement: achievement)
            }
        }
    }

    /// 播放个性化成就语音（用户点击成就卡片时也调用，可重播）
    private func playAchievementVoice(achievement: Achievement) {
        let text = makeAchievementText(for: achievement)
        guard !text.isEmpty else { return }

        let isEN = LanguageManager.shared.currentLocale == "en"
        let language = isEN ? "en" : "zh-Hans"
        let voiceId = VoiceService.voiceId(for: aiManager.coachStyle, language: language)

        // 手动点击/成就页面播报，重置冷却确保能播放
        VoiceService.shared.resetCooldown()
        loadingAchievementId = achievement.id  // 显示加载中状态

        Task {
            _ = await VoiceService.shared.speak(text: text, voice: voiceId, language: language)
            await MainActor.run { loadingAchievementId = nil }  // 播放开始后清除 loading
        }
        print("🏆 个性化成就语音: \(achievement.title) → \(text.prefix(20))…")
    }

    /// 根据成就类别和真实跑步数据生成个性化播报文案
    private func makeAchievementText(for achievement: Achievement) -> String {
        let isEN = LanguageManager.shared.currentLocale == "en"
        let record = runRecord
        let title = achievement.title

        // 本次跑步数据
        let distKm    = String(format: "%.1f", (record?.distance ?? 0) / 1000)
        let paceStr   = formatPace(record?.pace ?? 0)
        let calStr    = String(Int(record?.calories ?? 0))
        let minStr    = String(Int((record?.duration ?? 0) / 60))

        // 历史累计数据
        let allRecords = dataManager.runRecords
        let totalKm   = String(format: "%.0f", allRecords.reduce(0) { $0 + $1.distance / 1000.0 } + (record?.distance ?? 0) / 1000.0)
        let totalHrs  = String(format: "%.0f", (allRecords.reduce(0) { $0 + $1.duration } + (record?.duration ?? 0)) / 3600)
        let totalCal  = String(Int(allRecords.reduce(0) { $0 + $1.calories } + (record?.calories ?? 0)))
        let streak    = String(computeAchievementStreak())

        let variants: [String]

        switch achievement.category {

        case .distance:
            let zh = [
                "太棒了！今天跑了\(distKm)公里，配速\(paceStr)，正式解锁\(title)！你已经不一样了！",
                "历史性突破！\(distKm)公里达成，解锁\(title)！配速\(paceStr)，继续突破自己吧！",
                "解锁\(title)！今天\(distKm)公里，用时\(minStr)分钟，你又向更好的自己迈进了一步！"
            ]
            let en = [
                "Amazing! \(distKm) km today at pace \(paceStr) — \(title) unlocked! You're not the same runner you were!",
                "Historic run! \(distKm) km done — \(title) unlocked! Pace \(paceStr), keep pushing your limits!",
                "\(title) unlocked! \(distKm) km in \(minStr) minutes — every step brings you closer to your best self!"
            ]
            variants = isEN ? en : zh

        case .duration:
            let zh = [
                "累计跑步\(totalHrs)小时，解锁\(title)！时间是最好的见证者，你的每一分钟都有价值！",
                "已跑\(totalHrs)小时，解锁\(title)！每一个小时都是你选择自律的证明！",
                "解锁\(title)！\(totalHrs)小时的积累，你的体能正在悄悄升级！"
            ]
            let en = [
                "\(totalHrs) hours of running — \(title) unlocked! Time is the greatest witness to your dedication!",
                "\(totalHrs) hours clocked — \(title) unlocked! Every hour is proof of your commitment!",
                "\(title) unlocked! \(totalHrs) hours accumulated — your endurance is quietly leveling up!"
            ]
            variants = isEN ? en : zh

        case .frequency:
            let zh = [
                "连续跑步\(streak)天，解锁\(title)！你的意志力已经超越了大多数人！",
                "连跑\(streak)天，解锁\(title)！这份坚持，正在重塑你的身体和心态！",
                "解锁\(title)！\(streak)天连续跑步，习惯的力量正在改变你！"
            ]
            let en = [
                "\(streak) consecutive days — \(title) unlocked! Your willpower has surpassed most people!",
                "\(streak)-day streak — \(title) unlocked! This consistency is reshaping your body and mindset!",
                "\(title) unlocked! \(streak) days straight — the power of habit is changing you!"
            ]
            variants = isEN ? en : zh

        case .calories:
            if achievement.id.contains("total") {
                // 累计卡路里成就
                let zh = [
                    "累计消耗\(totalCal)大卡，解锁\(title)！每次跑步的努力都在你身上留下了印记！",
                    "历史燃脂\(totalCal)大卡，解锁\(title)！你的坚持正在从量变引起质变！",
                    "解锁\(title)！\(totalCal)大卡的积累，你的身体代谢已经全面升级！"
                ]
                let en = [
                    "\(totalCal) calories burned lifetime — \(title) unlocked! Every run leaves its mark on your body!",
                    "Lifetime fat-burn \(totalCal) calories — \(title) unlocked! Consistency is creating real change!",
                    "\(title) unlocked! \(totalCal) calories accumulated — your metabolism has fully leveled up!"
                ]
                variants = isEN ? en : zh
            } else {
                // 单次卡路里成就
                let zh = [
                    "本次燃脂\(calStr)大卡，解锁\(title)！你的身体正在悄悄发生变化！",
                    "单次\(calStr)大卡！解锁\(title)！这是教科书级别的燃脂效果！",
                    "解锁\(title)！今天燃掉\(calStr)大卡，脂肪正在悄悄离开！"
                ]
                let en = [
                    "\(calStr) calories this run — \(title) unlocked! Your body is quietly transforming!",
                    "Single-run \(calStr) calories — \(title) unlocked! This is textbook fat-burning efficiency!",
                    "\(title) unlocked! \(calStr) calories torched today — fat is quietly retreating!"
                ]
                variants = isEN ? en : zh
            }

        case .pace:
            let zh = [
                "配速突破到\(paceStr)！解锁\(title)！速度不是天生的，是跑出来的！",
                "最快配速\(paceStr)，解锁\(title)！你跑得越来越快，这才是进步的味道！",
                "解锁\(title)！\(paceStr)的配速，你今天重写了自己的极速纪录！"
            ]
            let en = [
                "Pace crushed to \(paceStr) — \(title) unlocked! Speed isn't born, it's earned on the road!",
                "Best pace \(paceStr) — \(title) unlocked! You're getting faster and that's what progress feels like!",
                "\(title) unlocked! \(paceStr) pace — today you rewrote your personal speed record!"
            ]
            variants = isEN ? en : zh

        case .special:
            if achievement.id.contains("morning") {
                let zh = [
                    "坚持晨跑，解锁\(title)！清晨的汗水，是你送给自己最好的礼物！",
                    "解锁\(title)！早起跑步5次，你的自律已经超越了大多数人！",
                    "\(title)到手！每个清晨你都选择了更好的自己！"
                ]
                let en = [
                    "Morning running habit — \(title) unlocked! Morning sweat is the best gift you give yourself!",
                    "\(title) unlocked! 5 early morning runs — your discipline is truly exceptional!",
                    "\(title) is yours! Every morning you choose to be a better version of yourself!"
                ]
                variants = isEN ? en : zh
            } else if achievement.id.contains("night") {
                let zh = [
                    "夜跑5次，解锁\(title)！当城市沉睡时，你选择了奔跑！",
                    "解锁\(title)！夜幕下的坚持，是独属于夜跑者的浪漫！",
                    "\(title)解锁！夜晚的跑道属于你！"
                ]
                let en = [
                    "5 night runs — \(title) unlocked! When the city sleeps, you choose to run!",
                    "\(title) unlocked! Persistence under the night sky — the romance of the night runner!",
                    "\(title) is yours! The night track belongs to you!"
                ]
                variants = isEN ? en : zh
            } else {
                // 雨天跑步
                let zh = [
                    "雨天不停跑，解锁\(title)！天气挡不住你，这才是跑者精神！",
                    "解锁\(title)！雨天跑步，你的意志力比天气更强悍！",
                    "\(title)解锁！风雨中的坚持，才是真正的勇气！"
                ]
                let en = [
                    "Running in the rain — \(title) unlocked! Weather can't stop you — that's the true runner's spirit!",
                    "\(title) unlocked! Running in the rain — your willpower is stronger than the weather!",
                    "\(title) is yours! Persisting through rain and wind is true courage!"
                ]
                variants = isEN ? en : zh
            }

        case .milestone:
            let zh = [
                "累计跑步\(totalKm)公里，解锁\(title)！你用脚步丈量了世界！",
                "历史总里程\(totalKm)公里，解锁\(title)！每一步都是伟大的积累！",
                "解锁\(title)！\(totalKm)公里的足迹，正在书写你的跑步传奇！"
            ]
            let en = [
                "\(totalKm) km total — \(title) unlocked! You're measuring the world with your footsteps!",
                "Lifetime \(totalKm) km — \(title) unlocked! Every step is a great accumulation!",
                "\(title) unlocked! \(totalKm) km of footprints — writing your running legend!"
            ]
            variants = isEN ? en : zh
        }

        return variants.randomElement() ?? ""
    }

    /// 计算连续跑步天数（用于频率成就语音注入）
    private func computeAchievementStreak() -> Int {
        var streak = 0
        let cal = Calendar.current
        var checkDay = cal.startOfDay(for: Date())
        for record in dataManager.runRecords {
            let day = cal.startOfDay(for: record.startTime)
            if day == checkDay {
                streak += 1
                checkDay = cal.date(byAdding: .day, value: -1, to: checkDay)!
            } else if day < checkDay {
                break
            }
        }
        return streak
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

        // 首次使用 AI 功能前检查授权
        if !aiConsentGranted {
            showAIConsent = true
            return
        }

        executeAISuggestion(record: record)
    }

    private func executeAISuggestion(record: RunRecord) {
        isLoadingAI = true

        Task {
            do {
                // 加载训练计划上下文
                let (trainingType, targetPace) = loadTodayTask()
                let goalName = loadGoalName()

                let distanceKm = record.distance / 1000.0
                let result = try await aiManager.getCoachFeedback(
                    currentPace: record.pace,
                    targetPace: targetPace,
                    distance: distanceKm,
                    totalDistance: distanceKm,
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
                    let isEN = LanguageManager.shared.currentLocale == "en"
                    aiSuggestion = isEN
                        ? "AI analysis failed: \(error.localizedDescription)"
                        : "AI建议生成失败：\(error.localizedDescription)"
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
    var isLoading: Bool = false

    private var isEN: Bool { LanguageManager.shared.currentLocale == "en" }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.system(size: 28))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text(isEN ? "🏆 Achievement Unlocked!" : "🏆 成就解锁！")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Text("\(achievement.localizedTitle)：\(achievement.localizedDescription)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            // 语音播放图标（加载中时显示 spinner）
            VStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Text(isLoading ? (isEN ? "Loading..." : "加载中...") : (isEN ? "Tap to play" : "点击听语音"))
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
