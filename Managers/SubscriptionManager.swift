//
//  SubscriptionManager.swift
//  AI跑步教练
//
//  订阅状态管理（RevenueCat wrapper）
//

import Foundation
import RevenueCat

// MARK: - Pro Feature Types

enum ProFeature {
    case unlimitedPlans
    case unlimitedFeedback
    case advancedVoice
    case cloudSync
    case allAchievements
    case advancedStats
}

// MARK: - SubscriptionManager

@MainActor
final class SubscriptionManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = SubscriptionManager()

    // MARK: - Published Properties

    @Published var isPro: Bool = false
    @Published var currentOffering: Offering?

    // MARK: - Free Quota

    /// 本次跑步已用反馈数（跑步开始时重置）
    var freeRunFeedbackCount: Int = 0

    // MARK: - Free Achievement IDs

    static let freeAchievementIDs: Set<String> = [
        "distance_3km",
        "distance_5km",
        "duration_5hours",
        "frequency_3days",
        "frequency_7days",
        "calories_300",
        "calories_500",
        "pace_7min",
        "pace_6min",
        "special_morning_5times",
        "milestone_100km"
    ]

    // MARK: - Constants

    private let apiKey = "appl_UaMzrPLwFdaslCwUoWIxwdKqrum"
    private let entitlementID = "pro"
    private let planGenerationMonthKey = "planGenerationMonth"
    private let planGenerationCountKey = "planGenerationCount"
    private let totalRunCountKey = "totalRunCount"

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    /// App 启动时初始化 RevenueCat
    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)

        // 监听订阅状态变化
        Purchases.shared.delegate = self

        // 初始检查订阅状态
        Task {
            await checkSubscriptionStatus()
            await fetchOfferings()
        }

        print("✅ RevenueCat 初始化完成")
    }

    // MARK: - Subscription Status

    /// 检查订阅状态
    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isPro = customerInfo.entitlements[entitlementID]?.isActive == true
            print("📦 订阅状态: \(isPro ? "Pro" : "免费")")
        } catch {
            print("❌ 检查订阅状态失败: \(error.localizedDescription)")
        }
    }

    /// 获取当前 Offering
    private func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            print("📦 当前 Offering: \(currentOffering?.identifier ?? "无")")
        } catch {
            print("❌ 获取 Offering 失败: \(error.localizedDescription)")
        }
    }

    /// 外部主动触发重新拉取（PaywallView onAppear 时调用）
    func refreshOfferings() {
        Task {
            await fetchOfferings()
        }
    }

    // MARK: - Purchase

    /// 购买套餐
    func purchase(package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        isPro = result.customerInfo.entitlements[entitlementID]?.isActive == true
        print("✅ 购买完成, isPro: \(isPro)")
    }

    /// 恢复购买
    func restore() async throws {
        let customerInfo = try await Purchases.shared.restorePurchases()
        isPro = customerInfo.entitlements[entitlementID]?.isActive == true
        print("✅ 恢复购买完成, isPro: \(isPro)")
    }

    // MARK: - Free Quota Management

    /// 本月已生成计划数
    var freeMonthlyPlanCount: Int {
        get {
            let currentMonth = Calendar.current.component(.month, from: Date())
            let currentYear = Calendar.current.component(.year, from: Date())
            let storedMonth = UserDefaults.standard.integer(forKey: planGenerationMonthKey)

            // 编码年月为 yearMonth (如 202602)
            let currentYearMonth = currentYear * 100 + currentMonth
            if storedMonth != currentYearMonth {
                // 新月份，重置计数
                UserDefaults.standard.set(currentYearMonth, forKey: planGenerationMonthKey)
                UserDefaults.standard.set(0, forKey: planGenerationCountKey)
                return 0
            }

            return UserDefaults.standard.integer(forKey: planGenerationCountKey)
        }
        set {
            let currentMonth = Calendar.current.component(.month, from: Date())
            let currentYear = Calendar.current.component(.year, from: Date())
            let currentYearMonth = currentYear * 100 + currentMonth
            UserDefaults.standard.set(currentYearMonth, forKey: planGenerationMonthKey)
            UserDefaults.standard.set(newValue, forKey: planGenerationCountKey)
        }
    }

    /// 是否可以生成训练计划
    func canGeneratePlan() -> Bool {
        return isPro || freeMonthlyPlanCount < 2
    }

    /// 是否可以获取教练反馈
    func canGetFeedback() -> Bool {
        return isPro || freeRunFeedbackCount < 3
    }

    /// 生成计划后计数 +1
    func incrementPlanCount() {
        if !isPro {
            freeMonthlyPlanCount += 1
        }
    }

    /// 获取反馈后计数 +1
    func incrementFeedbackCount() {
        if !isPro {
            freeRunFeedbackCount += 1
        }
    }

    /// 重置跑步反馈计数（每次跑步开始时调用）
    func resetRunFeedbackCount() {
        freeRunFeedbackCount = 0
    }

    // MARK: - Paywall Triggers

    /// 累计跑步次数
    var totalRunCount: Int {
        get { UserDefaults.standard.integer(forKey: totalRunCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: totalRunCountKey) }
    }

    /// 第 15 次跑步后是否应显示 PaywallView
    func shouldShowPaywallAfterRun(runCount: Int) -> Bool {
        return !isPro && runCount >= 15
    }

    /// Pro 功能是否应显示 PaywallView
    func shouldShowPaywallForFeature(_ feature: ProFeature) -> Bool {
        return !isPro
    }

    // MARK: - Achievement Helpers

    /// 判断成就是否为免费成就
    func isAchievementFree(_ id: String) -> Bool {
        return Self.freeAchievementIDs.contains(id)
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        let isActive = customerInfo.entitlements["pro"]?.isActive == true
        Task { @MainActor in
            self.isPro = isActive
            print("📦 订阅状态更新: \(isActive ? "Pro" : "免费")")
        }
    }
}
