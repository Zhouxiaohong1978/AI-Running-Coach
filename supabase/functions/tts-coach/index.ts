import "jsr:@supabase/functions-js/edge-runtime.d.ts";

/**
 * TTS (Text-to-Speech) Edge Function
 * 将文本转换为语音，用于 AI 跑步教练系统
 *
 * 请求格式：
 * {
 *   text: string,      // 要转换的文本
 *   voice: string      // 音色：zhiyan, zhitian 等
 * }
 */

interface TTSRequest {
  text: string;
  voice: string;
}

// Qwen3-TTS-Flash 音色映射（国际版支持的音色）
const VOICE_MAP: { [key: string]: string } = {
  "cherry": "Cherry",        // 女声，清晰
  "jennifer": "Jennifer",    // 女声，温柔
  "ethan": "Ethan",          // 男声，沉稳
  "default": "Cherry",       // 默认音色
};

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
    const body: TTSRequest = await req.json();
    const { text, voice = "cherry" } = body;

    if (!text || text.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "文本不能为空" }),
        {
          status: 400,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    console.log(`🔊 TTS 请求: 文本="${text.substring(0, 30)}...", 音色=${voice}`);

    // 获取阿里云 API Key
    const apiKey = Deno.env.get("DASHSCOPE_API_KEY");
    if (!apiKey) {
      throw new Error("DASHSCOPE_API_KEY not configured");
    }

    // 选择音色
    const selectedVoice = VOICE_MAP[voice.toLowerCase()] || "Cherry";

    // 调用阿里云国际版 Qwen3-TTS-Flash API
    const response = await fetch(
      "https://dashscope-intl.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: "qwen3-tts-flash",
          input: {
            text: text,
            voice: selectedVoice,
            language_type: "Chinese",  // 支持中文
          },
        }),
      }
    );

    if (!response.ok) {
      const error = await response.text();
      console.error("❌ 阿里云 TTS API 错误:", error);
      throw new Error(`TTS API 失败: ${response.status} ${error}`);
    }

    const data = await response.json();

    // Qwen3-TTS-Flash 返回音频 URL
    if (!data.output || !data.output.audio || !data.output.audio.url) {
      console.error("TTS API 返回格式:", JSON.stringify(data));
      throw new Error("TTS API 返回格式错误");
    }

    const audioUrl = data.output.audio.url;
    console.log(`📥 下载音频: ${audioUrl.substring(0, 80)}...`);

    // 下载音频文件
    const audioResponse = await fetch(audioUrl);
    if (!audioResponse.ok) {
      throw new Error(`下载音频失败: ${audioResponse.status}`);
    }

    const audioBuffer = await audioResponse.arrayBuffer();
    console.log(`✅ TTS 生成成功: ${audioBuffer.byteLength} 字节`);

    // 返回音频数据 (WAV 格式)
    return new Response(audioBuffer, {
      headers: {
        "Content-Type": "audio/wav",
        "Access-Control-Allow-Origin": "*",
        "Content-Length": audioBuffer.byteLength.toString(),
      },
    });

  } catch (error) {
    console.error("❌ TTS 生成失败:", error);

    // 返回错误（使用静默音频作为后备）
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "TTS generation failed",
        fallback: true
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
