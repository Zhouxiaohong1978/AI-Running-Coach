import SwiftUI

struct TermsOfUseView: View {
    @Environment(\.dismiss) private var dismiss
    private var isEN: Bool { LanguageManager.shared.currentLocale == "en" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text(isEN ? "Terms of Use (EULA)" : "使用条款 (EULA)")
                        .font(.title2.bold())
                        .padding(.bottom, 4)

                    Text(isEN ? "Last updated: February 2026" : "最后更新：2026年2月")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    section(
                        title: isEN ? "1. Acceptance" : "1. 接受条款",
                        content: isEN
                            ? "By downloading or using AI Running Coach, you agree to these Terms of Use and Apple's Standard End User License Agreement (EULA). If you do not agree, do not use the app."
                            : "下载或使用「AI跑步教练」即表示您同意本使用条款及 Apple 标准最终用户许可协议 (EULA)。如不同意，请勿使用本应用。"
                    )

                    section(
                        title: isEN ? "2. Subscriptions" : "2. 订阅服务",
                        content: isEN
                            ? """
AI Running Coach Pro is available as an auto-renewable subscription:
• Monthly or Annual plans available
• Payment is charged to your Apple ID account at confirmation of purchase
• Subscription automatically renews unless cancelled at least 24 hours before the end of the current period
• Your account will be charged for renewal within 24 hours prior to the end of the current period
• You can manage and cancel subscriptions in your Apple ID account settings
• Any unused portion of a free trial period will be forfeited when purchasing a subscription
"""
                            : """
AI跑步教练 Pro 为自动续费订阅服务：
• 提供月度和年度订阅方案
• 确认购买时将向您的 Apple ID 账户收费
• 订阅将自动续费，除非在当前订阅期结束前至少24小时取消
• 系统将在当前订阅期结束前24小时内扣除续费款项
• 您可在 Apple ID 账户设置中管理和取消订阅
• 购买订阅后，免费试用期的剩余部分将作废
"""
                    )

                    section(
                        title: isEN ? "3. Health Disclaimer" : "3. 健康免责声明",
                        content: isEN
                            ? "AI Running Coach provides general fitness guidance only. It is not a medical device and does not provide medical advice. Always consult a physician before starting any exercise program. Use the app at your own risk."
                            : "「AI跑步教练」仅提供一般健身指导，非医疗设备，不提供医疗建议。开始任何运动计划前请咨询医生。使用本应用的风险由用户自行承担。"
                    )

                    section(
                        title: isEN ? "4. User Conduct" : "4. 用户行为",
                        content: isEN
                            ? "You agree to use the app only for lawful purposes and in accordance with these terms. You are responsible for all activity under your account."
                            : "您同意仅将本应用用于合法目的，并遵守本条款。您对账户下的所有活动负责。"
                    )

                    section(
                        title: isEN ? "5. Intellectual Property" : "5. 知识产权",
                        content: isEN
                            ? "All content, features, and functionality of the app are owned by the developer and protected by copyright and other intellectual property laws."
                            : "本应用的所有内容、功能均归开发者所有，受版权及其他知识产权法律保护。"
                    )

                    section(
                        title: isEN ? "6. Limitation of Liability" : "6. 责任限制",
                        content: isEN
                            ? "To the fullest extent permitted by law, the developer shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the app."
                            : "在法律允许的最大范围内，开发者对因使用本应用而产生的任何间接、附带、特殊或后果性损害不承担责任。"
                    )

                    section(
                        title: isEN ? "7. Changes to Terms" : "7. 条款变更",
                        content: isEN
                            ? "We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the updated terms."
                            : "我们可能不时更新本条款。条款变更后继续使用本应用即视为接受更新后的条款。"
                    )

                    section(
                        title: isEN ? "8. Contact" : "8. 联系方式",
                        content: isEN
                            ? "For questions about these terms, contact us at: 1614103587@qq.com"
                            : "如对本条款有疑问，请联系：1614103587@qq.com"
                    )

                    // Apple 标准 EULA 链接
                    Link(
                        destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
                    ) {
                        Text(isEN ? "Apple Standard EULA" : "Apple 标准最终用户许可协议")
                            .font(.system(size: 13))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .navigationTitle(isEN ? "Terms of Use" : "使用条款")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func section(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            Text(content)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    TermsOfUseView()
}
