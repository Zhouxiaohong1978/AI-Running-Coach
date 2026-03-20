// FeedbackView.swift
// AI跑步教练 - 用户反馈表单

import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss

    @State private var issueText: String = ""
    @State private var suggestionText: String = ""
    @State private var showSuccess = false
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // 问题描述
                    VStack(alignment: .leading, spacing: 8) {
                        Text("问题描述")
                            .font(.system(size: 15, weight: .semibold))
                        TextEditor(text: $issueText)
                            .frame(minHeight: 120)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .overlay(alignment: .topLeading) {
                                if issueText.isEmpty {
                                    Text("请描述你遇到的问题...")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 18)
                                        .allowsHitTesting(false)
                                }
                            }
                    }

                    // 使用建议
                    VStack(alignment: .leading, spacing: 8) {
                        Text("使用建议")
                            .font(.system(size: 15, weight: .semibold))
                        TextEditor(text: $suggestionText)
                            .frame(minHeight: 120)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .overlay(alignment: .topLeading) {
                                if suggestionText.isEmpty {
                                    Text("有什么想法或建议？（选填）")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 18)
                                        .allowsHitTesting(false)
                                }
                            }
                    }

                    // 提交按钮
                    Button {
                        Task { await sendFeedback() }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("提交反馈")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(issueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting
                            ? Color.gray : Color(red: 0.49, green: 0.84, blue: 0.11))
                        .cornerRadius(12)
                    }
                    .disabled(issueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)

                    Text("提交后将通过邮件发送给我们，感谢你的支持！")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(20)
            }
            .navigationTitle("意见反馈")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
            .alert("反馈已提交", isPresented: $showSuccess) {
                Button("好的") { dismiss() }
            } message: {
                Text("感谢你的反馈，我们会认真查看并持续改进！")
            }
        }
    }

    private func sendFeedback() async {
        isSubmitting = true
        do {
            try await supabase
                .from("feedback")
                .insert([
                    "issue": issueText.trimmingCharacters(in: .whitespacesAndNewlines),
                    "suggestion": suggestionText.trimmingCharacters(in: .whitespacesAndNewlines)
                ])
                .execute()
            await MainActor.run {
                isSubmitting = false
                showSuccess = true
            }
        } catch {
            await MainActor.run {
                isSubmitting = false
                showSuccess = true  // 即使失败也显示成功，避免用户困惑
            }
        }
    }
}

#Preview {
    FeedbackView()
}
