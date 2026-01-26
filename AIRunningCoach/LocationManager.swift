//
//  LocationManager.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import Foundation
import CoreLocation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074), // 北京
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var pathUpdateVersion: Int = 0 // 用于触发地图轨迹更新
    @Published var distance: Double = 0 // 米
    @Published var currentPace: Double = 0 // 分钟/公里
    @Published var duration: TimeInterval = 0
    @Published var calories: Double = 0

    private var startTime: Date?
    private var lastLocation: CLLocation?
    private var isTracking = false
    private var timer: Timer?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 10 // 每10米更新一次
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        guard !isTracking else { return }

        isTracking = true
        startTime = Date()
        distance = 0
        duration = 0
        calories = 0
        routeCoordinates.removeAll()
        lastLocation = nil

        locationManager.startUpdatingLocation()

        // 开始计时器
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.duration = Date().timeIntervalSince(start)

            // 计算卡路里 (粗略估算: 1km约60卡路里)
            self.calories = (self.distance / 1000.0) * 60.0
        }
    }

    func pauseTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
    }

    func resumeTracking() {
        guard !isTracking else { return }
        isTracking = true
        locationManager.startUpdatingLocation()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.duration = Date().timeIntervalSince(start)
            self.calories = (self.distance / 1000.0) * 60.0
        }
    }

    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
    }

    private func calculatePace() {
        guard distance > 0, duration > 0 else {
            currentPace = 0
            return
        }

        // 配速 = 时间(分钟) / 距离(公里)
        let distanceInKm = distance / 1000.0
        let durationInMinutes = duration / 60.0
        currentPace = durationInMinutes / distanceInKm
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // 更新用户位置
        userLocation = location.coordinate

        // 更新地图区域
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )

        // 如果正在跟踪，添加到路线
        if isTracking {
            routeCoordinates.append(location.coordinate)
            pathUpdateVersion += 1 // 递增版本号触发地图更新

            // 计算距离
            if let lastLoc = lastLocation {
                let delta = location.distance(from: lastLoc)
                // 过滤异常值（超过100米的单次跳动可能是GPS漂移）
                if delta < 100 {
                    distance += delta
                    calculatePace()
                }
            }

            lastLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}
