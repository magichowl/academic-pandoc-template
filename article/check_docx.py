#!/usr/bin/env python3
"""
检查 DOCX 文件结构，查看带标签的公式
"""

import zipfile
import tempfile
import os
import shutil
import sys


def check_document(input_path):
    """检查 DOCX 文件"""
    temp_dir = tempfile.mkdtemp()

    try:
        with zipfile.ZipFile(input_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)

        xml_path = os.path.join(temp_dir, 'word', 'document.xml')
        with open(xml_path, 'r', encoding='utf-8') as f:
            xml_content = f.read()

        print(f"=== 检查 {os.path.basename(input_path)} ===")
        print(f"内容长度: {len(xml_content)}")
        
        # 检查是否有 EQUATION_NUMBER 标记
        eq_count = xml_content.count('EQUATION_NUMBER')
        print(f"\n找到 'EQUATION_NUMBER' 标记: {eq_count} 次")
        
        # 查找所有公式段落
        print(f"\n=== 包含公式的段落 ===")
        
        import re
        paragraphs = re.findall(r'<w:p>.*?</w:p>', xml_content, re.DOTALL)
        
        eq_paragraphs = []
        for i, p in enumerate(paragraphs):
            if '<m:oMath' in p or 'EQUATION_NUMBER' in p:
                eq_paragraphs.append((i, p))
                if len(eq_paragraphs) <= 5:  # 只显示前5个
                    print(f"\n段落 {i}:")
                    print(p[:300] + ('...' if len(p) > 300 else ''))
        
        print(f"\n找到包含公式的段落总数: {len(eq_paragraphs)}")
        
        return xml_content, paragraphs, eq_paragraphs

    except Exception as e:
        print(f"❌ 检查失败: {e}")
        import traceback
        traceback.print_exc()
        return None, None, None
    finally:
        shutil.rmtree(temp_dir)


def main():
    if len(sys.argv) < 2:
        print("用法: python check_docx.py <docx文件>")
        sys.exit(1)
    
    check_document(sys.argv[1])


if __name__ == "__main__":
    main()