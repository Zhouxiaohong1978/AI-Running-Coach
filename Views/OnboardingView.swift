//
//  OnboardingView.swift
//  AI跑步教练
//
//  新手引导：5步流程
//  Step 1 欢迎 + 品牌价值展示
//  Step 2 基本信息（身高、体重、年龄、当前跑步水平）
//  Step 3 目标选择
//  Step 4 AI 预览演示（让用户在 3 分钟内感受 AI 价值）
//  Step 5 权限申请（位置 + 健康）
//

import SwiftUI
import CoreLocation
import HealthKit

// MARK: - 引导步骤

private enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case basicInfo
    case goalSelect
    case aiPreview
    case permissions
}

// MARK: - 跑步水平

enum FitnessLevel: String, CaseIterable, Identifiable {
    case beginner  = "beginner"
    case casual    = "casual"
    case regular   = "regular"
    case advanced  = "advanced"

    var id: String { rawValue }

    var displayName: String {
        let isEN = LanguageManager.shared.currentLocale == "en"
        switch self {
        case .beginner: return isEN ? "Beginner (never run)" : "新手 (几乎没跑过)"
        case .casual:   return isEN ? "Occasional (1-2x/week)" : "偶尔跑 (每周 1-2 次)"
        case .regular:  return isEN ? "Regular (3-4x/week)" : "规律跑 (每周 3-4 次)"
        case .advanced: return isEN ? "Experienced (5K+ easy)" : "进阶跑者 (5km 无压力)"
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "figure.walk"
        case .casual:   return "figure.run.circle"
        case .regular:  return "figure.run"
        case .advanced: return "medal.fill"
        }
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @AppStorage("onboarding_completed") private var onboardingCompleted = false
    @ObservedObject private var langMgr = LanguageManager.shared
    private var isEN: Bool { langMgr.currentLocale == "en" }

    // 用户填写的基本信息
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 65
    @State private var ageYears: Int = 28
    @State private var fitnessLevel: FitnessLevel = .casual

    // 目标选择
    @State private var selectedGoal: TrainingGoal? = nil

    // 步骤控制
    @State private var step: OnboardingStep = .welcome
    @State private var animateIn = false

    // 权限请求
    @State private var locationGranted = false
    @State private var healthGranted = false
    @State private var notifGranted = false

    // 订阅 Paywall
    @State private var showPaywall = false

    // AI 预览动画
    @State private var aiTypingText = ""
    @State private var aiTypingDone = false
    private let aiPreviewMessages: [String] = []  // 在 body 外计算

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.08, blue: 0.02), Color(red: 0.02, green: 0.04, blue: 0.01)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 步骤指示器（step 1 之后显示）
                if step != .welcome {
                    stepIndicator
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                }

                // 主内容
                Group {
                    switch step {
                    case .welcome:    welcomeStep
                    case .basicInfo:  basicInfoStep
                    case .goalSelect: goalSelectStep
                    case .aiPreview:  aiPreviewStep
                    case .permissions: permissionsStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(step.rawValue)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall, onDismiss: {
            // Paywall 关闭后（无论是否订阅）继续引导流程
            if step == .aiPreview {
                withAnimation(.easeInOut(duration: 0.35)) { step = .permissions }
            }
        }) {
            PaywallView()
        }
    }

