### **AI跑步教练 (AIRunningCoach) 项目说明**

```markdown
# AI跑步教练 (AIRunningCoach) 项目说明

## 项目概述
这是一款基于GPS的AI跑步教练iOS应用，使用SwiftUI构建。
玩家通过现实世界跑步记录轨迹、AI语音指导、成就激励，打造个性化跑步体验。  
**核心理念**：复用“地球新主”项目95%代码（如LocationManager.swift、AuthManager.swift），快速构建MVP。

## 技术栈
- **UI框架**: SwiftUI (iOS 16+)
- **地图**: Apple MapKit（实时轨迹绘制）
- **后端**: Supabase (PostgreSQL + PostGIS，支持轨迹存储与LBS查询)
- **AI服务**: OpenAI/Claude API（训练计划生成 + 语音教练）
- **订阅**: RevenueCat（StoreKit 2内购）
- **架构**: MVVM + Manager模式（复用EventBus事件总线）
- **语言**: Swift 5.9

## 代码规范

### 命名约定
- View文件: `XxxView.swift` (如 `ActiveRunView.swift`、`BackpackView.swift`)
- Manager文件: `XxxManager.swift` (如 `LocationManager.swift`、`AchievementManager.swift`)
- 模型文件: `Models.swift` (统一存放，如Run.swift、Achievement.swift、TrainingPlan.swift)

### 设计系统
- 使用 `RunningTheme` 统一管理颜色、字体、间距（复用ApocalypseTheme逻辑）
- 所有颜色通过 `RunningTheme.Colors.xxx` 引用（如 `.primaryGreen` 用于轨迹）
- 所有圆角通过 `RunningTheme.CornerRadius.xxx` 引用（如 `.card` 用于成就徽章）

### UI文本
- 所有用户可见文本使用本地化函数 `L("key")`
- 本地化文件: `zh-Hans.lproj/Localizable.strings`、`en.lproj/Localizable.strings`（支持中英）

## 功能复用映射（95%复用“地球新主”）
| 地球新主模块 | AI跑步教练对应 | 复用度 |
|--------------|----------------|--------|
| LocationManager.swift | GPS轨迹 + 配速计算 | 100% |
| POIManager.swift | 途经地标打卡 | 100% |
| ItemManager.swift | 装备背包（跑鞋/徽章） | 90% |
| AchievementManager.swift | 跑步成就 | 100% |
| AuthManager.swift | Apple/邮箱登录 | 100% |
| StoreKitManager.swift | Pro订阅 | 100% |

## 数据模型概要（Supabase Postgres + PostGIS）
```sql
-- 核心表（复制自地球新主，微调）
users (id: uuid PK, email: text, total_distance: float)
runs (id: uuid PK, user_id: uuid FK, distance: float, geometry: geography(linestring, 4326))
achievements (id: uuid PK, user_id: uuid FK, type: text)
training_plans (id: uuid PK, user_id: uuid FK, plan_json: jsonb)
```

## 构建命令

```bash
# 构建（必须使用--quiet避免输出过多）
xcodebuild -scheme AIRunningCoach -sdk iphonesimulator -quiet

# 运行测试
xcodebuild test -scheme AIRunningCoach -sdk iphonesimulator -quiet

# 模拟器启动（带位置模拟）
xcodebuild -scheme AIRunningCoach -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' -quiet
```

## 开发提示（Claude Code专用）

- **复用优先**：所有Manager从“地球新主”项目复制，路径：/Users/zhouxiaohong/Desktop/EarthLord。
- **位置更新关键**：MapKit必须用`mapView(_:didUpdate userLocation:)`回调居中/绘制轨迹（课程5.1.2经验）。
- **AI Prompt模板**：
  
  ```
  你是资深iOS开发者，精通SwiftUI/MapKit/Supabase。
  根据AIRunningCoach规范，生成XxxView.swift或XxxManager.swift。
  严格遵守命名/主题/本地化。
  示例：用户跑步中，实时语音“配速5:30，保持住！L("keep_pace")”。
  ```
- **里程碑**：Week1: GPS+登录；Week2: AI教练+成就；Week3: 订阅+测试。
  
  ```
  
  ```


