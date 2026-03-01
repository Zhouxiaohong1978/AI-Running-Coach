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
    private let logger = DebugLogger.shared

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
    @Published var lastLocation: CLLocation?  // 暴露给外部使用（如获取天气）
    @Published var kmSplits: [Double] = [] // 每公里用时（秒）

    private var startTime: Date?
    private var isTracking = false
    private var timer: Timer?
    private var lastKmDistance: Double = 0 // 上一个km边界的累计距离
    private var lastKmTime: Date? // 上一个km边界的时间

    // GPS 过滤参数（复用 EarthLord 标准）
    private let minHorizontalAccuracy: Double = 10.0  // 最小精度要求（米），过滤低质量GPS点
    private let minMovementDistance: Double = 3.0     // 最小移动距离（米），小于此值视为漂移（distanceFilter=5，真实跑步delta常在5-8m）
    private let minSpeed: Double = 0.5                // 最小速度（米/秒），低于此值可能是静止（慢跑约1.5m/s）

    // MARK: - 模拟器模拟跑步
    #if targetEnvironment(simulator)
    private var simulationTimer: Timer?
    /// 模拟配速（分钟/公里），默认 6'00"/km
    var simulationPace: Double = 6.0
    /// 模拟起点（Cupertino Apple Park 附近）
    private let simStartLat: Double = 37.3349
    private let simStartLon: Double = -122.0090
    /// 模拟方向角度（弧度），每段微调模拟转弯
    private var simHeading: Double = 0.0
    private var simLat: Double = 0
    private var simLon: Double = 0
    #endif

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 5 // 每5米更新一次
        locationManager.requestWhenInUseAuthorization()
        // 立即开始获取位置
        locationManager.startUpdatingLocation()
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
        kmSplits = []
        lastKmDistance = 0
        lastKmTime = Date()

        // 跑步开始后启用后台定位（口袋模式：熄屏继续GPS+语音）
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()

        // 开始计时器
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.duration = Date().timeIntervalSince(start)

            // 计算卡路里 (粗略估算: 1km约100卡路里)
            self.calories = (self.distance / 1000.0) * 100.0
        }

        #if targetEnvironment(simulator)
        startSimulation()
        #endif
    }

    func pauseTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
        #if targetEnvironment(simulator)
        simulationTimer?.invalidate()
        simulationTimer = nil
        #endif
    }

    func resumeTracking() {
        guard !isTracking else { return }
        isTracking = true
        locationManager.startUpdatingLocation()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.duration = Date().timeIntervalSince(start)
            self.calories = (self.distance / 1000.0) * 100.0
        }

        #if targetEnvironment(simulator)
        startSimulation()
        #endif
    }

    func stopTracking() {
        // 处理最后不足1km的段落（≥200m时按比例推算）
        let remainingDistance = distance - lastKmDistance
        if remainingDistance >= 200, let kmStart = lastKmTime {
            let elapsedTime = Date().timeIntervalSince(kmStart)
            // 按比例推算完整1km配速
            let estimatedKmTime = elapsedTime * (1000.0 / remainingDistance)
            kmSplits.append(estimatedKmTime)
        }

        isTracking = false
        locationManager.stopUpdatingLocation()
        // 跑步结束，关闭后台定位
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.showsBackgroundLocationIndicator = false
        timer?.invalidate()
        timer = nil
        #if targetEnvironment(simulator)
        simulationTimer?.invalidate()
        simulationTimer = nil
        #endif
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
    // MARK: - 模拟器自动跑步

    #if targetEnvironment(simulator)
    /// 启动模拟跑步：每 2 秒生成一个 GPS 点，按 simulationPace 配速移动
    private func startSimulation() {
        simulationTimer?.invalidate()

        // 用当前位置或默认起点
        if let loc = userLocation {
            simLat = loc.latitude
            simLon = loc.longitude
        } else {
            simLat = simStartLat
            simLon = simStartLon
        }
        simHeading = 0.3  // 初始方向（略偏东北）

        // 配速转速度：6 min/km = 360s/km → speed = 1000/360 ≈ 2.78 m/s
        // 每 2 秒更新一次 → 每次移动 speed * 2 米
        let speedMPS = 1000.0 / (simulationPace * 60.0)
        let interval: TimeInterval = 2.0
        let stepMeters = speedMPS * interval

        print("🏃‍♂️ [模拟器] 开始模拟跑步: 配速 \(simulationPace)'/km, 速度 \(String(format: "%.2f", speedMPS))m/s, 每步 \(String(format: "%.1f", stepMeters))m")

        simulationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, self.isTracking else { return }

            // 每 500m 微调方向（模拟转弯）
            let totalDist = self.distance
            if Int(totalDist) % 500 < Int(stepMeters) + 1 {
                self.simHeading += 0.5  // 每 500m 右转约 28 度
            }

            // 1 度纬度 ≈ 111,000 米，1 度经度 ≈ 111,000 * cos(lat) 米
            let metersPerDegreeLat = 111_000.0
            let metersPerDegreeLon = 111_000.0 * cos(self.simLat * .pi / 180.0)

            let dLat = stepMeters * cos(self.simHeading) / metersPerDegreeLat
            let dLon = stepMeters * sin(self.simHeading) / metersPerDegreeLon

            self.simLat += dLat
            self.simLon += dLon

            // 构造模拟 CLLocation（高精度，确保通过 GPS 过滤）
            let simLocation = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: self.simLat, longitude: self.simLon),
                altitude: 10,
                horizontalAccuracy: 5.0,
                verticalAccuracy: 5.0,
                course: self.simHeading * 180.0 / .pi,
                speed: speedMPS,
                timestamp: Date()
            )

            // 注入到 didUpdateLocations 处理流程
            self.locationManager(self.locationManager, didUpdateLocations: [simLocation])
        }
    }
    #endif
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // 总是更新用户位置（用于显示蓝点）
        userLocation = location.coordinate

        // 总是更新地图区域（确保地图跟随用户）
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )

        // 精度太差时，只更新位置显示，不计入距离
        guard location.horizontalAccuracy >= 0 &&
              location.horizontalAccuracy <= minHorizontalAccuracy else {
            print("🛰️ 低精度定位，仅更新显示: \(location.horizontalAccuracy)米")
            return
        }

        // 如果不在跟踪状态，只更新 lastLocation（用于主页获取天气等）
        if !isTracking {
            lastLocation = location
            return
        }

        // 如果正在跟踪，添加到路线
        if isTracking {
            // 计算与上一个点的距离
            if let lastLoc = lastLocation {
                let delta = location.distance(from: lastLoc)
                let timeDelta = location.timestamp.timeIntervalSince(lastLoc.timestamp)
                let speed = timeDelta > 0 ? delta / timeDelta : 0

                // 过滤条件（必须同时满足）：
                // 1. 距离 >= 8米（过滤GPS漂移）
                // 2. 距离 < 100米（过滤GPS跳点）
                // 3. 速度 >= 0.8m/s（确保是真正在移动，不是静止漂移）
                let isValidMovement = delta >= minMovementDistance &&
                                      delta < 100 &&
                                      speed >= minSpeed

                if isValidMovement {
                    distance += delta
                    routeCoordinates.append(location.coordinate)
                    pathUpdateVersion += 1
                    calculatePace()
                    lastLocation = location

                    // 检查是否跨过了 km 边界
                    let nextKmBoundary = lastKmDistance + 1000.0
                    if distance >= nextKmBoundary, let kmStart = lastKmTime {
                        let splitTime = location.timestamp.timeIntervalSince(kmStart)
                        kmSplits.append(splitTime)
                        lastKmDistance = nextKmBoundary
                        lastKmTime = location.timestamp
                    }
                    print("✅ 有效移动: 距离=\(String(format: "%.1f", delta))米, 速度=\(String(format: "%.1f", speed))米/秒")
                    logger.log("✅ GPS更新: +\(String(format: "%.1f", delta))米, 总距离=\(String(format: "%.0f", distance))米", category: "DATA")
                } else {
                    logger.log("⚠️ GPS漂移: delta=\(String(format: "%.1f", delta))米, speed=\(String(format: "%.1f", speed))m/s (已过滤)", category: "WARN")
                    // 即使不计入距离，也更新 lastLocation 以避免累积误差
                    if timeDelta > 3 {  // 超过3秒没有有效移动，更新基准点
                        lastLocation = location
                    }
                    print("🚫 过滤: 距离=\(String(format: "%.1f", delta))米, 速度=\(String(format: "%.1f", speed))米/秒")
                }
            } else {
                // 第一个点，直接记录
                routeCoordinates.append(location.coordinate)
                pathUpdateVersion += 1
                lastLocation = location
            }
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
