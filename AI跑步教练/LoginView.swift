//
//  LoginView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [Color(red: 0.5, green: 0.8, blue: 0.1), Color(red: 0.3, green: 0.6, blue: 0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // Logo和标题
                    VStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text("AI跑步教练")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text(isSignUpMode ? "创建新账号" : "欢迎回来")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.bottom, 40)

                    // 输入表单
                    VStack(spacing: 16) {
                        // 邮箱输入
                        TextField("", text: $email)
                            .placeholder(when: email.isEmpty) {
                                Text("邮箱地址")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)

                        // 密码输入
                        SecureField("", text: $password)
                            .placeholder(when: password.isEmpty) {
                                Text("密码")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .textContentType(isSignUpMode ? .newPassword : .password)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)

                        // 错误提示
                        if showError, let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        // 登录/注册按钮
                        Button(action: handleAuth) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSignUpMode ? "注册" : "登录")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)

                        // 切换登录/注册模式
                        Button(action: {
                            isSignUpMode.toggle()
                            showError = false
                        }) {
                            Text(isSignUpMode ? "已有账号？立即登录" : "没有账号？立即注册")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }

                        // 分隔线
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            Text("或")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 8)

                        // Apple ID 登录按钮
                        SignInWithAppleButton()
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Actions

    private func handleAuth() {
        showError = false
        errorMessage = nil

        Task {
            do {
                if isSignUpMode {
                    try await authManager.signUp(email: email, password: password)
                } else {
                    try await authManager.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - TextField Placeholder Extension

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    LoginView()
}
