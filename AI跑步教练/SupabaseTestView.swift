//
//  SupabaseTestView.swift
//  AI跑步教练
//
//  Created by 周晓红 on 2026/1/21.
//

import SwiftUI
import Supabase

// 在 View 外部初始化 Supabase 客户端
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://aisgbqzksfzdlbjdcwpn.supabase.co")!,
    supabaseKey: "sb_publishable_Mr8yLtY7MDtlWReRFidL3w_Jn_Kswgl"
)

struct SupabaseTestView: View {
    @State private var connectionStatus: ConnectionStatus = .notTested
    @State private var logMessage: String = "点击按钮开始测试连接..."
    @State private var isTesting: Bool = false

    enum ConnectionStatus {
        case notTested
        case success
        case failure
    }

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("Supabase 连接测试")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            // 状态图标
            statusIcon
                .font(.system(size: 80))
                .padding(.vertical, 20)

            // 日志文本框
            ScrollView {
                Text(logMessage)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 300)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)

            // 测试连接按钮
            Button(action: testConnection) {
                HStack {
                    if isTesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isTesting ? "测试中..." : "测试连接")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isTesting ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isTesting)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    // 状态图标视图
    @ViewBuilder
    private var statusIcon: some View {
        switch connectionStatus {
        case .notTested:
            Image(systemName: "questionmark.circle")
                .foregroundColor(.gray)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failure:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
        }
    }

    // 测试连接函数
    private func testConnection() {
        isTesting = true
        logMessage = "开始测试连接...\n"
        logMessage += "URL: https://aisgbqzksfzdlbjdcwpn.supabase.co\n"
        logMessage += "正在尝试查询不存在的表...\n\n"

        Task {
            do {
                // 使用 v2.0 语法：故意查询一个不存在的表
                _ = try await supabase
                    .from("non_existent_table")
                    .select()
                    .execute()

                // 如果没有抛出错误（不太可能），说明表存在
                await MainActor.run {
                    connectionStatus = .success
                    logMessage += "⚠️ 查询成功，但表存在（这不应该发生）\n"
                    isTesting = false
                }
            } catch {
                // 分析错误信息
                let errorMessage = error.localizedDescription
                logMessage += "收到错误响应：\n\(errorMessage)\n\n"

                await MainActor.run {
                    // 判断错误类型
                    if errorMessage.contains("PGRST") ||
                       errorMessage.contains("PGRST205") ||
                       errorMessage.contains("Could not find the table") ||
                       errorMessage.contains("relation") && errorMessage.contains("does not exist") {
                        // 这些错误说明服务器正常响应，只是表不存在
                        connectionStatus = .success
                        logMessage += "✅ 连接成功（服务器已响应）\n"
                        logMessage += "说明：收到 PostgreSQL 错误响应，证明已成功连接到 Supabase 数据库"
                    } else if errorMessage.contains("hostname") ||
                              errorMessage.contains("URL") ||
                              errorMessage.contains("NSURLErrorDomain") ||
                              errorMessage.contains("network") {
                        // 网络或 URL 错误
                        connectionStatus = .failure
                        logMessage += "❌ 连接失败：URL 错误或无网络\n"
                        logMessage += "请检查：\n"
                        logMessage += "1. 网络连接是否正常\n"
                        logMessage += "2. Supabase URL 是否正确\n"
                        logMessage += "3. 防火墙设置"
                    } else {
                        // 其他未知错误
                        connectionStatus = .failure
                        logMessage += "❌ 连接失败：未知错误\n"
                        logMessage += "错误详情：\n\(error)"
                    }

                    isTesting = false
                }
            }
        }
    }
}

#Preview {
    SupabaseTestView()
}
