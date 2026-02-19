import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * 删除账户 Edge Function
 *
 * 功能：
 * 1. 删除用户的所有业务数据（run_records、user_achievements等）
 * 2. 删除auth.users记录（使用service_role权限）
 * 3. 确保账户完全删除，邮箱可重新注册
 */

Deno.serve(async (req: Request) => {
  try {
    // 1. 获取当前用户ID（从JWT）
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: "未授权" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    // 创建客户端（使用请求中的JWT）
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    });

    // 获取用户信息
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser();

    if (userError || !user) {
      console.error("❌ 获取用户失败:", userError);
      return new Response(
        JSON.stringify({ success: false, error: "获取用户失败" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const userId = user.id;
    console.log(`🗑️ 开始删除用户账户: ${userId}`);

    // 2. 删除业务数据（使用普通客户端）
    console.log("📦 删除跑步记录...");
    await supabaseClient
      .from("run_records")
      .delete()
      .eq("user_id", userId);

    console.log("🏆 删除成就数据...");
    await supabaseClient
      .from("user_achievements")
      .delete()
      .eq("user_id", userId);

    // 如果有其他表，也在这里删除
    // await supabaseClient.from("training_plans").delete().eq("user_id", userId);

    // 3. 删除auth.users记录（需要service_role权限）
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseServiceKey) {
      console.error("❌ 缺少SERVICE_ROLE_KEY环境变量");
      return new Response(
        JSON.stringify({
          success: false,
          error: "服务器配置错误",
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // 创建Admin客户端
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    console.log("👤 删除auth.users记录...");
    const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(
      userId
    );

    if (deleteAuthError) {
      console.error("❌ 删除auth用户失败:", deleteAuthError);
      return new Response(
        JSON.stringify({
          success: false,
          error: `删除认证记录失败: ${deleteAuthError.message}`,
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`✅ 用户账户已完全删除: ${userId}`);

    return new Response(
      JSON.stringify({
        success: true,
        message: "账户已删除",
        timestamp: new Date().toISOString(),
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("❌ 删除账户异常:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "未知错误",
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
