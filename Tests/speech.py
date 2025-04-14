#!/usr/bin/env python3
"""
测试脚本：测试文本转语音API
用法：python speech_test.py text_file.txt [--url API_URL] [--output OUTPUT_FILE] [--voice VOICE] [--instructions INSTRUCTIONS]
"""

import requests
import argparse
import os
import sys
from pathlib import Path
import time
import json

def main():
    # 设置命令行参数解析
    parser = argparse.ArgumentParser(description='测试文本转语音API')
    parser.add_argument('file', help='要转换的文本文件路径')
    parser.add_argument('--url', default='http://localhost:8080/speech', 
                      help='API端点URL (默认: http://localhost:8080/speech)')
    parser.add_argument('--output', '-o', help='输出文件路径 (默认: 在输入文件名后添加_speech.mp3后缀)')
    parser.add_argument('--voice', default='nova', help='语音类型 (默认: nova)')
    parser.add_argument('--instructions', help='语音指示 (如"兴奋的"、"平静的")')
    parser.add_argument('--chunk-size', type=int, default=1000, help='每个音频片段的最大字符数 (默认: 1000)')
    
    args = parser.parse_args()
    
    # 检查输入文件是否存在
    input_path = Path(args.file)
    if not input_path.exists():
        print(f"错误: 文件 '{args.file}' 不存在。", file=sys.stderr)
        return 1
    
    # 确定输出文件路径
    if args.output:
        output_path = Path(args.output)
    else:
        # 基于输入文件名创建输出文件名
        stem = input_path.stem
        output_path = input_path.with_name(f"{stem}_speech.mp3")
    
    try:
        # 读取输入文件
        print(f"读取文件: {input_path}")
        with open(input_path, 'r', encoding='utf-8') as f:
            file_content = f.read()
        
        file_size = len(file_content)
        print(f"文件大小: {file_size} 字符")
        
        # 准备请求数据
        request_data = {
            "text": file_content,
            "config": {
                "voice": args.voice,
                "chunkSize": args.chunk_size
            }
        }
        
        if args.instructions:
            request_data["config"]["instructions"] = args.instructions
        
        # 发送请求到API
        print(f"发送请求到 {args.url}...")
        print(f"使用语音: {args.voice}")
        print(f"分块大小: {args.chunk_size} 字符")
        if args.instructions:
            print(f"语音指示: {args.instructions}")
            
        start_time = time.time()
        
        response = requests.post(
            args.url,
            json=request_data,
            headers={"Content-Type": "application/json"},
            timeout=300,  # 增加超时时间，适应大文件处理
            stream=True   # 使用流式响应处理大文件
        )
        
        elapsed_time = time.time() - start_time
        print(f"请求完成，耗时 {elapsed_time:.2f} 秒")
        
        # 检查请求是否成功
        if response.status_code != 200:
            print(f"错误: 请求失败，状态码: {response.status_code}", file=sys.stderr)
            try:
                error_data = response.json()
                print(f"错误详情: {json.dumps(error_data, indent=2, ensure_ascii=False)}", file=sys.stderr)
            except:
                print(f"响应文本: {response.text[:500]}...", file=sys.stderr)
            return 1
        
        # 检查响应类型
        content_type = response.headers.get('Content-Type', '')
        if 'audio/mpeg' not in content_type:
            print(f"警告: 响应不是MP3音频，内容类型: {content_type}", file=sys.stderr)
            
            if 'application/json' in content_type:
                try:
                    error_data = response.json()
                    print(f"错误详情: {json.dumps(error_data, indent=2, ensure_ascii=False)}", file=sys.stderr)
                except:
                    print(f"响应文本: {response.text[:500]}...", file=sys.stderr)
                return 1
        
        # 将音频数据保存到输出文件
        with open(output_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        print(f"音频已保存到: {output_path}")
        print(f"原文大小: {file_size} 字符")
        print(f"音频文件大小: {os.path.getsize(output_path)} 字节")
        
        print("测试成功!")
        return 0
        
    except requests.exceptions.RequestException as e:
        print(f"请求错误: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())