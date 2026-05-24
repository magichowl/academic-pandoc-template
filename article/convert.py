#!/usr/bin/env python3
"""
一键转换：article.md -> article_fixed.docx
包含以下步骤：
1. Pandoc 转换 Markdown 到 DOCX
2. 应用 Lua 过滤器添加公式标记
3. 将带标记的公式替换为三列表格
"""

import os
import sys
import subprocess


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    print("=== 开始转换 ===")
    
    # Step 1: 使用 Pandoc 转换
    print("\n步骤 1: Pandoc 转换...")
    cmd = [
        'pandoc',
        '--defaults=../defaults.yaml',
        '--defaults=docx.yaml',
        '--lua-filter=expand-macros.lua',
        'article.md'
    ]
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print("✅ Pandoc 转换成功")
    except subprocess.CalledProcessError as e:
        print(f"❌ Pandoc 转换失败: {e.stderr}")
        return
    
    # Step 2: 替换公式为表格
    print("\n步骤 2: 替换公式为三列表格...")
    import equation_to_table
    output = equation_to_table.process_document('article.docx', 'article_fixed.docx')
    
    if output:
        print("\n=== 转换完成 ===")
        print(f"输出文件: {os.path.abspath(output)}")
        print("\n生成的文档特点：")
        print("- 所有带 \\label 的公式被替换为三列表格")
        print("- 中列：公式居中对齐")
        print("- 右列：编号右对齐")
        print("- 表格无边框")
    else:
        print("\n❌ 转换失败")


if __name__ == "__main__":
    main()