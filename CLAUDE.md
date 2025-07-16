# 闪念笔记 - 语音转录工作流项目

## 项目概述

这是一个自动化工具，用于将语音录音转录为文字并整理到 Apple Notes 的每日闪念笔记中。

## 🤖 AI 助手初始化指南

> **重要**：当用户首次使用本项目时，请按照以下步骤自动配置环境。除了 API 密钥外，不要让用户手动解决任何配置问题。

### 自动化初始配置步骤

1. **检查项目完整性**
   ```bash
   # 检查必要文件夹是否存在
   ls -la config/ scripts/ docs/ temp/ "Voice Recordings Backup/"
   ```
   如果缺少，创建它们：
   ```bash
   mkdir -p config scripts/{python,applescript,node} docs temp "Voice Recordings Backup"
   ```

2. **检查并安装系统依赖**
   ```bash
   # 检查 FFmpeg
   if ! command -v ffmpeg &> /dev/null; then
       echo "正在安装 FFmpeg..."
       brew install ffmpeg || echo "请手动安装 FFmpeg"
   fi
   
   # 检查 Python 3
   if ! command -v python3 &> /dev/null; then
       echo "需要 Python 3"
       exit 1
   fi
   ```

3. **配置 Python 环境**
   ```bash
   # 检查是否可以导入 requests
   if ! python3 -c "import requests" 2>/dev/null; then
       echo "配置 Python 虚拟环境..."
       python3 -m venv venv
       source venv/bin/activate
       pip install requests
   fi
   ```

4. **检查 API 密钥**
   ```bash
   if [ ! -f "config/api_key.txt" ] || [ ! -s "config/api_key.txt" ]; then
       echo "⚠️ 需要 11Labs API 密钥"
       echo "请向用户询问 API 密钥，然后运行："
       echo "echo 'API密钥' > config/api_key.txt"
   fi
   ```

5. **验证 Apple Notes 访问**
   ```bash
   # 测试 AppleScript 权限
   osascript -e 'tell application "Notes" to count notes' 2>/dev/null || {
       echo "需要授权访问 Notes 应用"
       echo "请在系统偏好设置中允许终端访问 Notes"
   }
   ```

6. **设置执行权限**
   ```bash
   chmod +x voice_to_notes.sh
   chmod +x "Notes AppleScript"
   ```

### AI 助手配置脚本

创建并运行以下一键配置脚本：

```bash
#!/bin/bash
# setup.sh - 自动配置脚本

echo "🚀 开始自动配置闪念笔记工具..."

# 1. 创建必要目录
echo "📁 创建目录结构..."
mkdir -p config scripts/{python,applescript,node} docs temp "Voice Recordings Backup"

# 2. 检查 FFmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "📦 安装 FFmpeg..."
    if command -v brew &> /dev/null; then
        brew install ffmpeg
    else
        echo "⚠️ 请告诉用户需要安装 FFmpeg"
    fi
fi

# 3. 配置 Python 环境
echo "🐍 配置 Python 环境..."
if ! python3 -c "import requests" 2>/dev/null; then
    python3 -m venv venv
    source venv/bin/activate
    pip install requests
    echo "✅ Python 环境配置完成"
fi

# 4. 检查 API 密钥
if [ ! -f "config/api_key.txt" ] || [ ! -s "config/api_key.txt" ]; then
    echo ""
    echo "⚠️ 需要配置 API 密钥"
    echo "请向用户获取 11Labs API 密钥"
    echo "获取后运行: echo 'sk_xxxxx' > config/api_key.txt"
    echo ""
fi

# 5. 设置权限
chmod +x voice_to_notes.sh 2>/dev/null
chmod +x "Notes AppleScript" 2>/dev/null

# 6. 创建 .gitkeep 文件
touch "Voice Recordings Backup/.gitkeep"
touch "temp/.gitkeep"

echo "✅ 基础配置完成！"

# 7. 验证配置
echo ""
echo "📋 配置检查："
[ -f "config/api_key.txt" ] && echo "✅ API 密钥已配置" || echo "❌ API 密钥未配置"
command -v ffmpeg &> /dev/null && echo "✅ FFmpeg 已安装" || echo "❌ FFmpeg 未安装"
python3 -c "import requests" 2>/dev/null && echo "✅ Python 依赖已安装" || echo "❌ Python 依赖未安装"

echo ""
echo "🎉 配置完成！如有红色 ❌ 标记，请解决相应问题。"
```

