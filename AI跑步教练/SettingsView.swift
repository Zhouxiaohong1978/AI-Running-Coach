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
    @State private var showLoginSheet = false
    @State private var showLogoutAlert = false

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
        }
    }
}

#Preview {
    SettingsView()
}
