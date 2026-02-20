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

    init() {
        SubscriptionManager.shared.configure()
        _ = LanguageManager.shared
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    HomeView()
                        .environmentObject(subscriptionManager)
                } else {
                    LoginView()
                }
            }
            .id(languageManager.currentLocale)                                       // locale 变化时重建整个视图树
            .environment(\.locale, Locale(identifier: languageManager.currentLocale)) // 告诉 SwiftUI Text 用哪个语言
            .environmentObject(languageManager)
        }
    }
}
