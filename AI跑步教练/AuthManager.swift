//
//  AuthManager.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import Foundation
import Supabase
import Combine
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false

    private init() {
        // 检查是否已有登录会话
        Task {
            await checkSession()
        }
    }

    // MARK: - Session Management

    /// 检查当前会话
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            isAuthenticated = true
            print("✅ [AuthManager] 检测到活跃会话: \(session.user.email ?? "unknown")")
        } catch {
            print("⚠️ [AuthManager] 无活跃会话: \(error.localizedDescription)")
            currentUser = nil
            isAuthenticated = false
        }
    }

    // MARK: - Authentication

    /// 用户注册
    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        print("📝 [AuthManager] 开始注册: \(email)")

        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )

        print("📝 [AuthManager] 注册响应: user=\(response.user.id.uuidString), session=\(response.session != nil)")

        // 检查是否有 session（有些配置需要邮箱验证）
        if let session = response.session {
            currentUser = session.user
            isAuthenticated = true
            print("✅ [AuthManager] 注册成功，已自动登录")
        } else {
            currentUser = response.user
            isAuthenticated = true
            print("⚠️ [AuthManager] 注册成功，但可能需要邮箱验证")
        }
    }

    /// 用户登录
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        print("🔑 [AuthManager] 开始登录: \(email)")

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            currentUser = session.user
            isAuthenticated = true
            print("✅ [AuthManager] 登录成功: user=\(session.user.id.uuidString)")
        } catch {
            print("❌ [AuthManager] 登录失败: \(error.localizedDescription)")
            // 检查是否是邮箱未验证的错误
            if error.localizedDescription.contains("Email not confirmed") ||
               error.localizedDescription.contains("email_not_confirmed") {
                throw NSError(domain: "AuthManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "请先验证邮箱后再登录"])
            }
            throw error
        }
    }

    /// 用户登出
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }

        print("🚪 [AuthManager] 开始退出登录...")
        try await supabase.auth.signOut()
        currentUser = nil
        isAuthenticated = false
        print("✅ [AuthManager] 已退出登录")
    }

    /// 重置密码（发送邮件）
    func resetPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }

        try await supabase.auth.resetPasswordForEmail(email)
    }

    /// 发送OTP验证码到邮箱（用于找回密码）
    func sendOTP(email: String) async throws {
        print("📧 [AuthManager] 发送OTP验证码到: \(email)")
        try await supabase.auth.signInWithOTP(email: email)
        print("✅ [AuthManager] OTP验证码已发送")
    }

    /// 验证OTP验证码
    func verifyOTP(email: String, token: String) async throws {
        isLoading = true
        defer { isLoading = false }

        print("🔐 [AuthManager] 验证OTP: \(token)")
        let session = try await supabase.auth.verifyOTP(
            email: email,
            token: token,
            type: .email
        )
        currentUser = session.user
        isAuthenticated = true
        print("✅ [AuthManager] OTP验证成功")
    }

    /// 更新密码
    func updatePassword(newPassword: String) async throws {
        isLoading = true
        defer { isLoading = false }

        print("🔑 [AuthManager] 更新密码...")
        try await supabase.auth.update(user: UserAttributes(password: newPassword))
        print("✅ [AuthManager] 密码更新成功")
    }

    /// Apple ID 登录
    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        defer { isLoading = false }

        print("🍎 [AuthManager] 开始Apple登录...")

        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )

        currentUser = session.user
        isAuthenticated = true
        print("✅ [AuthManager] Apple登录成功: \(session.user.email ?? "unknown")")
    }

    // MARK: - User Info

    /// 获取当前用户ID
    var currentUserId: UUID? {
        return currentUser?.id
    }

    /// 获取当前用户邮箱
    var currentUserEmail: String? {
        return currentUser?.email
    }
}
