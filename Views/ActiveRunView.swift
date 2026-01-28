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
    @StateObject private var speechManager = SpeechManager.shared
    @StateObject private var aiManager = AIManager.shared

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
                        speechManager.isEnabled = isVoiceEnabled
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
                                speechManager.announcePause()
                            } else {
                                locationManager.resumeTracking()
                                speechManager.announceResume()
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
            locationManager.startTracking()
            lastFeedbackTime = Date()

            // 延迟一点播报，确保视图完全加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                speechManager.isEnabled = isVoiceEnabled
                print("🏃 开始跑步，准备播报，isVoiceEnabled=\(isVoiceEnabled)")
                speechManager.announceStart()
            }
        }
        .onDisappear {
            locationManager.stopTracking()
            speechManager.stopAll()
        }
        .onChange(of: locationManager.distance) { newDistance in
            checkAndAnnounce(distance: newDistance)
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

        // 播报结束语音
        speechManager.announceFinish(
            distance: locationManager.distance,
            duration: locationManager.duration
        )

        // 创建跑步记录
        let record = RunRecord(
            distance: locationManager.distance,
            duration: locationManager.duration,
            pace: locationManager.currentPace,
            calories: locationManager.calories,
            startTime: Date().addingTimeInterval(-locationManager.duration),
            endTime: Date(),
            routeCoordinates: locationManager.routeCoordinates.map { Coordinate(from: $0) }
        )

        savedRecord = record

        // 保存到数据库
        Task {
            await dataManager.addRunRecord(record)

            // 延迟 2 秒后显示结束页面
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSummary = true
        }
    }

    // MARK: - AI Coach Methods

    /// 检查并播报里程和 AI 反馈
    private func checkAndAnnounce(distance: Double) {
        let distanceMeters = Int(distance)
        let current200m = distanceMeters / 200

        // 每 200 米播报一次距离
        if current200m > lastAnnouncedKm && current200m > 0 {
            lastAnnouncedKm = current200m

            // 播报距离（格式化为公里或米）
            let distanceKm = distance / 1000.0
            if distanceKm >= 1.0 {
                // 大于等于 1km，播报公里数
                speechManager.announceDistance(distanceKm)
            } else {
                // 小于 1km，播报米数
                speechManager.speak("已跑\(distanceMeters)米", priority: .low)
            }
        }

        // AI 反馈触发：每 200m 触发一次，或每 3 分钟触发一次
        let timeSinceLastFeedback = Date().timeIntervalSince(lastFeedbackTime)
        let distanceMetersInt = Int(distance)
        let lastFeedbackDistanceInt = Int(lastFeedbackDistance)
        // 每 200m 触发（跨过 200m 边界）
        let is200mMilestone = distanceMetersInt / 200 > lastFeedbackDistanceInt / 200 && distanceMetersInt >= 200
        // 时间触发
        let isTimeTrigger = timeSinceLastFeedback >= 180 && locationManager.duration > 60
        let shouldTrigger = isTimeTrigger || (is200mMilestone && timeSinceLastFeedback > 15)

        if shouldTrigger {
            lastFeedbackTime = Date()
            lastFeedbackDistance = distance
            // 延迟一秒，让距离播报先完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.fetchAIFeedback()
            }
        }
    }

    /// 获取 AI 教练反馈
    private func fetchAIFeedback() {
        guard isVoiceEnabled else { return }
        guard locationManager.currentPace > 0 else { return }

        Task {
            do {
                let feedback = try await aiManager.getCoachFeedback(
                    currentPace: locationManager.currentPace,
                    distance: locationManager.distance / 1000.0,
                    duration: locationManager.duration
                )

                await MainActor.run {
                    currentFeedback = feedback
                    speechManager.speak(feedback, priority: .high)

                    // 显示反馈气泡
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
            } catch {
                print("❌ AI反馈获取失败: \(error.localizedDescription)")

                // 使用后备反馈（即使 AI 失败也要给用户反馈）
                await MainActor.run {
                    let fallbackFeedback = getFallbackFeedback()
                    currentFeedback = fallbackFeedback
                    speechManager.speak(fallbackFeedback, priority: .high)

                    // 显示反馈气泡
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
            }
        }
    }

    /// 获取后备反馈（AI 失败时使用）
    private func getFallbackFeedback() -> String {
        let fallbacks = [
            "配速稳定，保持节奏，你做得很好！",
            "继续坚持，你已经跑了这么远了！",
            "呼吸均匀，保持这个状态！",
            "很棒的表现，继续加油！",
            "注意配速，不要太快也不要太慢。",
            "保持节奏，稳定前进！",
            "你的状态不错，继续保持！",
            "专注呼吸，放松肩膀，跑得更轻松。"
        ]

        // 基于距离选择不同的反馈
        let distanceKm = locationManager.distance / 1000.0
        let index = Int(distanceKm) % fallbacks.count
        return fallbacks[index]
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
