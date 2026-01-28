# Supabase Edge Function 部署指南

## 1. 创建 generate-training-plan Function

### 步骤：
1. 访问 Supabase Dashboard: https://supabase.com/dashboard
2. 选择你的项目
3. 进入 "Edge Functions" 页面
4. 点击 "Create Function"
5. 函数名称：`generate-training-plan`
6. 复制以下代码：

```typescript
// Edge Function: generate-training-plan
// 调用阿里云百炼生成个性化训练计划

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const DASHSCOPE_API_KEY = Deno.env.get('DASHSCOPE_API_KEY')!
const DASHSCOPE_API_URL = 'https://dashscope-intl.aliyuncs.com/api/v1/services/aigc/text-generation/generation'

interface GeneratePlanRequest {
  goal: string
  avgPace: number | null
  maxDistance: number | null
  weeklyRuns: number
  durationWeeks: number
}

serve(async (req) => {
  try {
    const { goal, avgPace, maxDistance, weeklyRuns, durationWeeks }: GeneratePlanRequest = await req.json()

    console.log('生成训练计划请求:', { goal, avgPace, maxDistance, weeklyRuns, durationWeeks })

    // 构建 Prompt
    const prompt = buildPrompt(goal, avgPace, maxDistance, weeklyRuns, durationWeeks)

    // 调用阿里云百炼API
    const response = await fetch(DASHSCOPE_API_URL, {
      method: 'POST',
      headers: {
        'Authorization': \`Bearer \${DASHSCOPE_API_KEY}\`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'qwen-plus',
        input: {
          messages: [
            {
              role: 'system',
              content: '你是一位专业的跑步教练，擅长根据跑者的历史数据制定科学的训练计划。'
            },
            {
              role: 'user',
              content: prompt
            }
          ]
        },
        parameters: {
          result_format: 'message',
          temperature: 0.7,
          top_p: 0.8,
          max_tokens: 2000
        }
      })
    })

    if (!response.ok) {
      const error = await response.text()
      console.error('百炼API错误:', error)
      throw new Error(\`API调用失败: \${response.status}\`)
    }

    const data = await response.json()
    console.log('百炼API响应:', data)

    const aiContent = data.output?.choices?.[0]?.message?.content || ''
    const plan = parseAIPlan(aiContent, goal, durationWeeks)

    return new Response(
      JSON.stringify({
        success: true,
        plan: plan,
        timestamp: new Date().toISOString()
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('生成训练计划错误:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

function buildPrompt(
  goal: string,
  avgPace: number | null,
  maxDistance: number | null,
  weeklyRuns: number,
  durationWeeks: number
): string {
  return \`请为以下跑者生成一个\${durationWeeks}周的训练计划：

**目标**: \${goal}
**历史数据**:
- 平均配速: \${avgPace ? \`\${avgPace.toFixed(2)}分钟/公里\` : '无历史记录'}
- 最长跑步距离: \${maxDistance ? \`\${maxDistance.toFixed(2)}公里\` : '无历史记录'}
- 每周跑步次数: \${weeklyRuns}次

**要求**:
1. 生成\${durationWeeks}周的详细计划，每周包含\${weeklyRuns}天训练
2. 每天的任务包括：
   - 星期几（1-7，1=周一）
   - 任务类型（easy_run/tempo_run/interval/long_run/rest/cross_training）
   - 目标距离（公里，保留2位小数）
   - 目标配速（格式：X'XX"/km）
   - 任务描述（50字以内）
3. 计划应循序渐进，避免过度训练

**输出格式**（严格按此JSON格式）:
\\\`\\\`\\\`json
{
  "goal": "\${goal}",
  "durationWeeks": \${durationWeeks},
  "difficulty": "beginner",
  "weeklyPlans": [
    {
      "weekNumber": 1,
      "theme": "适应期",
      "dailyTasks": [
        {
          "dayOfWeek": 1,
          "type": "easy_run",
          "targetDistance": 3.0,
          "targetPace": "6'30\\"",
          "description": "轻松跑"
        }
      ]
    }
  ],
  "tips": ["训练提示1", "训练提示2"]
}
\\\`\\\`\\\`

请只返回JSON数据。\`
}

function parseAIPlan(aiContent: string, goal: string, durationWeeks: number): any {
  try {
    const jsonMatch = aiContent.match(/```json\n([\s\S]*?)\n```/) ||
                     aiContent.match(/\{[\s\S]*\}/)

    if (!jsonMatch) {
      throw new Error('AI返回格式无效')
    }

    const jsonStr = jsonMatch[1] || jsonMatch[0]
    return JSON.parse(jsonStr)
  } catch (error) {
    console.error('解析AI计划失败:', error)
    return generateDefaultPlan(goal, durationWeeks)
  }
}

function generateDefaultPlan(goal: string, durationWeeks: number): any {
  const weeklyPlans = []
  for (let week = 1; week <= durationWeeks; week++) {
    weeklyPlans.push({
      weekNumber: week,
      theme: \`第\${week}周\`,
      dailyTasks: [
        {
          dayOfWeek: 1,
          type: "easy_run",
          targetDistance: 3.0,
          targetPace: "6'30\\"",
          description: "轻松跑，保持舒适配速"
        },
        {
          dayOfWeek: 3,
          type: "tempo_run",
          targetDistance: 5.0,
          targetPace: "5'45\\"",
          description: "节奏跑，提升乳酸阈值"
        },
        {
          dayOfWeek: 6,
          type: "long_run",
          targetDistance: 8.0 + week * 0.5,
          targetPace: "7'00\\"",
          description: "长距离跑，增强耐力"
        }
      ]
    })
  }

  return {
    goal: goal,
    durationWeeks: durationWeeks,
    difficulty: "beginner",
    weeklyPlans: weeklyPlans,
    tips: [
      "跑步前做好热身，跑后拉伸放松",
      "注意补水和营养摄入",
      "循序渐进，避免过度训练",
      "注意身体信号，如有不适及时休息"
    ]
  }
}
```

### 环境变量设置：
在 Supabase Dashboard 的 Settings → Edge Functions → Secrets 中添加：

```
DASHSCOPE_API_KEY=你的阿里云百炼API_KEY
```

---

## 2. 获取阿里云百炼 API Key

1. 访问：https://dashscope.console.aliyun.com/
2. 登录你的阿里云账号
3. 进入 "API-KEY 管理"
4. 创建新的 API Key
5. 复制 API Key 并保存到 Supabase Secrets

---

## 3. 测试 Function

部署完成后，在 iOS 应用中：
1. 进入"计划"Tab
2. 点击"生成训练计划"
3. 选择目标（如"5km入门"）
4. 点击"生成训练计划"按钮
5. AI 将基于你的历史跑步数据生成个性化计划

---

## 4. 常见问题

### Q: Function 调用失败怎么办？
A: 检查 Supabase Dashboard 的 Edge Functions Logs，查看错误信息

### Q: 阿里云百炼返回错误？
A: 确认 API Key 正确且有剩余额度

### Q: 计划生成太慢？
A: 阿里云百炼通常在2-5秒内返回，可以调整 timeout

---

## 5. 后续优化

- [ ] 添加计划编辑功能
- [ ] 实现日历可视化
- [ ] 支持计划分享
- [ ] 添加完成度追踪
