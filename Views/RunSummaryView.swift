//
//  RunSummaryView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI
import MapKit

struct RunSummaryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var dataManager = RunDataManager.shared
    var runRecord: RunRecord?

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var weeklyStats: [WeeklyRunStats] = []

    init(runRecord: RunRecord? = nil) {
        self.runRecord = runRecord

        if let record = runRecord,
           let firstCoord = record.routeCoordinates.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: firstCoord.toCLLocationCoordinate2D(),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Map Header
                    ZStack(alignment: .topLeading) {
                        Map(coordinateRegion: $region)
                            .frame(height: 250)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("跑步完成！")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.black)

                            Text(formatRunDate(runRecord?.startTime ?? Date()))
                                .font(.system(size: 14))
                                .foregroundColor(.black.opacity(0.6))
                        }
                        .padding(20)
                    }

                    // Achievement Banner
                    HStack(spacing: 12) {
                        Text("🏆")
                            .font(.system(size: 24))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("成就解锁！")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)

                            Text("早起的鸟儿：本次完成5次跑步。")
                                .font(.system(size: 12))
                                .foregroundColor(.black.opacity(0.6))
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.purple.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, -30)

                    // Stats Grid
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            StatCard(
                                icon: "location.fill",
                                iconColor: .blue,
                                label: "距离",
                                value: String(format: "%.2f", (runRecord?.distance ?? 0) / 1000.0),
                                unit: "km"
                            )

                            StatCard(
                                icon: "clock.fill",
                                iconColor: .orange,
                                label: "时间",
                                value: formatDuration(runRecord?.duration ?? 0),
                                unit: ""
                            )
                        }

                        HStack(spacing: 12) {
                            StatCard(
                                icon: "bolt.fill",
                                iconColor: .purple,
                                label: "平均配速",
                                value: formatPace(runRecord?.pace ?? 0),
                                unit: "/km"
                            )

                            StatCard(
                                icon: "flame.fill",
                                iconColor: .red,
                                label: "卡路里",
                                value: String(format: "%.0f", runRecord?.calories ?? 0),
                                unit: "kcal"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // AI Coach Insight
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                                .frame(width: 8, height: 8)

                            Text("AI教练建议")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.1))
                        }

                        Text("后半程配速保持得很好！你的耐力正在提升。下次可以尝试加入间歇冲刺来提高最大摄氧量。")
                            .font(.system(size: 15))
                            .foregroundColor(.black)
                            .lineSpacing(6)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.96, green: 0.98, blue: 0.88))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // 每周跑步里程柱状图
                    VStack(alignment: .leading, spacing: 16) {
                        Text("每周跑步里程")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)

                        if weeklyStats.isEmpty {
                            Text("暂无数据")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            HStack(alignment: .bottom, spacing: 12) {
                                ForEach(Array(weeklyStats.enumerated()), id: \.offset) { index, stat in
                                    WeekBar(
                                        distance: stat.totalDistance,
                                        weekLabel: ["第一周", "第二周", "第三周", "第四周", "第五周"][index]
                                    )
                                }
                            }
                            .frame(height: 220)
                        }
                    }
                    .padding(20)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer()
                        .frame(height: 120)
                }
            }

            // Bottom Buttons
            VStack {
                Spacer()

                HStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("关闭")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.5, green: 0.8, blue: 0.1))
                        .cornerRadius(12)
                    }

                    Button(action: {}) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("分享")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.5, green: 0.8, blue: 0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            calculateWeeklyStats()
        }
    }

    // MARK: - Weekly Stats Calculation

    /// 计算每周跑步统计
    private func calculateWeeklyStats() {
        let calendar = Calendar.current
        let now = Date()

        // 获取所有跑步记录
        let allRecords = dataManager.runRecords

        // 按周分组
        var weeklyData: [Int: Double] = [:]

        for record in allRecords {
            let weekOfYear = calendar.component(.weekOfYear, from: record.startTime)
            let year = calendar.component(.year, from: record.startTime)
            let weekKey = year * 100 + weekOfYear  // 组合年份和周数作为key

            weeklyData[weekKey, default: 0] += record.distance
        }

        // 获取当前周数
        let currentWeek = calendar.component(.weekOfYear, from: now)
        let currentYear = calendar.component(.year, from: now)

        // 生成最近5周的数据（包括当前周）
        var stats: [WeeklyRunStats] = []
        for i in 0..<5 {
            let targetWeek = currentWeek - (4 - i)
            let weekKey = currentYear * 100 + targetWeek

            let totalDistance = weeklyData[weekKey] ?? 0
            stats.append(WeeklyRunStats(
                weekNumber: targetWeek,
                totalDistance: totalDistance / 1000.0  // 转换为公里
            ))
        }

        weeklyStats = stats
    }

    // MARK: - Formatting

    private func formatPace(_ pace: Double) -> String {
        guard pace > 0, pace.isFinite else { return "0'00\"" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return "\(minutes)'\(String(format: "%02d", seconds))\""
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

    private func formatRunDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        let weekday = formatter.weekdaySymbols[Calendar.current.component(.weekday, from: date) - 1]
        let hour = Calendar.current.component(.hour, from: date)
        let timeOfDay: String
        if hour < 6 {
            timeOfDay = "凌晨跑"
        } else if hour < 12 {
            timeOfDay = "晨跑"
        } else if hour < 18 {
            timeOfDay = "午后跑"
        } else {
            timeOfDay = "晚跑"
        }

        formatter.dateFormat = "M月d日"
        let dateStr = formatter.string(from: date)

        return "\(weekday) \(timeOfDay) · \(dateStr)"
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 图标 + 标签（白底黑字）
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)

                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
            }

            // 数值和单位（绿色）
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Weekly Stats

/// 每周跑步统计
struct WeeklyRunStats {
    let weekNumber: Int
    let totalDistance: Double  // 公里
}

// MARK: - Week Bar (绿色柱状图)

struct WeekBar: View {
    let distance: Double  // 公里
    let weekLabel: String

    private var barHeight: CGFloat {
        // 根据距离计算柱高，最大20km对应180pt
        let maxDistance: Double = 20.0
        let maxHeight: CGFloat = 180.0
        let height = CGFloat(min(distance / maxDistance, 1.0)) * maxHeight
        return max(height, 20)  // 最小高度20pt
    }

    var body: some View {
        VStack(spacing: 8) {
            // 柱状图上方显示距离（绿色，带单位）
            Text(String(format: "%.1f公里", distance))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))

            // 绿色柱状图
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                .frame(height: barHeight)

            // 周标签（紫色）
            Text(weekLabel)
                .font(.system(size: 12))
                .foregroundColor(.purple)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    RunSummaryView()
}
