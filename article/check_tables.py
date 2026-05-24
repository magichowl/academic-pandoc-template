#!/usr/bin/env python3
"""
检查 article_fixed.docx 中的表格结构
"""

import zipfile
import tempfile
import os
import shutil
import sys


def check_tables(input_path):
    """检查 DOCX 文件中的表格"""
    temp_dir = tempfile.mkdtemp()

    try:
        with zipfile.ZipFile(input_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)

        xml_path = os.path.join(temp_dir, 'word', 'document.xml')
        with open(xml_path, 'r', encoding='utf-8') as f:
            xml_content = f.read()

        print(f"=== 检查 {os.path.basename(input_path)} 中的表格 ===")
        
        # 查找所有表格
        import re
        tables = re.findall(r'<w:tbl>.*?</w:tbl>', xml_content, re.DOTALL)
        
        print(f"\n找到 {len(tables)} 个表格")
        
        for i, table in enumerate(tables):
            print(f"\n--- 表格 {i + 1} ---")
            # 检查是否有边框隐藏
            if '<w:tblBorders>' in table:
                if 'w:val=\"none\"' in table:
                    print("✅ 表格已隐藏边框")
            
            # 检查列数
            grid_cols = table.count('<w:gridCol')
            print(f"列数: {grid_cols}")
            
            # 检查是否有公式
            if '<m:oMathPara>' in table:
                print("✅ 表格包含公式")
            
            # 检查是否有编号
            if '(1)' in table or '(2)' in table or '(3)' in table or '(4)' in table:
                print("✅ 表格包含编号")
        
        return tables

    except Exception as e:
        print(f"❌ 检查失败: {e}")
        import traceback
        traceback.print_exc()
        return None
    finally:
        shutil.rmtree(temp_dir)


def main():
    if len(sys.argv) < 2:
        print("用法: python check_tables.py <docx文件>")
        sys.exit(1)
    
    check_tables(sys.argv[1])


if __name__ == "__main__":
    main()