### 常见问题自动解决

1. **权限问题**
   ```bash
   # 如果遇到权限错误，自动修复
   chmod -R 755 scripts/
   chmod 644 config/api_key.txt
   ```

2. **路径空格问题**
   - 项目路径包含空格时，所有命令都已使用引号处理

3. **Python 版本问题**
   ```bash
   # 检查 Python 版本
   python3 --version
   # 需要 3.6 或更高版本
   ```

4. **Web服务器依赖**
   ```bash
   # 自动安装Flask依赖
   pip install flask flask-cors
   ```

### 给 AI 的提示模板

当用户克隆或下载此项目后，使用以下提示：

```
我刚下载了闪念笔记项目，请帮我自动配置环境。
项目路径：[项目路径]

请：
1. 检查并安装所有依赖
2. 创建必要的目录结构
3. 配置 Python 环境
4. 我会提供 11Labs API 密钥：[用户提供]
5. 验证所有配置是否正确

原则：除了 API 密钥，其他都自动解决，不要让我手动操作。
```

### 核心功能
- 批量处理多个音频文件
- 使用 11Labs API 进行高质量语音转文字
- 自动按日期整理到 Apple Notes
- 本地备份原始音频和转录文本
- 智能同步等待机制
- 🆕 Web界面支持拖拽上传音频文件

## 项目结构

```
闪念笔记/
├── README.md                    # 用户向导
├── CLAUDE.md                    # 本文档（AI助手参考）
├── voice_to_notes.sh           # 便捷启动脚本
├── web_interface.html          # 🆕 拖拽上传界面
├── web_server.py               # 🆕 Flask Web服务器
├── start_web_server.sh         # 🆕 Web服务启动脚本
├── .gitignore                  # Git配置
├── config/
│   └── api_key.txt            # 11Labs API密钥
├── scripts/
│   ├── applescript/           # Apple Notes操作脚本
│   │   ├── apple_notes_manager.applescript
│   │   ├── notes_simple_audio.applescript  # 当前使用
│   │   └── ...
│   ├── python/
│   │   ├── voice_to_notes_workflow.py     # 主工作流
│   │   └── transcribe_audio.py            # 转录模块
│   └── node/
│       └── append_to_note.js              # 笔记追加工具
├── docs/
│   └── VOICE_TO_NOTES_README.md          # 详细文档
├── temp/                                   # 临时文件
│   └── uploads/                           # 🆕 Web上传临时文件
├── venv/                                   # Python虚拟环境
└── Voice Recordings Backup/                # 音频备份目录
    └── YYYY/MM/DD/                        # 按日期组织
```

## 工作流程详解

### 1. 启动阶段
- 激活 Apple Notes 触发 iCloud 同步
- 开始并行处理音频文件

### 2. 音频处理
- **日期提取**：从文件名（格式：YYYY-MM-DD）或文件创建时间
- **FFmpeg 压缩**：
  ```bash
  ffmpeg -i input.wav -vn -acodec mp3 -ab 32k -ar 16000 -ac 1 output.mp3
  ```
  - 32kbps 比特率（STT 最佳平衡）
  - 16kHz 采样率（11Labs 标准）
  - 单声道

### 3. 转录处理
- 使用 11Labs API（模型：scribe_v1）
- 配置：`diarize: false`（不区分说话人）
- 只获取纯文本，无时间戳

