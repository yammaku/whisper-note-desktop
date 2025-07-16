# 闪念笔记 - 新机器安装指南

本指南帮助您在新的Mac上设置闪念笔记工具。

## 系统要求

- macOS 10.12 或更高版本
- Python 3.6 或更高版本
- 互联网连接（用于API调用）

## 安装步骤

### 1. 复制项目文件夹

将整个 `闪念笔记` 文件夹复制到新机器的任意位置。建议放在：
- `~/Documents/闪念笔记/`
- `~/Desktop/闪念笔记/`
- 或任何您方便的位置

### 2. 安装系统依赖

打开终端（Terminal），运行以下命令：

```bash
# 检查是否已安装Homebrew
if ! command -v brew &> /dev/null; then
    echo "安装Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 安装FFmpeg（用于音频处理）
brew install ffmpeg

# 检查Python版本
python3 --version
# 如果版本低于3.6，请运行：
# brew install python3
```

### 3. 设置API密钥

#### 选项A：使用现有密钥
如果您有11Labs API密钥文件，将其复制到：
```bash
闪念笔记/config/api_key.txt
```

#### 选项B：设置新密钥
1. 访问 [11Labs](https://elevenlabs.io/) 注册账号
2. 获取API密钥
3. 在项目目录中创建密钥文件：
```bash
cd 闪念笔记
mkdir -p config
echo "您的API密钥" > config/api_key.txt
```

### 4. 首次运行设置

#### 方法1：使用应用程序（推荐）
1. 双击 `闪念笔记.app`
2. 如果显示"无法打开"警告：
   - 右键点击 `闪念笔记.app`
   - 选择"打开"
   - 在弹出的对话框中点击"打开"

#### 方法2：使用命令脚本
1. 双击 `启动闪念笔记.command`
2. 如果提示权限问题，在终端运行：
```bash
cd 闪念笔记
chmod +x *.sh *.command
chmod +x scripts/applescript/*
```

### 5. Python依赖安装

首次运行时，系统会自动检查并安装所需的Python包：
- flask
- flask-cors
- requests

如果自动安装失败，可手动安装：
```bash
cd 闪念笔记
pip3 install flask flask-cors requests
```

### 6. Apple Notes权限设置

首次运行时，macOS可能会询问以下权限：
1. **辅助功能权限**：用于控制Apple Notes
   - 系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能
   - 添加并勾选Terminal（终端）

2. **自动化权限**：允许脚本控制Apple Notes
   - 首次运行时会自动弹出权限请求
   - 点击"好"允许

## 验证安装

### 测试Web界面
1. 启动应用（双击 `闪念笔记.app`）
2. 浏览器应自动打开 http://localhost:8181
3. 尝试拖拽一个音频文件到页面

### 测试命令行
```bash
cd 闪念笔记
./voice_to_notes.sh test.m4a
```

## 常见问题

### Q: 提示"无法验证开发者"
A: 这是macOS的安全机制。解决方法：
1. 系统偏好设置 > 安全性与隐私 > 通用
2. 点击"仍要打开"

### Q: 端口8181被占用
A: 检查并停止占用端口的进程：
```bash
lsof -i :8181
kill -9 <PID>
```

### Q: Apple Notes没有响应
A: 确保：
1. Apple Notes应用已安装并至少打开过一次
2. 已授予必要的权限（见上文权限设置）
3. iCloud同步已启用（如果使用iCloud笔记）

### Q: 转录结果为空
A: 检查：
1. API密钥是否正确
2. 音频文件是否损坏
3. 网络连接是否正常

## 文件结构说明

```
闪念笔记/
├── 闪念笔记.app          # 主应用程序（可移植）
├── config/               # 配置文件夹
│   └── api_key.txt      # API密钥（需要设置）
├── scripts/             # 脚本文件夹
├── temp/                # 临时文件（自动创建）
└── Voice Recordings Backup/  # 备份文件夹（自动创建）
```

## 更新和维护

- 所有路径都是相对路径，可以随意移动整个文件夹
- 备份文件夹会自动按日期组织
- 日志文件保存在 `web_server.log`

## 获取帮助

如遇到问题：
1. 查看 `web_server.log` 日志文件
2. 确保所有依赖都已正确安装
3. 检查文件权限是否正确

---

安装完成后，您就可以开始使用闪念笔记了！只需拖拽音频文件到Web界面，即可自动转录并同步到Apple Notes。