#!/bin/bash
# 语音转录到笔记的便捷启动脚本

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 激活虚拟环境（如果存在）
if [ -f "$SCRIPT_DIR/venv/bin/activate" ]; then
    source "$SCRIPT_DIR/venv/bin/activate"
fi

# 执行Python脚本
python3 "$SCRIPT_DIR/scripts/python/voice_to_notes_workflow.py" "$@"