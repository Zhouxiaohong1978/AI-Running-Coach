import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { callBailian } from "../_shared/bailian.ts";

/**
 * 生成训练计划 Edge Function
 *
 * 请求格式：
 * {
 *   goal: string,           // 训练目标（如 "5km入门"）
 *   avgPace?: number,       // 平均配速（分钟/公里）
 *   maxDistance?: number,   // 最长距离（公里）
 *   weeklyRuns: number,     // 每周跑步次数
 *   durationWeeks: number   // 计划周期（周）
 * }
 */

interface GeneratePlanRequest {
  goal: string;
  avgPace?: number;
  maxDistance?: number;
  weeklyRuns: number;
  durationWeeks: number;
}

interface DailyTask {
  dayOfWeek: number;
  type: string;
  targetDistance?: number;
  targetPace?: string;
  description: string;
}

interface WeekPlan {
  weekNumber: number;
  theme: string;
  dailyTasks: DailyTask[];
}

interface TrainingPlan {
  goal: string;
  durationWeeks: number;
  difficulty: string;
  weeklyPlans: WeekPlan[];
  tips: string[];
}

Deno.serve(async (req: Request) => {
  // CORS 处理
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  try {
    // 解析请求
    const body: GeneratePlanRequest = await req.json();
    const { goal, avgPace, maxDistance, weeklyRuns, durationWeeks } = body;

    console.log(`📋 收到训练计划生成请求: ${goal}, ${durationWeeks}周`);

    // 构建 prompt
    const userDataContext = buildUserContext(avgPace, maxDistance, weeklyRuns);
    const prompt = buildPrompt(goal, durationWeeks, userDataContext);

    // 调用阿里云百炼生成计划
    const aiResponse = await callBailian(
      [
        {
          role: "system",
          content: "你是一位专业的跑步教练，擅长制定科学、个性化的跑步训练计划。你需要根据用户目标和历史数据，生成详细的周训练计划，并以 JSON 格式返回。"
        },
        {
          role: "user",
          content: prompt
        }
      ],
      "qwen-plus",
      0.7
    );

    // 解析 AI 返回的 JSON
    const plan = parseAIResponse(aiResponse, goal, durationWeeks);

    console.log(`✅ 训练计划生成成功: ${plan.weeklyPlans.length}周计划`);

    // 返回结果
    return new Response(
      JSON.stringify({
        success: true,
        plan,
        timestamp: new Date().toISOString(),
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    console.error("❌ 训练计划生成失败:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "训练计划生成失败",
        timestamp: new Date().toISOString(),
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});

/**
 * 构建用户数据上下文
 */
function buildUserContext(
  avgPace?: number,
  maxDistance?: number,
  weeklyRuns?: number
): string {
  const parts: string[] = [];

  if (avgPace) {
    const mins = Math.floor(avgPace);
    const secs = Math.floor((avgPace - mins) * 60);
    parts.push(`平均配速: ${mins}'${secs}"/km`);
  } else {
    parts.push("平均配速: 无历史数据（新手）");
  }

  if (maxDistance) {
    parts.push(`最长跑步距离: ${maxDistance.toFixed(1)}km`);
  } else {
    parts.push("最长跑步距离: 无历史数据");
  }

  parts.push(`每周跑步频率: ${weeklyRuns || 3}次`);

  return parts.join("\n");
}

/**
 * 构建 AI Prompt
 */
function buildPrompt(
  goal: string,
  durationWeeks: number,
  userContext: string
): string {
  return `请为用户生成一个 ${durationWeeks} 周的跑步训练计划。

**用户目标**：${goal}

**用户当前水平**：
${userContext}

**要求**：
1. 根据用户目标和当前水平，制定科学的渐进式训练计划
2. 每周3-5次训练，包含不同类型的训练：轻松跑、节奏跑、间歇跑、长距离跑、休息日
3. 难度递增合理，避免运动损伤
4. 包含每周训练主题和具体任务

**请严格按照以下 JSON 格式返回**（只返回 JSON，不要其他文字）：

\`\`\`json
{
  "goal": "${goal}",
  "durationWeeks": ${durationWeeks},
  "difficulty": "beginner|intermediate|advanced",
  "weeklyPlans": [
    {
      "weekNumber": 1,
      "theme": "适应期 - 建立跑步习惯",
      "dailyTasks": [
        {
          "dayOfWeek": 1,
          "type": "easy_run",
          "targetDistance": 3.0,
          "targetPace": "6'30\\"",
          "description": "轻松跑3公里，配速不要求，重点是完成"
        },
        {
          "dayOfWeek": 3,
          "type": "easy_run",
          "targetDistance": 3.5,
          "targetPace": "6'30\\"",
          "description": "轻松跑3.5公里"
        },
        {
          "dayOfWeek": 6,
          "type": "long_run",
          "targetDistance": 4.0,
          "targetPace": "7'00\\"",
          "description": "周末长跑4公里，慢慢跑"
        }
      ]
    }
  ],
  "tips": [
    "每次跑步前做5-10分钟热身",
    "跑后拉伸很重要，预防受伤",
    "感觉疲劳时要休息，不要硬撑",
    "保持70-80%最大心率的强度"
  ]
}
\`\`\`

**任务类型说明**：
- easy_run: 轻松跑（恢复性训练）
- tempo_run: 节奏跑（提高乳酸阈值）
- interval: 间歇跑（提高速度）
- long_run: 长距离跑（提高耐力）
- rest: 休息日
- cross_training: 交叉训练（游泳、骑行等）

**星期编号**：1=周一, 2=周二, ..., 7=周日`;
}

/**
 * 解析 AI 返回结果
 */
function parseAIResponse(
  response: string,
  goal: string,
  durationWeeks: number
): TrainingPlan {
  try {
    // 提取 JSON（AI 可能返回 markdown 格式）
    let jsonStr = response;
    const jsonMatch = response.match(/```json\s*([\s\S]*?)\s*```/);
    if (jsonMatch) {
      jsonStr = jsonMatch[1];
    }

    // 解析 JSON
    const plan = JSON.parse(jsonStr.trim());

    // 验证必需字段
    if (!plan.weeklyPlans || !Array.isArray(plan.weeklyPlans)) {
      throw new Error("AI 返回的计划格式错误：缺少 weeklyPlans");
    }

    // 确保返回正确的周数
    if (plan.weeklyPlans.length !== durationWeeks) {
      console.warn(`警告: 期望 ${durationWeeks} 周，实际返回 ${plan.weeklyPlans.length} 周`);
    }

    // 确保有训练建议
    if (!plan.tips || plan.tips.length === 0) {
      plan.tips = [
        "循序渐进，不要急于求成",
        "每周增加跑量不超过10%",
        "感觉不适立即停止",
        "保证充足的睡眠和营养"
      ];
    }

    return plan;
  } catch (error) {
    console.error("解析 AI 返回失败，使用后备计划:", error);

    // 返回一个简单的后备计划
    return generateFallbackPlan(goal, durationWeeks);
  }
}

/**
 * 生成后备训练计划（当 AI 失败时）
 */
function generateFallbackPlan(goal: string, weeks: number): TrainingPlan {
  const weeklyPlans: WeekPlan[] = [];

  for (let week = 1; week <= weeks; week++) {
    const baseDistance = 3 + (week - 1) * 0.5;

    weeklyPlans.push({
      weekNumber: week,
      theme: week <= 2 ? "适应期" : week <= 4 ? "基础期" : week <= 6 ? "提高期" : "巩固期",
      dailyTasks: [
        {
          dayOfWeek: 1,
          type: "easy_run",
          targetDistance: baseDistance,
          targetPace: "6'30\"",
          description: `轻松跑${baseDistance.toFixed(1)}公里`
        },
        {
          dayOfWeek: 3,
          type: "easy_run",
          targetDistance: baseDistance + 0.5,
          targetPace: "6'30\"",
          description: `轻松跑${(baseDistance + 0.5).toFixed(1)}公里`
        },
        {
          dayOfWeek: 6,
          type: "long_run",
          targetDistance: baseDistance + 1,
          targetPace: "7'00\"",
          description: `周末长跑${(baseDistance + 1).toFixed(1)}公里`
        }
      ]
    });
  }

  return {
    goal,
    durationWeeks: weeks,
    difficulty: "beginner",
    weeklyPlans,
    tips: [
      "循序渐进，不要急于求成",
      "每周增加跑量不超过10%",
      "跑前热身，跑后拉伸",
      "保证充足的休息和营养"
    ]
  };
}
