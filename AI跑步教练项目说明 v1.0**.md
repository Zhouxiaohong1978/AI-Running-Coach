**# AI跑步教练项目说明 v1.0**

****版本:** 1.0**  

****iOS:** 16+**  

**## 概述**

**GPS轨迹 + 阿里云百炼AI语音 + 成就. 95%复用EarthLord (/Users/zhouxiaohong/Desktop/EarthLord).**

**## 技术栈**

**- UI: SwiftUI (iOS16+), MapKit轨迹.**

**- 后端: Supabase (PostGIS, Auth).**

**- AI: 阿里云百炼 (qwen-max, 计划/反馈).**

**- 订阅: RevenueCat.**

**- 架构: MVVM + EventBus.**

**## 代码规范**

**- View: XxxView.swift.**

**- Manager: XxxManager.swift.**

**- 主题: RunningTheme.Colors.primaryGreen.**

**- 文本: L("start_run").**

**## 复用表**

**| EarthLord | 这里 | 复用 |**

**|-----------|------|------|**

**| LocationManager | GPS | 95% |**

**| SpeechManager | 语音 | 100% |**

**| AchievementManager | 成就 | 100% |**

**## 构建**

**```bash**

**xcodebuild -scheme AIRunningCoach -sdk iphonesimulator -quiet**

Claude**指令**: **生成**iOS16+**语音优化**.
