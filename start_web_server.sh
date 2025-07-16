#!/bin/bash
# start_web_server.sh - 启动Web服务器的脚本

echo "🚀 启动闪念笔记Web服务器..."

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 检查是否需要使用虚拟环境
if [ -d "venv" ]; then
    echo "🔧 激活Python虚拟环境..."
    source venv/bin/activate
fi

# 检查是否已安装Flask
if ! python3 -c "import flask" 2>/dev/null; then
    echo "📦 安装Flask和依赖..."
    pip install flask flask-cors
fi

# 启动Web服务器
echo ""
echo "════════════════════════════════════════"
echo "🌐 Web服务器正在启动..."
echo "════════════════════════════════════════"
echo ""

python3 web_server.py