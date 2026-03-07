//
//  AchievementShareView.swift
//  AIRunningCoach
//
//  成就分享卡片 — 对照 Figma 设计实现，中英文双语
//  v3: 真实跑步数据 + 配速曲线 + 五彩纸屑 + 呼吸节奏动画
//

import SwiftUI
import Photos

// MARK: - 卡片模板

fileprivate enum ShareTemplate: CaseIterable {
    case instagram, wechat, weibo

    var nameCN: String {
        switch self { case .instagram: return "Instagram"; case .wechat: return "朋友圈"; case .weibo: return "微博长图" }
    }
    var nameEN: String {
        switch self { case .instagram: return "Instagram"; case .wechat: return "WeChat"; case .weibo: return "Weibo" }
    }
    var icon: String {
        switch self { case .instagram: return "camera.fill"; case .wechat: return "ellipsis.bubble.fill"; case .weibo: return "iphone" }
    }
    var ratio: String {
        switch self { case .instagram: return "9:16"; case .wechat: return "1:1"; case .weibo: return "3:4" }
    }
    var aspectRatio: CGFloat {
        switch self { case .instagram: return 9.0/16.0; case .wechat: return 1.0; case .weibo: return 3.0/4.0 }
    }
}

// MARK: - 卡片主题

fileprivate enum ShareTheme: CaseIterable {
    case purple, blue, rainbow, dark

    var nameCN: String {
        switch self { case .purple: return "紫色"; case .blue: return "蓝色"; case .rainbow: return "彩虹"; case .dark: return "暗黑" }
    }
    var nameEN: String {
        switch self { case .purple: return "Purple"; case .blue: return "Blue"; case .rainbow: return "Rainbow"; case .dark: return "Dark" }
    }
    var colors: [Color] {
        switch self {
        case .purple:  return [Color(red:0.66,green:0.27,blue:0.96), Color(red:0.93,green:0.26,blue:0.60)]
        case .blue:    return [Color(red:0.22,green:0.49,blue:0.97), Color(red:0.01,green:0.70,blue:0.84)]
        case .rainbow: return [Color(red:0.86,green:0.22,blue:0.91), Color(red:0.64,green:0.15,blue:0.85), Color(red:0.93,green:0.26,blue:0.60)]
        case .dark:    return [Color(red:0.12,green:0.16,blue:0.22), Color(red:0.06,green:0.08,blue:0.13)]
        }
    }
    var selectedBorder: Color {
        switch self { case .dark: return .gray; default: return .purple }
    }
}

// MARK: - 五彩纸屑

fileprivate struct ConfettiView: View {
    struct Particle: Identifiable {
        let id = UUID()
        let xFraction: CGFloat
        let delay: Double
        let duration: Double
        let color: Color
        let width: CGFloat
        let height: CGFloat
        let initialRotation: Double
        let sway: CGFloat
    }

    @State private var particles: [Particle] = []
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.width, height: p.height)
                    .rotationEffect(.degrees(animate ? p.initialRotation + 540 : p.initialRotation))
                    .position(
                        x: min(max(geo.size.width * p.xFraction + (animate ? p.sway : 0), 0), geo.size.width),
                        y: animate ? geo.size.height + 50 : -20
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(.easeIn(duration: p.duration).delay(p.delay), value: animate)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            let palette: [Color] = [
                .red, .orange, .yellow, .green, .blue, .purple, .pink,
                Color(red:1,green:0.5,blue:0), Color(red:0,green:0.9,blue:0.6)
            ]
            particles = (0..<72).map { _ in
                Particle(
                    xFraction: CGFloat.random(in: 0...1),
                    delay: Double.random(in: 0...2.0),
                    duration: Double.random(in: 1.8...3.5),
                    color: palette.randomElement()!,
                    width: CGFloat.random(in: 5...12),
                    height: CGFloat.random(in: 8...18),
                    initialRotation: Double.random(in: 0...360),
                    sway: CGFloat.random(in: -60...60)
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { animate = true }
        }
    }
}

