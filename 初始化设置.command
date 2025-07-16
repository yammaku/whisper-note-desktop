#!/bin/bash
# 闪念笔记初始化设置脚本

echo "🚀 闪念笔记初始化设置"
echo "===================="
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 检查系统
echo "📋 检查系统环境..."
echo ""

# 检查Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ Python已安装: $PYTHON_VERSION"
else
    echo "❌ 未找到Python3，请先安装Python"
    echo "   访问: https://www.python.org/downloads/"
    exit 1
fi

# 检查FFmpeg
if command -v ffmpeg &> /dev/null; then
    echo "✅ FFmpeg已安装"
else
    echo "⚠️  FFmpeg未安装"
    echo "   建议安装FFmpeg以获得更好的音频处理效果"
    echo "   安装方法: brew install ffmpeg"
fi

echo ""
echo "📝 设置权限..."

# 设置执行权限
chmod +x *.sh *.command 2>/dev/null
chmod +x scripts/applescript/* 2>/dev/null
chmod +x 闪念笔记.app/Contents/MacOS/* 2>/dev/null

echo "✅ 权限设置完成"

# 检查API密钥
echo ""
echo "🔑 检查API密钥..."

if [ -f "config/api_key.txt" ]; then
    echo "✅ API密钥文件已存在"
else
    echo "⚠️  未找到API密钥文件"
    echo ""
    echo "请设置您的11Labs API密钥："
    echo "1. 访问 https://elevenlabs.io/ 注册账号"
    echo "2. 获取API密钥"
    echo "3. 输入您的API密钥（输入后按回车）："
    read -r API_KEY
    
    if [ -n "$API_KEY" ]; then
        mkdir -p config
        echo "$API_KEY" > config/api_key.txt
        echo "✅ API密钥已保存"
    else
        echo "❌ API密钥不能为空"
    fi
fi

# 安装Python依赖
echo ""
echo "📦 检查Python依赖..."

# 检查Flask
if python3 -c "import flask" 2>/dev/null; then
    echo "✅ Flask已安装"
else
    echo "📦 安装Flask..."
    pip3 install flask flask-cors
fi

# 检查requests
if python3 -c "import requests" 2>/dev/null; then
    echo "✅ Requests已安装"
else
    echo "📦 安装Requests..."
    pip3 install requests
fi

# 创建必要的目录
echo ""
echo "📁 创建目录结构..."
mkdir -p temp/uploads
mkdir -p "Voice Recordings Backup"
echo "✅ 目录创建完成"

# 完成
echo ""
echo "════════════════════════════════════════"
echo "✨ 初始化完成！"
echo "════════════════════════════════════════"
echo ""
echo "现在您可以："
echo "1. 双击 '闪念笔记.app' 启动应用"
echo "2. 或双击 '启动闪念笔记.command' 启动服务"
echo ""
echo "首次使用时，macOS可能会要求授权："
echo "- 辅助功能权限（控制Apple Notes）"
echo "- 自动化权限（操作Apple Notes）"
echo ""
echo "按任意键退出..."
read -n 1