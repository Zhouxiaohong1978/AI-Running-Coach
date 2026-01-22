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
    @StateObject private var authManager = AuthManager.shared
    @State private var currentNonce: String?
    @State private var errorMessage: String?

    var body: some View {
        SignInWithAppleButtonRepresentable(
            onRequest: handleSignInWithAppleRequest,
            onCompletion: handleSignInWithAppleCompletion
        )
        .frame(height: 50)
        .cornerRadius(12)
    }

    private func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        print("🍎 [Apple Sign In] 开始请求...")
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        print("🍎 [Apple Sign In] Nonce已生成: \(nonce.prefix(10))...")
    }

    private func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            print("🍎 [Apple Sign In] 授权成功")
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("❌ [Apple Sign In] 无法获取Apple ID凭证")
                errorMessage = "无法获取Apple ID凭证"
                return
            }

            print("🍎 [Apple Sign In] 开始调用Supabase认证...")
            Task {
                do {
                    try await authManager.signInWithApple(idToken: idTokenString, nonce: nonce)
                    print("✅ [Apple Sign In] 登录成功")
                } catch {
                    print("❌ [Apple Sign In] 登录失败: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                }
            }

        case .failure(let error):
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                print("🍎 [Apple Sign In] 用户取消")
                // 用户取消了登录，不显示错误
                return
            }
            print("❌ [Apple Sign In] 授权失败: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
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

// MARK: - UIViewRepresentable

struct SignInWithAppleButtonRepresentable: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(
            authorizationButtonType: .signIn,
            authorizationButtonStyle: .black
        )
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleAuthorizationAppleIDButtonPress),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }

    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void

        init(onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
             onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }

        @objc func handleAuthorizationAppleIDButtonPress() {
            print("🍎 [Apple Sign In] 按钮被点击")
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            onRequest(request)

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            print("🍎 [Apple Sign In] 开始执行授权请求...")
            authorizationController.performRequests()
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            print("🍎 [Apple Sign In] 获取presentation anchor...")

            // 使用更可靠的方式获取window
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
                // 返回第一个场景的第一个window作为fallback
                return UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first?.windows.first ?? UIWindow()
            }

            print("✅ [Apple Sign In] Window找到")
            return validWindow
        }
    }
}
