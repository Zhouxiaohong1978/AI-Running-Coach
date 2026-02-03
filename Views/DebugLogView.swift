// DebugLogView.swift
import SwiftUI

struct DebugLogView: View {
    @StateObject private var logger = DebugLogger.shared
    @State private var autoScroll = true

    var body: some View {
        VStack(spacing: 0) {
            // 顶部操作栏
            HStack {
                Text("运行日志")
                    .font(.headline)

                Spacer()

                Toggle("自动滚动", isOn: $autoScroll)
                    .toggleStyle(.switch)
                    .labelsHidden()

                Button(action: {
                    logger.clearLogs()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }

                ShareLink(item: logger.exportLogs()) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .padding()
            .background(Color(.systemGray6))

            // 日志内容
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(logger.logs.enumerated()), id: \.offset) { index, log in
                            Text(log)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(colorForLog(log))
                                .textSelection(.enabled)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .id(index)
                        }
                    }
                }
                .onChange(of: logger.logs.count) { _ in
                    if autoScroll && !logger.logs.isEmpty {
                        withAnimation {
                            proxy.scrollTo(logger.logs.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .navigationTitle("调试日志")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func colorForLog(_ log: String) -> Color {
        if log.contains("[ERROR]") || log.contains("❌") {
            return .red
        } else if log.contains("[WARN]") || log.contains("⚠️") {
            return .orange
        } else if log.contains("[SUCCESS]") || log.contains("✅") {
            return .green
        } else if log.contains("[VOICE]") || log.contains("🔊") || log.contains("📢") {
            return .blue
        } else if log.contains("[疲劳检测]") || log.contains("[心率区间]") {
            return .purple
        } else {
            return .primary
        }
    }
}

#Preview {
    NavigationStack {
        DebugLogView()
    }
}
