import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * 删除账户 Edge Function
 */

Deno.serve(async (req: Request) => {
  console.log("🔍 收到删除账户请求");

  try {
    // 创建Supabase客户端
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const authHeader = req.headers.get("Authorization")!;

    console.log(`🔑 Authorization: ${authHeader ? "存在" : "不存在"}`);

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // 获取用户信息
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      console.error("❌ 获取用户失败:", userError);
      console.log("🔍 尝试从JWT解析用户ID...");

      // 尝试从JWT直接解析用户ID（兜底方案）
      if (authHeader && authHeader.startsWith("Bearer ")) {
        try {
          const token = authHeader.replace("Bearer ", "");
          const payload = JSON.parse(atob(token.split(".")[1]));
          const userId = payload.sub;

          console.log(`✅ 从JWT解析到用户ID: ${userId}`);

          // 使用解析出的userId继续删除流程
          await deleteUserData(supabase, userId);
          return new Response(
            JSON.stringify({ success: true, message: "账户已删除" }),
            { status: 200, headers: { "Content-Type": "application/json" } }
          );
        } catch (parseError) {
          console.error("❌ JWT解析失败:", parseError);
        }
      }

      return new Response(
        JSON.stringify({ success: false, error: "获取用户失败" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const userId = user.id;
    console.log(`🗑️ 开始删除用户账户: ${userId}`);

    // 删除数据
    await deleteUserData(supabase, userId);

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

async function deleteUserData(supabase: any, userId: string) {
  // 删除业务数据
  console.log("📦 删除跑步记录...");
  await supabase.from("run_records").delete().eq("user_id", userId);

  console.log("🏆 删除成就数据...");
  await supabase.from("user_achievements").delete().eq("user_id", userId);

  // 删除auth.users记录
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    supabaseServiceKey,
    {
      auth: { autoRefreshToken: false, persistSession: false },
    }
  );

  console.log("👤 删除auth.users记录...");
  const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(
    userId
  );

  if (deleteAuthError) {
    console.error("❌ 删除auth用户失败:", deleteAuthError);
    throw new Error(`删除认证记录失败: ${deleteAuthError.message}`);
  }

  console.log(`✅ 用户账户已完全删除: ${userId}`);
}
