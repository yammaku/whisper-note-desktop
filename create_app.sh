#!/bin/bash
# 创建macOS应用程序

APP_NAME="闪念笔记"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
PROJECT_DIR="/Users/yammaku/Documents/Claude Code Projects/闪念笔记"

echo "🚀 创建 ${APP_NAME} 应用程序..."

# 创建应用程序目录结构
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 创建可执行脚本
cat > "${MACOS_DIR}/${APP_NAME}" << 'EOF'
#!/bin/bash

# 获取应用程序所在目录
APP_DIR="$(cd "$(dirname "$0")/../../../.." && pwd)"
PROJECT_DIR="/Users/yammaku/Documents/Claude Code Projects/闪念笔记"

# 切换到项目目录
cd "$PROJECT_DIR"

# 检查服务器是否已经在运行
if lsof -Pi :8181 -sTCP:LISTEN -t >/dev/null ; then
    # 服务器已运行，直接打开浏览器
    open http://localhost:8181
else
    # 启动服务器
    osascript -e 'tell application "Terminal"
        activate
        do script "cd \"'"$PROJECT_DIR"'\" && ./start_web_server.sh"
    end tell'
    
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

# 创建图标（使用emoji作为临时方案）
cat > "${RESOURCES_DIR}/make_icon.sh" << 'EOF'
#!/bin/bash
# 创建一个简单的图标
sips -s format icns /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns --out icon.icns 2>/dev/null || true
EOF

chmod +x "${RESOURCES_DIR}/make_icon.sh"
cd "${RESOURCES_DIR}" && ./make_icon.sh

echo "✅ 应用程序创建完成！"
echo ""
echo "📍 应用程序位置: ${APP_DIR}"
echo ""
echo "使用方法："
echo "1. 双击 ${APP_NAME}.app 启动应用"
echo "2. 或将应用拖到 Applications 文件夹"
echo ""
echo "提示：首次运行可能需要右键点击选择'打开'以绕过安全限制"