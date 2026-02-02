// RunningDemoView.swift
import SwiftUI

struct RunningDemoView: View {
    @StateObject private var engine = VoiceTriggerEngine.shared
    @StateObject private var voiceService = VoiceService.shared
    @State private var distance: Double = 0
    @State private var calories: Double = 0
    @State private var duration: TimeInterval = 0  // 新增：跑步时长
    @State private var heartRate: Int = 120  // 新增：可调节心率
    @State private var selectedMode: RunMode = .beginner

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("AI跑步教练演示")
                    .font(.title)
                    .padding()

            // 模式选择
            Picker("跑步模式", selection: $selectedMode) {
                Text("新手3公里").tag(RunMode.beginner)
                Text("减肥燃脂").tag(RunMode.fatburn)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // 数据展示
            VStack(spacing: 10) {
                Text("距离: \(distance, specifier: "%.2f") km")
                Text("热量: \(Int(calories)) 大卡")
                Text("时长: \(Int(duration/60)) 分钟")
                Text("心率: \(heartRate) BPM")
                    .foregroundColor(heartRate >= 111 && heartRate <= 130 ? .green : (heartRate > 157 ? .red : .primary))
            }
            .padding()

            // 语音状态
            VStack(spacing: 8) {
                if voiceService.isPlaying {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("🔊 AI教练正在指导...")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                } else {
                    Text("🎧 等待触发...")
                        .foregroundColor(.gray)
                        .font(.caption)
                }

                // 已触发的脚本数量
                Text("已播放: \(engine.scriptManager.playedScripts.count) 条")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 控制按钮
            VStack(spacing: 15) {
                Button("开始跑步") {
                    distance = 0
                    calories = 0
                    duration = 0
                    heartRate = 120
                    print("\n\n\n")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    print("🚀🚀🚀 开始跑步按钮被点击了！🚀🚀🚀")
                    print("模式：\(selectedMode == .beginner ? "新手3公里" : "减肥燃脂")")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    print("\n")
                    engine.start(for: selectedMode)
                }
                .buttonStyle(.borderedProminent)

                // 距离控制
                Text("距离控制")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 10) {
                    Button("+100米") {
                        distance += 0.1
                        calories += 6
                        duration += 60  // 假设配速6分钟/公里
                        engine.updateContext(distance: distance, calories: calories, heartRate: heartRate, duration: duration)
                        print("📍 距离: \(distance)km, 时长: \(Int(duration))秒")
                    }
                    .buttonStyle(.bordered)

                    Button("+500米") {
                        distance += 0.5
                        calories += 30
                        duration += 300
                        engine.updateContext(distance: distance, calories: calories, heartRate: heartRate, duration: duration)
                        print("📍 距离: \(distance)km, 时长: \(Int(duration))秒")
                    }
                    .buttonStyle(.bordered)

                    Button("+1公里") {
                        distance += 1.0
                        calories += 60
                        duration += 600
                        engine.updateContext(distance: distance, calories: calories, heartRate: heartRate, duration: duration)
                        print("📍 距离: \(distance)km, 时长: \(Int(duration))秒")
                    }
                    .buttonStyle(.bordered)
                }

                Button("增加100大卡") {
                    calories += 100
                    engine.updateContext(calories: calories)
                    print("🔥 热量: \(Int(calories))卡")
                }
                .buttonStyle(.bordered)

                // 时间控制
                Text("时间控制")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 10) {
                    Button("+5分钟") {
                        duration += 300
                        engine.updateContext(duration: duration)
                        print("⏱️ 时长: \(Int(duration/60))分钟")
                    }
                    .buttonStyle(.bordered)

                    Button("+10分钟") {
                        duration += 600
                        engine.updateContext(duration: duration)
                        print("⏱️ 时长: \(Int(duration/60))分钟")
                    }
                    .buttonStyle(.bordered)

                    Button("+20分钟") {
                        duration += 1200
                        engine.updateContext(duration: duration)
                        print("⏱️ 时长: \(Int(duration/60))分钟")
                    }
                    .buttonStyle(.bordered)
                }

                // 心率控制
                Text("心率控制")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 10) {
                    Button("低心率110") {
                        heartRate = 110
                        engine.updateContext(heartRate: heartRate)
                        print("💓 心率: \(heartRate) BPM (低)")
                    }
                    .buttonStyle(.bordered)

                    Button("燃脂120") {
                        heartRate = 120
                        engine.updateContext(heartRate: heartRate)
                        print("💓 心率: \(heartRate) BPM (燃脂区间✅)")
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)

                    Button("高心率160") {
                        heartRate = 160
                        engine.updateContext(heartRate: heartRate)
                        print("💓 心率: \(heartRate) BPM (高)")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                // 快捷测试按钮（测试新的量化条件）
                VStack(spacing: 8) {
                    Text("🎯 量化条件测试")
                        .font(.caption)
                        .foregroundColor(.blue)

                    HStack(spacing: 10) {
                        Button("测试疲劳语音") {
                            distance = 2.0
                            calories = 120
                            duration = 1500  // 25分钟
                            heartRate = 160  // 高心率
                            engine.updateContext(distance: distance, calories: calories, heartRate: heartRate, duration: duration)
                            print("═══════════════════════════════════════")
                            print("🧪 【疲劳检测测试】")
                            print("📊 数据：时长=25分钟, 心率=160bpm, 距离=2km")
                            print("🎯 预期：应触发疲劳相关语音（满足时长>20分钟且心率>157）")
                            print("═══════════════════════════════════════")
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        .font(.caption)

                        Button("测试燃脂区间") {
                            distance = 1.5
                            calories = 90
                            duration = 900  // 15分钟
                            heartRate = 120  // 燃脂区间
                            engine.updateContext(distance: distance, calories: calories, heartRate: heartRate, duration: duration)
                            print("═══════════════════════════════════════")
                            print("🧪 【燃脂区间测试】")
                            print("📊 数据：心率=120bpm (燃脂区间111-130)")
                            print("🎯 预期：应触发燃脂区间语音")
                            print("═══════════════════════════════════════")
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                        .font(.caption)
                    }
                }

                // 测试冷却机制
                VStack(spacing: 8) {
                    Text("🧪 冷却机制测试")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Button("测试2.5km触发（验证无冲突）") {
                        distance = 2.5
                        calories = 150
                        engine.updateContext(distance: distance, calories: calories, duration: 1500)
                        print("═══════════════════════════════════════")
                        print("🧪 【测试开始】跳转到 2.5km")
                        print("📊 当前数据：距离=\(distance)km, 热量=\(calories)大卡, 时长=1500秒")
                        print("🎯 预期：应该只触发 beginner_15_2_5km 一条语音")
                        print("═══════════════════════════════════════")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .font(.caption)

                    Button("快速到达3公里（测试完成语音）") {
                        distance = 3.0
                        calories = 180
                        engine.updateContext(distance: distance, calories: calories)
                        print("🏁 到达终点: 3.0km")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .font(.caption)
                }

                Button("停止跑步") {
                    print("═══════════════════════════════════════")
                    print("🛑 【停止跑步】")
                    print("═══════════════════════════════════════")
                    engine.stop()
                    distance = 0
                    calories = 0
                    duration = 0
                    heartRate = 120
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()

            Text("当前模式: \(selectedMode == .beginner ? "新手3公里" : "减肥燃脂")")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 100)  // 给底部 Tab Bar 留出空间
            }
            .padding()
        }
    }
}

// 预览
#Preview {
    RunningDemoView()
}
