/**
 * 阿里云百炼 API 调用工具
 * 用于训练计划生成和教练反馈
 */

export interface BailianMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface BailianResponse {
  output: {
    text?: string;
    finish_reason?: string;
    choices?: Array<{
      finish_reason: string;
      message: {
        role: string;
        content: string;
      };
    }>;
  };
  usage: {
    input_tokens: number;
    output_tokens: number;
  };
  request_id: string;
}

/**
 * 调用阿里云百炼 API
 * @param messages 对话消息列表
 * @param model 模型名称，默认使用 qwen-plus
 * @param temperature 温度参数
 */
export async function callBailian(
  messages: BailianMessage[],
  model: string = 'qwen-plus',
  temperature: number = 0.7,
  maxTokens: number = 2000
): Promise<string> {
  const apiKey = Deno.env.get('DASHSCOPE_API_KEY');

  if (!apiKey) {
    throw new Error('DASHSCOPE_API_KEY not configured');
  }

  // 阿里云百炼使用 DashScope API（国际版）
  const response = await fetch('https://dashscope-intl.aliyuncs.com/api/v1/services/aigc/text-generation/generation', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      input: {
        messages,
      },
      parameters: {
        temperature,
        max_tokens: maxTokens,
        result_format: 'message',
      },
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error('阿里云百炼 API 错误:', error);
    throw new Error(`阿里云百炼 API 失败: ${response.status} ${error}`);
  }

  const data: BailianResponse = await response.json();

  // 兼容两种返回格式：text格式和message格式
  const text = data.output?.text
    || data.output?.choices?.[0]?.message?.content;

  if (!text) {
    console.error('百炼返回数据:', JSON.stringify(data));
    throw new Error('阿里云百炼返回格式错误');
  }

  return text;
}
