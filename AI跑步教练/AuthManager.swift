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
        } catch {
            print("No active session: \(error.localizedDescription)")
            currentUser = nil
            isAuthenticated = false
        }
    }

    // MARK: - Authentication

    /// 用户注册
    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )

        currentUser = response.user
        isAuthenticated = true
    }

    /// 用户登录
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )

        currentUser = session.user
        isAuthenticated = true
    }

    /// 用户登出
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }

        try await supabase.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    /// 重置密码（发送邮件）
    func resetPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }

        try await supabase.auth.resetPasswordForEmail(email)
    }

    /// Apple ID 登录
    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )

        currentUser = session.user
        isAuthenticated = true
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