### 4. 本地备份
```
Voice Recordings Backup/
└── 2025/07/16/
    ├── recording.wav              # 原始音频
    ├── recording_compressed.mp3   # 压缩音频
    └── recording.md              # 转录文本
```

### 5. Apple Notes 更新
- 等待 45 秒确保 iCloud 同步
- 笔记格式：
  ```
  转录文本内容...
  ####
  ```
- 注意：不再包含音频链接（因为file://链接在Notes中无法正常工作）
- 每条笔记以 #### 作为分隔符

## 技术细节

### API 密钥管理
- 位置：`config/api_key.txt`
- 格式：以 `sk_` 开头的 11Labs API 密钥

### Python 环境
- 使用虚拟环境：`venv/`
- 依赖：`requests`
- Python 3.x

### 相对路径设计
所有脚本使用相对路径，便于项目移植：
```python
PROJECT_ROOT = Path(__file__).parent.parent.parent
```

### Apple Notes 集成
- 使用 AppleScript 操作 Notes
- 限制：无法直接嵌入音频，使用 file:// 链接替代
- 文件夹路径：在 `Capture/閃念筆記`（繁体中文）文件夹中创建/更新笔记
- 注意：不是直接的"闪念笔记"文件夹，而是在Capture文件夹下的子文件夹

### 错误处理
- 转录失败的文件会被跳过
- 日期无法识别时使用文件创建时间
- API 错误会显示详细信息

## 使用方法

### 基本使用
```bash
./voice_to_notes.sh audio1.wav audio2.mp3 audio3.m4a
```

### 批量处理
```bash
./voice_to_notes.sh *.wav
```

### 从录音设备导入
```bash
./voice_to_notes.sh "/path/to/TP-7 Device/memo/*.wav"
```

### 🆕 Web界面使用
1. 启动Web服务器：
   ```bash
   ./start_web_server.sh
   ```

2. 打开浏览器访问：http://localhost:8181

3. 拖拽音频文件到网页或点击选择文件

4. 支持批量拖拽多个文件同时处理

## 常见问题

### Q: 为什么音频不是真正嵌入的？
A: Apple Notes 的 AppleScript API 不支持直接添加音频附件。当前方案使用可点击的文件链接。

### Q: 同步等待时间可以调整吗？
A: 可以，修改 `voice_to_notes_workflow.py` 中的 `MIN_SYNC_TIME` 常量（默认 45 秒）。

### Q: 支持哪些音频格式？
A: 理论上 FFmpeg 支持的格式都可以（wav, mp3, m4a, flac 等）。

### Q: 备份文件会自动清理吗？
A: 不会，需要手动管理 `Voice Recordings Backup` 文件夹。

### Q: Web界面如何使用？
A: 运行 `./start_web_server.sh` 启动服务器，然后在浏览器访问 http://localhost:8181，直接拖拽音频文件即可。

## 开发笔记

### 关键决策
1. **45 秒同步时间**：确保 iCloud 同步完成，即使处理单个短音频
2. **本地备份**：保留原始文件 + Markdown 转录，便于回溯
3. **相对路径**：提高可移植性
4. **虚拟环境**：避免系统 Python 包冲突

### 未来改进方向
1. 支持真正的音频嵌入（可能通过 Shortcuts）
2. 自动清理旧备份
3. 支持多语言转录
4. 添加转录质量检查
5. 支持远程音频文件

### 调试技巧
- 查看备份文件夹了解处理结果
- Apple Notes 错误通常与文件夹权限或同步有关
- FFmpeg 错误通常是格式或路径问题
- API 错误检查密钥和网络连接

## 维护指南

### 更新 API 密钥
```bash
echo "新的API密钥" > config/api_key.txt
```

### 清理备份
```bash
# 删除30天前的备份
find "Voice Recordings Backup" -type f -mtime +30 -delete
```

### 重置虚拟环境
```bash
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install requests
```

---

最后更新：2025-07-16
作者：Claude & User
版本：1.0