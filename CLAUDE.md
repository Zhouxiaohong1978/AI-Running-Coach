# AI跑步教练 (AIRunningCoach) 项目说明

## 项目概述
这是一款基于GPS的AI跑步教练iOS应用，使用SwiftUI构建。
用户通过跑步记录轨迹、获得成就、参与社区互动，AI教练提供实时语音指导。

## 技术栈
- **UI框架**: SwiftUI (iOS 16.6+)
- **地图**: Apple MapKit
- **后端**: Supabase (PostgreSQL + PostGIS)
- **架构**: MVVM + Manager模式
- **语言**: Swift 5
- **认证**: Supabase Auth + Apple Sign In

## 代码规范

### 命名约定
- View文件: `XxxView.swift` (如 `ActiveRunView.swift`)
- Manager文件: `XxxManager.swift` (如 `LocationManager.swift`)
- 模型文件: 放在 `Models/` 目录下 (如 `RunRecord.swift`)
- 工具类: 放在 `Utils/` 目录下 (如 `CoordinateConverter.swift`)

### 设计系统
- 使用 `RunningTheme` 统一管理颜色、字体、间距
- 所有颜色通过 `RunningTheme.Colors.xxx` 引用
- 所有圆角通过 `RunningTheme.CornerRadius.xxx` 引用
- 主题色调：蓝绿色系（运动、健康）

### UI文本
- 所有用户可见文本使用本地化函数 `L("key")`
- 本地化文件: `zh-Hans.lproj/Localizable.strings`

## 构建命令
```bash
# 构建（必须使用--quiet避免输出过多）
xcodebuild -scheme AIRunningCoach -sdk iphonesimulator -quiet

# 运行测试
xcodebuild test -scheme AIRunningCoach -sdk iphonesimulator -quiet
```

## 重要约定
1. 每个View文件控制在300行以内
2. 复杂界面拆分为多个子组件
3. 优先使用SF Symbols图标
4. 避免使用shadow和blur等消耗GPU的效果
5. 新增文件后需在Xcode中手动添加到项目

## 目录结构说明
```
/AIRunningCoach
├── Models/          - 数据模型 (RunRecord等)
├── Managers/        - 业务管理器 (AuthManager, LocationManager等)
├── Views/           - SwiftUI视图文件
├── Utils/           - 工具类和扩展
└── Assets.xcassets  - 图片资源
```

## 核心文件说明
| 文件 | 说明 |
|-----|------|
| `AuthManager.swift` | 用户认证管理（登录、注册、Apple登录） |
| `LocationManager.swift` | GPS定位和轨迹追踪 |
| `RunDataManager.swift` | 跑步数据CRUD和云端同步 |
| `RunRecord.swift` | 跑步记录数据模型 |
| `ActiveRunView.swift` | 跑步进行中界面（核心功能） |
| `HomeView.swift` | 主页Tab导航 |

## Supabase配置
- 项目使用Supabase作为后端
- 数据库表: `users`, `run_records`
- 已启用RLS（行级安全策略）
- MCP配置: `.mcp.json`

## 复用来源
本项目95%代码复用自《地球新主》(EarthLord)项目，详见 `功能复用规划.md`
