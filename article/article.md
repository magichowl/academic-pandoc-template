---
abstract: 'All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.'
author:
  - '[Eleanor Roosevelt](eleanor.eoosevelt@domain.com)'
  - '[John Peters Humphrey](jph@domain.com)'
bibliography: references.bib # bibliography to use for resolving references
csl: ../assets/csl/ieee.csl
date: 1 January 2023
keywords: # list of keywords to be included in HTML, PDF, ODT, pptx, docx and AsciiDoc metadata; repeat as for author, above
lang: zh-CN
# 适用于 DOCX 的选项（生成超链接）
linkReferences: true
nameInLink: true # 非必需，但强烈推荐以获得最佳体验
# 适用于 PDF (LaTeX) 的选项（生成超链接）
hyperref: true
# 为引用文本添加括号
eqnPrefixTemplate: ($$i$$)
# 自定义标题语言 (Title)
figureTitle: "图"
tableTitle: "表"
listingTitle: "代码清单"
# 自定义引用前缀 (Prefix)
figPrefix:
  - "图"
  - "图集"
tblPrefix:
  - "Table"
eqnPrefix:
  - "公式"
nocite: |
  @brown2016
references:
  - id: unitednations1948
    author:
      - literal: United Nations
    citation-key: unitednations1948
    issued:
      - year: 1948
        month: 12
    title: Universal Declaration of Human Rights
    type: book
subtitle: 'Subtitle'
title: 'Title'
toc: true

# LaTeX
abstract-title: 'Abstract'
beamerarticle: # produce an article from Beamer slides
classoption: # option for document class, e.g. oneside (a list).
documentclass: scrartcl # document class: usually one of the standard classes, article, book, and report; the KOMA-Script equivalents, scrartcl, scrbook, and scrreprt, which default to smaller margins; or memoir
geometry: # option for geometry package, e.g. margin=1in; repeat for multiple options:
header-includes: # contents specified by -H/--include-in-header (may have multiple values)
  - |
    ```{=latex}
    \raggedbottom % or \flushbottom
    ```
  - |
    ```{=latex}
    % keep figures where there are in the text
    \usepackage{float} 
    \floatplacement{figure}{H}
    ```
  - |
    ```{=latex}
    % add custom hyphentation rules
    \hyphenation
    {%
      Hyphenate-me-like-this
      Dontyoueverhyphenateme
    }%
    ```
  - |
    ```{=latex}
    % 引入外部宏定义文件
    \input{macros.tex}
    ```
hyperrefoptions: # option for hyperref package, e.g. linktoc=all; repeat for multiple options:
include-before: # contents specified by -B/--include-before-body (may have multiple values)
include-after: # contents specified by -A/--include-after-body (may have multiple values)
indent: # if true, pandoc will use document class settings for indentation (the default LaTeX template otherwise removes indentation and adds space between paragraphs)
linestretch: # adjusts line spacing using the setspace package, e.g. 1.25, 1.5
lof: true
lot: true
pagestyle: # control \pagestyle{}: the default article class supports plain (default), empty (no running heads or page numbers), and headings (section titles in running heads)
papersize: # paper size, e.g. letter, a4
secnumdepth: # numbering depth for sections (with --number-sections option or numbersections variable)
thanks: 'Many thanks for the valuable comments.'
toc-depth: 2
toc-title: 'Contents'

# Fonts
fontenc: # allows font encoding to be specified through fontenc package (with pdflatex); default is T1 (see LaTeX font encodings guide)
fontfamily: # font package for use with pdflatex: TeX Live includes many options, documented in the LaTeX Font Catalogue. The default is Latin Modern.
fontfamilyoptions: # options for package used as fontfamily; repeat for multiple options.
fontsize: # font size for body text. The standard classes allow 10pt, 11pt, and 12pt. To use another size, set documentclass to one of the KOMA-Script classes, such as scrartcl or scrbook.
mainfont:
sansfont:
monofont:
mathfont:
mainfontoptions:
sansfontoptions:
monofontoptions:
mathfontoptions:

# Word
category: # document category, included in docx and pptx metadata
description: # document description, included in ODT, docx and pptx metadata. Some applications show this as Comments metadata.
subject: # document subject, included in ODT, PDF, docx, EPUB, and pptx metadata
---

# Heading 1

