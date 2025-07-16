# 语音转录到闪念笔记工作流

这个工具可以自动将您的语音录音转录为文字，并整理到Apple Notes的每日闪念笔记中。

## 功能特点

- 🎙️ 批量处理多个音频文件
- 📝 使用11Labs API进行高质量转录（纯文本，无时间戳）
- 📅 自动按日期整理到对应的笔记
- 🗂️ 本地备份原始音频和转录文本
- ⏱️ 智能同步等待机制，确保iCloud同步完成
- 🔄 自动压缩音频以优化API调用

## 前置要求

1. **11Labs API密钥**
   - 在 `api_key.txt` 文件中保存您的API密钥

2. **FFmpeg**
   ```bash
   brew install ffmpeg
   ```

3. **Python依赖**
   ```bash
   pip install requests
   ```

4. **Apple Notes设置**
   - 确保已登录iCloud
   - 在Apple Notes中创建"闪念笔记"文件夹

## 使用方法

### 基本用法
```bash
python voice_to_notes_workflow.py audio1.m4a audio2.mp3 audio3.wav
```

### 批量处理
```bash
python voice_to_notes_workflow.py *.m4a
```

## 工作流程

1. **启动同步**: 激活Apple Notes触发iCloud同步
2. **音频处理**: 
   - 提取日期信息
   - 使用FFmpeg压缩音频（32kbps, 16kHz, 单声道）
   - 调用11Labs API转录
3. **本地备份**: 
   - 创建日期目录结构
   - 保存原始音频和Markdown格式的转录文本
4. **等待同步**: 确保至少等待45秒
5. **更新笔记**: 将内容添加到Apple Notes

## 文件组织

### Apple Notes结构
```
闪念笔记/
├── Jul 16, 2025
├── Jul 17, 2025
└── ...
```

每条录音在笔记中的格式：
```
[音频: recording_name.mp3]
转录的文本内容...
####
```

### 本地备份结构
```
Voice Recordings Backup/
├── 2025/
│   ├── 07/
│   │   ├── 16/
│   │   │   ├── recording_1.m4a (原始)
│   │   │   ├── recording_1.md (转录)
│   │   │   ├── recording_1_compressed.mp3
│   │   │   └── ...
```

## 日期识别规则

1. 优先从文件名提取（支持格式：YYYYMMDD, YYYY-MM-DD, YYYY_MM_DD）
2. 如果文件名无日期，使用文件创建时间

## 注意事项

- 确保网络连接稳定（用于API调用和iCloud同步）
- 压缩后的音频用于API调用和笔记嵌入
- 原始音频保留在本地备份中
- 转录失败的文件会被跳过，不影响其他文件处理

## 故障排除

1. **API错误**: 检查 `api_key.txt` 中的密钥是否正确
2. **FFmpeg错误**: 确保FFmpeg已正确安装
3. **Apple Notes错误**: 检查是否有"闪念笔记"文件夹
4. **同步问题**: 可以在脚本中调整 `MIN_SYNC_TIME` 常量

## 自定义配置

在 `voice_to_notes_workflow.py` 中可以调整：
- `MIN_SYNC_TIME`: 最小同步等待时间（默认45秒）
- `BACKUP_ROOT`: 备份根目录名称
- `COMPRESSED_SUFFIX`: 压缩文件后缀