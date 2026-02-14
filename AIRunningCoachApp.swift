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

    init() {
        SubscriptionManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                HomeView()
                    .environmentObject(subscriptionManager)
            } else {
                LoginView()
            }
        }
    }
}
