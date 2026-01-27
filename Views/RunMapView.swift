//
//  RunMapView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI
import MapKit

struct RunMapView: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var region: MKCoordinateRegion
    var routeCoordinates: [CLLocationCoordinate2D]
    var pathUpdateVersion: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        // 设置内边距，让用户位置显示在可见区域中心（底部有数据卡片遮挡）
        mapView.layoutMargins = UIEdgeInsets(top: 100, left: 0, bottom: 350, right: 0)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 当有用户位置时，更新地图中心
        if let location = userLocation {
            let currentCenter = mapView.region.center

            // 将地图中心向南偏移，让用户位置显示在配速文字上方
            let offsetLatitude = location.latitude + 0.012  // 继续增大偏移，让蓝点在配速上方
            let newCenter = CLLocationCoordinate2D(latitude: offsetLatitude, longitude: location.longitude)

            // 计算当前中心和新位置的距离
            let distance = sqrt(
                pow(currentCenter.latitude - newCenter.latitude, 2) +
                pow(currentCenter.longitude - newCenter.longitude, 2)
            )

            // 如果距离较大（超过0.0005度，约50米），更新地图
            if distance > 0.0005 || context.coordinator.isFirstUpdate {
                context.coordinator.isFirstUpdate = false
                let newRegion = MKCoordinateRegion(
                    center: newCenter,
                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                )
                mapView.setRegion(newRegion, animated: true)
            }
        }

        // 只有版本号变化时才更新轨迹
        if context.coordinator.lastPathVersion != pathUpdateVersion {
            context.coordinator.lastPathVersion = pathUpdateVersion

            // 移除旧的轨迹覆盖层
            let overlays = mapView.overlays.filter { $0 is MKPolyline }
            mapView.removeOverlays(overlays)

            // 绘制新的轨迹（转换坐标以修复中国大陆地图偏移）
            if routeCoordinates.count >= 2 {
                let convertedCoordinates = CoordinateConverter.wgs84ToGcj02(routeCoordinates)
                let polyline = MKPolyline(coordinates: convertedCoordinates, count: convertedCoordinates.count)
                mapView.addOverlay(polyline)
            }
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RunMapView
        var lastPathVersion: Int = -1
        var isFirstUpdate: Bool = true

        init(_ parent: RunMapView) {
            self.parent = parent
        }

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
    RunMapView(
        userLocation: .constant(CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)),
        region: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )),
        routeCoordinates: [],
        pathUpdateVersion: 0
    )
}
