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
    var runRecord: RunRecord?

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var showDetailedStats = false

    init(runRecord: RunRecord? = nil) {
        self.runRecord = runRecord

        // 如果有轨迹数据，设置地图中心
        if let record = runRecord,
           let firstCoord = record.routeCoordinates.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: firstCoord.toCLLocationCoordinate2D(),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    var body: some View {
        NavigationView {
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
                                Text("GREAT RUN!")
                                    .font(.system(size: 28, weight: .black))
                                    .foregroundColor(.white)

                                Text(formatRunDate(runRecord?.startTime ?? Date()))
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
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
                                    .foregroundColor(.white)

                                Text("早起的鸟儿：本月完成5次晨跑。")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.8)],
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
                                    label: "DISTANCE",
                                    value: String(format: "%.2f", (runRecord?.distance ?? 0) / 1000.0),
                                    unit: "km"
                                )

                                StatCard(
                                    icon: "clock.fill",
                                    label: "TIME",
                                    value: formatDuration(runRecord?.duration ?? 0),
                                    unit: ""
                                )
                            }

                            HStack(spacing: 12) {
                                StatCard(
                                    icon: "bolt.fill",
                                    label: "平均配速",
                                    value: formatPace(runRecord?.pace ?? 0),
                                    unit: ""
                                )

                                StatCard(
                                    icon: "flame.fill",
                                    label: "CALORIES",
                                    value: String(format: "%.0f", runRecord?.calories ?? 0),
                                    unit: "kcal"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // AI Coach Insight
                        Button(action: {
                            showDetailedStats = true
                        }) {
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("AI教练建议")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.1))

                                    Text("\"后半程配速保持得很好！你的耐力正在提升。下次可以尝试加入间歇冲刺来提高最大摄氧量。\"")
                                        .font(.system(size: 15))
                                        .foregroundColor(.primary)
                                        .lineSpacing(4)
                                }

                                Spacer()
                            }
                            .padding(20)
                            .background(Color(red: 0.96, green: 0.98, blue: 0.88))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        Spacer()
                            .frame(height: 100)
                    }
                }

                // Bottom Buttons
                VStack {
                    Spacer()

                    HStack(spacing: 16) {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("关闭")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
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
                            .background(Color(red: 0.1, green: 0.1, blue: 0.2))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showDetailedStats) {
                DetailedStatsView()
            }
        }
    }

    // MARK: - Formatting

    private func formatPace(_ pace: Double) -> String {
        guard pace > 0, pace.isFinite else { return "0'00\"" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return "\(minutes)'\(String(format: "%02d", seconds))\" /km"
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
            timeOfDay = "夜跑"
        }

        formatter.dateFormat = "M月d日"
        let dateStr = formatter.string(from: date)

        return "\(weekday) \(timeOfDay) · \(dateStr)"
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    RunSummaryView()
}
