//
//  RunRecord.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import Foundation
import CoreLocation

struct RunRecord: Identifiable, Codable {
    var id: UUID
    var userId: UUID?

    // 基本信息
    var distance: Double // 距离（米）
    var duration: TimeInterval // 时长（秒）
    var pace: Double // 配速（分钟/公里）
    var calories: Double // 卡路里

    // 时间信息
    var startTime: Date
    var endTime: Date

    // 轨迹数据
    var routeCoordinates: [Coordinate]

    // 统计信息
    var averageSpeed: Double? // 平均速度（米/秒）
    var maxSpeed: Double? // 最大速度（米/秒）

    // 元数据
    var createdAt: Date
    var updatedAt: Date
    var syncedToCloud: Bool // 是否已同步到云端

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        distance: Double,
        duration: TimeInterval,
        pace: Double,
        calories: Double,
        startTime: Date,
        endTime: Date,
        routeCoordinates: [Coordinate],
        averageSpeed: Double? = nil,
        maxSpeed: Double? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncedToCloud: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.distance = distance
        self.duration = duration
        self.pace = pace
        self.calories = calories
        self.startTime = startTime
        self.endTime = endTime
        self.routeCoordinates = routeCoordinates
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncedToCloud = syncedToCloud
    }
}

// MARK: - Coordinate Model

struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Supabase Database Model

struct RunRecordDTO: Codable {
    var id: UUID
    var userId: UUID
    var distance: Double
    var duration: Double
    var pace: Double
    var calories: Double
    var startTime: Date
    var endTime: Date
    var routeCoordinates: [Coordinate]
    var averageSpeed: Double?
    var maxSpeed: Double?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case distance
        case duration
        case pace
        case calories
        case startTime = "start_time"
        case endTime = "end_time"
        case routeCoordinates = "route_coordinates"
        case averageSpeed = "average_speed"
        case maxSpeed = "max_speed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from runRecord: RunRecord, userId: UUID) {
        self.id = runRecord.id
        self.userId = userId
        self.distance = runRecord.distance
        self.duration = runRecord.duration
        self.pace = runRecord.pace
        self.calories = runRecord.calories
        self.startTime = runRecord.startTime
        self.endTime = runRecord.endTime
        self.routeCoordinates = runRecord.routeCoordinates
        self.averageSpeed = runRecord.averageSpeed
        self.maxSpeed = runRecord.maxSpeed
        self.createdAt = runRecord.createdAt
        self.updatedAt = runRecord.updatedAt
    }

    func toRunRecord() -> RunRecord {
        return RunRecord(
            id: id,
            userId: userId,
            distance: distance,
            duration: duration,
            pace: pace,
            calories: calories,
            startTime: startTime,
            endTime: endTime,
            routeCoordinates: routeCoordinates,
            averageSpeed: averageSpeed,
            maxSpeed: maxSpeed,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedToCloud: true
        )
    }
}
