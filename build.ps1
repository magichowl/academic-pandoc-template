#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$ProjectDir = $PSScriptRoot
$ToolsDir = Join-Path $ProjectDir ".local\bin"

function Install-Tools {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Academic Pandoc Template - Windows Setup"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Path $ToolsDir)) {
        New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
    }

    Write-Host "[1/4] Downloading Pandoc..." -ForegroundColor Yellow
    $PandocExe = Join-Path $ToolsDir "pandoc.exe"
    if (-not (Test-Path $PandocExe)) {
        $TempZip = Join-Path $env:TEMP "pandoc.zip"
        $url = "https://ghproxy.com/https://github.com/jgm/pandoc/releases/download/3.8.3/pandoc-3.8.3-windows-x86_64.zip"
        $success = $false
        for ($i = 1; $i -le 3; $i++) {
            try {
                Invoke-WebRequest -Uri $url -OutFile $TempZip -ErrorAction Stop
                $zip = New-Object System.IO.Compression.ZipArchive([IO.File]::OpenRead($TempZip))
                $zip.Dispose()
                $success = $true
                break
            } catch {
                Write-Host "  Retry $i/3..." -ForegroundColor Yellow
                Remove-Item $TempZip -ErrorAction SilentlyContinue
            }
        }
        if (-not $success) {
            Write-Host "  Download failed after 3 attempts" -ForegroundColor Red
            exit 1
        }
        Expand-Archive -Path $TempZip -DestinationPath $ToolsDir -Force
        Remove-Item $TempZip -Force -ErrorAction SilentlyContinue
        Write-Host "  Pandoc installed successfully." -ForegroundColor Green
    } else {
        Write-Host "  Pandoc already installed." -ForegroundColor Gray
    }

    Write-Host "" -ForegroundColor White
    Write-Host "[2/4] Downloading Pandoc-crossref..." -ForegroundColor Yellow
    $PandocRefExe = Join-Path $ToolsDir "pandoc-crossref.exe"
    if (-not (Test-Path $PandocRefExe)) {
        $TempTar = Join-Path $env:TEMP "pandoc-crossref.tar.xz"
        $url = "https://ghproxy.com/https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.22b/pandoc-crossref-Windows-X64.tar.xz"
        $success = $false
        for ($i = 1; $i -le 3; $i++) {
            try {
                Invoke-WebRequest -Uri $url -OutFile $TempTar -ErrorAction Stop
                if ((Get-Item $TempTar).Length -lt 1000) {
                    throw "File too small"
                }
                $success = $true
                break
            } catch {
                Write-Host "  Retry $i/3..." -ForegroundColor Yellow
                Remove-Item $TempTar -ErrorAction SilentlyContinue
            }
        }
        if (-not $success) {
            Write-Host "  Download failed after 3 attempts" -ForegroundColor Red
            exit 1
        }
        tar -xf $TempTar -C $ToolsDir
        Remove-Item $TempTar -Force -ErrorAction SilentlyContinue
        Write-Host "  Pandoc-crossref installed successfully." -ForegroundColor Green
    } else {
        Write-Host "  Pandoc-crossref already installed." -ForegroundColor Gray
    }

    Write-Host "" -ForegroundColor White
    Write-Host "[3/4] Downloading Tectonic..." -ForegroundColor Yellow
    $TectonicExe = Join-Path $ToolsDir "tectonic.exe"
    if (-not (Test-Path $TectonicExe)) {
        $TempZip = Join-Path $env:TEMP "tectonic.zip"
        $url = "https://ghproxy.com/https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.16.9/tectonic-0.16.9-x86_64-pc-windows-gnu.zip"
        $success = $false
        for ($i = 1; $i -le 3; $i++) {
            try {
                Invoke-WebRequest -Uri $url -OutFile $TempZip -ErrorAction Stop
                $zip = New-Object System.IO.Compression.ZipArchive([IO.File]::OpenRead($TempZip))
                $zip.Dispose()
                $success = $true
                break
            } catch {
                Write-Host "  Retry $i/3..." -ForegroundColor Yellow
                Remove-Item $TempZip -ErrorAction SilentlyContinue
            }
        }
        if (-not $success) {
            Write-Host "  Download failed after 3 attempts" -ForegroundColor Red
            exit 1
        }
        Expand-Archive -Path $TempZip -DestinationPath $ToolsDir -Force
        Remove-Item $TempZip -Force -ErrorAction SilentlyContinue
        Write-Host "  Tectonic installed successfully." -ForegroundColor Green
    } else {
        Write-Host "  Tectonic already installed." -ForegroundColor Gray
    }

    Write-Host "" -ForegroundColor White
    Write-Host "[4/4] Verifying installation..." -ForegroundColor Yellow
    $env:PATH = "$ToolsDir;$env:PATH"

    try {
        $PandocVersion = & pandoc --version 2>&1 | Select-Object -First 1
        Write-Host "  Pandoc: $PandocVersion" -ForegroundColor Green
    } catch {
        Write-Host "  Warning: Pandoc not found in PATH" -ForegroundColor Red
    }

    Write-Host "" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Setup complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Tools installed in: $ToolsDir" -ForegroundColor White
    Write-Host ""
    Write-Host "To build the article, run:" -ForegroundColor White
    Write-Host "  .\build.ps1 article" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To build all documents, run:" -ForegroundColor White
    Write-Host "  .\build.ps1 all" -ForegroundColor Cyan
    Write-Host ""
}

