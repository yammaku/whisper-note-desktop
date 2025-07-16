#!/bin/bash
# 创建可移植的macOS应用程序

APP_NAME="闪念笔记"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🚀 创建可移植的 ${APP_NAME} 应用程序..."

# 删除旧版本
rm -rf "${APP_DIR}"

# 创建应用程序目录结构
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 创建可执行脚本（使用相对路径）
cat > "${MACOS_DIR}/${APP_NAME}" << 'EOF'
#!/bin/bash

# 获取应用程序包的真实路径
APP_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_BUNDLE_PATH="$( cd "${APP_PATH}/../.." && pwd )"
# 项目目录就是app所在的父目录
PROJECT_DIR="$( cd "${APP_BUNDLE_PATH}/.." && pwd )"

# 切换到项目目录
cd "$PROJECT_DIR"

# 检查是否是闪念笔记项目目录
if [ ! -f "start_web_server.sh" ]; then
    osascript -e 'display dialog "错误：未找到闪念笔记项目文件。\n\n请确保 闪念笔记.app 位于项目根目录中。" buttons {"确定"} default button 1 with icon stop'
    exit 1
fi

# 检查服务器是否已经在运行
if lsof -Pi :8181 -sTCP:LISTEN -t >/dev/null 2>&1; then
    # 服务器已运行，直接打开浏览器
    open http://localhost:8181
else
    # 启动服务器
    osascript -e "tell application \"Terminal\"
        activate
        do script \"cd \\\"${PROJECT_DIR}\\\" && ./start_web_server.sh\"
    end tell"
    
    # 等待服务器启动
    sleep 5
    
    # 检查服务器是否启动成功
    for i in {1..10}; do
        if curl -s http://localhost:8181/health >/dev/null 2>&1; then
            # 打开浏览器
            open http://localhost:8181
            break
        fi
        sleep 1
    done
fi
EOF

# 设置执行权限
chmod +x "${MACOS_DIR}/${APP_NAME}"

# 创建Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.flashnotes</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.12</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 复制图标
if [ -f "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns" ]; then
    cp "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns" "${RESOURCES_DIR}/icon.icns"
fi

echo "✅ 可移植应用程序创建完成！"
echo ""
echo "📍 应用程序位置: ${APP_DIR}"
echo ""
echo "这个应用程序现在完全可移植："
echo "- 使用相对路径定位项目文件"
echo "- 可以随项目文件夹一起复制到其他机器"
echo "- 无需修改任何路径配置"