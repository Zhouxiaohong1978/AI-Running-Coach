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
        auth: SupabaseClientOptions.AuthOptions(
            emitLocalSessionAsInitialSession: true
        )
    )
)