function Build-Document {
    param(
        [string]$Target,
        [string]$ContentFile = ""
    )

    $env:PATH = "$ToolsDir;$env:PATH"

    Write-Host "Building $Target..." -ForegroundColor Cyan
    Write-Host ""

    Push-Location

    switch ($Target) {
        "article" {
            & Build-Document -Target "article-docx"
            & Build-Document -Target "article-pdf"
            & Build-Document -Target "article-tex"
        }
        "article-docx" {
            Write-Host "[Building article DOCX...]" -ForegroundColor Yellow
            Set-Location "article"
            $pandocPath = Get-Command pandoc | Select-Object -ExpandProperty Source
            & $pandocPath --defaults=./../defaults.yaml --defaults=docx.yaml --lua-filter=../assets/cite-links.lua
            Set-Location ..
        }
        "article-pdf" {
            Write-Host "[Building article PDF...]" -ForegroundColor Yellow
            Set-Location "article"
            & pandoc --defaults=./../defaults.yaml --defaults=pdf.yaml
            Set-Location ..
        }
        "article-tex" {
            Write-Host "[Building article TeX...]" -ForegroundColor Yellow
            Set-Location "article"
            & pandoc --defaults=./../defaults.yaml --defaults=tex.yaml
            Set-Location ..
        }
        "presentation" {
            Write-Host "[Building presentation...]" -ForegroundColor Yellow
            Set-Location "presentation"
            
            $currentDir = Get-Location
            $baseDir = Split-Path $PSScriptRoot -Parent
            
            if ($ContentFile -eq "") {
                $ContentFile = "content.md"
            } else {
                $fileName = Split-Path $ContentFile -Leaf
                $testPath = Join-Path $currentDir $fileName
                if (Test-Path $testPath) {
                    $ContentFile = $fileName
                } else {
                    $testPath = Join-Path $baseDir "presentation\$fileName"
                    if (Test-Path $testPath) {
                        $ContentFile = $testPath
                    } else {
                        Write-Host "  Error: File not found: $fileName" -ForegroundColor Red
                        Write-Host "  Please ensure the file exists in the presentation directory." -ForegroundColor Yellow
                        Pop-Location
                        exit 1
                    }
                }
            }
            
            Write-Host "  Using content file: $ContentFile" -ForegroundColor Cyan
            
            Write-Host "  Building HTML..." -ForegroundColor Yellow
            $pandocPath = Get-Command pandoc | Select-Object -ExpandProperty Source
            & $pandocPath --defaults=./../defaults.yaml --defaults=html.yaml -f markdown -o presentation.html metadata.yaml $ContentFile
            Set-Location ..
            
            Set-Location "presentation"
            Write-Host "  Building PDF..." -ForegroundColor Yellow
            & pandoc --defaults=./../defaults.yaml --defaults=pdf.yaml -f markdown -o presentation.pdf metadata.yaml $ContentFile
            Set-Location ..
            
            Set-Location "presentation"
            Write-Host "  Building PPTX..." -ForegroundColor Yellow
            & pandoc --defaults=./../defaults.yaml --defaults=pptx.yaml -f markdown -o presentation.pptx metadata.yaml $ContentFile
            Set-Location ..
            
            Set-Location "presentation"
            Write-Host "  Building TeX..." -ForegroundColor Yellow
            & pandoc --defaults=./../defaults.yaml --defaults=tex.yaml -f markdown -o presentation.tex metadata.yaml $ContentFile
            Set-Location ..
        }
        "thesis" {
            Write-Host "[Building thesis...]" -ForegroundColor Yellow
            Set-Location "thesis"
            & pandoc --defaults=./../defaults.yaml --defaults=docx.yaml
            & pandoc --defaults=./../defaults.yaml --defaults=epub.yaml
            & pandoc --defaults=./../defaults.yaml --defaults=pdf.yaml
            & pandoc --defaults=./../defaults.yaml --defaults=tex.yaml
            Set-Location ..
        }
        "all" {
            & Build-Document -Target "article"
            & Build-Document -Target "presentation"
            & Build-Document -Target "thesis"
        }
        "clean" {
            Write-Host "[Cleaning build artifacts...]" -ForegroundColor Yellow
            Get-ChildItem -Path "article" -Include *.log,*.toc,*.aux -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path "article" -Include article.docx,article.pdf -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path "presentation" -Include *.log -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path "thesis" -Include *.log -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        default {
            Write-Host "Unknown target: $Target" -ForegroundColor Red
            Write-Host "Run '.\build.ps1 help' for available targets." -ForegroundColor White
            Pop-Location
            exit 1
        }
    }

    Pop-Location

    if ($Target -ne "clean" -and $Target -ne "help") {
        Write-Host ""
        Write-Host "Build complete for: $Target" -ForegroundColor Green
    }

    if ($Target -eq "all") {
        Write-Host ""
        Write-Host "All documents built successfully!" -ForegroundColor Green
    }
}

function Show-Help {
    Write-Host "Usage: .\build.ps1 [target] [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available targets:" -ForegroundColor White
    Write-Host "  article        - Build article (docx, pdf, tex)"
    Write-Host "  article-docx   - Build article in DOCX format"
    Write-Host "  article-pdf    - Build article in PDF format"
    Write-Host "  article-tex    - Build article in TeX format"
    Write-Host "  presentation   - Build presentation"
    Write-Host "  thesis         - Build thesis"
    Write-Host "  all            - Build all documents"
    Write-Host "  clean          - Clean build artifacts"
    Write-Host "  help           - Show this help message"
    Write-Host "  setup          - Install required tools"
    Write-Host ""
    Write-Host "Presentation options:" -ForegroundColor White
    Write-Host "  .\build.ps1 presentation              - Build with default content.md"
    Write-Host "  .\build.ps1 presentation myfile.md  - Build with custom content file"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  .\build.ps1 article" -ForegroundColor Cyan
    Write-Host "  .\build.ps1 all" -ForegroundColor Cyan
    Write-Host "  .\build.ps1 presentation" -ForegroundColor Cyan
    Write-Host "  .\build.ps1 presentation myslides.md" -ForegroundColor Cyan
    Write-Host "  .\build.ps1 setup" -ForegroundColor Cyan
}

$Targets = $args

if (-not $Targets -or $Targets.Count -eq 0) {
    Show-Help
    exit 0
}

$i = 0
while ($i -lt $Targets.Count) {
    $Target = $Targets[$i]
    
    switch ($Target) {
        "help" { 
            Show-Help 
            exit 0
        }
        "setup" { Install-Tools }
        "presentation" {
            $ContentFile = ""
            if ($i + 1 -lt $Targets.Count -and -not $Targets[$i + 1].StartsWith("-")) {
                $ContentFile = $Targets[$i + 1]
                $i++
            }
            Build-Document -Target "presentation" -ContentFile $ContentFile
        }
        default { Build-Document -Target $Target }
    }
    $i++
}
