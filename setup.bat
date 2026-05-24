@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Academic Pandoc Template - Windows Setup
echo ========================================
echo.

set "PROJECT_DIR=%~dp0"
set "TOOLS_DIR=%PROJECT_DIR%.local\bin"

echo Project directory: %PROJECT_DIR%
echo Tools directory: %TOOLS_DIR%
echo.

if not exist "%TOOLS_DIR%" (
    mkdir "%TOOLS_DIR%"
)

echo [1/4] Checking Pandoc...
where pandoc >nul 2>&1
if %errorlevel% equ 0 (
    echo   Pandoc found in system PATH, skipping installation.
) else if exist "%TOOLS_DIR%\pandoc.exe" (
    echo   Pandoc already installed.
) else (
    echo   Downloading Pandoc...
    powershell -Command "$url='https://ghproxy.com/https://github.com/jgm/pandoc/releases/download/3.8.3/pandoc-3.8.3-windows-x86_64.zip'; $out='%TEMP%\pandoc.zip'; $dir='%TOOLS_DIR%'; $success=$false; for($i=1;$i -le 3;$i++){ try { Invoke-WebRequest -Uri $url -OutFile $out -ErrorAction Stop; $zip=New-Object System.IO.Compression.ZipArchive([IO.File]::OpenRead($out)); $zip.Dispose(); Expand-Archive -Path $out -DestinationPath $dir -Force; Remove-Item $out -Force; $success=$true; break } catch { Write-Host \"  Retry $i/3...\"; Remove-Item $out -ErrorAction SilentlyContinue } }; if(-not $success) { Write-Host '  Download failed after 3 attempts'; [Environment]::Exit(1) }"
    if %errorlevel% neq 0 exit /b 1
    if exist "%TOOLS_DIR%\pandoc.exe" (
        echo   Pandoc installed successfully.
    ) else (
        echo   ERROR: pandoc.exe not found after installation!
        echo   Please try running: .\build.ps1 setup
        exit /b 1
    )
)

echo.
echo [2/4] Checking Pandoc-crossref...
where pandoc-crossref >nul 2>&1
if %errorlevel% equ 0 (
    echo   Pandoc-crossref found in system PATH, skipping installation.
) else if exist "%TOOLS_DIR%\pandoc-crossref.exe" (
    echo   Pandoc-crossref already installed.
) else (
    echo   Downloading Pandoc-crossref...
    powershell -Command "$url='https://ghproxy.com/https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.22b/pandoc-crossref-Windows-X64.tar.xz'; $out='%TEMP%\pandoc-crossref.tar.xz'; $dir='%TOOLS_DIR%'; $success=$false; for($i=1;$i -le 3;$i++){ try { Invoke-WebRequest -Uri $url -OutFile $out -ErrorAction Stop; if((Get-Item $out).Length -lt 1000) { throw 'File too small' }; tar -xf $out -C $dir 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { throw 'tar extraction failed' }; Remove-Item $out -Force; $success=$true; break } catch { Write-Host \"  Retry $i/3...\"; Remove-Item $out -ErrorAction SilentlyContinue } }; if(-not $success) { Write-Host '  Download failed after 3 attempts'; [Environment]::Exit(1) }"
    if %errorlevel% neq 0 exit /b 1
    if exist "%TOOLS_DIR%\pandoc-crossref.exe" (
        echo   Pandoc-crossref installed successfully.
    ) else (
        echo   ERROR: pandoc-crossref.exe not found after installation!
        echo   Please try running: .\build.ps1 setup
        exit /b 1
    )
)

echo.
echo [3/4] Checking Tectonic...
where tectonic >nul 2>&1
if %errorlevel% equ 0 (
    echo   Tectonic found in system PATH, skipping installation.
) else if exist "%TOOLS_DIR%\tectonic.exe" (
    echo   Tectonic already installed.
) else (
    echo   Downloading Tectonic...
    powershell -Command "$url='https://ghproxy.com/https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.16.9/tectonic-0.16.9-x86_64-pc-windows-gnu.zip'; $out='%TEMP%\tectonic.zip'; $dir='%TOOLS_DIR%'; $success=$false; for($i=1;$i -le 3;$i++){ try { Invoke-WebRequest -Uri $url -OutFile $out -ErrorAction Stop; $zip=New-Object System.IO.Compression.ZipArchive([IO.File]::OpenRead($out)); $zip.Dispose(); Expand-Archive -Path $out -DestinationPath $dir -Force; Remove-Item $out -Force; $success=$true; break } catch { Write-Host \"  Retry $i/3...\"; Remove-Item $out -ErrorAction SilentlyContinue } }; if(-not $success) { Write-Host '  Download failed after 3 attempts'; [Environment]::Exit(1) }"
    if %errorlevel% neq 0 exit /b 1
    if exist "%TOOLS_DIR%\tectonic.exe" (
        echo   Tectonic installed successfully.
    ) else (
        echo   ERROR: tectonic.exe not found after installation!
        echo   Please try running: .\build.ps1 setup
        exit /b 1
    )
)

echo.
echo [4/4] Setting up PATH...
setx PATH "%TOOLS_DIR%;%PATH%" >nul 2>&1
set "PATH=%TOOLS_DIR%;%PATH%"

echo.
echo ========================================
echo Setup complete!
echo ========================================
echo.
echo Tools installed in: %TOOLS_DIR%
echo.
echo To build the article, run:
echo   build.bat article
echo.
echo To build all documents, run:
echo   build.bat all
echo.
echo NOTE: You may need to restart your terminal for PATH changes to take effect.
echo.
pause
