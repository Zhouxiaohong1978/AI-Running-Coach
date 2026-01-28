//
//  HistoryView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI
import MapKit

struct HistoryView: View {
    @StateObject private var dataManager = RunDataManager.shared
    @State private var selectedRecord: RunRecord?
    @State private var showDetailView = false

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 自定义标题栏
                HStack {
                    Text("历史记录")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    if dataManager.isLoading || dataManager.isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 12)

                if dataManager.runRecords.isEmpty {
                    // 空状态
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("还没有跑步记录")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("开始你的第一次跑步吧！")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            // 统计卡片
                            StatsSummaryCard(dataManager: dataManager)
                                .padding(.horizontal)

                            // 记录列表
                            LazyVStack(spacing: 12) {
                                ForEach(dataManager.runRecords) { record in
                                    RunRecordCard(record: record)
                                        .onTapGesture {
                                            selectedRecord = record
                                            showDetailView = true
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showDetailView) {
            if let record = selectedRecord {
                HistoryDetailView(runRecord: record)
            }
        }
    }
}

// MARK: - Stats Summary Card

struct StatsSummaryCard: View {
    @ObservedObject var dataManager: RunDataManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("总计")
                .font(.system(size: 18, weight: .bold))

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("总距离")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", dataManager.getTotalDistance() / 1000)) km")
                        .font(.system(size: 20, weight: .bold))
                }

                Divider()
                    .frame(height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("总时长")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(formatTotalDuration(dataManager.getTotalDuration()))
                        .font(.system(size: 20, weight: .bold))
                }

                Divider()
                    .frame(height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("总次数")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("\(dataManager.runRecords.count)")
                        .font(.system(size: 20, weight: .bold))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }

    private func formatTotalDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Run Record Card

struct RunRecordCard: View {
    let record: RunRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 日期和时间
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(record.startTime))
                        .font(.system(size: 16, weight: .semibold))

                    Text(formatTime(record.startTime))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 云同步状态
                if record.syncedToCloud {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                }
            }

            Divider()

            // 统计数据
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("距离")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.2f", record.distance / 1000)) km")
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("时长")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(formatDuration(record.duration))
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("配速")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(formatPace(record.pace))
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func formatPace(_ pace: Double) -> String {
        guard pace > 0, pace.isFinite else { return "0'00\"" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return "\(minutes)'\(String(format: "%02d", seconds))\""
    }
}

#Preview {
    HistoryView()
}
