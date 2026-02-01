**# AI跑步教练功能复用规划 v1.0**

****版本:** 1.0**  

****iOS:** 16+**  

****复用率**: 95% EarthLord.**

**## 核心表**

**| EarthLord文件 | AI跑步 | 复用 | 备注 |**

**|--------------|--------|------|------|**

**| LocationManager.swift | GPS轨迹 | 95% | didUpdate优化 |**

**| SpeechManager.swift | AI语音 | 100% | iOS16队列 |**

**| AchievementManager.swift | 成就 | 100% | EventBus |**

**| AuthManager.swift | 登录 | 100% | Supabase |**

**| StoreKitManager.swift | 订阅 | 100% | RevenueCat |**

**## 4周规划**

**| 周 | 阶段 | 内容 |**

**|----|------|------|**

**| 1 | M1 | Auth+GPS |**

**| 2 | M2 | AI+语音 (百炼) |**

**| 3 | M3 | 成就+订阅 |**

**| 4 | M4 | 测试上架 |**

****Claude指令**: 生成复用代码, iOS16+语音调试.**

4. CLAUDE.md **根目录完整**

**# CLAUDE.md v1.0 - AIRunningCoach (iOS16+)**

****版本:** 1.0**  

**## 概述**

**iOS16+ SwiftUI跑步App. 95%复用EarthLord. 阿里云百炼AI语音.**

**## 构建**

**```bash**

**xcodebuild -scheme AIRunningCoach -sdk iphonesimulator -quiet**

**架构**

App → MainCoordinator → ActiveRunView (GPS) → AIManager (**百炼**).

**规范**

- View.swift, Manager.swift.
- RunningTheme, L("key").

**Claude指令**

**严格**v1.0, iOS16+: **生成**SpeechManager**优化** (AudioSession**通用**, **延迟**<2s).

**示例**: "**生成**ActiveRunView.swift, **复用**LocationManager."
