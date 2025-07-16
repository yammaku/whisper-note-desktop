#!/bin/bash
# 双击启动闪念笔记

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 设置工作目录
cd "$SCRIPT_DIR"

echo "🚀 启动闪念笔记服务..."
echo ""

# 检查是否已经在运行
if lsof -Pi :8181 -sTCP:LISTEN -t >/dev/null ; then
    echo "✅ 服务器已在运行"
    echo "🌐 正在打开浏览器..."
    open http://localhost:8181
else
    echo "📦 启动服务器..."
    
    # 启动服务器
    ./start_web_server.sh &
    
    echo "⏳ 等待服务器启动..."
    
    # 等待服务器启动
    for i in {1..15}; do
        if curl -s http://localhost:8181/health >/dev/null 2>&1; then
            echo ""
            echo "✅ 服务器启动成功！"
            echo "🌐 正在打开浏览器..."
            sleep 1
            open http://localhost:8181
            break
        fi
        printf "."
        sleep 1
    done
fi

echo ""
echo "════════════════════════════════════════"
echo "📝 闪念笔记正在运行"
echo "🌐 访问地址: http://localhost:8181"
echo "════════════════════════════════════════"
echo ""
echo "⚠️  请保持此窗口开启"
echo "关闭此窗口将停止服务器"
echo ""
echo "按 Ctrl+C 停止服务器"

# 保持窗口开启
wait