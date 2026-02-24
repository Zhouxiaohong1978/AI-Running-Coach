import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var langMgr = LanguageManager.shared
    private var isEN: Bool { langMgr.currentLocale == "en" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    // Intro
                    bilingualCard(
                        sectionNumber: nil,
                        enTitle: nil, zhTitle: nil,
                        enContent: "This Privacy Policy explains how AI Running Coach collects, uses, and protects your personal information. By using the App, you agree to this policy.",
                        zhContent: "本隐私政策说明「AI跑步教练」如何收集、使用和保护您的个人信息。使用本App即表示您同意本政策。"
                    )

                    bilingualCard(
                        sectionNumber: "1",
                        enTitle: "Information We Collect", zhTitle: "我们收集哪些信息",
                        enBullets: [
                            ("Location", "GPS records route and distance during runs only. Never tracked in background."),
                            ("Activity Data", "Distance, pace, calories — stored locally on device."),
                            ("Account Info", "Email address for login and account recovery."),
                            ("Usage Data", "Plan generation counts for free quota management.")
                        ],
                        zhBullets: [
                            ("位置信息", "跑步时使用 GPS，不在后台持续获取。"),
                            ("运动数据", "距离、配速、卡路里，存储在本地设备。"),
                            ("账户信息", "邮箱地址，用于登录和账户找回。"),
                            ("使用数据", "计划生成次数，用于免费配额管理。")
                        ]
                    )

                    bilingualCard(
                        sectionNumber: "2",
                        enTitle: "How We Use It", zhTitle: "如何使用信息",
                        enBullets: [
                            (nil, "Provide run tracking and training plans"),
                            (nil, "Generate personalized AI training advice"),
                            (nil, "Manage subscriptions and free quotas"),
                            (nil, "Improve App features and experience")
                        ],
                        zhBullets: [
                            (nil, "提供跑步追踪和训练计划功能"),
                            (nil, "生成 AI 个性化训练建议"),
                            (nil, "管理订阅状态和免费使用配额"),
                            (nil, "改善 App 功能和用户体验")
                        ]
                    )

                    bilingualCard(
                        sectionNumber: "3",
                        enTitle: "Information Sharing", zhTitle: "信息共享",
                        enContent: "We do not sell your data. Third-party sharing only:",
                        zhContent: "我们不出售您的数据。仅在以下情况下共享：",
                        enBullets: [
                            ("RevenueCat", "Subscription processing — anonymous ID only."),
                            ("Alibaba Cloud", "AI plan generation — training goals only, no identity info.")
                        ],
                        zhBullets: [
                            ("RevenueCat", "处理订阅，仅共享匿名用户 ID。"),
                            ("阿里云百炼", "生成 AI 计划，仅发送训练目标，不含身份信息。")
                        ]
                    )

                    bilingualCard(
                        sectionNumber: "4",
                        enTitle: "Data Security", zhTitle: "数据安全",
                        enContent: "Run data is stored locally on your device. Account info is encrypted in transit. We take reasonable measures to prevent unauthorized access.",
                        zhContent: "跑步数据主要存储在本地设备。账户信息通过加密传输，我们采取合理措施防止未经授权的访问。"
                    )

                    bilingualCard(
                        sectionNumber: "5",
                        enTitle: "Your Rights", zhTitle: "您的权利",
                        enBullets: [
                            (nil, "Delete account and all data in App Settings at any time"),
                            (nil, "Revoke location permission (affects run tracking)"),
                            (nil, "Email us to request data access or deletion")
                        ],
                        zhBullets: [
                            (nil, "随时在 App 设置中删除账户及所有数据"),
                            (nil, "关闭位置权限（将影响跑步追踪功能）"),
                            (nil, "通过邮件联系我们请求查阅或删除数据")
                        ]
                    )

                    bilingualCard(
                        sectionNumber: "6",
                        enTitle: "Children's Privacy", zhTitle: "儿童隐私",
                        enContent: "The App is not directed at children under 13. We do not knowingly collect information from children.",
                        zhContent: "本App不面向13岁以下儿童，我们不会有意收集儿童的个人信息。"
                    )

                    // Contact
                    contactCard()

                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .navigationTitle(isEN ? "Privacy Policy" : "隐私政策")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEN ? "Done" : "完成") { dismiss() }
                        .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20))
                }
            }
        }
    }

    // MARK: - Components

    @ViewBuilder
    private func bilingualCard(
        sectionNumber: String?,
        enTitle: String?, zhTitle: String?,
        enContent: String? = nil, zhContent: String? = nil,
        enBullets: [(String?, String?)] = [],
        zhBullets: [(String?, String?)] = []
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let n = sectionNumber, let et = enTitle, let zt = zhTitle {
                Text("\(n). \(et) · \(zt)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20))
            }

            HStack(alignment: .top, spacing: 12) {
                // English
                VStack(alignment: .leading, spacing: 6) {
                    langBadge("EN")
                    if let t = enContent {
                        Text(t).font(.system(size: 13)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(Array(enBullets.enumerated()), id: \.offset) { _, item in
                        bulletRow(bold: item.0, text: item.1 ?? "")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Chinese
                VStack(alignment: .leading, spacing: 6) {
                    langBadge("中")
                    if let t = zhContent {
                        Text(t).font(.system(size: 13)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(Array(zhBullets.enumerated()), id: \.offset) { _, item in
                        bulletRow(bold: item.0, text: item.1 ?? "")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6)
    }

    @ViewBuilder
    private func contactCard() -> some View {
        VStack(spacing: 10) {
            Text("Contact Us · 联系我们")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20))
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

    @ViewBuilder
    private func bulletRow(bold: String?, text: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text("•").font(.system(size: 13)).foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20))
            Group {
                if let b = bold {
                    Text(b).fontWeight(.semibold) + Text("：\(text)")
                } else {
                    Text(text)
                }
            }
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
