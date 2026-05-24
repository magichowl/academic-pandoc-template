#!/usr/bin/env python3
"""
将 DOCX 中带 \label 的公式替换成三列表格
三列表格结构：
- 左列：空
- 中列：公式（居中）
- 右列：编号（居右）
- 表格无边框
"""

import zipfile
import tempfile
import os
import shutil
import re
import sys


def process_document(input_path, output_path=None):
    """处理 DOCX 文件"""
    if output_path is None:
        output_path = input_path.replace('.docx', '_fixed.docx')

    temp_dir = tempfile.mkdtemp()

    try:
        print(f"🔧 正在处理 {os.path.basename(input_path)}...")

        # 1. 解压 DOCX
        with zipfile.ZipFile(input_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)

        # 2. 修改 document.xml
        xml_path = os.path.join(temp_dir, 'word', 'document.xml')
        with open(xml_path, 'r', encoding='utf-8') as f:
            xml_content = f.read()

        # 查找所有段落
        paragraphs = re.findall(r'<w:p>.*?</w:p>', xml_content, re.DOTALL)
        
        print(f"找到 {len(paragraphs)} 个段落")
        
        # 找出需要替换的公式段落对
        equation_counter = 1
        new_paragraphs = []
        i = 0
        
        while i < len(paragraphs):
            current_p = paragraphs[i]
            
            # 检查是否有公式（含 <m:oMathPara>）
            if '<m:oMathPara>' in current_p:
                # 检查下一段是否是 EQUATION_NUMBER 标记
                next_has_mark = False
                equation_mark_p = None
                
                if i + 1 < len(paragraphs):
                    next_p = paragraphs[i + 1]
                    if 'EQUATION_NUMBER' in next_p:
                        next_has_mark = True
                        equation_mark_p = next_p
                        i += 1  # 跳过下一段
                
                if next_has_mark:
                    # 创建三列表格
                    table = create_three_column_table(current_p, equation_counter)
                    new_paragraphs.append(table)
                    equation_counter += 1
                else:
                    new_paragraphs.append(current_p)
            else:
                new_paragraphs.append(current_p)
            
            i += 1

        # 重新构建 XML
        xml_content = re.sub(r'<w:p>.*?</w:p>', lambda m: new_paragraphs.pop(0), xml_content)

        # 3. 保存修改后的 XML
        with open(xml_path, 'w', encoding='utf-8') as f:
            f.write(xml_content)

        # 4. 重新打包
        with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(temp_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, temp_dir)
                    arcname = arcname.replace('\\', '/')
                    zipf.write(file_path, arcname)

        print(f"✅ 处理完成: {output_path}")
        print(f"替换了 {equation_counter - 1} 个公式")
        return output_path

    except Exception as e:
        print(f"❌ 处理失败: {e}")
        import traceback
        traceback.print_exc()
        return None
    finally:
        shutil.rmtree(temp_dir)


def create_three_column_table(equation_p, number):
    """创建三列表格"""
    # 确保公式段落居中
    if '<w:pPr>' not in equation_p:
        equation_p = equation_p.replace('<w:p>', '<w:p><w:pPr></w:pPr>')
    
    # 添加强制居中
    if '<w:jc w:val="center"/>' not in equation_p:
        equation_p = equation_p.replace('<w:pPr>', '<w:pPr><w:jc w:val="center"/>')
    
    table_xml = f'''
<w:tbl>
  <w:tblPr>
    <w:tblStyle w:val="TableGrid"/>
    <w:tblW w:w="0" w:type="auto"/>
    <w:tblLook w:val="04A0" w:firstRow="1" w:lastRow="0" w:firstColumn="1" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/>
    <!-- 隐藏表格边框 -->
    <w:tblBorders>
      <w:top w:val="none"/>
      <w:left w:val="none"/>
      <w:bottom w:val="none"/>
      <w:right w:val="none"/>
      <w:insideH w:val="none"/>
      <w:insideV w:val="none"/>
    </w:tblBorders>
    <!-- 表格列宽设置 -->
    <w:tblGrid>
      <w:gridCol w:w="500"/>
      <w:gridCol w:w="8500"/>
      <w:gridCol w:w="1000"/>
    </w:tblGrid>
  </w:tblPr>
  <w:tr>
    <!-- 左列：空 -->
    <w:tc>
      <w:tcPr>
        <w:tcW w:w="500" w:type="dxa"/>
      </w:tcPr>
      <w:p><w:pPr><w:jc w:val="left"/></w:pPr></w:p>
    </w:tc>
    <!-- 中列：公式 -->
    <w:tc>
      <w:tcPr>
        <w:tcW w:w="8500" w:type="dxa"/>
      </w:tcPr>
      {equation_p}
    </w:tc>
    <!-- 右列：编号 -->
    <w:tc>
      <w:tcPr>
        <w:tcW w:w="1000" w:type="dxa"/>
      </w:tcPr>
      <w:p>
        <w:pPr>
          <w:jc w:val="right"/>
        </w:pPr>
        <w:r>
          <w:t>({number})</w:t>
        </w:r>
      </w:p>
    </w:tc>
  </w:tr>
</w:tbl>
'''
    return table_xml


def main():
    if len(sys.argv) < 2:
        print("用法: python equation_to_table.py <docx文件>")
        sys.exit(1)
    
    input_path = sys.argv[1]
    
    if not os.path.exists(input_path):
        print(f"❌ 文件不存在: {input_path}")
        sys.exit(1)
    
    process_document(input_path)


if __name__ == "__main__":
    main()