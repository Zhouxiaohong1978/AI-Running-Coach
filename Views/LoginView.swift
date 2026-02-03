//
//  LoginView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var userName = ""  // 用户名（仅注册时使用）
    @State private var selectedTab = 0  // 0: 登录, 1: 注册
    @State private var showPassword = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showForgotPassword = false
    @State private var forgotPasswordEmail = ""
    @State private var showOTPVerification = false  // 显示 OTP 验证界面
    @State private var otpCode = ""  // OTP 验证码
    @State private var verificationEmail = ""  // 待验证的邮箱

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

                        Text(selectedTab == 0 ? "欢迎回来" : "创建新账号")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.bottom, 20)

                    // 登录/注册 Tab 切换
                    HStack(spacing: 0) {
                        TabButton(title: "登录", isSelected: selectedTab == 0) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = 0
                                showError = false
                            }
                        }
                        TabButton(title: "注册", isSelected: selectedTab == 1) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = 1
                                showError = false
                            }
                        }
                    }
                    .padding(.horizontal, 32)

                    // 输入表单
                    VStack(spacing: 16) {
                        // 用户名输入（仅注册时显示）
                        if selectedTab == 1 {
                            HStack(spacing: 12) {
                                Image(systemName: "person")
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 20)

                                TextField("", text: $userName)
                                    .placeholder(when: userName.isEmpty) {
                                        Text("用户名")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }

                        // 邮箱输入
                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 20)

                            TextField("", text: $email)
                                .placeholder(when: email.isEmpty) {
                                    Text("邮箱")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.emailAddress)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)

                        // 密码输入
                        HStack(spacing: 12) {
                            Image(systemName: "lock")
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 20)

                            if showPassword {
                                TextField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("密码")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .textContentType(selectedTab == 1 ? .newPassword : .password)
                                    .foregroundColor(.white)
                            } else {
                                SecureField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("密码")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .textContentType(selectedTab == 1 ? .newPassword : .password)
                                    .foregroundColor(.white)
                            }

                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye" : "eye.slash")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
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
                                Text(selectedTab == 0 ? "登录" : "注册")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.1))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || (selectedTab == 1 && userName.isEmpty))

                        // 忘记密码（仅登录模式显示）
                        if selectedTab == 0 {
                            Button(action: {
                                forgotPasswordEmail = email
                                showForgotPassword = true
                            }) {
                                Text("忘记密码？")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                        }

                        // 分隔线
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            Text("或者使用以下方式登录")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize()
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
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(initialEmail: $forgotPasswordEmail)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showOTPVerification) {
            OTPVerificationView(
                email: verificationEmail,
                otpCode: $otpCode,
                onVerify: verifyOTP,
                onCancel: {
                    showOTPVerification = false
                    otpCode = ""
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Actions

    private func handleAuth() {
        showError = false
        errorMessage = nil

        Task {
            do {
                if selectedTab == 1 {
                    print("📝 [注册] 开始注册...")
                    try await authManager.signUp(email: email, password: password)
                    print("✅ [注册] 注册成功")
                } else {
                    print("🔑 [登录] 开始登录...")
                    try await authManager.signIn(email: email, password: password)
                    print("✅ [登录] 登录成功")
                }

                // 登录/注册成功后关闭页面
                dismiss()
            } catch let error as NSError {
                print("❌ [认证] 失败: \(error.localizedDescription)")

                // 检查是否需要邮箱验证（code -4）
                if error.code == -4 && error.domain == "AuthManager" {
                    print("📧 [注册] 需要邮箱验证，显示 OTP 输入界面")
                    verificationEmail = email
                    showOTPVerification = true
                } else {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            } catch {
                print("❌ [认证] 失败: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // 验证 OTP
    private func verifyOTP() {
        Task {
            do {
                try await authManager.verifyOTP(email: verificationEmail, token: otpCode)
                print("✅ [验证] OTP 验证成功")

                // 保存用户名（如果填写了）
                if !userName.isEmpty {
                    UserDefaults.standard.set(userName, forKey: "user_name")
                    print("✅ [注册] 已保存用户名: \(userName)")
                }

                showOTPVerification = false
                dismiss()
            } catch {
                print("❌ [验证] OTP 验证失败: \(error.localizedDescription)")
                errorMessage = "验证码错误，请重新输入"
                showError = true
            }
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))

                Rectangle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
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

// MARK: - OTP Verification View

struct OTPVerificationView: View {
    let email: String
    @Binding var otpCode: String
    let onVerify: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // 标题
            VStack(spacing: 8) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.1))

                Text("验证邮箱")
                    .font(.system(size: 24, weight: .bold))

                Text("我们已向 \(email) 发送了验证码")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            // OTP 输入框
            VStack(alignment: .leading, spacing: 8) {
                Text("验证码")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                TextField("输入 6 位验证码", text: $otpCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)

            // 按钮
            VStack(spacing: 12) {
                // 验证按钮
                Button(action: onVerify) {
                    Text("验证")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(otpCode.count == 6 ? Color(red: 0.5, green: 0.8, blue: 0.1) : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(otpCode.count != 6)

                // 取消按钮
                Button(action: onCancel) {
                    Text("取消")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

#Preview {
    LoginView()
}
