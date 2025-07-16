#!/usr/bin/env python3
"""
11Labs Audio Transcription Script
Processes audio files through 11Labs API and generates multiple transcript formats
"""

import os
import json
import shutil
import requests
from pathlib import Path
from typing import Dict, List, Optional
import argparse
from datetime import datetime

def load_api_key():
    """Load API key from api_key.txt file"""
    # API密钥文件在config目录中
    project_root = Path(__file__).parent.parent.parent
    api_key_file = project_root / 'config' / 'api_key.txt'
    
    if not api_key_file.exists():
        raise FileNotFoundError(
            "api_key.txt not found. Please create this file and add your 11Labs API key."
        )
    
    with open(api_key_file, 'r') as f:
        api_key = f.read().strip()
    
    if not api_key:
        raise ValueError(
            "api_key.txt is empty. Please add your 11Labs API key to this file."
        )
    
    if not api_key.startswith('sk_'):
        raise ValueError(
            "Invalid API key format. 11Labs API keys should start with 'sk_'"
        )
    
    return api_key

class ElevenLabsTranscriber:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.api_url = "https://api.elevenlabs.io/v1/speech-to-text"
        self.headers = {
            "xi-api-key": api_key
        }
    
    def transcribe_audio(self, audio_path: str) -> Dict:
        """
        Transcribe audio file using 11Labs API with exact settings from N8N workflow
        """
        print(f"Transcribing {audio_path}...")
        
        with open(audio_path, 'rb') as audio_file:
            files = {
                'file': (os.path.basename(audio_path), audio_file, 'audio/mpeg')
            }
            
            data = {
                'model_id': 'scribe_v1',
                'additional_formats': '[{"format":"srt","include_speakers":true}]',
                'diarize': 'true'
            }
            
            response = requests.post(
                self.api_url,
                headers=self.headers,
                data=data,
                files=files
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"Transcription completed successfully")
                return result
            else:
                raise Exception(f"API Error: {response.status_code} - {response.text}")
    
    def generate_output_files(self, transcription_result: Dict, base_filename: str, output_dir: str) -> List[str]:
        """
        Generate the 4 output files from transcription result
        """
        output_files = []
        
        # Ensure output directory exists
        Path(output_dir).mkdir(parents=True, exist_ok=True)
        
        # 1. Pure text transcription
        text_file = os.path.join(output_dir, f"{base_filename}_TEXT.txt")
        with open(text_file, 'w', encoding='utf-8') as f:
            f.write(transcription_result.get('text', ''))
        output_files.append(text_file)
        print(f"Created: {text_file}")
        
        # 2. Words with timestamps (JSON format)
        words_file = os.path.join(output_dir, f"{base_filename}_WORDS.txt")
        with open(words_file, 'w', encoding='utf-8') as f:
            words_data = transcription_result.get('words', [])
            f.write(json.dumps(words_data, indent=2, ensure_ascii=False))
        output_files.append(words_file)
        print(f"Created: {words_file}")
        
        # 3. SRT format text file
        srt_content = ''
        if 'additional_formats' in transcription_result and len(transcription_result['additional_formats']) > 0:
            srt_content = transcription_result['additional_formats'][0].get('content', '')
        
        srt_text_file = os.path.join(output_dir, f"{base_filename}_SRT.txt")
        with open(srt_text_file, 'w', encoding='utf-8') as f:
            f.write(srt_content)
        output_files.append(srt_text_file)
        print(f"Created: {srt_text_file}")
        
        # 4. Standard SRT subtitle file
        srt_file = os.path.join(output_dir, f"{base_filename}.srt")
        with open(srt_file, 'w', encoding='utf-8') as f:
            f.write(srt_content)
        output_files.append(srt_file)
        print(f"Created: {srt_file}")
        
        return output_files
    
    def process_audio_file(self, audio_path: str, output_base_dir: str = None) -> str:
        """
        Process a single audio file: transcribe and organize outputs
        """
        # If no output dir specified, use default relative to project root
        if output_base_dir is None:
            # Assuming the script is run from the project root,
            # and 'Processed Files' is directly under the project root.
            output_base_dir = os.path.join(os.getcwd(), "Processed Files")
        
        # Get base filename without extension
        base_filename = Path(audio_path).stem
        
        # Create output folder named after the audio file
        output_dir = os.path.join(output_base_dir, base_filename)
        
        # Transcribe audio
        transcription_result = self.transcribe_audio(audio_path)
        
        # Generate output files
        self.generate_output_files(transcription_result, base_filename, output_dir)
        
        # Move original audio file to output folder
        destination_path = os.path.join(output_dir, os.path.basename(audio_path))
        shutil.move(audio_path, destination_path)
        print(f"Moved original audio to: {destination_path}")
        
        return output_dir

def main():
    parser = argparse.ArgumentParser(description='Transcribe audio files using 11Labs API')
    parser.add_argument('audio_file', help='Path to the audio file to transcribe')
    parser.add_argument('--output-dir', help='Base output directory', default=None)
    
    args = parser.parse_args()
    
    if not os.path.exists(args.audio_file):
        print(f"Error: Audio file not found: {args.audio_file}")
        return 1
    
    try:
        # Load API key from api_key.txt
        api_key = load_api_key()
        
        transcriber = ElevenLabsTranscriber(api_key)
        # Pass None if no output dir specified, so it uses the default
        output_dir = args.output_dir if args.output_dir else None
        output_folder = transcriber.process_audio_file(args.audio_file, output_dir)
        print(f"\nProcessing complete! All files saved to: {output_folder}")
        return 0
    except FileNotFoundError as e:
        print(f"Configuration Error: {str(e)}")
        return 1
    except ValueError as e:
        print(f"API Key Error: {str(e)}")
        return 1
    except Exception as e:
        print(f"Error during processing: {str(e)}")
        return 1

if __name__ == "__main__":
    exit(main())