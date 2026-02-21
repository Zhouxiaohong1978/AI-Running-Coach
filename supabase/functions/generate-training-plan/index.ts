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
 *   durationWeeks: number,  // 计划周期（周）
 *   currentPlan?: object,   // 用户修改后的当前计划（用于重新生成）
 *   preferences?: object    // 用户偏好设置
 * }
 */

interface TrainingPreferences {
  weeklyFrequency?: number;    // 每周训练次数（3-5）
  preferredDays?: number[];    // 偏好训练日（1-7，周一到周日）
  intensityLevel?: string;     // 强度等级："easy" | "balanced" | "intense"
}

interface GeneratePlanRequest {
  goal: string;
  avgPace?: number;
  maxDistance?: number;
  weeklyRuns: number;
  durationWeeks: number;
  currentPlan?: TrainingPlan;        // 用户修改后的计划
  preferences?: TrainingPreferences;  // 用户偏好
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
    const { goal, avgPace, maxDistance, weeklyRuns, durationWeeks, currentPlan, preferences } = body;

    console.log(`📋 收到训练计划生成请求: ${goal}, ${durationWeeks}周`);
    if (currentPlan) {
      console.log(`🔄 重新生成模式 - 参考用户修改的计划`);
    }
    if (preferences) {
      console.log(`⚙️  用户偏好: 每周${preferences.weeklyFrequency || weeklyRuns}次, 强度${preferences.intensityLevel || '默认'}`);
    }

    // 构建 prompt
    const userDataContext = buildUserContext(avgPace, maxDistance, weeklyRuns);
    const prompt = buildPrompt(goal, durationWeeks, userDataContext, preferences, currentPlan);

    // 根据计划周数动态计算 max_tokens（每周约 150 tokens + 基础 300，确保快速生成）
    const maxTokens = Math.min(durationWeeks * 150 + 300, 1500);

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
      "qwen-turbo",
      0.7,
      maxTokens,
      25000  // 计划生成允许 25 秒，比实时反馈的 8 秒更宽裕
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
  userContext: string,
  preferences?: TrainingPreferences,
  currentPlan?: TrainingPlan
): string {
  let prompt = `请为用户生成一个 ${durationWeeks} 周的跑步训练计划。

**用户目标**：${goal}

**用户当前水平**：
${userContext}`;

  // 添加用户偏好说明
  if (preferences) {
    prompt += `\n\n**用户偏好**：`;

    if (preferences.weeklyFrequency) {
      prompt += `\n- 每周训练 ${preferences.weeklyFrequency} 次`;
    }

    if (preferences.preferredDays && preferences.preferredDays.length > 0) {
      const dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      const days = preferences.preferredDays.map(d => dayNames[d - 1]).join('、');
      prompt += `\n- 偏好训练日：${days}`;
    }

    if (preferences.intensityLevel === 'easy') {
      prompt += `\n- 强度偏好：以轻松跑为主，减少高强度训练（间歇跑）`;
    } else if (preferences.intensityLevel === 'intense') {
      prompt += `\n- 强度偏好：追求突破，可以增加节奏跑和间歇跑`;
    } else {
      prompt += `\n- 强度偏好：平衡各种训练类型`;
    }
  }

  // 序列化用户修改后的计划，让 AI 严格保留每周各自的安排（每周独立，互不影响）
  if (currentPlan && currentPlan.weeklyPlans && currentPlan.weeklyPlans.length > 0) {
    const typeNames: Record<string, string> = {
      easy_run: '轻松跑', tempo_run: '节奏跑', interval: '间歇跑',
      long_run: '长距离跑', cross_training: '交叉训练', rest: '休息'
    };
    const dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    const allDays = [1, 2, 3, 4, 5, 6, 7];

    prompt += `\n\n**【必须严格遵守】用户已确认的各周独立安排**：`;
    prompt += `\n每一周的训练日和距离均已由用户确认，各周互相独立，不得以任何周为模板套用其他周：`;

    for (const week of currentPlan.weeklyPlans) {
      const trainTasks = week.dailyTasks
        .filter(t => t.type !== 'rest')
        .sort((a, b) => a.dayOfWeek - b.dayOfWeek);
      const restDayNums = allDays.filter(d => !trainTasks.find(t => t.dayOfWeek === d));

      const trainStr = trainTasks
        .map(t => {
          const typeName = typeNames[t.type] || t.type;
          const dist = t.targetDistance ? `${t.targetDistance}km` : '';
          return `${dayNames[t.dayOfWeek - 1]}${dist}`;
        })
        .join('、');
      const restStr = restDayNums.map(d => dayNames[d - 1]).join('、');

      prompt += `\n  第${week.weekNumber}周 训练日：${trainStr || '无'}；休息日：${restStr}`;
    }

    prompt += `\n\n**严格要求**：`;
    prompt += `\n- 以上每周的训练日/休息日安排各自独立有效，不得相互覆盖`;
    prompt += `\n- 每周的训练距离必须和上面完全一致，不得修改`;
    prompt += `\n- 你只能优化：训练类型（如轻松跑→节奏跑）、配速建议、训练描述文字`;
  }

  prompt += `\n\n科学渐进，难度递增合理`;

  return prompt + `

只返回JSON：
\`\`\`json
{
  "goal": "${goal}",
  "durationWeeks": ${durationWeeks},
  "difficulty": "beginner/intermediate/advanced",
  "weeklyPlans": [
    {
      "weekNumber": 1,
      "theme": "适应期",
      "dailyTasks": [
        {"dayOfWeek": 1, "type": "easy_run", "targetDistance": 3, "targetPace": "6'30\\"", "description": "轻松跑3km"}
      ]
    }
  ],
  "tips": ["跑前热身", "跑后拉伸"]
}
\`\`\`
类型: easy_run/tempo_run/interval/long_run/rest`;
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
