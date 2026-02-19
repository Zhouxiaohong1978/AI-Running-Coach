//
//  SignInWithAppleButton.swift
//  AI跑步教练
//
//  Created by Claude Code
//

import SwiftUI
import AuthenticationServices
import CryptoKit

struct SignInWithAppleButton: View {
    @StateObject private var viewModel = AppleSignInViewModel()

    var body: some View {
        Button(action: viewModel.handleAppleSignIn) {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .medium))
                Text("通过 Apple 登录")
                    .font(.system(size: 17, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .cornerRadius(12)
        }
        .alert("登录失败", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
    }
}

// MARK: - ViewModel

@MainActor
class AppleSignInViewModel: ObservableObject {
    @Published var showError = false
    @Published var errorMessage: String?

    private var coordinator: AppleSignInCoordinator?
    private let authManager = AuthManager.shared

    func handleAppleSignIn() {
        print("🍎 [Apple Sign In] 按钮被点击")
        let nonce = randomNonceString()

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        print("🍎 [Apple Sign In] Nonce已生成: \(nonce.prefix(10))...")

        // 创建 coordinator 并保持引用
        let newCoordinator = AppleSignInCoordinator(
            nonce: nonce,
            authManager: authManager,
            onError: { [weak self] error in
                self?.errorMessage = error
                self?.showError = true
            }
        )
        coordinator = newCoordinator

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = newCoordinator
        authorizationController.presentationContextProvider = newCoordinator
        print("🍎 [Apple Sign In] 开始执行授权请求...")
        authorizationController.performRequests()
    }

    // MARK: - Helper Functions

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - Apple Sign In Coordinator

class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let nonce: String
    let authManager: AuthManager
    let onError: (String) -> Void

    init(nonce: String, authManager: AuthManager, onError: @escaping (String) -> Void) {
        self.nonce = nonce
        self.authManager = authManager
        self.onError = onError
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 [Apple Sign In] 授权成功")
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("❌ [Apple Sign In] 无法获取Apple ID凭证")
            onError("无法获取Apple ID凭证")
            return
        }

        // 提取Apple返回的姓名（仅首次授权时有值）
        var userName: String?
        if let fullName = appleIDCredential.fullName {
            let givenName = fullName.givenName ?? ""
            let familyName = fullName.familyName ?? ""

            // 中文习惯：姓+名
            if !familyName.isEmpty || !givenName.isEmpty {
                userName = familyName + givenName
                print("🍎 [Apple Sign In] 获取到用户姓名: \(userName!)")
            }
        }

        print("🍎 [Apple Sign In] 开始调用Supabase认证...")
        Task { @MainActor in
            do {
                try await authManager.signInWithApple(idToken: idTokenString, nonce: nonce)
                print("✅ [Apple Sign In] 登录成功")

                // 如果Apple返回了姓名且用户还没有设置过用户名，则保存
                if let name = userName, authManager.currentUserName == nil {
                    try? await authManager.updateUserName(name)
                    UserDefaults.standard.set(name, forKey: "user_name")
                    print("✅ [Apple Sign In] 已保存用户名: \(name)")
                }
            } catch {
                print("❌ [Apple Sign In] 登录失败: \(error.localizedDescription)")
                onError(error.localizedDescription)
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError,
           authError.code == .canceled {
            print("🍎 [Apple Sign In] 用户取消")
            return
        }
        print("❌ [Apple Sign In] 授权失败: \(error.localizedDescription)")
        onError(error.localizedDescription)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        print("🍎 [Apple Sign In] 获取presentation anchor...")

        let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first { $0.isKeyWindow } ??
            UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first

        guard let validWindow = window else {
            print("❌ [Apple Sign In] 无法找到有效的window")
            return UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first ?? UIWindow()
        }

        print("✅ [Apple Sign In] Window找到")
        return validWindow
    }
}
