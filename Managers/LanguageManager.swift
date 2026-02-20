//
//  LanguageManager.swift
//  AI跑步教练
//
//  App 内即时语言切换
//  原理：.environment(\.locale, ...) + .id(currentLocale) 强制 SwiftUI 用指定语言重建视图树
//  与 EarthLord 方案一致，无需 exit(0) 重启
//

import Foundation
import SwiftUI
import Combine

// MARK: - AppLanguage

enum AppLanguage: String, CaseIterable {
    case system  = "system"
    case zhHans  = "zh-Hans"
    case english = "en"

    var displayName: String {
        let isEN = LanguageManager.shared.currentLocale == "en"
        switch self {
        case .system:  return isEN ? "Follow System" : "跟随系统"
        case .zhHans:  return "简体中文"
        case .english: return "English"
        }
    }

    /// 实际传给 Locale / .id() 的标识符
    var localeIdentifier: String {
        switch self {
        case .system:
            let lang = Locale.preferredLanguages.first ?? "zh-Hans"
            if lang.hasPrefix("en") { return "en" }
            return "zh-Hans"
        case .zhHans:  return "zh-Hans"
        case .english: return "en"
        }
    }
}

// MARK: - LanguageManager

final class LanguageManager: ObservableObject {

    static let shared = LanguageManager()

    /// 用户选择的语言（绑定 Picker）
    @Published var currentLanguage: AppLanguage

    /// 实际生效的 locale 标识符（变化时触发 .id() 重建视图树）
    @Published var currentLocale: String

    private let userDefaultsKey = "app_language"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let saved = UserDefaults.standard.string(forKey: userDefaultsKey) ?? AppLanguage.system.rawValue
        let language = AppLanguage(rawValue: saved) ?? .system
        self.currentLanguage = language
        self.currentLocale = language.localeIdentifier

        // 语言切换时：保存 + 延一帧更新 locale（让 SwiftUI 有机会响应 @Published 变化）
        $currentLanguage
            .sink { [weak self] lang in
                UserDefaults.standard.set(lang.rawValue, forKey: self?.userDefaultsKey ?? "app_language")
                DispatchQueue.main.async {
                    self?.currentLocale = lang.localeIdentifier
                }
            }
            .store(in: &cancellables)
    }
}
