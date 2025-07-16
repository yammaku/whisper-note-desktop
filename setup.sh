#!/bin/bash
# setup.sh - 闪念笔记自动配置脚本

echo "🚀 开始自动配置闪念笔记工具..."
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 1. 创建必要目录
echo "📁 创建目录结构..."
mkdir -p config scripts/{python,applescript,node} docs temp "Voice Recordings Backup"
echo "✅ 目录结构创建完成"
echo ""

# 2. 检查 FFmpeg
echo "🎬 检查 FFmpeg..."
if ! command -v ffmpeg &> /dev/null; then
    echo "📦 FFmpeg 未安装，正在尝试安装..."
    if command -v brew &> /dev/null; then
        brew install ffmpeg
    else
        echo "⚠️ 未找到 Homebrew，请手动安装 FFmpeg"
        echo "  访问: https://ffmpeg.org/download.html"
    fi
else
    echo "✅ FFmpeg 已安装"
fi
echo ""

# 3. 检查 Python
echo "🐍 检查 Python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误：未找到 Python 3"
    echo "  请安装 Python 3.6 或更高版本"
    exit 1
else
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo "✅ Python $PYTHON_VERSION 已安装"
fi
echo ""

# 4. 配置 Python 环境
echo "📦 配置 Python 依赖..."
if python3 -c "import requests" 2>/dev/null; then
    echo "✅ Python requests 模块已安装（系统级）"
else
    echo "🔧 创建虚拟环境..."
    python3 -m venv venv
    
    # 激活虚拟环境并安装依赖
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
        pip install requests flask flask-cors
        echo "✅ Python 虚拟环境配置完成"
        echo "  注意：使用时会自动激活虚拟环境"
    else
        echo "❌ 虚拟环境创建失败"
    fi
fi

# 检查 Flask（用于 Web 界面）
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
fi
if ! python3 -c "import flask" 2>/dev/null; then
    echo "📦 安装 Web 界面依赖..."
    pip install flask flask-cors
fi
echo ""

# 5. 检查 API 密钥
echo "🔑 检查 API 密钥..."
if [ -f "config/api_key.txt" ] && [ -s "config/api_key.txt" ]; then
    echo "✅ API 密钥文件已存在"
else
    echo "⚠️ API 密钥未配置"
    echo ""
    echo "请提供您的 11Labs API 密钥（以 sk_ 开头）："
    echo "配置方法："
    echo "  echo 'your-api-key' > config/api_key.txt"
    echo ""
    echo "获取 API 密钥："
    echo "  1. 访问 https://elevenlabs.io"
    echo "  2. 登录您的账户"
    echo "  3. 在设置中找到 API 密钥"
fi
echo ""

# 6. 设置执行权限
echo "🔧 设置文件权限..."
chmod +x voice_to_notes.sh 2>/dev/null
chmod +x "Notes AppleScript" 2>/dev/null
chmod -R 755 scripts/ 2>/dev/null
[ -f "config/api_key.txt" ] && chmod 600 config/api_key.txt
echo "✅ 文件权限设置完成"
echo ""

# 7. 创建 .gitkeep 文件
touch "Voice Recordings Backup/.gitkeep" 2>/dev/null
touch "temp/.gitkeep" 2>/dev/null

# 8. 验证 Apple Notes 访问
echo "📝 检查 Apple Notes 访问权限..."
if osascript -e 'tell application "Notes" to count notes' &>/dev/null; then
    echo "✅ Apple Notes 访问正常"
else
    echo "⚠️ 需要授权访问 Notes"
    echo "  请在系统偏好设置 > 安全性与隐私 > 隐私 > 自动化"
    echo "  允许终端访问 Notes"
fi
echo ""

# 9. 最终验证
echo "════════════════════════════════════════"
echo "📋 配置检查结果："
echo "════════════════════════════════════════"

# 检查各项配置
[ -d "config" ] && echo "✅ 配置目录" || echo "❌ 配置目录"
[ -d "scripts/python" ] && echo "✅ Python 脚本目录" || echo "❌ Python 脚本目录"
[ -d "scripts/applescript" ] && echo "✅ AppleScript 目录" || echo "❌ AppleScript 目录"
[ -d "Voice Recordings Backup" ] && echo "✅ 备份目录" || echo "❌ 备份目录"
[ -f "config/api_key.txt" ] && [ -s "config/api_key.txt" ] && echo "✅ API 密钥" || echo "❌ API 密钥"
command -v ffmpeg &> /dev/null && echo "✅ FFmpeg" || echo "❌ FFmpeg"
(python3 -c "import requests" 2>/dev/null || [ -d "venv" ]) && echo "✅ Python 依赖" || echo "❌ Python 依赖"
[ -x "voice_to_notes.sh" ] && echo "✅ 启动脚本" || echo "❌ 启动脚本"

echo "════════════════════════════════════════"
echo ""

# 提供下一步指导
if [ ! -f "config/api_key.txt" ] || [ ! -s "config/api_key.txt" ]; then
    echo "📌 下一步："
    echo "1. 配置 API 密钥："
    echo "   echo 'your-api-key-here' > config/api_key.txt"
    echo ""
fi

echo "🎉 配置脚本执行完成！"
echo ""
echo "使用方法："
echo "  ./voice_to_notes.sh audio1.wav audio2.mp3"
echo ""