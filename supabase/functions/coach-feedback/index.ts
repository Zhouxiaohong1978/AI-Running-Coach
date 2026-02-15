import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { callBailian } from "../_shared/bailian.ts";

/**
 * AI 教练实时反馈 Edge Function
 *
 * 请求格式：
 * {
 *   currentPace: number,    // 当前配速（分钟/公里）
 *   targetPace?: number,    // 目标配速（可选）
 *   distance: number,       // 已跑距离（公里）
 *   totalDistance?: number, // 总目标距离（可选）
 *   duration: number,       // 已跑时长（秒）
 *   heartRate?: number,     // 心率（可选）
 *   coachStyle?: string     // 教练风格：encouraging/strict/calm
 * }
 */

interface CoachFeedbackRequest {
  currentPace: number;
  targetPace?: number;
  distance: number;
  totalDistance?: number;
  duration: number;
  heartRate?: number;
  coachStyle?: string;
  kmSplits?: number[];
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
    const body: CoachFeedbackRequest = await req.json();
    const {
      currentPace,
      targetPace,
      distance,
      totalDistance,
      duration,
      heartRate,
      coachStyle = "encouraging"
    } = body;

    console.log(`🏃 收到教练反馈请求: 距离=${distance}km, 配速=${currentPace}min/km`);

    // 构建运动数据描述
    const statsDescription = buildStatsDescription(body);

    // 构建 prompt
    const hasKmSplits = !!(body.kmSplits && body.kmSplits.length > 0);
    const prompt = buildFeedbackPrompt(statsDescription, coachStyle, hasKmSplits);

    // 调用阿里云百炼生成反馈
    const feedback = await callBailian(
      [
        {
          role: "system",
          content: getSystemPrompt(coachStyle)
        },
        {
          role: "user",
          content: prompt
        }
      ],
      "qwen-plus",
      0.8  // 稍高的温度，让反馈更自然
    );

    // 清理反馈（移除多余符号）
    const cleanFeedback = cleanFeedbackText(feedback);

    console.log(`✅ 教练反馈生成成功: ${cleanFeedback.substring(0, 30)}...`);

