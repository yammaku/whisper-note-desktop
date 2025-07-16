# 闪念笔记工具集

这是一个用于管理Apple Notes和音频转录的工具集合，支持命令行和Web界面操作。

## 项目结构

```
闪念笔记/
├── README.md                # 项目说明
├── config/                  # 配置文件
│   └── api_key.txt         # 11Labs API密钥
├── scripts/                 # 脚本文件
│   ├── applescript/        # AppleScript脚本
│   │   ├── apple_notes_manager.applescript
│   │   ├── append_to_note.applescript
│   │   └── append_with_timestamp.applescript
│   ├── python/             # Python脚本
│   │   ├── transcribe_audio.py
│   │   └── voice_to_notes_workflow.py
│   └── node/               # Node.js脚本
│       └── append_to_note.js
├── docs/                    # 文档
│   └── VOICE_TO_NOTES_README.md
├── temp/                    # 临时文件
└── Voice Recordings Backup/ # 音频备份（自动创建）
```

## 主要功能

### 1. Apple Notes操作工具
- `Notes AppleScript` - 命令行工具，用于操作Apple Notes
- `append_to_note.js` - 向笔记追加内容的Node.js工具

### 2. 语音转录工作流
- `voice_to_notes_workflow.py` - 自动将语音转录并同步到Apple Notes
- `transcribe_audio.py` - 使用11Labs API进行音频转录

### 3. 🆕 Web界面
- `web_interface.html` - 拖拽上传音频文件的网页界面
- `web_server.py` - Flask服务器，提供Web API

## 快速开始

### 设置API密钥
```bash
echo "your-11labs-api-key" > config/api_key.txt
```

### 使用语音转录工作流

#### 方式1：命令行
```bash
# 单个文件
./voice_to_notes.sh audio1.m4a

# 多个文件
./voice_to_notes.sh audio1.m4a audio2.mp3

# 批量处理
./voice_to_notes.sh *.wav
```

#### 方式2：Web界面 🆕

**首次使用请先运行初始化：**
```bash
双击 "初始化设置.command"
```

**启动方式（三选一）：**
1. 双击 `闪念笔记.app` 图标（推荐，完全可移植）
2. 或双击 `启动闪念笔记.command` 文件
3. 或双击 `启动闪念笔记.html` 文件

**命令行方式：**
```bash
# 启动Web服务器
./start_web_server.sh

# 在浏览器中打开
# http://localhost:8181
```

然后直接拖拽音频文件到网页即可！

### 操作Apple Notes
```bash
# 列出所有笔记
./Notes\ AppleScript list

# 创建新笔记
./Notes\ AppleScript create "笔记标题" "笔记内容"

# 搜索笔记
./Notes\ AppleScript search "关键词"
```

## 详细文档

- [语音转录工作流详细说明](docs/VOICE_TO_NOTES_README.md)
- [新机器安装指南](docs/SETUP_GUIDE_NEW_MACHINE.md)

## 依赖要求

- macOS（用于Apple Notes集成）
- Python 3.x
- Node.js（可选）
- FFmpeg（用于音频处理）
- 11Labs API密钥
- Flask（Web界面，自动安装）