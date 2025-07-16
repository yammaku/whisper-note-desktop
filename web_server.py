#!/usr/bin/env python3
"""
Flask Web Server for Voice to Notes Workflow
提供拖拽上传音频文件的Web接口
"""

import os
import sys
import json
import tempfile
import shutil
from pathlib import Path
from flask import Flask, request, jsonify, send_from_directory, render_template_string
from flask_cors import CORS
from werkzeug.utils import secure_filename
import subprocess
import threading
import queue
import time

# 添加项目根目录到Python路径
PROJECT_ROOT = Path(__file__).parent
sys.path.append(str(PROJECT_ROOT / 'scripts' / 'python'))

# 导入工作流模块
from voice_to_notes_workflow import VoiceToNotesWorkflow
from transcribe_audio import load_api_key

# Flask应用配置
app = Flask(__name__)
CORS(app)  # 允许跨域请求

# 配置
UPLOAD_FOLDER = PROJECT_ROOT / 'temp' / 'uploads'
UPLOAD_FOLDER.mkdir(parents=True, exist_ok=True)
ALLOWED_EXTENSIONS = {'wav', 'mp3', 'm4a', 'flac', 'aac', 'ogg'}

# 处理队列
processing_queue = queue.Queue()
results = {}

def allowed_file(filename):
    """检查文件扩展名是否允许"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def index():
    """返回主页面"""
    return send_from_directory(str(PROJECT_ROOT), 'web_interface.html')

@app.route('/process', methods=['POST'])
def process_audio():
    """处理上传的音频文件"""
    if 'audio' not in request.files:
        return jsonify({'error': '没有找到音频文件'}), 400
    
    file = request.files['audio']
    
    if file.filename == '':
        return jsonify({'error': '没有选择文件'}), 400
    
    if file and allowed_file(file.filename):
        # 保存上传的文件
        filename = secure_filename(file.filename)
        timestamp = int(time.time() * 1000)
        unique_filename = f"{timestamp}_{filename}"
        filepath = UPLOAD_FOLDER / unique_filename
        file.save(str(filepath))
        
        # 添加到处理队列
        task_id = f"task_{timestamp}"
        processing_queue.put((task_id, str(filepath), filename))
        results[task_id] = {'status': 'queued', 'filename': filename}
        
        return jsonify({
            'success': True,
            'task_id': task_id,
            'message': f'文件 {filename} 已加入处理队列'
        })
    
    return jsonify({'error': '不支持的文件类型'}), 400

@app.route('/status/<task_id>')
def get_status(task_id):
    """获取任务状态"""
    if task_id in results:
        return jsonify(results[task_id])
    return jsonify({'error': '任务不存在'}), 404

@app.route('/batch_process', methods=['POST'])
def batch_process():
    """批量处理音频文件"""
    files = request.files.getlist('files[]')
    
    if not files:
        return jsonify({'error': '没有找到文件'}), 400
    
    # 保存所有文件并准备处理
    file_paths = []
    for file in files:
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            timestamp = int(time.time() * 1000)
            unique_filename = f"{timestamp}_{filename}"
            filepath = UPLOAD_FOLDER / unique_filename
            file.save(str(filepath))
            file_paths.append(str(filepath))
    
    if not file_paths:
        return jsonify({'error': '没有有效的音频文件'}), 400
    
    # 在后台线程中处理
    def process_batch():
        try:
            print(f"📋 开始批量处理 {len(file_paths)} 个文件...")
            for fp in file_paths:
                print(f"  - {os.path.basename(fp)}")
            
            # 加载API密钥
            api_key = load_api_key()
            print(f"✅ API密钥已加载")
            
            # 创建工作流实例
            workflow = VoiceToNotesWorkflow(api_key)
            
            # 处理所有文件
            workflow.process_audio_files(file_paths)
            
            print(f"✅ 批量处理完成")
            
            # 清理临时文件
            for filepath in file_paths:
                try:
                    os.remove(filepath)
                except:
                    pass
                    
        except Exception as e:
            print(f"❌ 批量处理错误: {str(e)}")
            import traceback
            traceback.print_exc()
    
    # 启动处理线程
    thread = threading.Thread(target=process_batch)
    thread.daemon = True
    thread.start()
    
    return jsonify({
        'success': True,
        'message': f'已开始处理 {len(file_paths)} 个文件',
        'count': len(file_paths)
    })

def process_worker():
    """后台处理工作线程"""
    try:
        # 加载API密钥
        api_key = load_api_key()
        workflow = VoiceToNotesWorkflow(api_key)
    except Exception as e:
        print(f"❌ 初始化错误: {str(e)}")
        import traceback
        traceback.print_exc()
        return
    
    while True:
        try:
            # 从队列获取任务
            task_id, filepath, original_filename = processing_queue.get(timeout=1)
            
            # 更新状态
            results[task_id] = {
                'status': 'processing',
                'filename': original_filename,
                'message': '正在处理...'
            }
            
            try:
                # 处理单个文件
                workflow.process_audio_files([filepath])
                
                # 更新状态为成功
                results[task_id] = {
                    'status': 'success',
                    'filename': original_filename,
                    'message': '处理完成'
                }
                
                # 清理临时文件
                try:
                    os.remove(filepath)
                except:
                    pass
                    
            except Exception as e:
                # 更新状态为失败
                results[task_id] = {
                    'status': 'error',
                    'filename': original_filename,
                    'message': f'处理失败: {str(e)}'
                }
            
        except queue.Empty:
            continue
        except Exception as e:
            print(f"处理工作线程错误: {str(e)}")

@app.route('/health')
def health_check():
    """健康检查端点"""
    try:
        # 检查API密钥
        api_key = load_api_key()
        has_api_key = bool(api_key)
    except:
        has_api_key = False
    
    # 检查FFmpeg
    try:
        subprocess.run(['ffmpeg', '-version'], capture_output=True, check=True)
        has_ffmpeg = True
    except:
        has_ffmpeg = False
    
    return jsonify({
        'status': 'ok' if (has_api_key and has_ffmpeg) else 'error',
        'has_api_key': has_api_key,
        'has_ffmpeg': has_ffmpeg,
        'upload_folder': str(UPLOAD_FOLDER),
        'project_root': str(PROJECT_ROOT)
    })

# 启动处理工作线程
worker_thread = threading.Thread(target=process_worker)
worker_thread.daemon = True
worker_thread.start()

if __name__ == '__main__':
    print("🚀 启动闪念笔记Web服务器...")
    print(f"📁 项目目录: {PROJECT_ROOT}")
    print(f"📂 上传目录: {UPLOAD_FOLDER}")
    print("")
    print("🌐 访问地址: http://localhost:8181")
    print("   或打开浏览器访问上述地址")
    print("")
    print("按 Ctrl+C 停止服务器")
    
    # 启动服务器
    app.run(host='0.0.0.0', port=8181, debug=False)