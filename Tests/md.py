#!/usr/bin/env python3
"""
测试脚本：测试文本处理API，将Markdown或HTML文件转换为ADHD友好格式。
用法：python test_text_processor.py input_file.md [--url API_URL] [--output OUTPUT_FILE]
"""

import requests
import argparse
import os
import sys
from pathlib import Path
import time

def main():
    # 设置命令行参数解析
    parser = argparse.ArgumentParser(description='测试文本处理API')
    parser.add_argument('file', help='要处理的文件路径(markdown或html)')
    parser.add_argument('--url', default='http://localhost:8080/process-text', 
                      help='API端点URL (默认: http://localhost:8080/process-text)')
    parser.add_argument('--output', '-o', help='输出文件路径 (默认: 在输入文件名后添加_processed后缀)')
    parser.add_argument('--api-key', help='OpenAI API密钥 (如果服务器没有配置环境变量)')
    
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
        output_path = input_path.with_name(f"{stem}_processed{input_path.suffix}")
    
    try:
        # 读取输入文件
        print(f"读取文件: {input_path}")
        with open(input_path, 'r', encoding='utf-8') as f:
            file_content = f.read()
        
        file_size = len(file_content)
        print(f"文件大小: {file_size} 字符")
        
        # 检测文件类型
        file_ext = input_path.suffix.lower()
        if file_ext in ['.md', '.markdown']:
            file_type = "Markdown"
        elif file_ext in ['.html', '.htm']:
            file_type = "HTML"
        else:
            file_type = "未知"
        print(f"检测到的文件类型: {file_type}")
        
        # 发送请求到API
        print(f"发送请求到 {args.url}...")
        start_time = time.time()
        
        headers = {"Content-Type": "application/json"}
        if args.api_key:
            headers["Authorization"] = f"Bearer {args.api_key}"
        
        response = requests.post(
            args.url,
            json={"text": file_content},
            headers=headers,
            timeout=120  # 增加超时时间，适应大文件处理
        )
        
        elapsed_time = time.time() - start_time
        print(f"请求完成，耗时 {elapsed_time:.2f} 秒")
        
        # 检查请求是否成功
        response.raise_for_status()
        
        # 解析响应
        result = response.json()
        processed_text = result.get("processedText")
        
        if not processed_text:
            print("错误: 响应中不包含processedText字段。", file=sys.stderr)
            return 1
        
        # 将处理后的文本保存到输出文件
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(processed_text)
        
        print(f"处理后的文本已保存到: {output_path}")
        print(f"原始大小: {file_size} 字符")
        print(f"处理后大小: {len(processed_text)} 字符")
        
        # 显示样本
        sample_length = min(200, len(processed_text))
        print("\n处理后的文本样本:")
        print("-" * 50)
        print(processed_text[:sample_length] + ("..." if len(processed_text) > sample_length else ""))
        print("-" * 50)
        
        print("测试成功!")
        
        return 0
        
    except requests.exceptions.RequestException as e:
        print(f"请求错误: {e}", file=sys.stderr)
        if hasattr(e, 'response') and e.response is not None:
            print(f"响应状态码: {e.response.status_code}", file=sys.stderr)
            try:
                error_data = e.response.json()
                print(f"错误详情: {error_data}", file=sys.stderr)
            except:
                print(f"响应文本: {e.response.text[:500]}...", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())