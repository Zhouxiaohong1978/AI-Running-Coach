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
    @State private var hasSpokenStart = false
    @State private var hasSpoken500m = false
    @State private var hasSpoken1km = false
    @State private var hasSpoken1_5km = false
    @State private var hasSpoken2km = false
    @State private var hasSpoken2_5km = false
    @State private var hasSpoken3km = false
    @State private var achievement1kmWarned = false  // 是否已提醒1km成就
    @State private var achievement3kmWarned = false  // 是否已提醒3km成就
    @State private var achievement300calWarned = false  // 是否已提醒300卡成就
    @State private var showUpgradeHint = false  // 免费用户反馈用完时的升级提示

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

                // 免费用户升级提示
                if showUpgradeHint {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                        Text("升级 Pro 获取无限教练反馈")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(16)
                    .transition(.opacity)
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
                        Text(formatPace(locationManager.currentPace))
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
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
                                Text("\(Int(locationManager.calories))")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
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
                                Text("--")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("心率")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
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
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.2))
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
            lastFeedbackTime = Date()

            // 重置音频播放状态和免费反馈计数
            audioPlayerManager.reset()
            audioPlayerManager.isEnabled = isVoiceEnabled
            subscriptionManager.resetRunFeedbackCount()

            // 延迟一点播报，确保视图完全加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("🏃 MVP 1.0 开始跑步，三位一体联动启动")
                self.logger.log("🎯 准备播放开始语音", category: "VOICE")
                // 播放开始语音（女声）
                playStartVoice()
            }
        }
        .onDisappear {
            locationManager.stopTracking()
            audioPlayerManager.stopAll()
        }
        .onChange(of: locationManager.distance) { newDistance in
            checkAndAnnounce(distance: newDistance)
        }
        .onChange(of: showSummary) { newValue in
            // 当跑步结束后，摘要页面被关闭时，自动返回主页
            if !newValue && savedRecord != nil {
                dismiss()
            }
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

        // 检查是否提前结束（未到3km）
        let distanceKm = locationManager.distance / 1000.0
        if distanceKm < 3.0 {
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
            kmSplits: locationManager.kmSplits.isEmpty ? nil : locationManager.kmSplits
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

    /// 播放开始语音（女声：跑前_01）
    private func playStartVoice() {
        guard let startVoice = voiceMap.getStartVoice() else { return }
        if audioPlayerManager.play(startVoice.fileName, priority: startVoice.priority) {
            showFeedbackBubble(startVoice.description)
        }
        print("🎙️ 播放开始语音: \(startVoice.fileName)")
    }

    /// 检查并触发语音（距离变化时调用）
    private func checkAndAnnounce(distance: Double) {
        let distanceKm = distance / 1000.0
        logger.log("📍 距离更新: \(String(format: "%.3f", distanceKm))km", category: "DATA")

        // 1. 检查跑中距离语音（男声）
        checkDistanceVoice(distanceKm: distanceKm)

        // 2. 检查完成语音（3km）
        if distanceKm >= 3.0 && !hasSpoken3km {
            hasSpoken3km = true
            logger.log("🎉 到达3km，触发完成语音", category: "VOICE")
            playCompleteVoices()
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

        // 免费用户检查反馈次数限制
        if !subscriptionManager.canGetFeedback() {
            // 显示升级提示（仅一次）
            if !showUpgradeHint {
                withAnimation {
                    showUpgradeHint = true
                }
            }
            return
        }

        // 获取当前距离对应的语音
        if let voice = voiceMap.getDistanceVoice(distance: distanceKm, goal: userGoal) {
            logger.log("🎯 触发距离语音: \(voice.fileName) at \(String(format: "%.3f", distanceKm))km", category: "VOICE")
            if audioPlayerManager.play(voice.fileName, priority: voice.priority) {
                subscriptionManager.incrementFeedbackCount()  // 只有播放成功才计数
                showFeedbackBubble(voice.description)
                print("🎙️ 播放距离语音: \(voice.fileName) at \(distanceKm)km")
            }
        }
    }

    /// 播放完成语音（女声：跑后_01 → 跑后_02）
    private func playCompleteVoices() {
        let completeVoices = voiceMap.getCompleteVoices()

        // 按顺序播放两条完成语音
        for (index, voice) in completeVoices.enumerated() {
            // 第二条语音延迟播放（等第一条播完）
            let delay = index == 0 ? 0.0 : 3.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if self.audioPlayerManager.play(voice.fileName, priority: voice.priority) {
                    self.showFeedbackBubble(voice.description)
                }
                print("🎙️ 播放完成语音: \(voice.fileName)")
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

    /// 播放应急语音（心率过高/状态不佳时调用）
    func playEmergencyVoice() {
        guard let voice = voiceMap.getEmergencyVoice() else { return }
        if audioPlayerManager.play(voice.fileName, priority: voice.priority) {
            showFeedbackBubble(voice.description)
        }
        print("🚨 播放应急语音: \(voice.fileName)")
    }

    /// 播放提前结束语音（用户提前停止时调用）
    func playEarlyStopVoice() {
        guard let voice = voiceMap.getEarlyStopVoice() else { return }
        if audioPlayerManager.play(voice.fileName, priority: voice.priority) {
            showFeedbackBubble(voice.description)
        }
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
