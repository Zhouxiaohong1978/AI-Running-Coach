//
//  PaywallView.swift
//  AI跑步教练
//
//  Pro 付费墙界面
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 标题
                        headerSection

                        // 稀缺感横幅
                        scarcityBanner

                        // Free vs Pro 对比
                        comparisonSection

                        // 套餐选择
                        packageSection

                        // CTA 按钮
                        purchaseButton

                        // 恢复购买 + 条款
                        footerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert("购买失败", isPresented: $showError) {
                Button("确定") {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                // 默认选择年订阅
                if let offering = subscriptionManager.currentOffering {
                    selectedPackage = offering.annual ?? offering.monthly
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("解锁 AI 跑步教练 Pro")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)

            Text("无限 AI 训练计划 · 实时教练反馈 · 全部成就")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }

    // MARK: - Scarcity Banner

    private var scarcityBanner: some View {
        Group {
            if hasIntroductoryOffer {
                HStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.white)
                    Text("前 1000 名用户专属价")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
        }
    }

    /// 是否有 introductory offer
    private var hasIntroductoryOffer: Bool {
        guard let offering = subscriptionManager.currentOffering else { return false }
        let annual = offering.annual
        return annual?.storeProduct.introductoryDiscount != nil
    }

    // MARK: - Comparison Section

    private var comparisonSection: some View {
        VStack(spacing: 0) {
            // 表头
            HStack {
                Text("功能")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("免费")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 70)
                Text("Pro")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                    .frame(width: 70)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            comparisonRow("AI 训练计划", free: "每月1次", pro: "无限制")
            comparisonRow("AI 教练反馈", free: "每次3条", pro: "无限制")
            comparisonRow("语音播报", free: "基础", pro: "完整")
            comparisonRow("云端同步", free: "—", pro: "✓")
            comparisonRow("成就系统", free: "10个", pro: "全部")
            comparisonRow("高级统计", free: "—", pro: "✓")
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
    }

    private func comparisonRow(_ feature: String, free: String, pro: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(feature)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(free)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 70)
                Text(pro)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                    .frame(width: 70)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()
                .padding(.leading, 16)
        }
    }

    // MARK: - Package Section

    private var packageSection: some View {
        VStack(spacing: 12) {
            if let offering = subscriptionManager.currentOffering {
                // 年订阅
                if let annual = offering.annual {
                    packageCard(
                        package: annual,
                        title: "年订阅",
                        badge: savingsBadge(offering: offering),
                        isSelected: selectedPackage?.identifier == annual.identifier
                    )
                }

                // 月订阅
                if let monthly = offering.monthly {
                    packageCard(
                        package: monthly,
                        title: "月订阅",
                        badge: nil,
                        isSelected: selectedPackage?.identifier == monthly.identifier
                    )
                }
            } else {
                // 加载中
                ProgressView("加载套餐中...")
                    .padding()
            }
        }
    }

    private func packageCard(package: Package, title: String, badge: String?, isSelected: Bool) -> some View {
        Button {
            selectedPackage = package
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }

                    // 显示 introductory offer 价格
                    if let intro = package.storeProduct.introductoryDiscount {
                        Text("首发价 \(intro.localizedPriceString)/\(periodText(intro.subscriptionPeriod))")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }

                    Text(package.localizedPriceString + "/" + packagePeriodText(package))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    // 免费试用
                    if package.storeProduct.introductoryDiscount?.paymentMode == .freeTrial {
                        Text("7 天免费试用")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(red: 0.5, green: 0.8, blue: 0.1) : .gray)
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(red: 0.5, green: 0.8, blue: 0.1) : Color.clear, lineWidth: 2)
            )
        }
    }

    private func savingsBadge(offering: Offering) -> String? {
        guard let annual = offering.annual,
              let monthly = offering.monthly else { return nil }

        let monthlyPrice = monthly.storeProduct.price as Decimal
        let annualPrice = annual.storeProduct.price as Decimal
        let annualMonthly = annualPrice / 12

        guard monthlyPrice > 0 else { return nil }
        let savings = ((monthlyPrice - annualMonthly) / monthlyPrice * 100) as NSDecimalNumber
        let savingsInt = savings.intValue
        return savingsInt > 0 ? "省 \(savingsInt)%" : nil
    }

    private func packagePeriodText(_ package: Package) -> String {
        switch package.packageType {
        case .monthly: return "月"
        case .annual: return "年"
        default: return ""
        }
    }

    private func periodText(_ period: SubscriptionPeriod) -> String {
        switch period.unit {
        case .month: return "月"
        case .year: return "年"
        case .week: return "周"
        case .day: return "天"
        @unknown default: return ""
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            guard let package = selectedPackage else { return }
            isPurchasing = true
            Task {
                do {
                    try await subscriptionManager.purchase(package: package)
                    isPurchasing = false
                    if subscriptionManager.isPro {
                        dismiss()
                    }
                } catch {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(purchaseButtonText)
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(red: 0.5, green: 0.8, blue: 0.1))
            .cornerRadius(14)
        }
        .disabled(selectedPackage == nil || isPurchasing)
    }

    private var purchaseButtonText: String {
        guard let package = selectedPackage else { return "选择套餐" }

        if package.storeProduct.introductoryDiscount?.paymentMode == .freeTrial {
            return "7 天免费试用，然后 \(package.localizedPriceString)/\(packagePeriodText(package))"
        }

        return "订阅 \(package.localizedPriceString)/\(packagePeriodText(package))"
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 12) {
            Button {
                isPurchasing = true
                Task {
                    do {
                        try await subscriptionManager.restore()
                        isPurchasing = false
                        if subscriptionManager.isPro {
                            dismiss()
                        }
                    } catch {
                        isPurchasing = false
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            } label: {
                Text("恢复购买")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }

            HStack(spacing: 16) {
                Button {
                    // TODO: 打开隐私政策
                } label: {
                    Text("隐私政策")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Text("·")
                    .foregroundColor(.secondary)

                Button {
                    // TODO: 打开服务条款
                } label: {
                    Text("服务条款")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Text("订阅将自动续费，可随时在系统设置中取消")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    PaywallView()
}
