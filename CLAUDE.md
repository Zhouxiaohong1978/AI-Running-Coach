# CLAUDE.md - AIRunningCoach v1.0

此文件为 Claude Code 在此代码库中工作时提供指导。

## 项目概述

AIRunningCoach 是一个纯 SwiftUI iOS 应用（iOS16+）。使用 NavigationStack。95%复用EarthLord。

- **最低iOS版本:** 16.0
- **Swift版本:** 5.9
- **Bundle ID:** com.zhouxiaohong.AIRunningCoach

## 构建和运行

在 Xcode 中打开 `AIRunningCoach.xcodeproj`，按 Cmd+R 运行。

```bash
xcodebuild -scheme AIRunningCoach -sdk iphonesimulator -quiet
```

## 架构

```
AIRunningCoachApp (@main)
└── WindowGroup
    └── ContentView (NavigationStack)
        ├── LoginView
        ├── ActiveRunView (GPS/MapKit)
        └── ProfileView (成就)
```

使用技术:
- SwiftUI + #Preview
- NavigationStack
- SF Symbols
- 管理器: LocationManager, SpeechManager (语音), AIManager (百炼)

## 测试

xcodebuild test -quiet。添加 Test Target 进行单元测试。

## 注意事项

- 中英本地化 L("key")
- String catalogs
- Info.plist 自动生成 (位置/音频权限)
- 复用: EarthLord Location/Speech/Achievement
- 调试: AI语音 iOS16+ AudioSession队列 <2s

Claude指令: 生成iOS16+ SpeechManager优化, 复用EarthLord。
