//
//  HomeView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI

struct HomeView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Tab Content
            switch selectedTab {
            case 0:
                homeContent
            case 1:
                planContent
            case 2:
                HistoryView()
            case 3:
                SettingsView()
            default:
                homeContent
            }

            // Bottom Tab Bar
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    TabBarItem(icon: "house.fill", label: "开始", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }

                    TabBarItem(icon: "calendar", label: "计划", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }

                    TabBarItem(icon: "clock", label: "历史", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }

                    TabBarItem(icon: "person", label: "我的", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                }
                .padding(.vertical, 8)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: -2)
            }
        }
    }

    // MARK: - Home Content

    private var homeContent: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Main Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Weather and Greeting
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Text("☀️")
                                        .font(.title3)
                                    Text("晴天, 24°C")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                HStack(spacing: 0) {
                                    Text("准备好今天的跑步了吗，")
                                        .font(.system(size: 32, weight: .bold))
                                    Text("小红")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                                    Text("?")
                                        .font(.system(size: 32, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                            // 开始 Run Button
                            NavigationLink(destination: ActiveRunView()) {
                                ZStack {
                                    // Outer glow rings
                                    Circle()
                                        .fill(Color(red: 0.5, green: 0.8, blue: 0.1).opacity(0.1))
                                        .frame(width: 240, height: 240)

                                    Circle()
                                        .fill(Color(red: 0.5, green: 0.8, blue: 0.1).opacity(0.15))
                                        .frame(width: 200, height: 200)

                                    // Main button
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                                            .frame(width: 160, height: 160)

                                        VStack(spacing: 8) {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(.white)

                                            Text("开始跑步")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 20)

                            // 每周目标 Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("每周目标")
                                            .font(.system(size: 18, weight: .semibold))
                                        Text("1月21日 - 1月27日")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                                }

                                HStack(alignment: .lastTextBaseline, spacing: 8) {
                                    Text("12.5")
                                        .font(.system(size: 48, weight: .bold))
                                    Text("/ 20 km")
                                        .font(.system(size: 18))
                                        .foregroundColor(.secondary)
                                }

                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 8)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(red: 0.5, green: 0.8, blue: 0.1))
                                            .frame(width: geometry.size.width * 0.625, height: 8)
                                    }
                                }
                                .frame(height: 8)

                                Text("你已超前完成2.5公里！")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        }
                    }
                }

                // Help Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {}) {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 48, height: 48)

                                Text("?")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Plan Content (Placeholder)

    private var planContent: some View {
        NavigationView {
            VStack {
                Text("训练计划")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("即将推出")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("计划")
        }
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(red: 0.5, green: 0.8, blue: 0.1) : .gray)

                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? Color(red: 0.5, green: 0.8, blue: 0.1) : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    HomeView()
}
