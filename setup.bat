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

echo [1/4] Downloading Pandoc...
if not exist "%TOOLS_DIR%\pandoc.exe" (
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/jgm/pandoc/releases/download/3.8.3/pandoc-3.8.3-1-amd64.deb' -OutFile '%TEMP%\pandoc.deb'"
    powershell -Command "tar -xf '%TEMP%\pandoc.deb' -C '%TEMP%'"
    copy "%TEMP%\pandoc-3.8.3-1-amd64\usr\bin\pandoc.exe" "%TOOLS_DIR%\pandoc.exe" /Y
    del /f /q "%TEMP%\pandoc.deb"
    rmdir /s /q "%TEMP%\pandoc-3.8.3-1-amd64" 2>nul
    echo   Pandoc installed successfully.
) else (
    echo   Pandoc already installed.
)

echo.
echo [2/4] Downloading Pandoc-crossref...
if not exist "%TOOLS_DIR%\pandoc-crossref.exe" (
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.23a/pandoc-crossref-Windows-X64.7z' -OutFile '%TEMP%\pandoc-crossref.7z'"
    powershell -Command "if (Get-Command 7z -ErrorAction SilentlyContinue) { 7z x '%TEMP%\pandoc-crossref.7z' -o'%TOOLS_DIR%' -y } else { if (Test-Path 'C:\Program Files\7-Zip\7z.exe') { & 'C:\Program Files\7-Zip\7z.exe' x '%TEMP%\pandoc-crossref.7z' -o'%TOOLS_DIR%' -y } else { Write-Host 'Please install 7-Zip or use Git Bash to extract .7z files'; exit 1 } }"
    del /f /q "%TEMP%\pandoc-crossref.7z"
    echo   Pandoc-crossref installed successfully.
) else (
    echo   Pandoc-crossref already installed.
)

echo.
echo [3/4] Downloading Tectonic...
if not exist "%TOOLS_DIR%\tectonic.exe" (
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.16.9/tectonic-0.16.9-x86_64-pc-windows-gnu.zip' -OutFile '%TEMP%\tectonic.zip'"
    powershell -Command "Expand-Archive -Path '%TEMP%\tectonic.zip' -DestinationPath '%TOOLS_DIR%' -Force"
    del /f /q "%TEMP%\tectonic.zip"
    echo   Tectonic installed successfully.
) else (
    echo   Tectonic already installed.
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
