//
//  DetailedStatsView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI

struct DetailedStatsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Close")
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        Text("跑步详情")
                            .font(.system(size: 17, weight: .semibold))

                        Spacer()

                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 50)

                    // Stats Cards Row
                    HStack(spacing: 12) {
                        DetailedStatCard(
                            icon: "bolt.fill",
                            iconColor: Color.blue.opacity(0.6),
                            label: "AVG PACE",
                            value: "5'33\"",
                            unit: "/km"
                        )

                        DetailedStatCard(
                            icon: "flame.fill",
                            iconColor: Color.orange.opacity(0.6),
                            label: "CALORIES",
                            value: "15",
                            unit: "kcal"
                        )
                    }
                    .padding(.horizontal, 20)

                    // AI Coach Insight Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                                .frame(width: 8, height: 8)

                            Text("AI COACH INSIGHT")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.1))
                        }

                        Text("\"Great job maintaining a steady pace in the second half! Your stamina is improving. Consider adding some interval sprints next time to boost your VO2 max.\"")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.96, green: 0.98, blue: 0.88))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // Splits Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("每公里配速")
                            .font(.system(size: 20, weight: .bold))

                        HStack(alignment: .bottom, spacing: 20) {
                            SplitBar(height: 160, label: "1km")
                            SplitBar(height: 180, label: "2km")
                            SplitBar(height: 170, label: "3km")
                            SplitBar(height: 175, label: "4km")
                            SplitBar(height: 165, label: "5km")
                        }
                        .frame(height: 200)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct DetailedStatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)

                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))

                Text(unit)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
}

struct SplitBar: View {
    let height: CGFloat
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                .frame(height: height)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DetailedStatsView()
}
