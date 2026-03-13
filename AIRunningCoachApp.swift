//
//  AI跑步教练App.swift
//  AI跑步教练
//
//  Created by 周晓红 on 2026/1/21.
//

import SwiftUI
import RevenueCat

@main
struct AI跑步教练App: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showSplash = true
    @AppStorage("onboarding_completed") private var onboardingCompleted = false

    init() {
        SubscriptionManager.shared.configure()
        _ = LanguageManager.shared
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashVideoView {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            showSplash = false
                        }
                    }
                } else if authManager.isAuthenticated {
                    if onboardingCompleted {
                        HomeView()
                            .environmentObject(subscriptionManager)
                    } else {
                        // 新用户引导流程
                        OnboardingView()
                    }
                } else {
                    LoginView()
                }
            }
            .id(languageManager.currentLocale)
            .environment(\.locale, Locale(identifier: languageManager.currentLocale))
            .environmentObject(languageManager)
        }
    }
}
