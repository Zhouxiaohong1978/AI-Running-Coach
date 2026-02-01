**# CLAUDE.md - AIRunningCoach v1.0**

**This file provides guidance to Claude Code when working with this repository.**

**## Project Overview**

**AIRunningCoach is a pure SwiftUI iOS application (iOS16+). Uses NavigationStack. 95%复用EarthLord.**

****Minimum iOS:** 16.0**

****Swift Version:** 5.9**

****Bundle ID:** com.zhouxiaohong.AIRunningCoach**

**## Build and Run**

**Open `AIRunningCoach.xcodeproj` in Xcode, Cmd+R.**

**```bash**

**xcodebuild -scheme AIRunningCoach -sdk iphonesimulator -quiet**

**Architecture**

**AIRunningCoachApp (@main)**

**└── WindowGroup**

    **└── ContentView (NavigationStack)**

        **├── LoginView**

        **├── ActiveRunView (GPS/MapKit)**

        **└── ProfileView (成就)**

Uses:

- SwiftUI + #Preview
- NavigationStack
- SF Symbols
- Managers: LocationManager, SpeechManager (**语音**), AIManager (**百炼**)

**Testing**

xcodebuild test -quiet. Add Test Target for**单元**.

**Notes**

- **中英本地化** L("key")
- String catalogs
- Info.plist auto-gen (Location/Audio**权限**)
- **复用**: EarthLord Location/Speech/Achievement
- **调试**: AI**语音** iOS16+ AudioSession**队列** <2s

Claude**指令**: **生成**iOS16+ SpeechManager**优化**, **复用**EarthLord.