1. 多行公式示例（LaTeX 语法）
$$
\begin{align}
E &= mc^2 \\
F &= ma \\
\int_{-\infty}^{\infty} e^{-x^2} dx &= \sqrt{\pi} 
\end{align}
$${#eq:gauss}
引用公式[@eq:gauss]. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

2. 测试向量和矩阵符号（使用自定义宏）
$$
\x \quad \X \quad \loss
$$

3. 测试函数定义
$$
\func{x}{y}{z}
$$

4. 组合测试
$$
\loss = \sum_{i=1}^{n} \func{\x_i}{\X_i}{\theta}
$$

5. 测试单参数宏
$$
\vec{v} \quad \mat{A}
$$

6. 测试双参数宏
$$
\add{a}{b} \quad \mult{x}{y}
$${#eq:add_mult}

## Heading 2

参考文献引用示例[@brown2016].
All human beings are born free and equal in dignity and rights, crossref [@eq:add_mult]. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

### Heading 3

All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

测试带编号的多行公式

$$ \begin{equation} \begin{aligned} \sin^2 x + \cos^2 x &= 1 \\ \tan x &= \frac{\sin x}{\cos x} \end{aligned}\end{equation} $${#eq:tri}	

#### Heading 4

Test equation reference [@eq:tri].  All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

## Bold

**All human beings are born free and equal in dignity and rights.** All human beings are born free and equal in dignity and rights.All human beings are born free and equal in dignity and rights.All human beings are born free and equal in dignity and rights.

## Italic

_All human beings are born free and equal in dignity and rights._ All human beings are born free and equal in dignity and rights.All human beings are born free and equal in dignity and rights.All human beings are born free and equal in dignity and rights.

## Bold and italic

**_All human beings are born free and equal in dignity and rights._** All human beings are born free and equal in dignity and rights.All human beings are born free and equal in dignity and rights.All human beings are born free and equal in dignity and rights.

## Struck through

~~All human beings are born free and equal in dignity and rights.~~ All human beings are born free and equal in dignity and rights.All human beings are born free and equal in dignity and rights.All human beings are born free and equal in dignity and rights.

## Numbered lists

1. All human beings are born free and equal in dignity and rights.
1. All human beings are born free and equal in dignity and rights.
1. All human beings are born free and equal in dignity and rights.
1. All human beings are born free and equal in dignity and rights.

All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

## Unnumbered lists

- All human beings are born free and equal in dignity and rights.
  - All human beings are born free and equal in dignity and rights.
- All human beings are born free and equal in dignity and rights.

All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

## Mixed lists

- All human beings are born free and equal in dignity and rights.
  1. All human beings are born free and equal in dignity and rights.
  2. All human beings are born free and equal in dignity and rights.
- All human beings are born free and equal in dignity and rights.

All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

## Figures and captions

![Eleanor Roosevelt hält die englische Version der Allgemeinen Erklärung der Menschenrechte (FDR Presidential Library & Museum, CC BY 2.0 <https://creativecommons.org/licenses/by/2.0>, via Wikimedia Commons)](images/Eleanor_Roosevelt_and_Human_Rights_Declaration.jpeg){#fig:example_fig}

All human beings are born free and equal in dignity and rights, crossref [@fig:example_fig]. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

## Code

All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

```bash
ping wikipedia.org
```

All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

## URLs and email addresses

[wikipedia.org](https://www.wikipedia.org/), [info@wikipedia.org](mailto:info@wikipedia.org). All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

## Tables

| column 1                                                        | column 2                                                        |
| --------------------------------------------------------------- | --------------------------------------------------------------- |
| All human beings are born free and equal in dignity and rights. | All human beings are born free and equal in dignity and rights. |
| All human beings are born free and equal in dignity and rights. | All human beings are born free and equal in dignity and rights. |
| All human beings are born free and equal in dignity and rights. | All human beings are born free and equal in dignity and rights. |
| All human beings are born free and equal in dignity and rights. | All human beings are born free and equal in dignity and rights. |

: Table caption {#tbl:example_tbl}

All human beings are born free and equal in dignity and rights, crossref [@tbl:example_tbl]. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

## Footnotes

All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.^[All human beings are born free and equal in dignity and rights.]

## Quotes

::: {lang=de}

> Alle Menschen sind frei und gleich an Würde und Rechten geboren.

:::

All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.

## Scientific citations

> All human beings are born free and equal in dignity and rights. They are endowed with reason and conscience and should act towards one another in a spirit of brotherhood. @unitednations1948

All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights. All human beings are born free and equal in dignity and rights.[@unitednations1948]

# Bibliography

::: {#refs}
:::
