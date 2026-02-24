import SwiftUI

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var langMgr = LanguageManager.shared
    private var isEN: Bool { langMgr.currentLocale == "en" }

    private let faqs: [(enQ: String, zhQ: String, enA: String, zhA: String)] = [
        (
            "GPS inaccurate / Distance not updating",
            "GPS 定位不准 / 距离不更新",
            "Make sure location permission is \"While Using the App\". GPS is less accurate indoors — use in an open outdoor area.",
            "请确保已授权「使用期间允许」定位权限。室内 GPS 精度较低，建议在室外空旷地带使用。"
        ),
        (
            "No voice announcements",
            "语音播报没有声音",
            "Check the side silent switch is off and system volume is up. Confirm Bluetooth headphones are connected.",
            "请检查侧边静音开关是否关闭，并调高系统音量。使用蓝牙耳机时请确认已连接。"
        ),
        (
            "Training plan generation failed",
            "训练计划生成失败",
            "Plans require internet. Check your network and retry. Free: 1 plan/month. Pro: unlimited.",
            "训练计划由 AI 生成，需要网络连接。请检查网络后重试。免费用户每月 1 次，Pro 无限制。"
        ),
        (
            "How to cancel subscription",
            "如何取消订阅",
            "iPhone Settings → Your Name → Subscriptions → \"AI Running Coach\" → Cancel Subscription.",
            "iPhone「设置」→「你的姓名」→「订阅」→ 找到「AI跑步教练」→「取消订阅」。"
        ),
        (
            "Pro features not unlocked after purchase",
            "购买后无法解锁 Pro 功能",
            "Tap \"Restore Purchase\" on the Profile page to restore your Pro benefits.",
            "在 App 内「我的」页面点击「恢复购买」按钮即可恢复 Pro 权益。"
        ),
        (
            "Achievements or run records missing",
            "成就和跑步记录丢失",
            "Data is stored on your local device — do not uninstall. If lost, contact us for help.",
            "数据存储在本地设备，请勿卸载 App。若已丢失，请联系我们协助恢复。"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    // FAQ cards
                    ForEach(Array(faqs.enumerated()), id: \.offset) { _, faq in
                        VStack(alignment: .leading, spacing: 10) {
                            // Question
                            Text("\(faq.enQ) · \(faq.zhQ)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)

                            // Answer bilingual
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    langBadge("EN")
                                    Text(faq.enA)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Divider()

                                VStack(alignment: .leading, spacing: 4) {
                                    langBadge("中")
                                    Text(faq.zhA)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.05), radius: 6)
                    }

                    // Contact card
                    VStack(spacing: 10) {
                        Text("Contact Us · 联系我们")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20))
                        Text(isEN ? "Still need help? Email us within 1–2 business days." : "如以上内容未能解决问题，欢迎发邮件，1-2个工作日内回复。")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Text("1614103587@qq.com")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        Link(isEN ? "Send Email" : "发送邮件",
                             destination: URL(string: "mailto:1614103587@qq.com")!)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.18, green: 0.49, blue: 0.20))
                            .cornerRadius(22)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.05), radius: 6)

                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .navigationTitle(isEN ? "Technical Support" : "技术支持")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEN ? "Done" : "完成") { dismiss() }
                        .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20))
                }
            }
        }
    }

    @ViewBuilder
    private func langBadge(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(red: 0.18, green: 0.49, blue: 0.20).opacity(0.12))
            .cornerRadius(4)
    }
}

#Preview {
    SupportView()
}
