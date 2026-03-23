//
//  HelpGuideView.swift
//  AI跑步教练
//
//  App 使用说明
//

import SwiftUI

struct HelpGuideView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var showFeedback = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // 欢迎语
                    VStack(spacing: 8) {
                        Text("🏃")
                            .font(.system(size: 48))
                        Text("AI跑步教练使用指南")
                            .font(.system(size: 20, weight: .bold))
                        Text("5分钟上手，轻松开始跑步之旅")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                    // 功能卡片
                    HelpCard(
                        emoji: "▶️",
                        title: "开始跑步",
                        steps: [
                            "点击首页大绿按钮「开始跑步」",
                            "允许定位权限，GPS 开始追踪路线",
                            "跑步过程中语音教练自动播报里程进度",
                            "到达目标距离或手动长按「结束」按钮停止",
                            "结束后查看配速、卡路里、AI 教练分析"
                        ]
                    )

                    HelpCard(
                        emoji: "📋",
                        title: "AI 训练计划",
                        steps: [
                            "点击底部「计划」标签进入训练计划页",
                            "首次使用点击「生成训练计划」",
                            "选择训练目标（3km / 5km / 减肥 等）",
                            "选择每周训练天数和训练强度",
                            "3秒内看到计划，AI 在后台自动优化（约15秒）",
                            "每天按计划完成对应训练任务"
                        ]
                    )

                    HelpCard(
                        emoji: "🎙️",
                        title: "语音教练",
                        steps: [
                            "跑步全程自动语音陪伴，无需看屏幕",
                            "每个里程碑（500m、1km、2km…）自动播报",
                            "到达今日目标距离时播报完成庆祝语音",
                            "跑步结束后播报 AI 教练总结分析",
                            "右上角麦克风图标可随时开关语音"
                        ]
                    )

                    HelpCard(
                        emoji: "🏆",
                        title: "成就系统",
                        steps: [
                            "跑步数据自动检测，达成条件即时解锁",
                            "涵盖距离、配速、次数、连续打卡等维度",
                            "解锁成就时语音播报庆祝",
                            "点击「我的」→「成就」查看全部成就",
                            "每个成就可点击分享给朋友"
                        ]
                    )

                    HelpCard(
                        emoji: "📊",
                        title: "跑步历史",
                        steps: [
                            "点击底部「历史」查看所有跑步记录",
                            "每条记录包含地图轨迹、配速、卡路里",
                            "点击记录查看详情",
                            "可删除不需要的记录"
                        ]
                    )

                    // 免费 vs Pro
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("🆓 免费 vs 👑 Pro")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                        }

                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("免费版")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                ForEach(freeFeatures, id: \.self) { item in
                                    Label(LocalizedStringKey(item), systemImage: "checkmark")
                                        .font(.system(size: 12))
                                        .foregroundColor(.primary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Pro 会员")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11))
                                ForEach(proFeatures, id: \.self) { item in
                                    Label(LocalizedStringKey(item), systemImage: "checkmark.seal.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .padding(.horizontal, 16)

                    // 意见反馈
                    VStack(spacing: 10) {
                        Text("意见反馈")
                            .font(.system(size: 14, weight: .semibold))
                        Text("你的反馈是我们进步的动力")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Button {
                            showFeedback = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "envelope.fill")
                                Text("发送反馈意见")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.49, green: 0.84, blue: 0.11))
                            .cornerRadius(10)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("使用指南")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFeedback) {
                FeedbackView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(Color(red: 0.49, green: 0.84, blue: 0.11))
                }
            }
        }
    }

    private let freeFeatures = [
        "无限次跑步记录",
        "GPS 跑步追踪",
        "时间里程碑语音播报",
        "AI 训练计划（每月2次）",
        "跑后 AI 教练反馈",
        "成就系统（部分）"
    ]
    private let proFeatures = [
        "心率区间实时播报",
        "卡路里消耗实时播报",
        "配速变化智能提醒",
        "个人距离记录突破播报",
        "AI 训练计划（无限制）",
        "全部成就徽章",
        "云端同步",
        "优先客服支持"
    ]
}

// MARK: - HelpCard

private struct HelpCard: View {
    let emoji: String
    let title: String
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 20))
                Text(LocalizedStringKey(title))
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color(red: 0.49, green: 0.84, blue: 0.11))
                            .clipShape(Circle())
                        Text(LocalizedStringKey(step))
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
}

#Preview {
    HelpGuideView()
}
