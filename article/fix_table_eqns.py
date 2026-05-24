"""
修复 pandoc-crossref tableEqns 生成的表格布局
- 移除表格缩进 (tblInd)，防止编号超出正文右边缘
- 保持公式居中、编号右对齐
"""
import zipfile, os, re, shutil, tempfile


def fix_equation_tables(input_path, output_path=None):
    if output_path is None:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_fixed{ext}"

    tmp = tempfile.mkdtemp()
    try:
        # 1. 解压 DOCX
        with zipfile.ZipFile(input_path, 'r') as z:
            z.extractall(tmp)

        xml_path = os.path.join(tmp, 'word', 'document.xml')
        with open(xml_path, 'r', encoding='utf-8') as f:
            xml = f.read()

        # 2. 读取正文区域宽度
        text_width = get_text_width(xml)
        right_tab_pos = str(text_width)
        print(f"正文区域宽度: {text_width} twips ({text_width/1440:.2f} inches)")

        # 3. 查找所有公式表格并修复
        fixed_count = 0
        tables = re.findall(r'<w:tbl>.*?</w:tbl>', xml, re.DOTALL)
        for tbl in tables:
            if '<m:oMath' not in tbl:
                continue
            new_tbl = fix_single_table(tbl, text_width)
            xml = xml.replace(tbl, new_tbl)
            fixed_count += 1

        print(f"修复了 {fixed_count} 个公式表格")

        # 4. 禁止 Word 弹出"是否更新域"提示
        settings_path = os.path.join(tmp, 'word', 'settings.xml')
        if os.path.exists(settings_path):
            with open(settings_path, 'r', encoding='utf-8') as f:
                settings_xml = f.read()
            # 添加 updateFields，让 Word 自动更新域而不弹窗
            if '<w:updateFields' not in settings_xml:
                settings_xml = re.sub(
                    r'(<w:settings[^>]*>)',
                    r'\1<w:updateFields w:val="true"/>',
                    settings_xml)
                with open(settings_path, 'w', encoding='utf-8') as f:
                    f.write(settings_xml)
                print("已禁用域更新提示")
        else:
            print("settings.xml 不存在，跳过域更新设置")

        # 5. 写回
        with open(xml_path, 'w', encoding='utf-8') as f:
            f.write(xml)

        # 6. 重新打包
        with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zout:
            for root, dirs, files in os.walk(tmp):
                for fname in files:
                    fpath = os.path.join(root, fname)
                    arcname = os.path.relpath(fpath, tmp).replace('\\', '/')
                    zout.write(fpath, arcname)

        print(f"输出: {output_path}")
        return output_path
    finally:
        shutil.rmtree(tmp)


def get_text_width(xml):
    """从 sectPr 读取正文区域宽度"""
    sect = re.search(r'<w:sectPr>.*?</w:sectPr>', xml, re.DOTALL)
    if sect:
        s = sect.group(0)
        # 页面宽度
        pg = re.search(r'<w:pgSz[^>]*w:w="(\d+)"', s)
        pg_w = int(pg.group(1)) if pg else 12240  # 默认 Letter
        
        # 页边距
        mar = re.search(
            r'<w:pgMar[^>]*w:left="(\d+)"[^>]*w:right="(\d+)"', s)
        if mar:
            left = int(mar.group(1))
            right = int(mar.group(2))
        else:
            left = right = 1440  # 默认 1 inch
        
        return pg_w - left - right
    return 9072  # 默认 A4 文本宽度


def fix_single_table(tbl, text_width):
    """修复单个公式表格"""
    # 1. 移除 tblInd (缩进是编号超出边缘的元凶)
    tbl = re.sub(r'<w:tblInd[^/>]+/>', '', tbl)

    # 2. 确保 tblW 为 100% (5000 = 100%)
    tbl = re.sub(
        r'<w:tblW[^/>]+/>',
        f'<w:tblW w:w="5000" w:type="pct"/>', tbl, count=1)

    # 3. 添加无边框
    if '<w:tblBorders>' not in tbl:
        tbl = tbl.replace(
            '<w:tblPr>',
            '<w:tblPr><w:tblBorders>'
            '<w:top w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
            '<w:left w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
            '<w:bottom w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
            '<w:right w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
            '<w:insideH w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
            '<w:insideV w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
            '</w:tblBorders>',
            count=1)

    # 4. 修复列宽：公式列占正文区域主要部分，编号列靠右
    eqn_width = int(text_width * 0.88)
    num_width = text_width - eqn_width
    # 用字符串精确替换避免正则重复匹配
    grids = re.findall(r'<w:gridCol[^/>]*/>', tbl)
    if len(grids) >= 2:
        tbl = tbl.replace(grids[0], f'<w:gridCol w:w="{eqn_width}"/>')
        tbl = tbl.replace(grids[1], f'<w:gridCol w:w="{num_width}"/>')

    # 5. 确保公式单元格居中、编号单元格右对齐+垂直居中
    cells = re.findall(r'<w:tc>.*?</w:tc>', tbl, re.DOTALL)
    new_cells = []
    for i, cell in enumerate(cells):
        if i == 0:  # 公式单元格
            if '<w:jc w:val="center"/>' not in cell:
                if '<w:tcPr>' in cell:
                    cell = cell.replace(
                        '<w:tcPr>',
                        '<w:tcPr><w:jc w:val="center"/>')
                else:
                    cell = cell.replace(
                        '<w:tc>',
                        '<w:tc><w:tcPr><w:jc w:val="center"/></w:tcPr>')
        else:  # 编号单元格
            # 修改对齐为 right
            cell = re.sub(
                r'<w:jc w:val="\w+"/>',
                '<w:jc w:val="right"/>', cell)
            if '<w:jc' not in cell:
                if '<w:tcPr>' in cell:
                    cell = cell.replace(
                        '<w:tcPr>',
                        '<w:tcPr><w:jc w:val="right"/>')
        new_cells.append(cell)
    
    # 重建表格
    for old, new in zip(cells, new_cells):
        tbl = tbl.replace(old, new, 1)

    return tbl


if __name__ == '__main__':
    import sys
    inp = sys.argv[1] if len(sys.argv) > 1 else 'article.docx'
    out = sys.argv[2] if len(sys.argv) > 2 else None
    fix_equation_tables(inp, out)