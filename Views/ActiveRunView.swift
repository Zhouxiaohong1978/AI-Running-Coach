//
//  ActiveRunView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI
import MapKit

struct ActiveRunView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    @StateObject private var dataManager = RunDataManager.shared
    // @StateObject private var speechManager = SpeechManager.shared  // 已弃用：改用真实语音
    @StateObject private var aiManager = AIManager.shared
    @StateObject private var achievementManager = AchievementManager.shared
    @StateObject private var audioPlayerManager = AudioPlayerManager.shared  // MVP 1.0: 真实语音播放
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var dynamicEngine = DynamicVoiceEngine.shared  // 动态语音引擎
    private let logger = DebugLogger.shared  // 日志记录器

    @State private var isPaused = false
    @State private var showSummary = false
    @State private var isEnding = false
    @State private var savedRecord: RunRecord?
    @State private var isVoiceEnabled = true
    @State private var lastAnnouncedKm: Int = 0
    @State private var lastFeedbackTime: Date = Date()
    @State private var lastFeedbackDistance: Double = 0
    @State private var showCoachFeedback = false
    @State private var currentFeedback: String = ""
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var holdTimer: Timer?

    // MVP 1.0: 智能语音系统
    @State private var userGoal: TrainingGoal = .threeK  // 用户当前训练目标
    @State private var todayTargetKm: Double = 3.0       // 今日训练计划目标距离
    @State private var hasSpokenStart = false
    @State private var hasSpoken500m = false
    @State private var hasSpoken1km = false
    @State private var hasSpoken1_5km = false
    @State private var hasSpoken2km = false
    @State private var hasSpoken2_5km = false
    @State private var hasSpoken3km = false
    @State private var hasSpokenTodayGoal = false  // 今日目标达成语音
    @State private var achievement1kmWarned = false  // 是否已提醒1km成就
    @State private var achievement3kmWarned = false  // 是否已提醒3km成就
    @State private var achievement300calWarned = false  // 是否已提醒300卡成就
    @State private var showUpgradeHint = false  // 免费用户反馈用完时的升级提示
    @State private var showPaywallFromRun = false // 跑步中点击升级提示弹出付费墙
    @AppStorage("ai_data_consent_granted") private var aiConsentGranted = false

    var body: some View {
        ZStack {
            // Map Background with route polyline
            RunMapView(
                userLocation: $locationManager.userLocation,
                region: $locationManager.region,
                routeCoordinates: locationManager.routeCoordinates,
                pathUpdateVersion: locationManager.pathUpdateVersion
            )
            .ignoresSafeArea()

            VStack {
                // Top Status Bar
                HStack {
                    // 左侧：GPS 状态
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                            .frame(width: 8, height: 8)
                        Text("GPS ACTIVE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)

                    Spacer()

                    // 语音开关按钮（麦克风图标）
                    Button(action: {
                        isVoiceEnabled.toggle()
                        audioPlayerManager.isEnabled = isVoiceEnabled
                    }) {
                        Image(systemName: isVoiceEnabled ? "mic.fill" : "mic.slash.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isVoiceEnabled ? .green : .white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)

                // 定位按钮（点击回到用户位置中心）
                HStack {
                    Spacer()
                    Button(action: {
                        // 触发地图更新回到用户位置
                        if let location = locationManager.userLocation {
                            locationManager.region = MKCoordinateRegion(
                                center: location,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // AI 教练反馈气泡
                if showCoachFeedback && !currentFeedback.isEmpty {
                    HStack {
                        Image(systemName: "bubble.left.fill")
                            .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                        Text(currentFeedback)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 10)
                }

                // 免费用户锁定气泡（点击跳转付费墙）
                if dynamicEngine.showLockedBubble {
                    Button {
                        showPaywallFromRun = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            Text(dynamicEngine.lockedBubbleText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 4)
                }

                Spacer()

                // Metrics Display - 按设计稿样式
                VStack(spacing: 12) {
                    // 配速（最大显示）
                    VStack(spacing: 0) {
                        Text("配速")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(formatPace(locationManager.currentPace))
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("/km")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    // 距离和时间
                    HStack(spacing: 40) {
                        // 距离
                        VStack(spacing: 2) {
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text(String(format: "%.2f", locationManager.distance / 1000.0))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("km")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Text("距离")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        // 时间
                        VStack(spacing: 2) {
                            Text(formatDuration(locationManager.duration))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("时间")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    // 卡路里和心率
                    HStack(spacing: 30) {
                        // 卡路里
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(alignment: .lastTextBaseline, spacing: 2) {
                                    Text("\(Int(locationManager.calories))")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("kcal")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Text("卡路里")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }

                        // 心率
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(alignment: .lastTextBaseline, spacing: 2) {
                                    Text(healthKit.heartRate > 0 ? "\(healthKit.heartRate)" : "--")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    if healthKit.heartRate > 0 {
                                        Text("bpm")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                HStack(spacing: 4) {
                                    Text(LanguageManager.shared.currentLocale == "en" ? "Heart Rate" : "心率")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.7))
                                    HStack(spacing: 2) {
                                        Image(systemName: "heart.text.square")
                                            .font(.system(size: 9))
                                        Text("HealthKit")
                                            .font(.system(size: 9, weight: .medium))
                                    }
                                    .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.5))
                .cornerRadius(20)

                Spacer()
                    .frame(height: 12)

                // Control Buttons or Loading
                if isEnding {
                    // 结束加载动画
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("正在保存跑步数据...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(height: 80)
                    .padding(.bottom, 40)
                } else {
                    HStack(spacing: 60) {
                        // Pause Button（左侧）
                        Button(action: {
                            isPaused.toggle()
                            if isPaused {
                                locationManager.pauseTracking()
                                // 暂停时停止音频播放
                                audioPlayerManager.stopAll()
                            } else {
                                locationManager.resumeTracking()
                                // 继续时无需语音提示
                            }
                        }) {
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.black)
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.85))
                                .clipShape(Circle())
                        }

                        // Stop Button（右侧，长按停止 + 进度环）
                        ZStack {
                            // 背景圆
                            Circle()
                                .fill(Color.red)
                                .frame(width: 80, height: 80)

                            // 进度环（在按钮外圈）
                            Circle()
                                .trim(from: 0, to: holdProgress)
                                .stroke(Color.white, lineWidth: 5)
                                .frame(width: 88, height: 88)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.1), value: holdProgress)

                            // 内容
                            VStack(spacing: 2) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                Text("长按\n结束")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isHolding {
                                        isHolding = true
                                        startHoldAnimation()
                                    }
                                }
                                .onEnded { _ in
                                    isHolding = false
                                    holdTimer?.invalidate()
                                    holdTimer = nil
                                    // 进度不足时重置
                                    if holdProgress < 1.0 {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            holdProgress = 0
                                        }
                                    }
                                }
                        )
                    }
                    .padding(.bottom, 120)  // 上移避免被 TabBar 挡住
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            logger.log("🏃 开始真实跑步", category: "START")
            locationManager.startTracking()
            healthKit.requestAuthorization()
            healthKit.startHeartRateMonitoring()
            lastFeedbackTime = Date()

            // 重置音频播放状态和免费反馈计数
            audioPlayerManager.reset()
            audioPlayerManager.isEnabled = isVoiceEnabled
            subscriptionManager.resetRunFeedbackCount()

            // 加载今日训练目标距离
            todayTargetKm = loadTodayTargetKm()

            // 重置动态语音引擎（传入历史最佳距离用于个人记录检测）
            let bestKm = dataManager.runRecords.compactMap { $0.distance > 0 ? $0.distance / 1000.0 : nil }.max() ?? 0
            dynamicEngine.reset(personalBestDistanceKm: bestKm)

            // EN 模式预缓存所有里程碑 TTS 音频
            if LanguageManager.shared.currentLocale == "en" {
                prefetchENVoicesForRun()
            }

            // 延迟 2s 播报，给 EN 模式预缓存留出下载时间（单条 TTS 约 1-1.5s）
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("🏃 MVP 1.0 开始跑步，三位一体联动启动")
                self.logger.log("🎯 准备播放开始语音", category: "VOICE")
                // 播放开始语音（女声）
                playStartVoice()
            }
        }
        .onDisappear {
            locationManager.stopTracking()
            healthKit.stopHeartRateMonitoring()
            audioPlayerManager.stopAll()
            VoiceService.shared.clearCache()
        }
        .onChange(of: locationManager.distance) { newDistance in
            checkAndAnnounce(distance: newDistance)
            // 距离更新时也驱动动态引擎（覆盖配速/卡路里/个人记录事件）
            if aiConsentGranted { dynamicEngine.update(context: buildRunContext()) }
        }
        .onChange(of: locationManager.duration) { newDuration in
            // 每 10 秒驱动一次动态引擎（覆盖时间里程碑事件）
            if aiConsentGranted && Int(newDuration) % 10 == 0 {
                dynamicEngine.update(context: buildRunContext())
            }
        }
        .onChange(of: healthKit.heartRate) { _ in
            // 心率变化时驱动引擎（覆盖心率区间事件）
            if aiConsentGranted { dynamicEngine.update(context: buildRunContext()) }
        }
        .onChange(of: dynamicEngine.showBubble) { showing in
            // 动态引擎触发气泡时同步显示
            if showing {
                showFeedbackBubble(dynamicEngine.bubbleText)
            }
        }
        .onChange(of: showSummary) { newValue in
            // 当跑步结束后，摘要页面被关闭时，自动返回主页
            if !newValue && savedRecord != nil {
                dismiss()
            }
        }
        .sheet(isPresented: $showPaywallFromRun) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $showSummary) {
            if let record = savedRecord {
                RunSummaryView(runRecord: record)
            } else {
                RunSummaryView()
            }
        }
    }

    // MARK: - Actions

    private func endRun() {
        isEnding = true
        locationManager.stopTracking()

        // 检查是否提前结束（未到今日目标）
        let distanceKm = locationManager.distance / 1000.0
        if distanceKm < todayTargetKm {
            playEarlyStopVoice()
        }

        // 创建跑步记录
        let record = RunRecord(
            distance: locationManager.distance,
            duration: locationManager.duration,
            pace: locationManager.currentPace,
            calories: locationManager.calories,
            startTime: Date().addingTimeInterval(-locationManager.duration),
            endTime: Date(),
            routeCoordinates: locationManager.routeCoordinates.map { Coordinate(from: $0) },
            kmSplits: locationManager.kmSplits.isEmpty ? nil : locationManager.kmSplits,
            isRainy: WeatherManager.shared.currentWeather?.isRainy ?? false
        )

        savedRecord = record

        // 保存到数据库
        Task {
            await dataManager.addRunRecord(record)

            // 立即显示结束页面
            await MainActor.run {
                isEnding = false  // 重置加载状态
                showSummary = true
            }
        }
    }

    // MARK: - MVP 1.0: 三位一体语音系统（训练计划 + 真实语音 + 成就系统）

    private let voiceMap = VoiceAssetMap.shared

    /// 从训练计划读取今日目标距离
    private func loadTodayTargetKm() -> Double {
        guard let data = UserDefaults.standard.data(forKey: "saved_training_plan"),
              let plan = try? JSONDecoder().decode(TrainingPlanData.self, from: data) else {
            return 3.0
        }
        var weekNumber = 1
        if let startDate = UserDefaults.standard.object(forKey: "training_plan_start_date") as? Date {
            let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
            weekNumber = max(1, days / 7 + 1)
        }
        let clampedWeek = min(weekNumber, plan.weeklyPlans.count)
        guard let weekPlan = plan.weeklyPlans.first(where: { $0.weekNumber == clampedWeek }) else { return 3.0 }
        let weekday = Calendar.current.component(.weekday, from: Date())
        let dow = weekday == 1 ? 7 : weekday - 1
        guard let task = weekPlan.dailyTasks.first(where: { $0.dayOfWeek == dow }),
              let distance = task.targetDistance, distance > 0 else { return 3.0 }
        return distance
    }

    // MARK: - 构建富上下文（供 DynamicVoiceEngine 使用）

    private func buildRunContext() -> EnrichedRunContext {
        let records = dataManager.runRecords  // 按时间倒序，不含本次
        let distanceKm = locationManager.distance / 1000.0

        // 本月统计
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
        let monthRecords = records.filter { $0.startTime >= startOfMonth }
        let monthlyKm = monthRecords.reduce(0.0) { $0 + $1.distance / 1000.0 } + distanceKm
        let monthlyRunCount = monthRecords.count + 1  // +1 含本次

        // 历史配速
        let validPaces = records.compactMap { $0.pace > 0 && $0.pace < 30 ? $0.pace : nil }
        let personalBestPace = validPaces.min() ?? 0
        let lastRunPace = records.first?.pace ?? 0
        let lastRunDistanceKm = (records.first?.distance ?? 0) / 1000.0

        // 累计公里（含本次）
        let historicalKm = records.reduce(0.0) { $0 + $1.distance / 1000.0 }
        let totalLifetimeKm = historicalKm + distanceKm

        // 连续跑步天数
        let streak = computeStreak(records: records)

        return EnrichedRunContext(
            distanceKm: distanceKm,
            durationSeconds: locationManager.duration,
            currentPace: locationManager.currentPace,
            calories: locationManager.calories,
            heartRate: healthKit.heartRate,
            goal: userGoal,
            goalDistanceKm: todayTargetKm,
            totalRunCount: records.count + 1,
            personalBestPace: personalBestPace,
            lastRunPace: lastRunPace,
            lastRunDistanceKm: lastRunDistanceKm,
            totalLifetimeKm: totalLifetimeKm,
            monthlyKm: monthlyKm,
            monthlyRunCount: monthlyRunCount,
            currentStreak: streak
        )
    }

    private func computeStreak(records: [RunRecord]) -> Int {
        var streak = 0
        let cal = Calendar.current
        var checkDay = cal.startOfDay(for: Date())
        for record in records {
            let recordDay = cal.startOfDay(for: record.startTime)
            if recordDay == checkDay {
                streak += 1
                checkDay = cal.date(byAdding: .day, value: -1, to: checkDay)!
            } else if recordDay < checkDay {
                break
            }
        }
        return streak
    }

    // MARK: - 统一语音路由（中文=本地文件 / 英文=TTS API）

    /// 播放语音资源，自动按 App 语言路由
    /// - Returns: 是否触发了播放
    @discardableResult
    private func playVoiceAsset(_ voice: VoiceAsset) -> Bool {
        let isEN = LanguageManager.shared.currentLocale == "en"

        if isEN {
            // 去重：与 ZH 模式共享 audioPlayerManager.playedAudios
            guard !audioPlayerManager.hasPlayed(voice.fileName) else { return false }
            audioPlayerManager.markPlayed(voice.fileName)

            let text = voice.descriptionEn.isEmpty ? voice.description : voice.descriptionEn
            let voiceId = VoiceService.voiceId(for: aiManager.coachStyle, language: "en")

            Task {
                // speakImmediate 绕过所有冷却，等待上一条播完再播
                let started = await VoiceService.shared.speakImmediate(
                    text: text, voice: voiceId, language: "en", cacheKey: voice.fileName
                )
                if started {
                    // 播放开始后才显示气泡（与声音同步）
                    await MainActor.run { showFeedbackBubble(text) }
                }
            }
            return true
        } else {
            // 中文：播放本地预录制 .m4a 文件
            // 如果 TTS 正在播放或下载中，跳过本地语音避免并行播报
            if VoiceService.shared.isPlaying || VoiceService.shared.isPending {
                return false
            }
            if audioPlayerManager.play(voice.fileName, priority: voice.priority) {
                showFeedbackBubble(voice.description)
                return true
            }
            return false
        }
    }

    /// EN 模式预缓存所有里程碑 TTS 音频（跑步开始时后台并行下载）
    /// 开始语音优先单独预缓存，确保 2s 后 playStartVoice 命中缓存
    private func prefetchENVoicesForRun() {
        let voiceId = VoiceService.voiceId(for: aiManager.coachStyle, language: "en")
        Task {
            // 1. 优先预缓存开始语音（单独下载，不等其他）
            if let startVoice = voiceMap.getStartVoice() {
                let text = startVoice.descriptionEn.isEmpty ? startVoice.description : startVoice.descriptionEn
                await VoiceService.shared.prefetch(
                    cacheKey: startVoice.fileName, text: text, voice: voiceId, language: "en"
                )
                print("✅ 开始语音预缓存完成: \(startVoice.fileName)")
            }

            // 2. 并行预缓存其余里程碑语音
            let voices = voiceMap.getAllRunVoices(goal: userGoal)
            await withTaskGroup(of: Void.self) { group in
                for voice in voices {
                    let text = voice.descriptionEn.isEmpty ? voice.description : voice.descriptionEn
                    group.addTask {
                        await VoiceService.shared.prefetch(
                            cacheKey: voice.fileName, text: text, voice: voiceId, language: "en"
                        )
                    }
                }
            }
            print("✅ EN 预缓存完成，共 \(voices.count) 条")
        }
    }

    /// 播放开始语音（女声：跑前_01）
    private func playStartVoice() {
        guard let startVoice = voiceMap.getStartVoice() else { return }
        playVoiceAsset(startVoice)
        print("🎙️ 播放开始语音: \(startVoice.fileName)")
    }

    /// 检查并触发语音（距离变化时调用）
    private func checkAndAnnounce(distance: Double) {
        let distanceKm = distance / 1000.0
        logger.log("📍 距离更新: \(String(format: "%.3f", distanceKm))km", category: "DATA")

        // 1. 检查跑中距离语音（男声）
        checkDistanceVoice(distanceKm: distanceKm)

        // 2. 检查今日目标完成
        if distanceKm >= todayTargetKm && !hasSpokenTodayGoal {
            hasSpokenTodayGoal = true
            hasSpoken3km = true
            dynamicEngine.markGoalCompleted()  // 停止动态语音，避免干扰完成体验
            logger.log("🎉 到达今日目标 \(todayTargetKm)km，触发完成语音", category: "VOICE")
            if todayTargetKm == 3.0 {
                // 3km目标：播放预录制跑後_01（文案含"3公里完成啦"）
                playCompleteVoices()
            } else {
                // 非3km目标：TTS播报，不播跑後_01（文案不符合实际距离）
                let isEN = LanguageManager.shared.currentLocale == "en"
                let goalText = isEN ? "Goal completed, well done!" : "今日目标完成，太棒了！"
                let lang = isEN ? "en" : "zh-Hans"
                let goalVoiceId = VoiceService.voiceId(for: aiManager.coachStyle, language: lang)
                Task {
                    let started = await VoiceService.shared.speakImmediate(
                        text: goalText, voice: goalVoiceId, language: lang
                    )
                    if started {
                        await MainActor.run { showFeedbackBubble(goalText) }
                    }
                }
            }
        }

        // 3. 检查成就进度提醒（90%警告）
        checkAchievementProgress(distanceKm: distanceKm)
    }

    /// 检查距离里程碑语音
    private func checkDistanceVoice(distanceKm: Double) {
        guard isVoiceEnabled else {
            logger.log("⚠️ 语音已关闭，跳过检查", category: "WARN")
            return
        }

        // 获取当前距离对应的语音（预录音频免费不限次数）
        let effectiveStyle: CoachStyle = SubscriptionManager.shared.isPro ? AIManager.shared.coachStyle : .encouraging
        if let voice = voiceMap.getDistanceVoice(distance: distanceKm, goal: userGoal, targetKm: todayTargetKm, coachStyle: effectiveStyle) {
            // 通过 playVoiceAsset 路由：中文=本地.m4a，英文=TTS API
            if playVoiceAsset(voice) {
                logger.log("🎯 触发距离语音: \(voice.fileName) at \(String(format: "%.3f", distanceKm))km", category: "VOICE")
                // 预录制语音优先：将该距离对应的目标进度里程碑标记为已覆盖
                // 防止 DynamicVoiceEngine 在预录制结束后再重复触发同义 TTS
                if case .onDistance(let km) = voice.triggerType, todayTargetKm > 0 {
                    let pct = km / todayTargetKm * 100
                    if abs(pct - 50) <= 5 { dynamicEngine.markPreRecordedCovered(.goalHalfway) }
                    if abs(pct - 80) <= 5 { dynamicEngine.markPreRecordedCovered(.goal80pct) }
                    if abs(pct - 90) <= 5 { dynamicEngine.markPreRecordedCovered(.goal90pct) }
                }
            }
        }
    }

    /// 播放完成语音（女声：跑后_01 → 跑后_02，自动按语言路由）
    private func playCompleteVoices() {
        let completeVoices = voiceMap.getCompleteVoices()
        let isEN = LanguageManager.shared.currentLocale == "en"

        if isEN {
            // EN 模式：串行播放，等第一条播完再播第二条
            Task {
                for voice in completeVoices {
                    guard !audioPlayerManager.hasPlayed(voice.fileName) else { continue }
                    audioPlayerManager.markPlayed(voice.fileName)
                    let text = voice.descriptionEn.isEmpty ? voice.description : voice.descriptionEn
                    let voiceId = VoiceService.voiceId(for: aiManager.coachStyle, language: "en")
                    let started = await VoiceService.shared.speakImmediate(
                        text: text, voice: voiceId, language: "en", cacheKey: voice.fileName
                    )
                    if started {
                        await MainActor.run { showFeedbackBubble(text) }
                        await VoiceService.shared.waitForFinish()  // 等播完再播下一条
                    }
                }
            }
        } else {
            // ZH 模式：AudioPlayerManager 自带队列，不变
            for voice in completeVoices {
                if audioPlayerManager.play(voice.fileName, priority: voice.priority) {
                    showFeedbackBubble(voice.description)
                }
            }
        }
    }

    /// 成就系统联动检查（90%警告，使用TTS提醒）
    private func checkAchievementProgress(distanceKm: Double) {
        _ = locationManager.calories

        // 已移除旧的AI成就提醒语音
        // 现在使用VoiceAssetMap中预录制的真实语音
    }

    /// 显示教练反馈气泡
    private func showFeedbackBubble(_ message: String) {
        currentFeedback = message
        // 语音正在播报时隐藏升级提示，避免自相矛盾
        showUpgradeHint = false
        withAnimation(.spring()) {
            showCoachFeedback = true
        }

        // 5秒后隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation {
                showCoachFeedback = false
            }
        }
    }

    /// 播放应急语音（心率过高/状态不佳时调用，自动按语言路由）
    func playEmergencyVoice() {
        guard let voice = voiceMap.getEmergencyVoice() else { return }
        playVoiceAsset(voice)
        print("🚨 播放应急语音: \(voice.fileName)")
    }

    /// 播放提前结束语音（用户提前停止时调用，自动按语言路由）
    func playEarlyStopVoice() {
        guard let voice = voiceMap.getEarlyStopVoice() else { return }
        playVoiceAsset(voice)
        print("⏹️ 播放提前结束语音: \(voice.fileName)")
    }

    private func startHoldAnimation() {
        holdProgress = 0
        holdTimer?.invalidate()

        // 使用 Timer 实现进度，1.5秒完成
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if self.isHolding {
                self.holdProgress += 0.05 / 1.5  // 1.5秒完成
                if self.holdProgress >= 1.0 {
                    timer.invalidate()
                    self.holdTimer = nil
                    self.endRun()
                }
            } else {
                timer.invalidate()
                self.holdTimer = nil
            }
        }
    }

    private func formatPace(_ pace: Double) -> String {
        guard pace > 0, pace.isFinite else { return "0'00\"" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return "\(minutes)'\(String(format: "%02d", seconds))\""
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct MetricCard: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
    }
}

#Preview {
    ActiveRunView()
}
