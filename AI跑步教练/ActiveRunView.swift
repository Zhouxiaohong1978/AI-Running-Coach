//
//  ActiveRunView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI
import MapKit

struct ActiveRunView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var isPaused = false
    @State private var showSummary = false

    var body: some View {
        ZStack {
            // Map Background with route polyline
            RunMapView(
                userLocation: $locationManager.userLocation,
                region: $locationManager.region,
                routeCoordinates: locationManager.routeCoordinates,
                pathUpdateVersion: locationManager.pathUpdateVersion
            )
            .ignoresSafeArea()

            VStack {
                // Top Status Bar
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                            .frame(width: 8, height: 8)
                        Text("GPS ACTIVE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)

                Spacer()

                // Metrics Cards
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        // Pace Card
                        MetricCard(
                            label: "配速",
                            value: formatPace(locationManager.currentPace),
                            unit: ""
                        )

                        // Time Card
                        MetricCard(
                            label: "时间",
                            value: formatDuration(locationManager.duration),
                            unit: ""
                        )
                    }

                    HStack(spacing: 12) {
                        // Distance Card
                        MetricCard(
                            label: "距离",
                            value: String(format: "%.2f", locationManager.distance / 1000.0),
                            unit: " km"
                        )

                        // Calories Card
                        MetricCard(
                            label: "卡路里",
                            value: String(format: "%.0f", locationManager.calories),
                            unit: " kcal"
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
                    .frame(height: 40)

                // Control Buttons
                HStack(spacing: 40) {
                    // Pause Button
                    Button(action: {
                        isPaused.toggle()
                        if isPaused {
                            locationManager.pauseTracking()
                        } else {
                            locationManager.resumeTracking()
                        }
                    }) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }

                    // Stop Button
                    Button(action: {
                        locationManager.stopTracking()
                        showSummary = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 80, height: 80)

                            Text("结束")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            locationManager.startTracking()
        }
        .onDisappear {
            locationManager.stopTracking()
        }
        .fullScreenCover(isPresented: $showSummary) {
            RunSummaryView()
        }
    }

    private func formatPace(_ pace: Double) -> String {
        guard pace > 0, pace.isFinite else { return "0'00\"" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return "\(minutes)'\(String(format: "%02d", seconds))\""
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct MetricCard: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
    }
}

#Preview {
    ActiveRunView()
}