    // 返回结果
    return new Response(
      JSON.stringify({
        success: true,
        feedback: cleanFeedback,
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
    console.error("❌ 教练反馈生成失败:", error);

    // 返回后备反馈
    const fallbackFeedback = getFallbackFeedback();

    return new Response(
      JSON.stringify({
        success: true,  // 即使失败也返回成功，使用后备反馈
        feedback: fallbackFeedback,
        timestamp: new Date().toISOString(),
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});

/**
 * 获取系统提示词（根据教练风格）
 */
function getSystemPrompt(style: string): string {
  const basePrompt = "你是一位专业的跑步教练，正在通过语音为用户提供实时跑步指导。";

  const stylePrompts = {
    encouraging: "你的风格是鼓励型，热情、积极，善于激励用户，用正面的语言帮助用户坚持下去。",
    strict: "你的风格是严格型，专业、直接，注重科学训练，会指出问题并给出明确建议。",
    calm: "你的风格是温和型，平和、耐心，像朋友一样陪伴用户，给予温暖的支持。"
  };

  const styleDesc = stylePrompts[style as keyof typeof stylePrompts] || stylePrompts.encouraging;

  return `${basePrompt}${styleDesc}

**重要要求**：
1. 反馈要简短（15-25个字），适合语音播报
2. 用口语化的表达，像在面对面交流
3. 根据用户当前状态给予即时、具体的建议
4. 不要使用书面语、专业术语
5. 语气自然，有感染力`;
}

/**
 * 构建运动数据描述
 */
function buildStatsDescription(data: CoachFeedbackRequest): string {
  const parts: string[] = [];

  // 配速信息
  const paceMin = Math.floor(data.currentPace);
  const paceSec = Math.floor((data.currentPace - paceMin) * 60);
  parts.push(`当前配速: ${paceMin}分${paceSec}秒/公里`);

  if (data.targetPace) {
    const targetMin = Math.floor(data.targetPace);
    const targetSec = Math.floor((data.targetPace - targetMin) * 60);
    parts.push(`目标配速: ${targetMin}分${targetSec}秒/公里`);

    // 配速对比
    const paceGap = data.currentPace - data.targetPace;
    if (Math.abs(paceGap) > 0.5) {
      parts.push(paceGap > 0 ? "当前偏慢" : "当前偏快");
    } else {
      parts.push("配速合适");
    }
  }

  // 距离信息
  parts.push(`已跑距离: ${data.distance.toFixed(2)}公里`);
  if (data.totalDistance) {
    const remaining = data.totalDistance - data.distance;
    parts.push(`剩余距离: ${remaining.toFixed(2)}公里`);

    // 进度百分比
    const progress = (data.distance / data.totalDistance * 100).toFixed(0);
    parts.push(`完成进度: ${progress}%`);
  }

  // 时长信息
  const mins = Math.floor(data.duration / 60);
  const secs = Math.floor(data.duration % 60);
  parts.push(`已跑时间: ${mins}分${secs}秒`);

  // 心率信息
  if (data.heartRate) {
    parts.push(`心率: ${data.heartRate}bpm`);

    // 心率区间判断（简单判断）
    if (data.heartRate > 170) {
      parts.push("心率偏高");
    } else if (data.heartRate > 150) {
      parts.push("心率适中");
    } else if (data.heartRate > 130) {
      parts.push("心率正常");
    } else {
      parts.push("心率偏低");
    }
  }

  // 每公里分段配速
  if (data.kmSplits && data.kmSplits.length > 0) {
    parts.push("\n每公里分段配速:");
    data.kmSplits.forEach((splitSec, i) => {
      const min = Math.floor(splitSec / 60);
      const sec = Math.floor(splitSec % 60);
      parts.push(`  第${i + 1}公里: ${min}分${sec.toString().padStart(2, '0')}秒`);
    });

    // 计算分段分析
    const avg = data.kmSplits.reduce((a, b) => a + b, 0) / data.kmSplits.length;
    const fastest = Math.min(...data.kmSplits);
    const slowest = Math.max(...data.kmSplits);
    const fastestKm = data.kmSplits.indexOf(fastest) + 1;
    const slowestKm = data.kmSplits.indexOf(slowest) + 1;
    const variation = ((slowest - fastest) / avg * 100).toFixed(1);

    parts.push(`分段分析: 最快第${fastestKm}公里, 最慢第${slowestKm}公里, 配速波动${variation}%`);

    // 判断是否有后半程掉速
    if (data.kmSplits.length >= 2) {
      const mid = Math.floor(data.kmSplits.length / 2);
      const firstHalf = data.kmSplits.slice(0, mid).reduce((a, b) => a + b, 0) / mid;
      const secondHalf = data.kmSplits.slice(mid).reduce((a, b) => a + b, 0) / (data.kmSplits.length - mid);
      if (secondHalf > firstHalf * 1.05) {
        parts.push("趋势: 后半程掉速");
      } else if (firstHalf > secondHalf * 1.05) {
        parts.push("趋势: 负分段（越跑越快）");
      } else {
        parts.push("趋势: 配速均匀");
      }
    }
  }

  return parts.join("\n");
}

/**
 * 构建反馈提示词
 */
function buildFeedbackPrompt(statsDescription: string, style: string, hasKmSplits: boolean): string {
  if (hasKmSplits) {
    // 跑后总结模式：更详细的分析
    return `用户刚完成一次跑步，数据如下：

${statsDescription}

请根据以上数据（特别是每公里分段配速），给用户一段跑后总结建议（50-80个字）。

要求：
1. 先肯定表现，再分析配速节奏（是否均匀、哪段掉速、是否负分段等）
2. 给出1-2条具体改进建议（如前期压配速、加强后半程耐力等）
3. 语气要符合${style === 'encouraging' ? '鼓励型' : style === 'strict' ? '严格型' : '温和型'}风格
4. 口语化，不要用列表格式，用自然段落`;
  }

  return `用户正在跑步，当前状态如下：

${statsDescription}

请根据以上数据，给用户一句简短的实时反馈（15-25个字）。

**反馈示例**：
- 鼓励型："配速很稳定，保持住，你可以的！"
- 严格型："心率过高，放慢速度，控制呼吸。"
- 温和型："跑得不错，慢慢来，享受过程。"

注意：
1. 只返回一句话，不要多余解释
2. 语气要符合${style === 'encouraging' ? '鼓励型' : style === 'strict' ? '严格型' : '温和型'}风格
3. 口语化，自然流畅`;
}

/**
 * 清理反馈文本
 */
function cleanFeedbackText(text: string): string {
  return text
    .trim()
    .replace(/^["']|["']$/g, '')  // 移除首尾引号
    .replace(/\n+/g, ' ')          // 换行变空格
    .replace(/\s+/g, ' ')          // 多个空格变一个
    .substring(0, 300);             // 限制长度
}

/**
 * 获取后备反馈（AI 失败时使用）
 */
function getFallbackFeedback(): string {
  const fallbacks = [
    "配速稳定，保持节奏，你做得很好！",
    "继续坚持，你已经跑了这么远了！",
    "呼吸均匀，保持这个状态！",
    "很棒的表现，继续加油！",
    "注意配速，不要太快也不要太慢。",
    "保持节奏，稳定前进！",
    "你的状态不错，继续保持！",
    "专注呼吸，放松肩膀，跑得更轻松。"
  ];

  // 随机返回一个
  return fallbacks[Math.floor(Math.random() * fallbacks.length)];
}
