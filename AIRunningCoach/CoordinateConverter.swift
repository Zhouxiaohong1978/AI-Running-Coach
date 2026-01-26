//
//  CoordinateConverter.swift
//  AI跑步教练
//
//  WGS-84 到 GCJ-02 坐标转换工具
//  用于修复中国大陆地图轨迹漂移问题
//

import CoreLocation

enum CoordinateConverter {
    // 地球椭球体参数 (Krasovsky 1940)
    private static let a: Double = 6378245.0  // 长半轴
    private static let ee: Double = 0.00669342162296594323  // 扁率

    // MARK: - 公开接口

    /// 判断坐标是否在中国范围内
    /// - Parameter coordinate: 待判断的坐标
    /// - Returns: 是否在中国大陆范围内
    static func isInChina(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        // 中国范围：纬度 0.8293~55.8271，经度 72.004~137.8347
        return (lat >= 0.8293 && lat <= 55.8271) && (lon >= 72.004 && lon <= 137.8347)
    }

    /// 将单个 WGS-84 坐标转换为 GCJ-02 坐标
    /// - Parameter coordinate: WGS-84 坐标
    /// - Returns: GCJ-02 坐标（火星坐标）
    static func wgs84ToGcj02(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // 不在中国范围内，直接返回原坐标
        guard isInChina(coordinate) else {
            return coordinate
        }

        let lat = coordinate.latitude
        let lon = coordinate.longitude

        // 计算纬度偏移
        var dLat = transformLat(lon - 105.0, lat - 35.0)
        // 计算经度偏移
        var dLon = transformLon(lon - 105.0, lat - 35.0)

        let radLat = lat / 180.0 * .pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)

        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * .pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * .pi)

        return CLLocationCoordinate2D(
            latitude: lat + dLat,
            longitude: lon + dLon
        )
    }

    /// 批量将 WGS-84 坐标转换为 GCJ-02 坐标
    /// - Parameter coordinates: WGS-84 坐标数组
    /// - Returns: GCJ-02 坐标数组
    static func wgs84ToGcj02(_ coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        return coordinates.map { wgs84ToGcj02($0) }
    }

    // MARK: - 私有转换函数

    /// 纬度偏移转换
    private static func transformLat(_ x: Double, _ y: Double) -> Double {
        var result = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y
        result += 0.1 * x * y + 0.2 * sqrt(abs(x))
        result += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        result += (20.0 * sin(y * .pi) + 40.0 * sin(y / 3.0 * .pi)) * 2.0 / 3.0
        result += (160.0 * sin(y / 12.0 * .pi) + 320.0 * sin(y * .pi / 30.0)) * 2.0 / 3.0
        return result
    }

    /// 经度偏移转换
    private static func transformLon(_ x: Double, _ y: Double) -> Double {
        var result = 300.0 + x + 2.0 * y + 0.1 * x * x
        result += 0.1 * x * y + 0.1 * sqrt(abs(x))
        result += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        result += (20.0 * sin(x * .pi) + 40.0 * sin(x / 3.0 * .pi)) * 2.0 / 3.0
        result += (150.0 * sin(x / 12.0 * .pi) + 300.0 * sin(x / 30.0 * .pi)) * 2.0 / 3.0
        return result
    }
}