// MARK: - 主视图

struct AchievementShareView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var runData = RunDataManager.shared
    let achievement: Achievement

    @State private var template: ShareTemplate = .instagram
    @State private var theme: ShareTheme = .rainbow
    @State private var isFlipped = false
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var isGenerating = false
    @State private var showConfetti = false
    @State private var showActionDialog = false   // 分享/保存选择弹窗
    @State private var savedToast: String? = nil  // 保存成功/失败提示

    private var isEN: Bool { lang.currentLocale == "en" }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        // 选择模板
                        header(isEN ? "Select Template" : "选择模板")
                        templatePicker.padding(.horizontal, 20).padding(.bottom, 20)

                        // 选择主题
                        header(isEN ? "Select Theme" : "选择主题")
                        themePicker.padding(.horizontal, 20).padding(.bottom, 20)

                        // 翻转按钮
                        flipButton.padding(.horizontal, 20).padding(.bottom, 20)

                        // 卡片预览
                        cardPreview.padding(.horizontal, 20).padding(.bottom, 28)

                        // 分享按钮
                        shareButton.padding(.horizontal, 20).padding(.bottom, 48)
                    }
                }
                .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())

                // 五彩纸屑覆盖层
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                }

                // 保存成功/失败 Toast
                if let toast = savedToast {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.75))
                            .clipShape(Capsule())
                            .padding(.bottom, 60)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.4), value: savedToast)
                    .allowsHitTesting(false)
                }
            }
            .navigationTitle(isEN ? "Share Achievement" : "分享成就卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEN ? "Close" : "关闭") { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let img = shareImage { ShareSheet(items: [img]) }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showConfetti = true
                }
            }
            // 选择弹窗：分享 or 保存到相册
            .confirmationDialog(
                isEN ? "Share or Save?" : "分享或保存？",
                isPresented: $showActionDialog,
                titleVisibility: .visible
            ) {
                Button(isEN ? "Share to Social Platforms" : "分享到社交平台") {
                    generateImage { img in
                        shareImage = img
                        showShareSheet = true
                    }
                }
                Button(isEN ? "Save to Photos" : "保存到相册") {
                    generateImage { img in
                        saveToPhotos(img)
                    }
                }
                Button(isEN ? "Cancel" : "取消", role: .cancel) {}
            } message: {
                Text(isEN ? "Choose how to use your achievement card" : "选择成就卡片的使用方式")
            }
        }
    }

    // MARK: - 保存到相册提示 Toast（叠加在外部调用处）

    // MARK: - 分组标题

    private func header(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
            Spacer()
        }
    }

    // MARK: - 模板选择器

    private var templatePicker: some View {
        HStack(spacing: 12) {
            ForEach(ShareTemplate.allCases, id: \.ratio) { t in
                Button { withAnimation(.spring(response: 0.3)) { template = t } } label: {
                    VStack(spacing: 8) {
                        Image(systemName: t.icon)
                            .font(.system(size: 26))
                            .foregroundColor(template == t ? .white : .secondary)
                            .frame(width: 52, height: 52)
                            .background(
                                Group {
                                    if template == t {
                                        AnyView(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    } else {
                                        AnyView(Color(UIColor.systemBackground))
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        Text(isEN ? t.nameEN : t.nameCN)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(template == t ? .purple : .primary)
                        Text(t.ratio)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(template == t ? Color.purple : Color.clear, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 主题选择器

    private var themePicker: some View {
        HStack(spacing: 12) {
            ForEach(ShareTheme.allCases, id: \.nameCN) { t in
                Button { withAnimation(.spring(response: 0.3)) { theme = t } } label: {
                    VStack(spacing: 8) {
                        LinearGradient(colors: t.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Text(isEN ? t.nameEN : t.nameCN)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(theme == t ? t.selectedBorder : Color.clear, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 翻转按钮

    private var flipButton: some View {
        Button {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { isFlipped.toggle() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                Text(isFlipped
                    ? (isEN ? "View Front" : "查看正面")
                    : (isEN ? "Flip Card (View Stats)" : "翻转卡片（查看数据）"))
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - 卡片预览（带3D翻转）

    private var cardPreview: some View {
        AchievementCardFace(
            achievement: achievement,
            theme: theme,
            isFlipped: isFlipped,
            isEN: isEN,
            runRecords: runData.runRecords
        )
        .aspectRatio(template.aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.22), radius: 20, y: 10)
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: isFlipped)
    }

    // MARK: - 分享按钮

    private var shareButton: some View {
        VStack(spacing: 10) {
            Button {
                showActionDialog = true
            } label: {
                HStack(spacing: 10) {
                    if isGenerating {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 20))
                    }
                    Text(isGenerating
                        ? (isEN ? "Generating..." : "生成中...")
                        : (isEN ? "Share / Save" : "分享 / 保存"))
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    isGenerating
                        ? AnyView(Color.gray)
                        : AnyView(LinearGradient(colors: [Color(red:0.20,green:0.72,blue:0.28), Color(red:0.12,green:0.58,blue:0.19)],
                                                  startPoint: .leading, endPoint: .trailing))
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color.green.opacity(0.35), radius: 10, y: 4)
            }
            .disabled(isGenerating)

            HStack(spacing: 4) {
                Image(systemName: "info.circle").font(.system(size: 12))
                Text(isEN ? "Share to WeChat, Instagram, Weibo or save to Photos" : "可直接分享到微信、微博、Instagram 或保存到相册")
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(.secondary)
        }
    }

    // MARK: - 渲染成就卡片图片（公共步骤）

    private func generateImage(completion: @escaping (UIImage) -> Void) {
        isGenerating = true
        let wasFlipped = isFlipped
        if wasFlipped { withAnimation { isFlipped = false } }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let card = AchievementCardFace(
                achievement: achievement,
                theme: theme,
                isFlipped: false,
                isEN: isEN,
                runRecords: runData.runRecords
            )
            .frame(width: 390)
            .aspectRatio(template.aspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            let renderer = ImageRenderer(content: card)
            renderer.scale = 3.0
            if let img = renderer.uiImage {
                completion(img)
                Task { await AchievementManager.shared.incrementShareCountAndSync(for: achievement.id) }
            }
            isGenerating = false
            if wasFlipped { withAnimation { isFlipped = true } }
        }
    }

    // MARK: - 保存到相册

    private func saveToPhotos(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    } completionHandler: { success, _ in
                        DispatchQueue.main.async {
                            showToast(success
                                ? (isEN ? "Saved to Photos!" : "已保存到相册")
                                : (isEN ? "Save failed" : "保存失败，请重试"))
                        }
                    }
                default:
                    showToast(isEN ? "Photos access denied. Enable in Settings." : "相册权限未开启，请在设置中允许")
                }
            }
        }
    }

    private func showToast(_ message: String) {
        savedToast = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            savedToast = nil
        }
    }
}

// MARK: - 卡片正/背面（独立 View，可被 ImageRenderer 渲染）

fileprivate struct AchievementCardFace: View {
    let achievement: Achievement
    let theme: ShareTheme
    let isFlipped: Bool
    let isEN: Bool
    let runRecords: [RunRecord]

    @State private var breatheScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(colors: theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if !isFlipped {
                frontContent
            } else {
                backContent
                    // 抵消父视图翻转，让背面文字方向正确
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                breatheScale = 1.10
            }
        }
    }

    // ── 正面 ──
    private var frontContent: some View {
        VStack(spacing: 0) {
            // "Achievement Unlocked" / "成就解锁"
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.yellow)
                Text(isEN ? "Achievement\nUnlocked" : "成就解锁")
                    .font(.system(size: isEN ? 20 : 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 36)

            Spacer()

            // 徽章大图标 — 呼吸节奏动画
            ZStack {
                // 外光晕（呼吸）
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 155, height: 155)
                    .scaleEffect(breatheScale)
                // 主圆（呼吸）
                Circle()
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 130, height: 130)
                    .scaleEffect(breatheScale)
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 2)
                    .frame(width: 130, height: 130)
                    .scaleEffect(breatheScale)
                Image(systemName: achievement.icon)
                    .font(.system(size: 58))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.5), radius: 10)
            }
            .padding(.bottom, 28)

            // 标题
            Text(achievement.localizedTitle)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

            // 描述
            Text(achievement.localizedDescription)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.88))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)

            // 击败百分比
            HStack(spacing: 6) {
                Text("🔥")
                Text(isEN
                    ? "Beat \(beatPct)% of runners"
                    : "击败了 \(beatPct)% 的跑者")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.22))
            .clipShape(Capsule())

            Spacer()

            // 底部日期 + App名
            VStack(spacing: 6) {
                if let date = achievement.unlockedAt {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar").font(.system(size: 12))
                        Text((isEN ? "Unlocked on " : "解锁于 ") + formatDate(date, isEN: isEN))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.65))
                }
                HStack(spacing: 5) {
                    Image(systemName: "figure.run").font(.system(size: 13))
                    Text("AIRunningCoach")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.85))
            }
            .padding(.bottom, 32)
        }
    }

    // ── 背面（真实跑步数据统计）──
    private var backContent: some View {
        VStack(spacing: 0) {
            // 标题
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.localizedTitle)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                Text(isEN ? "Stats" : "数据统计")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.70))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 40)
            .padding(.bottom, 20)

            // 4格真实数据
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                statCell(
                    label: isEN ? "Distance" : "距离",
                    value: totalDistanceStr,
                    unit: isEN ? "km" : "公里"
                )
                statCell(
                    label: isEN ? "Time" : "用时",
                    value: totalDurationStr,
                    unit: ""
                )
                statCell(
                    label: isEN ? "Pace" : "配速",
                    value: achievementPaceStr,
                    unit: isEN ? "min/km" : "分/公里"
                )
                statCell(
                    label: isEN ? "Beat" : "击败跑者",
                    value: "\(beatPct)",
                    unit: "%"
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // 配速曲线（有跑步记录就显示）
            VStack(alignment: .leading, spacing: 8) {
                Text(paceChartTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.80))
                if paceHistory.count >= 2 {
                    paceLineChart
                        .frame(height: 72)
                } else if paceHistory.count == 1 {
                    // 只有1次记录：显示单点 + 提示
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                        Text(isEN ? "1 run logged — keep going!" : "已有1次记录，继续跑步解锁趋势图")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 40)
                } else {
                    Text(isEN ? "Complete a run to see your pace trend" : "完成跑步后查看配速趋势")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.60))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 40)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)

            Spacer()

            // 底部
            HStack(spacing: 5) {
                Image(systemName: "figure.run").font(.system(size: 13))
                Text("AIRunningCoach").font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.8))
            .padding(.bottom, 32)
        }
    }

    // 配速折线图（Canvas 绘制，兼容 ImageRenderer）
    private var paceLineChart: some View {
        let data = paceHistory
        return Canvas { ctx, size in
            guard data.count >= 2 else { return }
            let minP = (data.min() ?? 4.0) - 0.3
            let maxP = (data.max() ?? 8.0) + 0.3
            let range = maxP - minP
            guard range > 0 else { return }

            let stepX = size.width / CGFloat(data.count - 1)

            func point(at i: Int) -> CGPoint {
                CGPoint(
                    x: CGFloat(i) * stepX,
                    y: size.height * CGFloat(1.0 - (data[i] - minP) / range)
                )
            }

            // 填充区域
            var fillPath = Path()
            fillPath.move(to: point(at: 0))
            for i in 1..<data.count { fillPath.addLine(to: point(at: i)) }
            fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
            fillPath.addLine(to: CGPoint(x: 0, y: size.height))
            fillPath.closeSubpath()
            ctx.fill(fillPath, with: .color(.white.opacity(0.15)))

            // 折线
            var linePath = Path()
            linePath.move(to: point(at: 0))
            for i in 1..<data.count { linePath.addLine(to: point(at: i)) }
            ctx.stroke(linePath, with: .color(.white), lineWidth: 2.5)

            // 数据点
            for i in 0..<data.count {
                let p = point(at: i)
                let dot = CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)
                ctx.fill(Path(ellipseIn: dot), with: .color(.white))
                // 最后一点（最新跑步）用稍大高亮圆
                if i == data.count - 1 {
                    let ring = CGRect(x: p.x - 7, y: p.y - 7, width: 14, height: 14)
                    let ringPath = Path(ellipseIn: ring)
                    ctx.stroke(ringPath, with: .color(.white.opacity(0.6)), lineWidth: 1.5)
                }
            }
        }
    }

    private func statCell(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.68))
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(unit)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 计算属性（真实跑步数据）

    // 找到解锁该成就时对应的跑步记录（时间最接近 unlockedAt 的那条）
    private var unlockingRun: RunRecord? {
        guard let unlockedAt = achievement.unlockedAt, !runRecords.isEmpty else { return runRecords.first }
        return runRecords.min(by: {
            abs($0.startTime.timeIntervalSince(unlockedAt)) < abs($1.startTime.timeIntervalSince(unlockedAt))
        })
    }

    // 配速图数据：
    // 优先用解锁跑步的 kmSplits（每公里分段用时→分/公里），展示本次跑步内部配速变化
    // 不足时降级为最近7次跑步的平均配速趋势
    private var paceHistory: [Double] {
        if let splits = unlockingRun?.kmSplits, splits.count >= 2 {
            return splits.map { $0 / 60.0 }  // 秒 → 分/公里
        }
        return runRecords.prefix(7).reversed().compactMap { $0.pace > 0 ? $0.pace : nil }
    }

    // 图表标题：有分段用"配速曲线"，跨次用"配速进步曲线"
    private var paceChartTitle: String {
        if let splits = unlockingRun?.kmSplits, splits.count >= 2 {
            return isEN ? "Pace per km" : "配速曲线"
        }
        return isEN ? "Pace Trend" : "配速进步曲线"
    }

    // 解锁时那次跑步的距离（千米）
    private var totalDistanceStr: String {
        let km = (unlockingRun?.distance ?? 0) / 1000.0
        if km >= 100 { return String(format: "%.0f", km) }
        return String(format: "%.1f", km)
    }

    // 解锁时那次跑步的用时（h:mm:ss 或 mm:ss）
    private var totalDurationStr: String {
        let total = Int(unlockingRun?.duration ?? 0)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    // 配速：取解锁跑步的实际配速（RunRecord.pace 单位：分/公里）
    // 对于配速成就，用户跑出的实际配速比目标门槛更能体现成就（如 5'09" 优于门槛 6'00"）
    private var achievementPaceStr: String {
        let pace = unlockingRun?.pace ?? 0
        guard pace > 0 else { return "--" }
        let m = Int(pace)
        let s = Int((pace - Double(m)) * 60)
        return String(format: "%d'%02d\"", m, s)
    }

    // 击败百分比（基于成就进度估算）
    private var beatPct: Int {
        let p = achievement.progress
        switch achievement.category {
        case .pace:               return Int(min(p * 92, 96))
        case .distance:           return Int(min(p * 86, 95))
        case .duration:           return Int(min(p * 82, 93))
        case .frequency:          return Int(min(p * 88, 95))
        case .calories:           return Int(min(p * 84, 94))
        case .special, .milestone: return Int(min(p * 93, 98))
        }
    }
}

// MARK: - 辅助函数

private func formatDate(_ date: Date, isEN: Bool) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: isEN ? "en_US" : "zh_CN")
    f.dateFormat = isEN ? "MMM d, yyyy" : "yyyy年M月d日"
    return f.string(from: date)
}

// MARK: - UIKit 系统分享面板

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    AchievementShareView(achievement: Achievement.allAchievements[0])
}
