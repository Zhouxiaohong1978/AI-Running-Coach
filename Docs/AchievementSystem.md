# 成就系统完整实现文档

## 📋 目录

1. [功能概述](#功能概述)
2. [技术架构](#技术架构)
3. [成就列表](#成就列表)
4. [使用指南](#使用指南)
5. [Supabase配置](#supabase配置)
6. [测试方法](#测试方法)

---

## 功能概述

AIRunningCoach成就系统提供以下功能：

- ✅ **28个成就**：覆盖距离、时长、频率、燃脂、配速、特殊、里程碑7大类别
- ✅ **自动检测**：每次跑步结束后自动检测成就解锁
- ✅ **AI语音庆祝**：成就解锁时，AI教练语音播报庆祝消息
- ✅ **进度追踪**：实时显示每个成就的完成进度
- ✅ **社交分享**：生成精美成就卡片，分享到微信/朋友圈/微博/小红书
- ✅ **云端同步**：支持Supabase云端存储，换设备数据不丢失
- ✅ **本地存储**：离线状态下也能记录成就

---

## 技术架构

### 1. 数据层

#### **Achievement.swift**
- 定义成就模型（Achievement）
- 定义成就类别（AchievementCategory）
- 预定义28个成就数据
- Supabase数据传输对象（AchievementDTO）

```swift
struct Achievement: Identifiable, Codable {
    var id: String
    var category: AchievementCategory
    var title: String
    var description: String
    var icon: String
    var targetValue: Double
    var currentValue: Double
    var isUnlocked: Bool
    var unlockedAt: Date?
    var celebrationMessage: String
}
```

### 2. 业务逻辑层

#### **AchievementManager.swift**
- 单例模式管理成就数据
- 成就检测逻辑（7种类别）
- 本地存储（UserDefaults）
- 云端同步（Supabase）
- AI语音庆祝触发

**核心方法**：
```swift
// 检查成就（从RunRecord触发）
func checkAchievements(from runRecord: RunRecord, allRecords: [RunRecord])

// 同步到云端
func syncToCloud() async

// 从云端拉取
func fetchFromCloud() async
```

#### **集成到RunDataManager**
```swift
func addRunRecord(_ record: RunRecord) async {
    // 保存记录
    runRecords.insert(newRecord, at: 0)
    saveToLocal()

    // 🏆 检查成就解锁
    AchievementManager.shared.checkAchievements(from: newRecord, allRecords: runRecords)

    // 云端同步
    if authManager.isAuthenticated {
        await syncToCloud(newRecord)
    }
}
```

### 3. UI层

#### **RunSummaryView.swift**（跑步总结页面）
- 动态显示最近解锁的成就横幅
- 点击横幅打开成就Sheet
- 仅在有新成就时显示

#### **AchievementSheetView.swift**（成就列表）
- 显示所有成就（分类折叠）
- 进度条展示未解锁成就
- 成就卡片右上角有分享按钮
- 成就统计（已解锁/总数）

#### **AchievementShareView.swift**（成就分享）
- 生成精美成就卡片图片
- 支持分享到：微信好友、朋友圈、微博、小红书、更多应用
- 记录分享次数到云端

### 4. 测试层

#### **AchievementTestView.swift**（测试界面）
- 模拟跑步记录（1km、5km、10km）
- 模拟晨跑（触发特殊成就）
- 查看最近解锁的成就
- 重置所有成就

---

## 成就列表

### 1. 距离成就（单次距离）
| 成就ID | 标题 | 目标 | 图标 |
|--------|------|------|------|
| `distance_1km` | 起步阶段 | 1公里 | 🚶 |
| `distance_5km` | 进阶挑战 | 5公里 | 🏃 |
| `distance_10km` | 半马征程 | 10公里 | 🏃‍♂️ |
| `distance_21km` | 全马英雄 | 21公里 | 🏅 |
| `distance_42km` | 极限挑战 | 42公里 | 🏆 |

### 2. 时长成就（累计时间）
| 成就ID | 标题 | 目标 | 图标 |
|--------|------|------|------|
| `duration_5hours` | 时光起步 | 5小时 | ⏱️ |
| `duration_10hours` | 持之以恒 | 10小时 | ⏰ |
| `duration_50hours` | 马拉松精神 | 50小时 | 🕐 |
| `duration_100hours` | 时间征服者 | 100小时 | ⏳ |

### 3. 频率成就（连续天数）
| 成就ID | 标题 | 目标 | 图标 |
|--------|------|------|------|
| `frequency_3days` | 初露锋芒 | 3天 | 🔥 |
| `frequency_7days` | 坚持不懈 | 7天 | 💪 |
| `frequency_30days` | 铁人意志 | 30天 | 🎯 |
| `frequency_100days` | 跑步狂人 | 100天 | 🏃 |

### 4. 🔥 燃脂成就（卡路里消耗）
| 成就ID | 标题 | 目标 | 图标 |
|--------|------|------|------|
| `calories_300` | 初见成效 | 单次300卡 | 🔥 |
| `calories_500` | 燃脂达人 | 单次500卡 | 🔥 |
| `calories_1000` | 燃脂狂魔 | 单次1000卡 | 🔥 |
| `calories_total_10k` | 卡路里杀手 | 累计1万卡 | 🔥 |
| `calories_total_50k` | 减肥战士 | 累计5万卡 | 🔥 |
| `calories_total_100k` | 脂肪克星 | 累计10万卡 | 🔥 |

### 5. 配速成就（最快配速）
| 成就ID | 标题 | 目标 | 图标 |
|--------|------|------|------|
| `pace_6min` | 速度觉醒 | 6分钟/公里 | ⚡ |
| `pace_5min` | 飞毛腿 | 5分钟/公里 | 🚀 |
| `pace_4min` | 闪电侠 | 4分钟/公里 | ⚡ |

### 6. 特殊成就（时间段）
| 成就ID | 标题 | 目标 | 图标 |
|--------|------|------|------|
| `special_morning_5times` | 早起的鸟儿 | 5次晨跑（5:00-8:00） | 🌅 |
| `special_night_5times` | 夜跑勇士 | 5次夜跑（20:00-23:00） | 🌙 |
| `special_rainy_1time` | 风雨无阻 | 雨天跑步1次 | 🌦️ |

### 7. 里程碑成就（累计距离）
| 成就ID | 标题 | 目标 | 图标 |
|--------|------|------|------|
| `milestone_100km` | 环球旅行 | 100公里 | 🌍 |
| `milestone_500km` | 横跨中国 | 500公里 | 🗺️ |
| `milestone_1000km` | 绕地球一圈 | 1000公里 | 🌏 |

---

## 使用指南

### 开发集成

1. **导入AchievementManager**
```swift
import SwiftUI

@StateObject private var achievementManager = AchievementManager.shared
```

2. **在跑步结束后自动检测**
```swift
// RunDataManager.swift 已自动集成
func addRunRecord(_ record: RunRecord) async {
    // ...
    AchievementManager.shared.checkAchievements(from: newRecord, allRecords: runRecords)
}
```

3. **显示成就横幅**
```swift
if !achievementManager.recentlyUnlocked.isEmpty {
    ForEach(achievementManager.recentlyUnlocked.prefix(3)) { achievement in
        AchievementBanner(achievement: achievement)
    }
    .onTapGesture {
        showAchievementSheet = true
    }
}
```

4. **打开成就列表Sheet**
```swift
.sheet(isPresented: $showAchievementSheet) {
    AchievementSheetView()
}
```

### AI语音庆祝

成就解锁时自动播报：
```swift
// AchievementManager.swift（已实现）
private func unlockAchievement(at index: Int) {
    achievements[index].isUnlocked = true
    achievements[index].unlockedAt = Date()

    // 🎉 播放AI语音庆祝
    let message = achievements[index].celebrationMessage
    SpeechManager.shared.speak(message, priority: .high)
}
```

### 社交分享

打开成就分享视图：
```swift
.sheet(item: $selectedAchievement) { achievement in
    AchievementShareView(achievement: achievement)
}
```

---

## Supabase配置

### 1. 创建数据库表

在Supabase SQL Editor中执行：
```sql
-- 复制 Database/user_achievements_table.sql 内容并执行
```

### 2. 配置RLS策略

表已启用Row Level Security (RLS)，用户只能访问自己的成就数据。

### 3. 云端同步

**上传成就数据**：
```swift
Task {
    await AchievementManager.shared.syncToCloud()
}
```

**拉取云端数据**：
```swift
Task {
    await AchievementManager.shared.fetchFromCloud()
}
```

---

## 测试方法

### 方法1：使用测试界面

1. 打开`AchievementTestView`
2. 点击"模拟跑步"按钮
3. 观察成就解锁和AI语音播报
4. 点击"查看成就"进入成就列表

### 方法2：真实跑步测试

1. 开始跑步
2. 完成跑步后，在`RunSummaryView`查看成就横幅
3. 点击横幅打开成就列表
4. 点击分享按钮测试社交分享

### 方法3：单元测试（TODO）

创建XCTest单元测试：
```swift
func testAchievementUnlock() {
    let manager = AchievementManager.shared
    let record = RunRecord(distance: 5000, duration: 1800, ...)

    manager.checkAchievements(from: record, allRecords: [record])

    XCTAssertTrue(manager.achievements.first { $0.id == "distance_5km" }?.isUnlocked == true)
}
```

---

## 🎯 完成清单

- ✅ 数据层：Achievement.swift + AchievementManager.swift
- ✅ 逻辑层：成就检测 + Supabase云同步
- ✅ UI层：RunSummaryView + AchievementSheetView + AchievementShareView
- ✅ 语音系统：AI语音庆祝
- ✅ 分享系统：成就卡片生成 + 社交分享
- ✅ 测试界面：AchievementTestView
- ✅ 数据库脚本：user_achievements_table.sql
- ✅ 文档：本文档

---

## 📝 注意事项

1. **语音播报**：确保设备音量开启，首次使用需授予音频权限
2. **云端同步**：需要用户登录后才能同步到云端
3. **成就检测**：连续天数成就需要每天至少跑步一次
4. **配速成就**：配速值越小越好（分钟/公里）
5. **雨天成就**：暂未集成天气API，需手动触发
6. **分享功能**：需要安装对应的社交应用（微信、微博等）

---

## 🚀 未来优化

- [ ] 集成天气API检测雨天跑步
- [ ] 添加成就排行榜（全局/好友）
- [ ] 支持自定义成就目标
- [ ] 成就解锁动画效果
- [ ] 成就徽章系统
- [ ] 成就推送通知

---

**开发者**: Claude Code
**版本**: 1.0
**更新日期**: 2026-02-02
