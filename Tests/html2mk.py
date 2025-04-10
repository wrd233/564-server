#!/usr/bin/env python3

import sys
import json
import requests
import argparse

def main():
    # 解析命令行参数
    parser = argparse.ArgumentParser(description='将HTML文件转换为Markdown')
    parser.add_argument('html_file', help='输入的HTML文件路径')
    parser.add_argument('output_file', help='输出的Markdown文件路径')
    parser.add_argument('--server', default='http://localhost:8080/convert/html-to-markdown',
                        help='转换服务器URL (默认: http://localhost:8080/convert/html-to-markdown)')
    parser.add_argument('--github', action='store_true', help='使用GitHub风格的Markdown')
    
    args = parser.parse_args()
    
    # 读取HTML文件
    try:
        with open(args.html_file, 'r', encoding='utf-8') as f:
            html_content = f.read()
    except Exception as e:
        print(f"错误: 无法读取HTML文件: {e}")
        return 1
    
    # 准备请求数据
    request_data = {
        'html': html_content,
        'options': {
            'githubFlavored': args.github
        }
    }
    
    # 调用API
    print(f"正在转换HTML文件 '{args.html_file}'...")
    try:
        response = requests.post(
            args.server,
            headers={'Content-Type': 'application/json'},
            json=request_data
        )
        response.raise_for_status()  # 检查HTTP错误
        
        result = response.json()
        markdown = result['markdown']
        success = result['success']
        
        # 保存结果
        with open(args.output_file, 'w', encoding='utf-8') as f:
            f.write(markdown)
        
        if success:
            print(f"转换成功! Markdown已保存到 '{args.output_file}'")
        else:
            message = result.get('message', '未知错误')
            print(f"警告: 转换可能不完整: {message}")
            print(f"已将内容保存到 '{args.output_file}'")
            
    except requests.exceptions.RequestException as e:
        print(f"错误: 调用API失败: {e}")
        return 1
    except Exception as e:
        print(f"错误: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    sys.exit(main())