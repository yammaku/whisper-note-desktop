#!/usr/bin/env python3
"""
Voice to Apple Notes Workflow
自动将语音录音转录并同步到Apple Notes的闪念笔记中
"""

import os
import sys
import json
import time
import shutil
import subprocess
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Tuple, Optional
import argparse

# 添加Python脚本目录到路径
sys.path.append(str(Path(__file__).parent))

# 导入现有的转录模块
from transcribe_audio import ElevenLabsTranscriber, load_api_key

# 配置常量
MIN_SYNC_TIME = 45  # 最小同步等待时间（秒）
BACKUP_ROOT = "Voice Recordings Backup"
COMPRESSED_SUFFIX = "_compressed"
PROJECT_ROOT = Path(__file__).parent.parent.parent  # 项目根目录

class VoiceToNotesWorkflow:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.transcriber = ElevenLabsTranscriber(api_key)
        self.start_time = None
        
    def extract_date_from_file(self, file_path: str) -> datetime:
        """
        从文件中提取日期
        优先级：1. 文件名中的日期 2. 文件创建时间
        """
        # 尝试从文件名提取日期 (假设格式如: recording_20250716_143025.m4a)
        import re
        filename = Path(file_path).stem
        
        # 尝试匹配各种日期格式
        patterns = [
            r'(\d{4})(\d{2})(\d{2})',  # YYYYMMDD
            r'(\d{4})-(\d{2})-(\d{2})',  # YYYY-MM-DD
            r'(\d{4})_(\d{2})_(\d{2})',  # YYYY_MM_DD
        ]
        
        for pattern in patterns:
            match = re.search(pattern, filename)
            if match:
                year, month, day = match.groups()
                try:
                    # 验证日期是否有效
                    date = datetime(int(year), int(month), int(day))
                    # 确保日期在合理范围内（2000年到2100年）
                    if 2000 <= date.year <= 2100:
                        return date
                except ValueError:
                    # 日期无效，继续尝试其他模式
                    continue
        
        # 如果文件名中没有日期，使用文件创建时间
        stat = os.stat(file_path)
        # 在macOS上，使用birthtime（创建时间）
        creation_time = stat.st_birthtime if hasattr(stat, 'st_birthtime') else stat.st_mtime
        return datetime.fromtimestamp(creation_time)
    
    def compress_audio(self, input_path: str, output_path: str) -> bool:
        """
        使用FFmpeg压缩音频文件
        """
        cmd = [
            'ffmpeg',
            '-i', input_path,
            '-vn',  # 仅提取音频
            '-acodec', 'mp3',
            '-ab', '32k',  # 32kbps比特率
            '-ar', '16000',  # 16kHz采样率
            '-ac', '1',  # 单声道
            '-y',  # 覆盖输出文件
            output_path
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✓ 压缩成功: {Path(output_path).name}")
                return True
            else:
                print(f"✗ 压缩失败: {result.stderr}")
                return False
        except Exception as e:
            print(f"✗ FFmpeg错误: {str(e)}")
            return False
    
    def activate_apple_notes(self):
        """
        激活Apple Notes应用以触发同步
        """
        script = '''
        tell application "Notes"
            activate
            delay 2
        end tell
        '''
        
        try:
            subprocess.run(['osascript', '-e', script], capture_output=True)
            print("✓ Apple Notes已激活，开始同步...")
        except Exception as e:
            print(f"✗ 激活Apple Notes失败: {str(e)}")
    
    def format_date_for_notes(self, date: datetime) -> str:
        """
        格式化日期为Apple Notes的格式 (如: Jul 16, 2025)
        """
        return date.strftime("%b %-d, %Y")
    
    def create_backup_structure(self, date: datetime) -> str:
        """
        创建本地备份目录结构
        返回目录路径
        """
        year = date.strftime("%Y")
        month = date.strftime("%m")
        day = date.strftime("%d")
        
        backup_dir = PROJECT_ROOT / BACKUP_ROOT / year / month / day
        backup_dir.mkdir(parents=True, exist_ok=True)
        
        return str(backup_dir)
    
    def transcribe_audio_simple(self, audio_path: str) -> str:
        """
        转录音频，只返回纯文本（无时间戳）
        """
        print(f"正在转录: {Path(audio_path).name}")
        
        import requests
        
        with open(audio_path, 'rb') as audio_file:
            files = {
                'file': (os.path.basename(audio_path), audio_file, 'audio/mpeg')
            }
            
            # 修改配置：不需要SRT格式和说话人识别
            data = {
                'model_id': 'scribe_v1',
                'diarize': 'false'  # 不需要说话人识别
            }
            
            response = requests.post(
                self.transcriber.api_url,
                headers=self.transcriber.headers,
                data=data,
                files=files
            )
            
            if response.status_code == 200:
                result = response.json()
                return result.get('text', '')
            else:
                print(f"API错误: {response.status_code} - {response.text}")
                return ""
    
    def check_or_create_note(self, note_title: str) -> bool:
        """
        检查笔记是否存在，不存在则创建
        """
        cmd = [
            'osascript',
            str(PROJECT_ROOT / 'scripts' / 'applescript' / 'notes_simple_audio.applescript'),
            'check_or_create',
            note_title
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                status = result.stdout.strip()
                if status == "created":
                    print(f"✓ 创建新笔记: {note_title}")
                else:
                    print(f"✓ 找到现有笔记: {note_title}")
                return True
            else:
                print(f"✗ 错误: {result.stderr}")
                return False
        except Exception as e:
            print(f"✗ 错误: {str(e)}")
            return False
    
    def append_to_apple_notes(self, note_title: str, audio_path: str, transcript: str, backup_filename: str = None):
        """
        将音频和转录文本添加到Apple Notes
        """
        # 首先确保笔记存在
        if not self.check_or_create_note(note_title):
            return False
        
        # 处理文本中的特殊字符
        escaped_transcript = transcript.replace('"', '\\"').replace('\n', '<br>')
        
        # 如果提供了备份文件名，使用它；否则从audio_path提取
        if backup_filename:
            # 使用备份文件名，但仍传递原始路径给AppleScript（为了兼容性）
            # 我们将在传递给AppleScript时使用特殊格式：路径|文件名
            audio_info = f"{audio_path}|{backup_filename}"
        else:
            audio_info = audio_path
        
        # 使用新的脚本，传递完整的音频文件路径
        cmd = [
            'osascript',
            str(PROJECT_ROOT / 'scripts' / 'applescript' / 'notes_simple_audio.applescript'),
            'append_with_audio',
            note_title,
            audio_info,  # 传递路径信息（可能包含自定义文件名）
            escaped_transcript
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0 and result.stdout.strip() == "success":
                print(f"✓ 已添加到笔记: {note_title}")
                return True
            else:
                print(f"✗ 添加失败: {result.stderr or result.stdout}")
                return False
        except Exception as e:
            print(f"✗ 错误: {str(e)}")
            return False
    
    def save_transcript_backup(self, backup_dir: str, filename: str, transcript: str):
        """
        保存转录文本的本地备份（Markdown格式）
        """
        md_filename = Path(filename).stem + '.md'
        md_path = Path(backup_dir) / md_filename
        
        # 创建Markdown内容
        content = f"""# {filename}

## 转录内容
{transcript}

## 元数据
- 原始文件: {filename}
- 转录时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
        
        with open(md_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✓ 转录备份已保存: {md_filename}")
    
    def process_audio_files(self, audio_files: List[str]):
        """
        处理多个音频文件的主流程
        """
        self.start_time = time.time()
        
        print(f"\n开始处理 {len(audio_files)} 个音频文件...")
        
        # 1. 激活Apple Notes开始同步
        self.activate_apple_notes()
        
        # 2. 按日期组织文件
        files_by_date = {}
        for audio_file in audio_files:
            try:
                date = self.extract_date_from_file(audio_file)
                date_key = date.strftime('%Y-%m-%d')
                if date_key not in files_by_date:
                    files_by_date[date_key] = []
                files_by_date[date_key].append((audio_file, date))
                print(f"✓ 文件 {Path(audio_file).name} -> 日期 {date_key}")
            except Exception as e:
                print(f"✗ 无法处理文件 {Path(audio_file).name}: {str(e)}")
                continue
        
        # 3. 处理每个日期的文件
        all_results = []
        
        for date_key, file_list in files_by_date.items():
            print(f"\n处理日期: {date_key}")
            
            # 按时间正序排序（最早的先处理）
            file_list.sort(key=lambda x: self.extract_time_from_file(x[0]))
            
            for audio_file, date in file_list:
                result = self.process_single_file(audio_file, date)
                if result:
                    all_results.append(result)
        
        # 4. 确保达到最小同步时间
        elapsed_time = time.time() - self.start_time
        remaining_wait = max(0, MIN_SYNC_TIME - elapsed_time)
        
        if remaining_wait > 0:
            print(f"\n等待 {remaining_wait:.1f} 秒以确保同步完成...")
            time.sleep(remaining_wait)
        
        # 5. 更新Apple Notes
        print("\n开始更新Apple Notes...")
        for result in all_results:
            self.append_to_apple_notes(
                result['note_title'],
                result['compressed_audio'],
                result['transcript'],
                result.get('backup_filename')  # 传递备份文件名
            )
        
        print("\n✓ 所有处理完成！")
    
    def extract_time_from_file(self, file_path: str) -> float:
        """
        从文件提取时间用于排序
        """
        # 可以从文件名或创建时间提取
        stat = os.stat(file_path)
        return stat.st_birthtime if hasattr(stat, 'st_birthtime') else stat.st_mtime
    
    def process_single_file(self, audio_file: str, date: datetime) -> Optional[Dict]:
        """
        处理单个音频文件
        """
        print(f"\n--- 处理文件: {Path(audio_file).name} ---")
        
        try:
            # 1. 创建备份目录
            backup_dir = self.create_backup_structure(date)
            
            # 2. 压缩音频到临时目录
            temp_dir = PROJECT_ROOT / "temp"
            temp_dir.mkdir(exist_ok=True)
            compressed_name = Path(audio_file).stem + COMPRESSED_SUFFIX + '.mp3'
            compressed_path = temp_dir / compressed_name
            
            if not self.compress_audio(audio_file, str(compressed_path)):
                print(f"跳过文件: {audio_file} (压缩失败)")
                return None
            
            # 3. 转录音频
            transcript = self.transcribe_audio_simple(str(compressed_path))
            if not transcript:
                print(f"跳过文件: {audio_file} (转录失败)")
                return None
            
            # 4. 保存原始音频到备份目录
            # 获取原始文件名（移除可能的时间戳前缀）
            original_filename = Path(audio_file).name
            # 如果文件名包含时间戳前缀（格式：timestamp_filename），移除它
            if '_' in original_filename and original_filename.split('_')[0].isdigit():
                parts = original_filename.split('_', 1)
                if len(parts) > 1:
                    original_filename = parts[1]
            
            # 检查文件是否已存在，如果存在则添加计数器
            backup_audio_path = Path(backup_dir) / original_filename
            counter = 1
            while backup_audio_path.exists():
                stem = Path(original_filename).stem
                suffix = Path(original_filename).suffix
                backup_audio_path = Path(backup_dir) / f"{stem}_({counter}){suffix}"
                counter += 1
            
            shutil.copy2(audio_file, backup_audio_path)
            print(f"✓ 原始音频已备份: {backup_audio_path.name}")
            
            # 5. 保存转录文本备份（使用相同的原始文件名）
            self.save_transcript_backup(backup_dir, backup_audio_path.name, transcript)
            
            # 6. 准备Apple Notes数据
            note_title = self.format_date_for_notes(date)
            
            # 7. 清理压缩文件（转录完成后不再需要）
            try:
                os.remove(compressed_path)
                print(f"✓ 已清理临时压缩文件")
            except:
                pass
            
            return {
                'note_title': note_title,
                'compressed_audio': '',  # 不再需要，因为已删除
                'transcript': transcript,
                'date': date,
                'backup_filename': backup_audio_path.name  # 添加备份后的文件名
            }
            
        except Exception as e:
            print(f"✗ 处理失败: {str(e)}")
            return None

def main():
    parser = argparse.ArgumentParser(
        description='将语音录音自动转录并同步到Apple Notes'
    )
    parser.add_argument(
        'audio_files',
        nargs='+',
        help='要处理的音频文件路径'
    )
    
    args = parser.parse_args()
    
    # 验证文件存在
    for audio_file in args.audio_files:
        if not os.path.exists(audio_file):
            print(f"错误: 文件不存在 - {audio_file}")
            return 1
    
    try:
        # 加载API密钥
        api_key = load_api_key()
        
        # 创建工作流实例并处理文件
        workflow = VoiceToNotesWorkflow(api_key)
        workflow.process_audio_files(args.audio_files)
        
        return 0
        
    except Exception as e:
        print(f"错误: {str(e)}")
        return 1

if __name__ == "__main__":
    exit(main())