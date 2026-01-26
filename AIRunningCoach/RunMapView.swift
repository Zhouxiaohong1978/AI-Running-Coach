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
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
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

        // 更新地图区域跟随用户
        if let location = userLocation {
            let currentCenter = mapView.region.center
            let distance = CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude)
                .distance(from: CLLocation(latitude: location.latitude, longitude: location.longitude))

            // 只有当用户移动超过50米时才更新地图中心
            if distance > 50 {
                mapView.setRegion(region, animated: true)
            }
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RunMapView
        var lastPathVersion: Int = -1

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