    // MARK: - 步骤指示器

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(1..<OnboardingStep.allCases.count, id: \.self) { i in
                Capsule()
                    .fill(i <= step.rawValue
                          ? Color(red: 0.49, green: 0.84, blue: 0.11)
                          : Color.white.opacity(0.2))
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Step 0: 欢迎页

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // 品牌 Logo 区域
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.49, green: 0.84, blue: 0.11).opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "figure.run")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11))
                }
                .scaleEffect(animateIn ? 1 : 0.7)
                .opacity(animateIn ? 1 : 0)
                .onAppear {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                        animateIn = true
                    }
                }

                VStack(spacing: 12) {
                    Text(isEN ? "Your AI Running Coach" : "你的 AI 跑步教练")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(isEN
                         ? "Personalized plans, real-time coaching,\nand AI feedback tailored just for you."
                         : "个性化训练计划 · 实时语音陪跑\n让每一次跑步都有 AI 教练相伴")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(animateIn ? 1 : 0)
            }
            .padding(.horizontal, 32)

            Spacer()

            // 三大价值点
            VStack(spacing: 14) {
                featureRow(
                    icon: "brain.head.profile",
                    color: .blue,
                    title: isEN ? "Smart Training Plans" : "智能训练计划",
                    desc: isEN ? "AI generates a plan based on your fitness" : "AI 根据你的状态量身定制"
                )
                featureRow(
                    icon: "speaker.wave.3.fill",
                    color: Color(red: 0.49, green: 0.84, blue: 0.11),
                    title: isEN ? "Real-time Voice Coach" : "实时语音教练",
                    desc: isEN ? "Live pace, heart rate & encouragement" : "配速、心率、激励语音实时播报"
                )
                featureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange,
                    title: isEN ? "Progress Insights" : "数据分析反馈",
                    desc: isEN ? "AI analyzes every run for you" : "每次跑步后 AI 为你分析进步"
                )
            }
            .padding(.horizontal, 24)
            .opacity(animateIn ? 1 : 0)

            Spacer()

            // 开始按钮
            Button(action: nextStep) {
                Text(isEN ? "Get Started →" : "开始设置 →")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.04, green: 0.08, blue: 0.02))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(red: 0.49, green: 0.84, blue: 0.11))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(animateIn ? 1 : 0)
        }
    }

    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }

    // MARK: - Step 1: 基本信息

    private var basicInfoStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                stepHeader(
                    title: isEN ? "Tell us about you" : "告诉我们你的情况",
                    subtitle: isEN ? "AI uses this to build your personal plan" : "AI 用这些信息为你量身定制计划"
                )

                // 身高
                sliderCard(
                    label: isEN ? "Height" : "身高",
                    value: $heightCm,
                    range: 140...210,
                    step: 1,
                    format: { String(format: "%.0f cm", $0) }
                )

                // 体重
                sliderCard(
                    label: isEN ? "Weight" : "体重",
                    value: $weightKg,
                    range: 40...120,
                    step: 0.5,
                    format: { String(format: "%.1f kg", $0) }
                )

                // 年龄
                VStack(alignment: .leading, spacing: 10) {
                    Text(isEN ? "Age" : "年龄")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    HStack {
                        Button { if ageYears > 14 { ageYears -= 1 } } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11))
                        }
                        Spacer()
                        Text("\(ageYears)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(isEN ? "yrs" : "岁")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Button { if ageYears < 80 { ageYears += 1 } } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                }

                // 当前跑步水平
                VStack(alignment: .leading, spacing: 12) {
                    Text(isEN ? "Current Running Level" : "当前跑步水平")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    VStack(spacing: 8) {
                        ForEach(FitnessLevel.allCases) { level in
                            fitnessLevelRow(level)
                        }
                    }
                }

                nextButton(isEN ? "Next →" : "下一步 →", enabled: true)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    private func sliderCard(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: @escaping (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(format(value.wrappedValue))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11))
            }
            Slider(value: value, in: range, step: step)
                .tint(Color(red: 0.49, green: 0.84, blue: 0.11))
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }

    @ViewBuilder
    private func fitnessLevelRow(_ level: FitnessLevel) -> some View {
        let selected = fitnessLevel == level
        return Button { fitnessLevel = level } label: {
            HStack(spacing: 14) {
                Image(systemName: level.icon)
                    .font(.system(size: 18))
                    .foregroundColor(selected ? Color(red: 0.04, green: 0.08, blue: 0.02) : Color(red: 0.49, green: 0.84, blue: 0.11))
                    .frame(width: 36, height: 36)
                    .background(selected
                                ? Color(red: 0.49, green: 0.84, blue: 0.11)
                                : Color(red: 0.49, green: 0.84, blue: 0.11).opacity(0.15))
                    .cornerRadius(10)

                Text(level.displayName)
                    .font(.system(size: 14, weight: selected ? .semibold : .regular))
                    .foregroundColor(.white)

                Spacer()

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11))
                }
            }
            .padding(14)
            .background(selected
                        ? Color(red: 0.49, green: 0.84, blue: 0.11).opacity(0.18)
                        : Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected
                            ? Color(red: 0.49, green: 0.84, blue: 0.11).opacity(0.6)
                            : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: 目标选择

    private var goalSelectStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                stepHeader(
                    title: isEN ? "What's your goal?" : "你的跑步目标是什么？",
                    subtitle: isEN ? "Pick one — AI will build your plan around it" : "选一个，AI 会围绕它生成你的专属计划"
                )

                // 目标网格（新用户只显示默认解锁的目标）
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(TrainingGoal.allCases.filter { $0.requiredDistance == 0 }) { goal in
                        goalCard(goal)
                    }
                }

                if selectedGoal != nil {
                    nextButton(isEN ? "Preview My Plan →" : "预览我的计划 →", enabled: true)
                        .padding(.bottom, 40)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    private func goalCard(_ goal: TrainingGoal) -> some View {
        let selected = selectedGoal == goal
        return Button { withAnimation(.spring(response: 0.3)) { selectedGoal = goal } } label: {
            VStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.system(size: 30))
                    .foregroundColor(selected ? Color(red: 0.04, green: 0.08, blue: 0.02) : Color(red: 0.49, green: 0.84, blue: 0.11))

                Text(goal.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selected ? Color(red: 0.04, green: 0.08, blue: 0.02) : .white)
                    .multilineTextAlignment(.center)

                Text(goal.description)
                    .font(.system(size: 11))
                    .foregroundColor(selected ? Color(red: 0.04, green: 0.08, blue: 0.02).opacity(0.7) : .white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(selected
                        ? Color(red: 0.49, green: 0.84, blue: 0.11)
                        : Color.white.opacity(0.07))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected
                            ? Color.clear
                            : Color.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(selected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: AI 价值预览

    @State private var revealedCards: Set<Int> = []
    @State private var aiAnimating = false

    private var aiPreviewStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                stepHeader(
                    title: isEN ? "Here's what AI sees" : "AI 已了解你的情况",
                    subtitle: isEN ? "Your personalized plan is ready in seconds" : "你的个性化计划几秒内生成"
                )

                // AI 分析卡片——依次出现
                aiSummaryCard
                aiPlanPreviewCard
                aiVoiceCard

                // 订阅转化按钮组：购买意愿最高时机
                aiPreviewCTA
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .onAppear { startAIAnimation() }
    }

    private var aiSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(isEN ? "Your Profile" : "你的基本档案",
                  systemImage: "person.text.rectangle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11))

            HStack(spacing: 0) {
                profileStat(value: String(format: "%.0f", heightCm), unit: "cm",
                            label: isEN ? "Height" : "身高")
                Divider().background(Color.white.opacity(0.15)).frame(height: 40)
                profileStat(value: String(format: "%.0f", weightKg), unit: "kg",
                            label: isEN ? "Weight" : "体重")
                Divider().background(Color.white.opacity(0.15)).frame(height: 40)
                profileStat(value: "\(ageYears)", unit: isEN ? "yrs" : "岁",
                            label: isEN ? "Age" : "年龄")
                Divider().background(Color.white.opacity(0.15)).frame(height: 40)
                profileStat(value: bmiString, unit: "BMI",
                            label: isEN ? "BMI" : "体重指数")
            }
            .frame(maxWidth: .infinity)

            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 8) {
                Image(systemName: fitnessLevel.icon)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11))
                Text(fitnessLevel.displayName)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                if let goal = selectedGoal {
                    Text(goal.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.49, green: 0.84, blue: 0.11).opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
        .opacity(revealedCards.contains(0) ? 1 : 0)
        .offset(y: revealedCards.contains(0) ? 0 : 20)
    }

    private func profileStat(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private var bmiString: String {
        let heightM = heightCm / 100
        let bmi = weightKg / (heightM * heightM)
        return String(format: "%.1f", bmi)
    }

    private var aiPlanPreviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(isEN ? "Your 8-Week Plan Preview" : "8 周计划预览",
                  systemImage: "calendar.badge.checkmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.orange)

            // 模拟 AI 生成的周次概览
            VStack(spacing: 8) {
                ForEach(planPreviewWeeks, id: \.0) { week in
                    HStack(spacing: 12) {
                        Text(isEN ? "W\(week.0)" : "第\(week.0)周")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 36, alignment: .leading)

                        // 进度条
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 0.49, green: 0.84, blue: 0.11).opacity(0.7))
                                    .frame(width: geo.size.width * week.1, height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text(week.2)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                            .frame(width: 68, alignment: .trailing)
                    }
                }
            }

            Text(isEN
                 ? "✦ Complete plan generated after setup"
                 : "✦ 完整计划在设置完成后立即生成")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.35))
                .italic()
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
        .opacity(revealedCards.contains(1) ? 1 : 0)
        .offset(y: revealedCards.contains(1) ? 0 : 20)
    }

    // 根据目标 + 水平生成示例周计划
    private var planPreviewWeeks: [(Int, Double, String)] {
        let goal = selectedGoal ?? .fiveK
        let isEN = LanguageManager.shared.currentLocale == "en"
        switch goal {
        case .threeK, .fiveK:
            return isEN
                ? [(1,0.3,"Easy jog 2km"),(2,0.4,"Build base"),(3,0.5,"3km target"),(4,0.6,"Long run 4km")]
                : [(1,0.3,"轻松跑 2km"),(2,0.4,"打好基础"),(3,0.5,"冲刺 3km"),(4,0.6,"长距离 4km")]
        case .weightLoss:
            return isEN
                ? [(1,0.25,"Fat burn walk/run"),(2,0.4,"Interval 20min"),(3,0.55,"Steady 5km"),(4,0.65,"Push to 6km")]
                : [(1,0.25,"燃脂走跑结合"),(2,0.4,"间歇跑 20分钟"),(3,0.55,"匀速跑 5km"),(4,0.65,"冲刺 6km")]
        case .tenK:
            return isEN
                ? [(1,0.3,"Build endurance"),(2,0.45,"5km baseline"),(3,0.6,"Tempo run"),(4,0.75,"8km long run")]
                : [(1,0.3,"建立耐力基础"),(2,0.45,"5km 基础跑"),(3,0.6,"节奏跑"),(4,0.75,"8km 长距离")]
        case .halfMarathon:
            return isEN
                ? [(1,0.2,"Base mileage"),(2,0.4,"10km easy"),(3,0.6,"Tempo runs"),(4,0.75,"14km long run")]
                : [(1,0.2,"里程积累"),(2,0.4,"10km 轻松跑"),(3,0.6,"节奏跑训练"),(4,0.75,"14km 长距离")]
        case .fullMarathon:
            return isEN
                ? [(1,0.2,"Easy aerobic"),(2,0.35,"16km long"),(3,0.55,"Interval work"),(4,0.75,"24km long run")]
                : [(1,0.2,"有氧基础"),(2,0.35,"16km 长距离"),(3,0.55,"间歇训练"),(4,0.75,"24km 长距离")]
        }
    }

    private var aiVoiceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(isEN ? "Real-time Voice Sample" : "实时语音教练示例",
                  systemImage: "speaker.wave.2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.blue)

            // 模拟语音气泡
            VStack(alignment: .leading, spacing: 8) {
                voiceBubble(isEN
                            ? "You've hit 5 minutes! Heart rate zone: fat burn. Keep going!"
                            : "跑步满 5 分钟了！心率处于燃脂区间，继续保持这个配速！",
                            delay: 0)
                voiceBubble(isEN
                            ? "Pace improved! You're 30 sec/km faster — great form!"
                            : "配速提升了！比刚才快了 30 秒/公里，保持住！",
                            delay: 0.4)
                voiceBubble(isEN
                            ? "1km done! Breathing steady — you're crushing it."
                            : "1 公里完成！呼吸很稳，继续冲！",
                            delay: 0.8)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
        .opacity(revealedCards.contains(2) ? 1 : 0)
        .offset(y: revealedCards.contains(2) ? 0 : 20)
    }

    private func voiceBubble(_ text: String, delay: Double) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.blue)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.blue.opacity(0.12))
        .cornerRadius(12)
    }

    // MARK: - AI 预览页底部 CTA（购买意愿最高时刻）

    private var aiPreviewCTA: some View {
        VStack(spacing: 12) {
            // 主按钮：订阅 Pro
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text(isEN ? "Unlock All Pro Features →" : "解锁 Pro 全部功能 →")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(Color(red: 0.04, green: 0.08, blue: 0.02))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(red: 0.49, green: 0.84, blue: 0.11))
                .cornerRadius(16)
            }

            // Pro 权益简述
            HStack(spacing: 16) {
                proFeatureTag(isEN ? "AI Voice Coach" : "AI 语音教练")
                proFeatureTag(isEN ? "Smart Plans" : "智能计划")
                proFeatureTag(isEN ? "All Goals" : "全部目标")
            }
            .frame(maxWidth: .infinity)

            // 次要链接：跳过
            Button {
                withAnimation(.easeInOut(duration: 0.35)) { step = .permissions }
            } label: {
                Text(isEN ? "Continue without Pro" : "暂不升级，继续")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.35))
                    .underline()
            }
            .padding(.top, 4)
        }
        .padding(.top, 8)
        .opacity(revealedCards.contains(2) ? 1 : 0)  // 随第三张卡片一起出现
    }

    private func proFeatureTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11).opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(red: 0.49, green: 0.84, blue: 0.11).opacity(0.1))
            .cornerRadius(6)
    }

    private func startAIAnimation() {
        // 三张卡片依次出现
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            revealedCards.insert(0)
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            revealedCards.insert(1)
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            revealedCards.insert(2)
        }
    }

    // MARK: - Step 4: 权限申请

    private var permissionsStep: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    stepHeader(
                        title: isEN ? "Enable Key Features" : "开启关键功能",
                        subtitle: isEN
                            ? "These permissions let AI coach you in real time"
                            : "开启后 AI 才能在跑步时实时陪伴你"
                    )

                    VStack(spacing: 14) {
                        permissionRow(
                            icon: "location.fill",
                            color: .blue,
                            title: isEN ? "Location" : "位置权限",
                            desc: isEN ? "Track your route, pace & distance" : "追踪路线、配速和距离",
                            status: locationGranted,
                            action: requestLocation
                        )

                        permissionRow(
                            icon: "heart.fill",
                            color: .red,
                            title: isEN ? "Health & Heart Rate" : "健康 & 心率",
                            desc: isEN ? "Read heart rate from Apple Watch" : "读取 Apple Watch 心率数据",
                            status: healthGranted,
                            action: requestHealth
                        )

                        permissionRow(
                            icon: "bell.fill",
                            color: .orange,
                            title: isEN ? "Notifications" : "通知权限",
                            desc: isEN ? "Training reminders & plan updates" : "训练提醒 & 计划更新通知",
                            status: notifGranted,
                            action: requestNotifications
                        )
                    }

                    // 说明文字
                    Text(isEN
                         ? "You can change permissions anytime in iPhone Settings."
                         : "你可以随时在 iPhone「设置」中修改权限。")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    nextButton(
                        isEN ? "Start Running! →" : "开始跑步！→",
                        label: isEN ? "Complete Setup" : "完成设置",
                        enabled: true
                    )
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
    }

    private func permissionRow(
        icon: String,
        color: Color,
        title: String,
        desc: String,
        status: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(status ? .white : color)
                .frame(width: 40, height: 40)
                .background(status ? color : color.opacity(0.2))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            if status {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11))
            } else {
                Button(action: action) {
                    Text(isEN ? "Allow" : "允许")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.04, green: 0.08, blue: 0.02))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(red: 0.49, green: 0.84, blue: 0.11))
                        .cornerRadius(10)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }

    // MARK: - 权限请求

    private func requestLocation() {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let status = manager.authorizationStatus
            locationGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
        }
    }

    private func requestHealth() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthGranted = false
            return
        }
        let store = HKHealthStore()
        let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        store.requestAuthorization(toShare: [], read: [hrType]) { success, _ in
            DispatchQueue.main.async { healthGranted = success }
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { notifGranted = granted }
        }
    }

    // MARK: - 通用组件

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private func nextButton(_ title: String, label: String? = nil, enabled: Bool) -> some View {
        Button(action: nextStep) {
            Text(label ?? title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(enabled ? Color(red: 0.04, green: 0.08, blue: 0.02) : .white.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(enabled
                            ? Color(red: 0.49, green: 0.84, blue: 0.11)
                            : Color.white.opacity(0.1))
                .cornerRadius(16)
        }
        .disabled(!enabled)
        .padding(.top, 8)
    }

    // MARK: - 步骤跳转

    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.35)) {
            switch step {
            case .welcome:     step = .basicInfo
            case .basicInfo:   step = .goalSelect
            case .goalSelect:  step = selectedGoal != nil ? .aiPreview : .goalSelect
            case .aiPreview:   step = .permissions
            case .permissions: completeOnboarding()
            }
        }
    }

    private func completeOnboarding() {
        // 保存用户基本信息
        UserDefaults.standard.set(heightCm, forKey: "user_height_cm")
        UserDefaults.standard.set(weightKg, forKey: "user_weight_kg")
        UserDefaults.standard.set(ageYears, forKey: "user_age")
        UserDefaults.standard.set(fitnessLevel.rawValue, forKey: "user_fitness_level")
        if let goal = selectedGoal {
            UserDefaults.standard.set(goal.rawValue, forKey: "user_onboarding_goal")
        }
        onboardingCompleted = true
    }
}

// MARK: - UserNotifications import

import UserNotifications

#Preview {
    OnboardingView()
}
