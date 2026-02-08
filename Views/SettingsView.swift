//
//  SettingsView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var dataManager = RunDataManager.shared
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var showLoginSheet = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showResetAchievementAlert = false

    var body: some View {
        NavigationView {
            List {
                // 账户部分
                Section {
                    if authManager.isAuthenticated {
                        // 已登录状态
                        VStack(alignment: .leading, spacing: 8) {
                            Text("已登录")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            if let email = authManager.currentUserEmail {
                                Text(email)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .padding(.vertical, 4)

                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            HStack {
                                Text("退出登录")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }

                        Button(action: {
                            showDeleteAccountAlert = true
                        }) {
                            HStack {
                                Text("删除账户")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    } else {
                        // 未登录状态
                        Button(action: {
                            showLoginSheet = true
                        }) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 20))
                                Text("登录账号")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text("登录后可将跑步数据同步到云端")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("账户")
                }

                // 数据同步部分
                if authManager.isAuthenticated {
                    Section {
                        HStack {
                            Text("云端同步")
                            Spacer()
                            if dataManager.isSyncing {
                                ProgressView()
                            } else {
                                Button("立即同步") {
                                    Task {
                                        await dataManager.syncAllToCloud()
                                        await dataManager.fetchFromCloud()
                                    }
                                }
                            }
                        }

                        HStack {
                            Text("本地记录")
                            Spacer()
                            Text("\(dataManager.runRecords.count)")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("已同步")
                            Spacer()
                            Text("\(dataManager.runRecords.filter { $0.syncedToCloud }.count)")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("数据同步")
                    }
                }

                // 开发者选项
                Section {
                    NavigationLink(destination: DebugLogView()) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            Text("运行日志")
                            Spacer()
                        }
                    }

                    Button(action: {
                        showResetAchievementAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20))
                                .foregroundColor(.orange)
                            Text("重置成就数据")
                            Spacer()
                        }
                    }
                } header: {
                    Text("开发者选项")
                } footer: {
                    Text("查看跑步过程中的详细运行日志，用于调试")
                }

                // 关于部分
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Button(action: {}) {
                        HStack {
                            Text("隐私政策")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {}) {
                        HStack {
                            Text("用户协议")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showLoginSheet) {
                LoginView()
            }
            .onChange(of: authManager.isAuthenticated) { isAuthenticated in
                // 登录成功后自动关闭登录页面
                if isAuthenticated {
                    showLoginSheet = false
                }
            }
            .alert("确认退出", isPresented: $showLogoutAlert) {
                Button("取消", role: .cancel) {}
                Button("退出", role: .destructive) {
                    Task {
                        try? await authManager.signOut()
                    }
                }
            } message: {
                Text("退出后，您的跑步数据仍会保存在本地")
            }
            .alert("重置成就", isPresented: $showResetAchievementAlert) {
                Button("取消", role: .cancel) {}
                Button("重置", role: .destructive) {
                    Task {
                        achievementManager.resetAndRecalculate(allRecords: dataManager.runRecords)
                        await achievementManager.clearCloudAchievements()
                        await achievementManager.syncToCloud()
                    }
                }
            } message: {
                Text("将清除所有成就数据（包括测试数据），并根据真实跑步记录重新计算成就进度。")
            }
            .alert("删除账户", isPresented: $showDeleteAccountAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    Task {
                        do {
                            try await authManager.deleteAccount()
                            // 删除本地数据
                            await dataManager.clearAllData()
                        } catch {
                            print("❌ 删除账户失败: \(error.localizedDescription)")
                        }
                    }
                }
            } message: {
                Text("删除账户后，您的所有数据将被永久删除且无法恢复。确定要继续吗？")
            }
        }
    }
}

#Preview {
    SettingsView()
}
