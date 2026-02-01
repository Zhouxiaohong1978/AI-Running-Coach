#!/bin/bash

# 测试所有 Qwen3-TTS 音色

VOICES=("Vivian" "Serena" "Uncle_Fu" "Dylan" "Eric" "Ryan" "Aiden" "Ono_Anna" "Sohee")
TEXT="你好，我是AI跑步教练，今天我们一起加油！"

echo "开始测试所有音色..."
echo ""

for voice in "${VOICES[@]}"; do
    echo "测试音色: $voice"
    
    curl -s -X POST "https://aisgbqzksfzdlbjdcwpn.supabase.co/functions/v1/tts-coach" \
      -H "Content-Type: application/json" \
      -d "{\"text\":\"$TEXT\",\"voice\":\"$voice\"}" \
      --output "/tmp/voice-$voice.wav" 2>&1
    
    if [ -f "/tmp/voice-$voice.wav" ] && [ -s "/tmp/voice-$voice.wav" ]; then
        file_size=$(ls -lh "/tmp/voice-$voice.wav" | awk '{print $5}')
        echo "✅ $voice: 生成成功 ($file_size)"
        echo "   播放: afplay /tmp/voice-$voice.wav"
    else
        echo "❌ $voice: 生成失败"
    fi
    echo ""
    sleep 1
done

echo "所有音色测试完成！"
echo ""
echo "试听命令："
for voice in "${VOICES[@]}"; do
    echo "  afplay /tmp/voice-$voice.wav  # $voice"
done
