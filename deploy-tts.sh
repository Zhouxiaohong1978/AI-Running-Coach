#!/bin/bash

# AI 跑步教练 - TTS 服务部署脚本
# 一键部署 tts-coach Edge Function 到 Supabase

set -e  # 遇到错误立即退出

echo "🚀 开始部署 TTS 服务..."
echo ""

# 检查是否在正确的目录
if [ ! -f "AIRunningCoach.xcodeproj/project.pbxproj" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

# 检查 Supabase CLI
if ! command -v supabase &> /dev/null; then
    echo "❌ 错误: Supabase CLI 未安装"
    echo "请运行: brew install supabase/tap/supabase"
    exit 1
fi

echo "✅ Supabase CLI 已安装"

# 检查是否已登录
if ! supabase projects list &> /dev/null; then
    echo "❌ 错误: 未登录 Supabase"
    echo "请运行: supabase login"
    exit 1
fi

echo "✅ 已登录 Supabase"

# 项目 ID
PROJECT_REF="aisgbqzksfzdlbjdcwpn"

# 检查 DASHSCOPE_API_KEY
echo ""
echo "📝 检查环境变量..."

read -p "请输入阿里云 DashScope API Key (如已配置请按回车跳过): " API_KEY

if [ ! -z "$API_KEY" ]; then
    echo "⚙️  配置 API Key..."
    supabase secrets set DASHSCOPE_API_KEY="$API_KEY" --project-ref $PROJECT_REF
    echo "✅ API Key 已配置"
else
    echo "⏭️  跳过 API Key 配置"
fi

# 部署 tts-coach function
echo ""
echo "📦 部署 tts-coach function..."
supabase functions deploy tts-coach --project-ref $PROJECT_REF

echo ""
echo "✅ 部署完成！"
echo ""
echo "🔗 Function URL:"
echo "   https://$PROJECT_REF.supabase.co/functions/v1/tts-coach"
echo ""
echo "📋 测试命令:"
echo "   curl -X POST https://$PROJECT_REF.supabase.co/functions/v1/tts-coach \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"text\":\"测试语音\",\"voice\":\"zhiyan\"}' \\"
echo "     --output test.mp3"
echo ""
echo "   afplay test.mp3"
echo ""
echo "📚 查看日志:"
echo "   supabase functions logs tts-coach --project-ref $PROJECT_REF"
echo ""
