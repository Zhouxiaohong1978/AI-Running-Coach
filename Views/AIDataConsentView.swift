//
//  AIDataConsentView.swift
//  AI跑步教练
//
//  AI数据共享授权弹窗 — 满足 Apple 5.1.1(i) / 5.1.2(i) 要求
//  首次使用 AI 功能前展示，用户明确同意后记录到 UserDefaults
//

import SwiftUI

struct AIDataConsentView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var langMgr = LanguageManager.shared
    private var isEN: Bool { langMgr.currentLocale == "en" }

    /// 用户点击同意后调用
    var onAgree: () -> Void
    /// 用户点击拒绝后调用
    var onDecline: () -> Void

    @State private var showPrivacyPolicy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 图标
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20))
                        .padding(.top, 24)

                    // 标题
                    Text(isEN ? "AI Feature Authorization" : "AI 功能数据授权")
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text(isEN
                         ? "To provide personalized AI coaching, this app sends your run data to a third-party AI service."
                         : "为提供个性化 AI 训练指导，本 App 需要将您的跑步数据发送至第三方 AI 服务。")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    // 发送数据明细
                    dataCard

                    // 接收方
                    recipientCard

                    // 说明
                    noteCard

                    // 隐私政策链接
                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        Text(isEN ? "View Full Privacy Policy" : "查看完整隐私政策")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20))
                            .underline()
                    }

                    // 操作按钮
                    VStack(spacing: 12) {
                        Button {
                            UserDefaults.standard.set(true, forKey: "ai_data_consent_granted")
                            onAgree()
                            dismiss()
                        } label: {
                            Text(isEN ? "Agree & Continue" : "同意并继续")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.18, green: 0.49, blue: 0.20))
                                .cornerRadius(14)
                        }

                        Button {
                            onDecline()
                            dismiss()
                        } label: {
                            Text(isEN ? "Decline (AI features unavailable)" : "拒绝（AI 功能将不可用）")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEN ? "Close" : "关闭") {
                        onDecline()
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
    }

    // MARK: - 发送数据明细卡片

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(isEN ? "Data Sent to AI Service" : "发送至 AI 服务的数据",
                  systemImage: "arrow.up.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20))

            let items: [(String, String)] = isEN ? [
                ("figure.run", "Running data: pace, distance, duration"),
                ("heart.fill",  "Heart rate (when available)"),
                ("target",      "Training goal (e.g., 5K, half marathon)"),
                ("chart.bar",   "Historical run count & total distance"),
                ("speaker.wave.2", "Coaching text for AI voice generation")
            ] : [
                ("figure.run", "跑步数据：配速、距离、时长"),
                ("heart.fill",  "心率数据（如有 Apple Watch）"),
                ("target",      "训练目标（如 5公里、半马等）"),
                ("chart.bar",   "历史跑步次数和累计里程"),
                ("speaker.wave.2", "教练语音文本（用于 AI 语音合成）")
            ]

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: item.0)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20))
                        .frame(width: 16)
                    Text(item.1)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6)
    }

    // MARK: - 接收方卡片

    private var recipientCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(isEN ? "Data Recipients" : "数据接收方",
                  systemImage: "building.2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 8) {
                recipientRow(
                    name: isEN ? "Alibaba Cloud Bailian (DashScope)" : "阿里云百炼 (DashScope)",
                    purpose: isEN
                        ? "AI training plan generation & real-time coaching feedback"
                        : "AI 训练计划生成 & 实时语音教练反馈",
                    policyURL: isEN
                        ? "https://www.alibabacloud.com/help/en/legal/latest/alibaba-cloud-international-website-privacy-policy"
                        : "https://terms.aliyun.com/legal-agreement/terms/suit_bu1_ali_cloud/suit_bu1_ali_cloud202112071754_83380.html"
                )

                Divider()

                recipientRow(
                    name: "RevenueCat",
                    purpose: isEN
                        ? "Subscription management (anonymous ID only, no run data)"
                        : "订阅管理（仅匿名 ID，不含跑步数据）",
                    policyURL: "https://www.revenuecat.com/privacy"
                )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6)
    }

    @ViewBuilder
    private func recipientRow(name: String, purpose: String, policyURL: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: 13, weight: .semibold))
            Text(purpose)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            if let url = URL(string: policyURL) {
                Link(isEN ? "View Privacy Policy" : "查看隐私政策", destination: url)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20))
            }
        }
    }

    // MARK: - 说明卡片

    private var noteCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(.blue)
                .font(.system(size: 16))
            Text(isEN
                 ? "Your data is used only to generate personalized coaching content. It is not sold or used for advertising. You can withdraw consent anytime in Settings → Privacy."
                 : "您的数据仅用于生成个性化训练指导，不会被出售或用于广告。您可随时在「设置 → 隐私」中撤回授权。")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.blue.opacity(0.06))
        .cornerRadius(12)
    }
}

#Preview {
    AIDataConsentView(onAgree: {}, onDecline: {})
}
