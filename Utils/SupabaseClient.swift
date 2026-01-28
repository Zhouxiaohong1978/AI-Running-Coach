//
//  SupabaseClient.swift
//  AI跑步教练
//
//  全局 Supabase 客户端实例
//

import Foundation
import Supabase

/// 全局 Supabase 客户端实例
/// 在整个应用中共享使用
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://aisgbqzksfzdlbjdcwpn.supabase.co")!,
    supabaseKey: "sb_publishable_Mr8yLtY7MDtlWReRFidL3w_Jn_Kswgl",
    options: SupabaseClientOptions(
        auth: .init(
            // 修复警告：启用新的 session 行为
            // 确保本地存储的 session 总是被发出，无论其有效性或过期状态
            emitLocalSessionAsInitialSession: true
        )
    )
)
