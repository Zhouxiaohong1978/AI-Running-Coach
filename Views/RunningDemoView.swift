// RunningDemoView.swift
import SwiftUI

struct RunningDemoView: View {
    @StateObject private var engine = VoiceTriggerEngine.shared
    @StateObject private var voiceService = VoiceService.shared
    @State private var distance: Double = 0
    @State private var calories: Double = 0
    @State private var selectedMode: RunMode = .beginner

    var body: some View {
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
                Text("心率: \(engine.context.heartRate) BPM")
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
                    engine.start(for: selectedMode)
                    print("📍 数据重置，距离: \(distance)km")
                }
                .buttonStyle(.borderedProminent)

                HStack(spacing: 10) {
                    Button("+100米") {
                        distance += 0.1
                        calories += 6
                        engine.updateContext(distance: distance, calories: calories)
                        print("📍 距离: \(distance)km")
                    }
                    .buttonStyle(.bordered)

                    Button("+500米") {
                        distance += 0.5
                        calories += 30
                        engine.updateContext(distance: distance, calories: calories)
                        print("📍 距离: \(distance)km")
                    }
                    .buttonStyle(.bordered)

                    Button("+1公里") {
                        distance += 1.0
                        calories += 60
                        engine.updateContext(distance: distance, calories: calories)
                        print("📍 距离: \(distance)km")
                    }
                    .buttonStyle(.bordered)
                }

                Button("增加100大卡") {
                    calories += 100
                    engine.updateContext(calories: calories)
                    print("🔥 热量: \(Int(calories))卡")
                }

                Button("模拟心率升高") {
                    engine.updateContext(heartRate: 165)
                    print("💓 心率: 165 BPM")
                }

                // 快速完成按钮
                Button("快速到达3公里（测试完成语音）") {
                    distance = 3.0
                    calories = 180
                    engine.updateContext(distance: distance, calories: calories)
                    print("🏁 到达终点: 3.0km")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .font(.caption)

                Button("停止跑步") {
                    engine.stop()
                    distance = 0
                    calories = 0
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            .padding()

            Spacer()

            Text("当前模式: \(selectedMode == .beginner ? "新手3公里" : "减肥燃脂")")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

// 预览
#Preview {
    RunningDemoView()
}
