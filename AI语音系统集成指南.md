# AI 语音教练系统集成指南

## 系统已完成 ✅

### 1. 核心服务
- ✅ **TTS Edge Function** (`tts-coach` v4) - 已部署
- ✅ **VoiceService.swift** - HTTP 客户端
- ✅ **VoiceTriggerEngine.swift** - 触发引擎
- ✅ **VoiceScriptManager.swift** - 脚本管理（50条语音）
- ✅ **RunningDemoView.swift** - 演示界面

### 2. 语音脚本库

**新手模式** (30条)：
- 起步鼓励：散步节奏、身体感知、热身提醒
- 里程碑：500m、1km、1.5km、2km、2.5km、3km
- 应对疲劳：心理认知重构、游戏化、正念引导
- 完成庆祝：数据回顾、成就感强化

**减肥模式** (20条)：
- 燃脂教育：心率区间、代谢原理
- 热量里程碑：100、200、300 大卡
- 效率反馈：燃脂评分、周进度追踪
- 视觉化引导：脂肪细胞缩小想象

### 3. 音色配置
- `cherry` (默认): 女声，清晰 → 新手模式
- `jennifer`: 女声，温柔 → 减肥模式
- `ethan`: 男声，沉稳 → 备用

## 快速测试

### 方法1：运行演示界面

在 Xcode 中打开项目，找到 `RunningDemoView.swift`，点击预览或运行：

```swift
// ContentView.swift 中添加导航
NavigationLink("测试 AI 语音") {
    RunningDemoView()
}
```

### 方法2：命令行测试

```bash
# 测试 TTS API
curl -X POST "https://aisgbqzksfzdlbjdcwpn.supabase.co/functions/v1/tts-coach" \
  -H "Content-Type: application/json" \
  -d '{"text":"加油，你已经跑了1公里！","voice":"cherry"}' \
  --output test.wav && afplay test.wav
```

## 集成到主应用

### 在 ActiveRunView 中集成

```swift
import SwiftUI

struct ActiveRunView: View {
    @StateObject private var voiceEngine = VoiceTriggerEngine.shared
    @State private var distance: Double = 0
    @State private var calories: Double = 0

    var body: some View {
        // ... 你的 UI
    }

    func onDistanceUpdate(_ newDistance: Double) {
        distance = newDistance
        voiceEngine.updateContext(distance: distance)
    }

    func startRun() {
        voiceEngine.start(for: .beginner)  // 或 .fatburn
    }

    func stopRun() {
        voiceEngine.stop()
    }
}
```

## 关键配置检查

### 1. Supabase Secrets
在 [Supabase Dashboard](https://supabase.com/dashboard/project/aisgbqzksfzdlbjdcwpn/settings/functions) 确认：

```
DASHSCOPE_API_KEY = sk-01451f04c23e4e86a37269a56fb50c36
```

### 2. 项目文件确认
```
✅ Managers/VoiceService.swift
✅ Managers/VoiceTriggerEngine.swift
✅ Managers/VoiceScriptManager.swift
✅ Models/VoiceScript.swift
✅ Views/RunningDemoView.swift
✅ supabase/functions/tts-coach/index.ts
```

## 触发规则逻辑

```swift
距离触发 (distance):
  0km → "我们轻轻开始..."
  0.5km → "500米了！身体开始热起来..."
  1.0km → "1公里！第一个里程碑..."
  ...

热量触发 (calories):
  100卡 → "100大卡达成！"
  200卡 → "200大卡！这需要散步50分钟..."

心率触发 (heartRate):
  >160 → "如果感觉呼吸急促，很正常..."
  >170 → "心率有点快？我们走1分钟..."

疲劳触发 (fatigue):
  high → "感到累了？这是身体在说'我正在变强'..."
```

## 性能优化（可选）

1. **本地缓存**：缓存常用语音到设备
2. **预生成**：启动时预加载前 5 条语音
3. **降级方案**：网络失败时使用 `AVSpeechSynthesizer`
4. **队列管理**：避免语音重叠播放

## 下一步行动

1. [ ] 在 Supabase Dashboard 确认 `DASHSCOPE_API_KEY` 已配置
2. [ ] 运行 `RunningDemoView` 测试完整流程
3. [ ] 在 `ActiveRunView` 中集成 `VoiceTriggerEngine`
4. [ ] 添加设置页面的音量/静音控制
5. [ ] 测试真实跑步场景

## 故障排查

### 问题：语音无法播放
1. 检查网络连接
2. 查看 Edge Function 日志：`supabase functions logs tts-coach`
3. 确认 API key 是否有效

### 问题：语音质量差
- 确认使用了正确的音色 (cherry/jennifer/ethan)
- 检查文本是否包含特殊字符

### 问题：延迟过高 (>5秒)
- 正常延迟：3-4秒（API + 下载）
- 优化：添加本地缓存或预生成

## 技术支持

- Edge Function URL: https://aisgbqzksfzdlbjdcwpn.supabase.co/functions/v1/tts-coach
- Dashboard: https://supabase.com/dashboard/project/aisgbqzksfzdlbjdcwpn
- API 文档: [Qwen3-TTS-Flash](https://www.alibabacloud.com/help/en/model-studio/qwen-tts)

---

**更新时间**: 2026-02-01
**状态**: 可用 ✅
**测试**: 通过 3/3
