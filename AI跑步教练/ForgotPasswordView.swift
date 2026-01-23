//
//  ForgotPasswordView.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared

    @Binding var initialEmail: String
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var currentStep = 0  // 0: 输入邮箱, 1: 输入验证码, 2: 设置新密码
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false

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
                    // 拖动指示器
                    Capsule()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)

                    // 步骤指示器
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(index == currentStep ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 8)

                    // 根据步骤显示不同内容
                    switch currentStep {
                    case 0:
                        emailInputView
                    case 1:
                        verificationCodeView
                    case 2:
                        newPasswordView
                    default:
                        successView
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .principal) {
                    Text("找回密码")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            email = initialEmail
        }
    }

    // MARK: - Step 1: 输入邮箱

    private var emailInputView: some View {
        VStack(spacing: 24) {
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .padding(.top, 20)

            Text("输入注册邮箱")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Text("我们将发送6位验证码到您的邮箱")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))

            // 邮箱输入框
            HStack(spacing: 12) {
                Image(systemName: "envelope")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 20)

                TextField("", text: $email)
                    .placeholder(when: email.isEmpty) {
                        Text("请输入邮箱")
                            .foregroundColor(.white.opacity(0.5))
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

            // 错误提示
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.red.opacity(0.8))
                .cornerRadius(8)
            }

            // 发送验证码按钮
            Button(action: sendVerificationCode) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.3, green: 0.6, blue: 0.1)))
                } else {
                    Text("发送验证码")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.1))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(email.isEmpty ? Color.white.opacity(0.5) : Color.white)
            .cornerRadius(12)
            .disabled(email.isEmpty || isLoading)
        }
    }

    // MARK: - Step 2: 输入验证码

    private var verificationCodeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "number.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .padding(.top, 20)

            Text("输入验证码")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Text("验证码已发送至 \(email)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))

            // 验证码输入框
            HStack(spacing: 12) {
                Image(systemName: "number")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 20)

                TextField("", text: $verificationCode)
                    .placeholder(when: verificationCode.isEmpty) {
                        Text("请输入6位验证码")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .keyboardType(.numberPad)
                    .foregroundColor(.white)
                    .onChange(of: verificationCode) { newValue in
                        // 限制只能输入6位数字
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count > 6 {
                            verificationCode = String(filtered.prefix(6))
                        } else {
                            verificationCode = filtered
                        }
                    }
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)

            // 错误提示
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.red.opacity(0.8))
                .cornerRadius(8)
            }

            // 验证按钮
            Button(action: verifyCode) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.3, green: 0.6, blue: 0.1)))
                } else {
                    Text("验证")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.1))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(verificationCode.count < 6 ? Color.white.opacity(0.5) : Color.white)
            .cornerRadius(12)
            .disabled(verificationCode.count < 6 || isLoading)

            // 重新发送
            Button(action: sendVerificationCode) {
                Text("重新发送验证码")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .disabled(isLoading)
        }
    }

    // MARK: - Step 3: 设置新密码

    private var newPasswordView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .padding(.top, 20)

            Text("设置新密码")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            // 新密码输入框
            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 20)

                if showPassword {
                    TextField("", text: $newPassword)
                        .placeholder(when: newPassword.isEmpty) {
                            Text("请输入新密码（至少6位）")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .foregroundColor(.white)
                } else {
                    SecureField("", text: $newPassword)
                        .placeholder(when: newPassword.isEmpty) {
                            Text("请输入新密码（至少6位）")
                                .foregroundColor(.white.opacity(0.5))
                        }
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

            // 确认密码输入框
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 20)

                if showPassword {
                    TextField("", text: $confirmPassword)
                        .placeholder(when: confirmPassword.isEmpty) {
                            Text("请确认新密码")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .foregroundColor(.white)
                } else {
                    SecureField("", text: $confirmPassword)
                        .placeholder(when: confirmPassword.isEmpty) {
                            Text("请确认新密码")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)

            // 错误提示
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.red.opacity(0.8))
                .cornerRadius(8)
            }

            // 确认按钮
            Button(action: updatePassword) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.3, green: 0.6, blue: 0.1)))
                } else {
                    Text("确认修改")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.1))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canUpdatePassword ? Color.white : Color.white.opacity(0.5))
            .cornerRadius(12)
            .disabled(!canUpdatePassword || isLoading)
        }
    }

    // MARK: - 成功页面

    private var successView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
                .padding(.top, 40)

            Text("密码修改成功")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text("您的密码已成功修改\n请使用新密码登录")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button(action: {
                dismiss()
            }) {
                Text("返回登录")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.1))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .padding(.top, 20)
        }
    }

    // MARK: - Helpers

    private var canUpdatePassword: Bool {
        return newPassword.count >= 6 && newPassword == confirmPassword
    }

    // MARK: - Actions

    private func sendVerificationCode() {
        guard !email.isEmpty else {
            errorMessage = "请输入邮箱地址"
            return
        }

        guard email.contains("@") && email.contains(".") else {
            errorMessage = "请输入有效的邮箱地址"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authManager.sendOTP(email: email)
                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        currentStep = 1
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let errorDesc = error.localizedDescription.lowercased()
                    if errorDesc.contains("network") || errorDesc.contains("connection") {
                        errorMessage = "网络连接不稳定，请检查网络后重试"
                    } else if errorDesc.contains("rate") || errorDesc.contains("limit") {
                        errorMessage = "发送过于频繁，请稍后再试"
                    } else {
                        errorMessage = "发送失败: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func verifyCode() {
        guard verificationCode.count == 6 else {
            errorMessage = "请输入完整的6位验证码"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authManager.verifyOTP(email: email, token: verificationCode)
                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        currentStep = 2
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "验证码错误或已过期"
                }
            }
        }
    }

    private func updatePassword() {
        guard newPassword.count >= 6 else {
            errorMessage = "密码至少需要6位"
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "两次输入的密码不一致"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authManager.updatePassword(newPassword: newPassword)
                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        currentStep = 3
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "密码修改失败: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView(initialEmail: .constant("test@example.com"))
}
