# 部署 TTS 语音服务到 Supabase

## 前提条件

1. 已安装 Supabase CLI
2. 已有阿里云 DashScope API Key
3. 已登录 Supabase 项目

## 检查 Supabase CLI

```bash
# 检查是否已安装
supabase --version

# 如果未安装，使用 Homebrew 安装
brew install supabase/tap/supabase
```

## 登录 Supabase

```bash
# 登录（如果还没登录）
supabase login

# 链接到项目
cd /Users/zhouxiaohong/Desktop/AIRunningCoach
supabase link --project-ref aisgbqzksfzdlbjdcwpn
```

## 配置环境变量

在 Supabase Dashboard 中配置 API Key:

1. 访问: https://supabase.com/dashboard/project/aisgbqzksfzdlbjdcwpn/settings/functions
2. 点击 "Edge Functions" → "Secrets"
3. 添加环境变量:
   - Name: `DASHSCOPE_API_KEY`
   - Value: `你的阿里云 DashScope API Key`

或者使用命令行:

```bash
# 设置阿里云 API Key
supabase secrets set DASHSCOPE_API_KEY=你的API_KEY --project-ref aisgbqzksfzdlbjdcwpn
```

## 部署 TTS Function

```bash
cd /Users/zhouxiaohong/Desktop/AIRunningCoach

# 部署 tts-coach function
supabase functions deploy tts-coach --project-ref aisgbqzksfzdlbjdcwpn
```

## 测试部署

### 方法1: 使用 curl 测试

```bash
# 测试 TTS 服务
curl -X POST https://aisgbqzksfzdlbjdcwpn.supabase.co/functions/v1/tts-coach \
  -H "Content-Type: application/json" \
  -d '{"text":"测试语音","voice":"zhiyan"}' \
  --output test.mp3

# 播放音频
afplay test.mp3
```

### 方法2: 在 iOS 应用中测试

1. 打开 Xcode
2. 运行应用
3. 进入"我的" → "AI语音教练演示"
4. 点击"开始跑步"
5. 观察是否有语音播放

## 验证清单

- [ ] Supabase CLI 已安装
- [ ] 已登录并链接到项目
- [ ] DASHSCOPE_API_KEY 已配置
- [ ] tts-coach function 部署成功
- [ ] curl 测试返回音频数据
- [ ] iOS 应用可以播放语音

## 常见问题

### 问题1: 部署失败 - "project not linked"

```bash
# 重新链接项目
supabase link --project-ref aisgbqzksfzdlbjdcwpn
```

### 问题2: API Key 未配置

```bash
# 检查 secrets
supabase secrets list --project-ref aisgbqzksfzdlbjdcwpn

# 重新设置
supabase secrets set DASHSCOPE_API_KEY=你的KEY --project-ref aisgbqzksfzdlbjdcwpn
```

### 问题3: 音频无法播放

检查:
1. API 返回是否是音频数据（Content-Type: audio/mpeg）
2. 文件大小是否正常（不应该是 0 字节）
3. 使用 ffplay 或其他工具测试音频文件

### 问题4: 阿里云 TTS API 调用失败

可能原因:
1. API Key 错误或过期
2. 余额不足
3. 音色名称不支持

解决:
1. 登录阿里云控制台检查 API Key
2. 检查账户余额
3. 查看阿里云文档确认支持的音色列表

## 阿里云 TTS 音色列表

当前支持的音色:
- `zhiyan`: 知言（女声，温柔）- 适合新手模式
- `zhitian`: 知甜（女声，甜美）- 适合减肥模式
- `aixia`: 艾夏（女声，亲和）
- `aitong`: 艾彤（女声，热情）
- `aiqi`: 艾琪（女声，可爱）

更多音色请查看: https://help.aliyun.com/zh/dashscope/developer-reference/cosyvoice-models

## 本地测试（不部署）

如果想在本地测试 Edge Function:

```bash
# 启动本地 Supabase
supabase start

# 本地运行 function
supabase functions serve tts-coach --env-file .env.local

# 测试
curl -X POST http://localhost:54321/functions/v1/tts-coach \
  -H "Content-Type: application/json" \
  -d '{"text":"本地测试","voice":"zhiyan"}' \
  --output test_local.mp3
```

创建 `.env.local` 文件:
```
DASHSCOPE_API_KEY=你的API_KEY
```

## 监控和日志

### 查看 Function 日志

1. 访问 Supabase Dashboard
2. 进入 Edge Functions → tts-coach
3. 查看 Logs 标签

或使用命令行:

```bash
supabase functions logs tts-coach --project-ref aisgbqzksfzdlbjdcwpn
```

### 监控调用量

在 Supabase Dashboard 的 Functions 页面可以看到:
- 调用次数
- 错误率
- 平均响应时间

## 成本估算

阿里云 TTS 定价（参考）:
- 标准版: ¥0.0015/次
- 高级版: ¥0.0030/次

示例:
- 100 次语音播放 ≈ ¥0.15-0.30
- 1000 次语音播放 ≈ ¥1.50-3.00

Supabase Edge Functions:
- 免费额度: 500,000 次调用/月
- 超出后: $2/百万次调用

## 优化建议

### 1. 添加缓存

对于相同的文本，可以缓存生成的音频:

```typescript
// 使用 Supabase Storage 存储音频
const audioUrl = await uploadToStorage(audioBuffer, text);
return Response.redirect(audioUrl);
```

### 2. 压缩音频

调整参数减小音频大小:
```typescript
parameters: {
  format: "mp3",
  sample_rate: 16000,  // 降低采样率
  volume: 50,
}
```

### 3. 批量生成

提前生成常用语音并存储，减少实时调用。

## 下一步

部署成功后:

1. ✅ 在 iOS 应用中测试完整流程
2. ✅ 验证 50 条语音脚本都能正常播放
3. ✅ 检查语音质量和延迟
4. ✅ 监控调用量和成本
5. ✅ 考虑添加缓存优化

## 总结

完成部署后，TTS 服务将通过以下 URL 提供:

```
https://aisgbqzksfzdlbjdcwpn.supabase.co/functions/v1/tts-coach
```

iOS 应用将通过这个 URL 实时生成语音播报。
