@echo off
setlocal enabledelayedexpansion

set "PROJECT_DIR=%~dp0"
set "TOOLS_DIR=%PROJECT_DIR%.local\bin"
set "PATH=%TOOLS_DIR%;%PATH%"

if "%~1"=="" (
    echo Usage: build.bat [target]
    echo.
    echo Available targets:
    echo   article        - Build article (docx, pdf, tex)
    echo   article-docx   - Build article in DOCX format
    echo   article-pdf    - Build article in PDF format
    echo   article-tex    - Build article in TeX format
    echo   presentation   - Build presentation
    echo   thesis         - Build thesis
    echo   all            - Build all documents
    echo   clean          - Clean build artifacts
    echo   help           - Show this help message
    echo.
    echo Example:
    echo   build.bat article
    exit /b 1
)

if "%~1"=="clean" (
    echo Cleaning build artifacts...
    if exist "article\*.log" del /q "article\*.log"
    if exist "article\*.toc" del /q "article\*.toc"
    if exist "article\*.aux" del /q "article\*.aux"
    if exist "article\article.docx" del /q "article\article.docx"
    if exist "article\article.pdf" del /q "article\article.pdf"
    if exist "presentation\*.log" del /q "presentation\*.log"
    if exist "thesis\*.log" del /q "thesis\*.log"
    echo Clean complete.
    exit /b 0
)

if "%~1"=="help" (
    echo Usage: build.bat [target]
    echo.
    echo Available targets:
    echo   article        - Build article (docx, pdf, tex)
    echo   article-docx   - Build article in DOCX format
    echo   article-pdf    - Build article in PDF format
    echo   article-tex    - Build article in TeX format
    echo   presentation   - Build presentation
    echo   thesis         - Build thesis
    echo   all            - Build all documents
    echo   clean          - Clean build artifacts
    echo   help           - Show this help message
    exit /b 0
)

echo Building %~1...
echo.

if "%~1"=="article" (
    call :build_article
) else if "%~1"=="article-docx" (
    call :build_article_docx
) else if "%~1"=="article-pdf" (
    call :build_article_pdf
) else if "%~1"=="article-tex" (
    call :build_article_tex
) else if "%~1"=="presentation" (
    call :build_presentation
) else if "%~1"=="thesis" (
    call :build_thesis
) else if "%~1"=="all" (
    call :build_article
    call :build_presentation
    call :build_thesis
) else (
    echo Unknown target: %~1
    echo Run 'build.bat help' for available targets.
    exit /b 1
)

echo.
echo Build complete!
exit /b 0

:build_article_docx
echo [Building article DOCX...]
cd article
pandoc --defaults=./../defaults.yaml --defaults=docx.yaml --lua-filter=../assets/cite-links.lua
cd ..
exit /b 0

:build_article_pdf
echo [Building article PDF...]
cd article
pandoc --defaults=./../defaults.yaml --defaults=pdf.yaml
cd ..
exit /b 0

:build_article_tex
echo [Building article TeX...]
cd article
pandoc --defaults=./../defaults.yaml --defaults=tex.yaml
cd ..
exit /b 0

:build_article
call :build_article_docx
call :build_article_pdf
call :build_article_tex
exit /b 0

:build_presentation
echo [Building presentation...]
cd presentation
pandoc --defaults=./../defaults.yaml --defaults=html.yaml
pandoc --defaults=./../defaults.yaml --defaults=pdf.yaml
pandoc --defaults=./../defaults.yaml --defaults=pptx.yaml
pandoc --defaults=./../defaults.yaml --defaults=tex.yaml
cd ..
exit /b 0

:build_thesis
echo [Building thesis...]
cd thesis
pandoc --defaults=./../defaults.yaml --defaults=docx.yaml
pandoc --defaults=./../defaults.yaml --defaults=epub.yaml
pandoc --defaults=./../defaults.yaml --defaults=pdf.yaml
pandoc --defaults=./../defaults.yaml --defaults=tex.yaml
cd ..
exit /b 0
