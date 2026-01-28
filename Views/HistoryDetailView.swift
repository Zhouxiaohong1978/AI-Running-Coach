//
//  HistoryDetailView.swift
//  AI跑步教练
//
//  Created by Claude Code
//  支持离线查看历史跑步轨迹

import SwiftUI
import MapKit

struct HistoryDetailView: View {
    @Environment(\.dismiss) var dismiss
    let runRecord: RunRecord
    @StateObject private var dataManager = RunDataManager.shared

    @State private var region: MKCoordinateRegion
    @State private var showDeleteConfirmation = false

    init(runRecord: RunRecord) {
        self.runRecord = runRecord

        // 设置地图中心为轨迹的第一个点
        if let firstCoord = runRecord.routeCoordinates.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: firstCoord.toCLLocationCoordinate2D(),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                    .onAppear {
                        // 确保视图完全加载
                        print("📍 详情页加载: 距离=\(runRecord.distance)m, 时长=\(runRecord.duration)s")
                    }

                ScrollView {
                    VStack(spacing: 0) {
                        // 地图视图（显示离线轨迹）
                        HistoryMapView(coordinates: runRecord.routeCoordinates, region: $region)
                            .frame(height: 250)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top, 16)

                        // 统计卡片
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                DetailStatCard(
                                    icon: "location.fill",
                                    label: "距离",
                                    value: String(format: "%.2f", runRecord.distance / 1000),
                                    unit: "km"
                                )

                                DetailStatCard(
                                    icon: "clock.fill",
                                    label: "时长",
                                    value: formatDuration(runRecord.duration),
                                    unit: ""
                                )
                            }

                            HStack(spacing: 12) {
                                DetailStatCard(
                                    icon: "bolt.fill",
                                    label: "配速",
                                    value: formatPace(runRecord.pace),
                                    unit: ""
                                )

                                DetailStatCard(
                                    icon: "flame.fill",
                                    label: "卡路里",
                                    value: String(format: "%.0f", runRecord.calories),
                                    unit: "kcal"
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)

                        // 时间信息
                        VStack(alignment: .leading, spacing: 12) {
                            Text("跑步时间")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("开始时间")
                                        .font(.system(size: 12))
                                        .foregroundColor(.black.opacity(0.6))
                                    Text(formatDateTime(runRecord.startTime))
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("结束时间")
                                        .font(.system(size: 12))
                                        .foregroundColor(.black.opacity(0.6))
                                    Text(formatDateTime(runRecord.endTime))
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top, 16)

                        // 同步状态
                        HStack(spacing: 8) {
                            Image(systemName: runRecord.syncedToCloud ? "cloud.fill" : "icloud.slash")
                                .font(.system(size: 14))
                                .foregroundColor(runRecord.syncedToCloud ? .green : .gray)

                            Text(runRecord.syncedToCloud ? "已同步到云端" : "仅保存在本地")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("跑步详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                        }

                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .alert("确认删除", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteRecord()
            }
        } message: {
            Text("确定要删除这条跑步记录吗？删除后无法恢复。")
        }
    }

    // MARK: - Delete Function

    private func deleteRecord() {
        Task {
            await dataManager.deleteRunRecord(runRecord)
            await MainActor.run {
                dismiss()
            }
        }
    }

    // MARK: - Formatting

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
        guard pace > 0, pace.isFinite else { return "0'00\" /km" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return "\(minutes)'\(String(format: "%02d", seconds))\" /km"
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Detail Stat Card

struct DetailStatCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String

    // 根据图标名称返回对应的颜色
    private var iconColor: Color {
        switch icon {
        case "location.fill":
            return .blue
        case "clock.fill":
            return .orange
        case "bolt.fill":
            return .purple
        case "flame.fill":
            return .red
        default:
            return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)

                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - History Map View (Offline)

struct HistoryMapView: UIViewRepresentable {
    let coordinates: [Coordinate]
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 清除旧的覆盖层
        mapView.removeOverlays(mapView.overlays)

        // 如果有轨迹数据，绘制路线
        if coordinates.count >= 2 {
            let clCoordinates = coordinates.map { $0.toCLLocationCoordinate2D() }
            // 应用GCJ-02转换（修复中国大陆地图偏移）
            let convertedCoordinates = CoordinateConverter.wgs84ToGcj02(clCoordinates)
            let polyline = MKPolyline(coordinates: convertedCoordinates, count: convertedCoordinates.count)
            mapView.addOverlay(polyline)

            // 调整地图区域以适应整条路线
            let rect = polyline.boundingMapRect
            mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: false)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemGreen
                renderer.lineWidth = 5.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#Preview {
    HistoryDetailView(runRecord: RunRecord(
        distance: 5000,
        duration: 1800,
        pace: 6.0,
        calories: 300,
        startTime: Date().addingTimeInterval(-1800),
        endTime: Date(),
        routeCoordinates: []
    ))
}
