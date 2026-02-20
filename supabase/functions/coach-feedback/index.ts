import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { callBailian } from "../_shared/bailian.ts";

/**
 * AI 教练反馈 Edge Function
 *
 * 支持两种模式：
 * 1. 实时反馈（跑步中）：简短语音播报
 * 2. 跑后分析（有 kmSplits）：结构化事实 + 场景分类 + 三段式输出
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
  trainingType?: string;
  goalName?: string;
  language?: string;  // "en" or "zh-Hans"
}

// MARK: - 结构化事实

interface StructuredFacts {
  avgPace: number;           // 平均配速（秒/公里）
  bestKm: number;            // 最快公里编号
  worstKm: number;           // 最慢公里编号
  bestKmPace: number;        // 最快配速（秒）
  worstKmPace: number;       // 最慢配速（秒）
  paceVariability: number;   // 配速波动（max-min，秒）
  paceStdDev: number;        // 配速标准差（秒）
  positiveSplit: boolean;    // 后半程掉速（阈值3%）
  complianceRate: number;    // 达标率（±15秒内的公里占比，0-1）
  firstHalfAvg: number;      // 前半程平均配速（秒）
  secondHalfAvg: number;     // 后半程平均配速（秒）
  totalKm: number;           // 总公里数
  hrZoneSummary?: string;    // 心率区间摘要（预留）
}

type Scene =
  | "恢复跑"
  | "前快后崩"
  | "波动大"
  | "全程偏快风险高"
  | "全程偏慢但稳定"
  | "稳定达标";

interface FeedbackParagraphs {
  summary: string;
  analysis: string;
  suggestion: string;
}

function computeFacts(body: CoachFeedbackRequest): StructuredFacts {
  const splits = body.kmSplits!;
  const n = splits.length;

  const avg = splits.reduce((a, b) => a + b, 0) / n;
  const fastest = Math.min(...splits);
  const slowest = Math.max(...splits);
  const bestKm = splits.indexOf(fastest) + 1;
  const worstKm = splits.indexOf(slowest) + 1;

  // 标准差
  const variance = splits.reduce((sum, s) => sum + (s - avg) ** 2, 0) / n;
  const stdDev = Math.sqrt(variance);

  // 前后半程
  const mid = Math.floor(n / 2);
  const firstHalfAvg = splits.slice(0, mid).reduce((a, b) => a + b, 0) / mid;
  const secondHalfSlice = splits.slice(mid);
  const secondHalfAvg = secondHalfSlice.reduce((a, b) => a + b, 0) / secondHalfSlice.length;

  // 后半程掉速：后半程比前半程慢 >3%
  const positiveSplit = secondHalfAvg > firstHalfAvg * 1.03;

  // 达标率：在目标配速 ±15秒 内的公里占比
  let complianceRate = 0;
  if (body.targetPace && body.targetPace > 0) {
    const targetSec = body.targetPace * 60; // targetPace 是分钟/公里，转为秒
    const compliantKms = splits.filter(s => Math.abs(s - targetSec) <= 15).length;
    complianceRate = compliantKms / n;
  }

  return {
    avgPace: avg,
    bestKm,
    worstKm,
    bestKmPace: fastest,
    worstKmPace: slowest,
    paceVariability: slowest - fastest,
    paceStdDev: stdDev,
    positiveSplit,
    complianceRate,
    firstHalfAvg,
    secondHalfAvg,
    totalKm: n,
  };
}

function classifyScene(facts: StructuredFacts, body: CoachFeedbackRequest): Scene {
  const { positiveSplit, secondHalfAvg, firstHalfAvg, paceStdDev, avgPace, complianceRate } = facts;

  // 恢复跑：trainingType 为 easy_run/rest 或无 targetPace
  if (
    body.trainingType === "easy_run" ||
    body.trainingType === "rest" ||
    !body.targetPace
  ) {
    return "恢复跑";
  }

  const targetSec = body.targetPace * 60;

  // 前快后崩：positiveSplit 且后半程比前半程慢 >5%
  if (positiveSplit && secondHalfAvg > firstHalfAvg * 1.05) {
    return "前快后崩";
  }

  // 配速变异率
  const cv = (paceStdDev / avgPace) * 100;

  // 波动大：变异率 ≥12%
  if (cv >= 12) {
    return "波动大";
  }

  // 全程偏快风险高：均速快于目标 >8% 且稳定
  if (avgPace < targetSec * 0.92 && cv < 12) {
    return "全程偏快风险高";
  }

  // 全程偏慢但稳定：均速慢于目标 >8% 且稳定
  if (avgPace > targetSec * 1.08 && cv < 12) {
    return "全程偏慢但稳定";
  }

  // 稳定达标：稳定且达标率 ≥70%
  if (complianceRate >= 0.7) {
    return "稳定达标";
  }

  // 默认：按达标率判断
  return complianceRate >= 0.5 ? "稳定达标" : "波动大";
}

function formatPaceSec(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = Math.floor(sec % 60);
  return `${m}'${s.toString().padStart(2, "0")}"`;
}

function buildPostRunPrompt(
  facts: StructuredFacts,
  scene: Scene,
  body: CoachFeedbackRequest
): string {
  const isEN = body.language === "en";
  const lines: string[] = [];

  if (isEN) {
    lines.push(`[Scene] ${scene}`);
    lines.push(`[Total Distance] ${facts.totalKm} km`);
    lines.push(`[Avg Pace] ${formatPaceSec(facts.avgPace)}/km`);
    lines.push(`[Fastest] km ${facts.bestKm} at ${formatPaceSec(facts.bestKmPace)}`);
    lines.push(`[Slowest] km ${facts.worstKm} at ${formatPaceSec(facts.worstKmPace)}`);
    lines.push(`[Variation] ${Math.round(facts.paceVariability)}s (StdDev ${Math.round(facts.paceStdDev)}s)`);
    lines.push(`[First Half Avg] ${formatPaceSec(facts.firstHalfAvg)}`);
    lines.push(`[Second Half Avg] ${formatPaceSec(facts.secondHalfAvg)}`);
    lines.push(`[Positive Split] ${facts.positiveSplit ? "Yes" : "No"}`);
    if (body.targetPace) {
      lines.push(`[Target Pace] ${formatPaceSec(body.targetPace * 60)}/km`);
      lines.push(`[Compliance] ${Math.round(facts.complianceRate * 100)}%`);
    }
    if (body.goalName) lines.push(`[Training Goal] ${body.goalName}`);
  } else {
    lines.push(`[场景] ${scene}`);
    lines.push(`[总距离] ${facts.totalKm}公里`);
    lines.push(`[均速] ${formatPaceSec(facts.avgPace)}/km`);
    lines.push(`[最快] 第${facts.bestKm}公里 ${formatPaceSec(facts.bestKmPace)}`);
    lines.push(`[最慢] 第${facts.worstKm}公里 ${formatPaceSec(facts.worstKmPace)}`);
    lines.push(`[波动] ${Math.round(facts.paceVariability)}秒 (标准差${Math.round(facts.paceStdDev)}秒)`);
    lines.push(`[前半程均速] ${formatPaceSec(facts.firstHalfAvg)}`);
    lines.push(`[后半程均速] ${formatPaceSec(facts.secondHalfAvg)}`);
    lines.push(`[掉速] ${facts.positiveSplit ? "是" : "否"}`);
    if (body.targetPace) {
      lines.push(`[目标配速] ${formatPaceSec(body.targetPace * 60)}/km`);
      lines.push(`[达标率] ${Math.round(facts.complianceRate * 100)}%`);
    }
    if (body.goalName) lines.push(`[训练目标] ${body.goalName}`);
  }

  const factsBlock = lines.join("\n");
  const style = body.coachStyle || "encouraging";

  if (isEN) {
    const styleName = style === "encouraging" ? "encouraging" : style === "strict" ? "strict" : "calm";
    return `Below are the pre-calculated running data facts. Write three paragraphs based on them.

${factsBlock}

Output strictly in this format:
[P1] Performance summary (15–25 words, one sentence on pace and rhythm)
[P2] Analysis (20–40 words, data-driven explanation)
[P3] Next-run suggestion (20–40 words, starting with "Next time:", include specific numbers like pace X'XX" and distance Xkm)

Tone: ${styleName}, conversational, no lists.
Output only [P1] [P2] [P3], nothing else.`;
  }

  const styleName = style === "encouraging" ? "鼓励型" : style === "strict" ? "严格型" : "温和型";
  return `以下是系统已计算好的跑步数据事实，请基于这些事实写三段文案。

${factsBlock}

严格按以下格式输出，每段前用标记：
【P1】本次表现总结（15-25字，一句话点评配速节奏）
【P2】原因分析（20-40字，基于数据分析原因）
【P3】下次建议（20-40字，以"下次建议："开头，含具体数字如配速X'XX"、距离Xkm）

语气：${styleName}，口语化，不要用列表格式。
只输出【P1】【P2】【P3】三段，不要输出其他内容。`;
}

function parseParagraphs(text: string): FeedbackParagraphs | null {
  // Support both Chinese 【P1】 and English [P1] marker formats
  const p1Match = text.match(/(?:【P1】|\[P1\])([\s\S]*?)(?=(?:【P2】|\[P2\])|$)/);
  const p2Match = text.match(/(?:【P2】|\[P2\])([\s\S]*?)(?=(?:【P3】|\[P3\])|$)/);
  const p3Match = text.match(/(?:【P3】|\[P3\])([\s\S]*?)$/);

  if (!p1Match || !p2Match || !p3Match) {
    return null;
  }

  const summary = p1Match[1].trim();
  const analysis = p2Match[1].trim();
  const suggestion = p3Match[1].trim();

  if (!summary || !analysis || !suggestion) {
    return null;
  }

  return { summary, analysis, suggestion };
}

// MARK: - Main Handler

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
    const body: CoachFeedbackRequest = await req.json();
    const { coachStyle = "encouraging" } = body;
    const hasKmSplits = !!(body.kmSplits && body.kmSplits.length > 0);

    console.log(`🏃 收到教练反馈请求: 距离=${body.distance}km, 配速=${body.currentPace}min/km, 分段=${hasKmSplits}`);

    let prompt: string;
    let facts: StructuredFacts | null = null;
    let scene: Scene | null = null;

    if (hasKmSplits) {
      // 跑后分析模式：结构化事实 + 场景分类
      facts = computeFacts(body);
      scene = classifyScene(facts, body);
      prompt = buildPostRunPrompt(facts, scene, body);
      console.log(`📊 场景分类: ${scene}, 达标率: ${Math.round(facts.complianceRate * 100)}%`);
    } else {
      // 实时反馈模式
      const statsDescription = buildStatsDescription(body);
      prompt = buildRealtimePrompt(statsDescription, coachStyle, body.language || "zh-Hans");
    }

    // 调用阿里云百炼生成反馈
    const systemPrompt = getSystemPrompt(coachStyle, hasKmSplits, body.language || "zh-Hans");
    const feedback = await callBailian(
      [
        { role: "system", content: systemPrompt },
        { role: "user", content: prompt },
      ],
      "qwen-plus",
      0.7
    );

    // 处理响应
    let cleanFeedback: string;
    let paragraphs: FeedbackParagraphs | null = null;

    if (hasKmSplits) {
      // 跑后模式：尝试解析三段
      paragraphs = parseParagraphs(feedback);
      if (paragraphs) {
        cleanFeedback = `${paragraphs.summary}\n${paragraphs.analysis}\n${paragraphs.suggestion}`;
      } else {
        // 解析失败，用清理后的原文
        cleanFeedback = cleanFeedbackText(feedback, true);
      }
    } else {
      cleanFeedback = cleanFeedbackText(feedback, false);
    }

    console.log(`✅ 教练反馈生成成功: ${cleanFeedback.substring(0, 50)}...`);

    return new Response(
      JSON.stringify({
        success: true,
        feedback: cleanFeedback,
        paragraphs: paragraphs,
        scene: scene,
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

    const fallbackFeedback = getFallbackFeedback();

    return new Response(
      JSON.stringify({
        success: true,
        feedback: fallbackFeedback,
        paragraphs: null,
        scene: null,
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

// MARK: - System Prompt

function getSystemPrompt(style: string, isPostRun: boolean, language: string): string {
  const isEN = language === "en";

  const stylePrompts: Record<string, string> = isEN ? {
    encouraging: "Your style is encouraging: enthusiastic, positive, motivating the user with uplifting language.",
    strict: "Your style is strict: professional, direct, scientifically focused, pointing out issues with clear advice.",
    calm: "Your style is calm: peaceful, patient, accompanying the user like a friend with warm support.",
  } : {
    encouraging: "你的风格是鼓励型，热情、积极，善于激励用户，用正面的语言帮助用户坚持下去。",
    strict: "你的风格是严格型，专业、直接，注重科学训练，会指出问题并给出明确建议。",
    calm: "你的风格是温和型，平和、耐心，像朋友一样陪伴用户，给予温暖的支持。",
  };

  const styleDesc = stylePrompts[style] || stylePrompts.encouraging;

  if (isPostRun) {
    return isEN
      ? `You are a professional running coach providing post-run analysis. ${styleDesc}

IMPORTANT:
1. All data facts have been pre-calculated — just write commentary based on them
2. Strictly output in the format [P1] [P2] [P3]
3. Do not recalculate data; reference the provided figures directly
4. Conversational, natural, engaging
5. Suggestions must include specific numbers`
      : `你是一位专业的跑步教练，正在为用户提供跑后分析。${styleDesc}

**重要要求**：
1. 系统已经计算好了所有数据事实，你只需基于这些事实写文案
2. 严格按照【P1】【P2】【P3】格式输出
3. 不要自己计算数据，直接引用系统提供的数据
4. 口语化，自然流畅，有感染力
5. 建议必须包含具体数字`;
  }

  return isEN
    ? `You are a professional running coach providing real-time voice coaching. ${styleDesc}

IMPORTANT:
1. Keep feedback short (15–25 words), suitable for voice playback
2. Use conversational language, as if speaking face-to-face
3. Give immediate, specific advice based on the user's current state
4. Avoid formal or technical language
5. Natural tone, engaging`
    : `你是一位专业的跑步教练，正在通过语音为用户提供实时跑步指导。${styleDesc}

**重要要求**：
1. 反馈要简短（15-25个字），适合语音播报
2. 用口语化的表达，像在面对面交流
3. 根据用户当前状态给予即时、具体的建议
4. 不要使用书面语、专业术语
5. 语气自然，有感染力`;
}

// MARK: - 实时反馈（保留原逻辑）

function buildStatsDescription(data: CoachFeedbackRequest): string {
  const parts: string[] = [];

  const paceMin = Math.floor(data.currentPace);
  const paceSec = Math.floor((data.currentPace - paceMin) * 60);
  parts.push(`当前配速: ${paceMin}分${paceSec}秒/公里`);

  if (data.targetPace) {
    const targetMin = Math.floor(data.targetPace);
    const targetSec = Math.floor((data.targetPace - targetMin) * 60);
    parts.push(`目标配速: ${targetMin}分${targetSec}秒/公里`);

    const paceGap = data.currentPace - data.targetPace;
    if (Math.abs(paceGap) > 0.5) {
      parts.push(paceGap > 0 ? "当前偏慢" : "当前偏快");
    } else {
      parts.push("配速合适");
    }
  }

  parts.push(`已跑距离: ${data.distance.toFixed(2)}公里`);
  if (data.totalDistance) {
    const remaining = data.totalDistance - data.distance;
    parts.push(`剩余距离: ${remaining.toFixed(2)}公里`);
    const progress = (data.distance / data.totalDistance * 100).toFixed(0);
    parts.push(`完成进度: ${progress}%`);
  }

  const mins = Math.floor(data.duration / 60);
  const secs = Math.floor(data.duration % 60);
  parts.push(`已跑时间: ${mins}分${secs}秒`);

  if (data.heartRate) {
    parts.push(`心率: ${data.heartRate}bpm`);
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

  return parts.join("\n");
}

function buildRealtimePrompt(statsDescription: string, style: string, language: string): string {
  const isEN = language === "en";
  if (isEN) {
    const styleName = style === "encouraging" ? "encouraging" : style === "strict" ? "strict" : "calm";
    return `The user is currently running. Current status:

${statsDescription}

Give the user one short real-time feedback sentence (15–25 words).

Rules:
1. Return only one sentence, no extra explanation
2. Match the ${styleName} tone
3. Conversational and natural`;
  }
  const styleName = style === "encouraging" ? "鼓励型" : style === "strict" ? "严格型" : "温和型";
  return `用户正在跑步，当前状态如下：

${statsDescription}

请根据以上数据，给用户一句简短的实时反馈（15-25个字）。

注意：
1. 只返回一句话，不要多余解释
2. 语气要符合${styleName}风格
3. 口语化，自然流畅`;
}

// MARK: - Helpers

function cleanFeedbackText(text: string, preserveNewlines: boolean): string {
  let cleaned = text
    .trim()
    .replace(/^["']|["']$/g, "");

  if (!preserveNewlines) {
    cleaned = cleaned.replace(/\n+/g, " ").replace(/\s+/g, " ");
  }

  return cleaned.substring(0, 500);
}

function getFallbackFeedback(): string {
  const fallbacks = [
    "配速稳定，保持节奏，你做得很好！",
    "继续坚持，你已经跑了这么远了！",
    "呼吸均匀，保持这个状态！",
    "很棒的表现，继续加油！",
    "注意配速，不要太快也不要太慢。",
    "保持节奏，稳定前进！",
    "你的状态不错，继续保持！",
    "专注呼吸，放松肩膀，跑得更轻松。",
  ];

  return fallbacks[Math.floor(Math.random() * fallbacks.length)];
}
