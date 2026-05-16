#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"
$ProjectDir = $PSScriptRoot
$ToolsDir = Join-Path $ProjectDir ".local\bin"

function Invoke-Download {
    param(
        [string]$Name,
        [string]$ExeName,
        [string]$Url,
        [string]$FileType,
        [switch]$ExtractTar
    )
    
    $exePath = Join-Path $ToolsDir $ExeName
    if (Test-Path $exePath) {
        Write-Host "  $Name already installed." -ForegroundColor Gray
        return
    }
    
    $tempFile = Join-Path $env:TEMP "temp.$FileType"
    $success = $false
    for ($i = 1; $i -le 3; $i++) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $tempFile -ErrorAction Stop
            if ((Get-Item $tempFile).Length -lt 1000) { throw "File too small" }
            $success = $true
            break
        } catch {
            Write-Host "  Retry $i/3..." -ForegroundColor Yellow
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
    }
    if (-not $success) {
        Write-Host "  Download failed after 3 attempts" -ForegroundColor Red
        exit 1
    }
    
    if ($ExtractTar) {
        tar -xf $tempFile -C $ToolsDir
    } else {
        Expand-Archive -Path $tempFile -DestinationPath $ToolsDir -Force
    }
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    Write-Host "  $Name installed successfully." -ForegroundColor Green
}

function Install-Tools {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Academic Pandoc Template - Windows Setup"
    Write-Host "========================================" -ForegroundColor Cyan
    
    if (-not (Test-Path $ToolsDir)) {
        New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
    }
    
    Write-Host "[1/4] Downloading Pandoc..." -ForegroundColor Yellow
    Invoke-Download -Name "Pandoc" -ExeName "pandoc.exe" `
        -Url "https://ghproxy.com/https://github.com/jgm/pandoc/releases/download/3.8.3/pandoc-3.8.3-windows-x86_64.zip" `
        -FileType "zip"
    
    Write-Host "[2/4] Downloading Pandoc-crossref..." -ForegroundColor Yellow
    Invoke-Download -Name "Pandoc-crossref" -ExeName "pandoc-crossref.exe" `
        -Url "https://ghproxy.com/https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.22b/pandoc-crossref-Windows-X64.tar.xz" `
        -FileType "tar.xz" -ExtractTar
    
    Write-Host "[3/4] Downloading Tectonic..." -ForegroundColor Yellow
    Invoke-Download -Name "Tectonic" -ExeName "tectonic.exe" `
        -Url "https://ghproxy.com/https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.16.9/tectonic-0.16.9-x86_64-pc-windows-gnu.zip" `
        -FileType "zip"
    
    Write-Host "[4/4] Verifying installation..." -ForegroundColor Yellow
    $env:PATH = "$ToolsDir;$env:PATH"
    try {
        $PandocVersion = & pandoc --version 2>&1 | Select-Object -First 1
        Write-Host "  Pandoc: $PandocVersion" -ForegroundColor Green
    } catch {
        Write-Host "  Warning: Pandoc not found in PATH" -ForegroundColor Red
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Setup complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To build the article, run:" -ForegroundColor White
    Write-Host "  .\build.ps1 article" -ForegroundColor Cyan
    Write-Host ""
}

function Build-Document {
    param(
        [string]$Target,
        [string]$ContentFile = "",
        [string]$Format = "all"
    )
    
    $env:PATH = "$ToolsDir;$env:PATH"
    Write-Host "Building $Target..." -ForegroundColor Cyan
    
    Push-Location
    try {
        switch ($Target) {
            "article" {
                $formats = if ($Format -eq "all") { @("docx", "pdf", "tex") } else { $Format -split "," }
                foreach ($f in $formats) { & Build-Document -Target "article-$f" }
            }
            "article-docx" {
                Write-Host "[Building article DOCX...]" -ForegroundColor Yellow
                Set-Location "article"
                & pandoc --defaults=./../defaults.yaml --defaults=docx.yaml --lua-filter=../assets/cite-links.lua
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
                    $outputBaseName = "presentation"
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
                            exit 1
                        }
                    }
                    $outputBaseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
                }
                
                Write-Host "  Using content file: $ContentFile" -ForegroundColor Cyan
                Write-Host "  Output base name: $outputBaseName" -ForegroundColor Cyan
                
                $formats = if ($Format -eq "all") { @("html", "pdf", "pptx", "tex") } else { $Format -split "," }
                foreach ($f in $formats) {
                    Write-Host "  Building $($f.ToUpper())..." -ForegroundColor Yellow
                    & pandoc --defaults=./../defaults.yaml --defaults=$f.yaml -f markdown -o "${outputBaseName}.$f" metadata.yaml $ContentFile
                }
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
                Get-ChildItem -Path "article" -Include *.log,*.toc,*.aux,article.docx,article.pdf -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Get-ChildItem -Path "presentation" -Include *.log -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Get-ChildItem -Path "thesis" -Include *.log -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            }
            default {
                Write-Host "Unknown target: $Target" -ForegroundColor Red
                Write-Host "Run '.\build.ps1 help' for available targets." -ForegroundColor White
                exit 1
            }
        }
        
        if ($Target -ne "clean" -and $Target -ne "help") {
            Write-Host ""
            Write-Host "Build complete for: $Target" -ForegroundColor Green
        }
        
        if ($Target -eq "all") {
            Write-Host ""
            Write-Host "All documents built successfully!" -ForegroundColor Green
        }
    } finally {
        Pop-Location
    }
}

function Show-Help {
    Write-Host "Usage: .\build.ps1 [target] [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available targets:" -ForegroundColor White
    Write-Host "  article (a)    - Build article"
    Write-Host "  article-docx (ad) - Build article DOCX"
    Write-Host "  article-pdf (ap) - Build article PDF"
    Write-Host "  article-tex (at) - Build article TeX"
    Write-Host "  presentation (p/pt) - Build presentation"
    Write-Host "  thesis (t)     - Build thesis"
    Write-Host "  all            - Build all documents"
    Write-Host "  clean          - Clean build artifacts"
    Write-Host "  help           - Show this help message"
    Write-Host "  setup          - Install required tools"
    Write-Host ""
    Write-Host "Quick shortcuts:" -ForegroundColor White
    Write-Host "  ad, ap, at    - Article formats"
    Write-Host "  ph, pd, pp, px - Presentation formats (HTML/PDF/PPTX/TeX)"
    Write-Host ""
    Write-Host "Article options: --docx, --pdf, --tex"
    Write-Host "Presentation options: [file], --html, --pdf, --pptx, --tex"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  .\build.ps1 a"
    Write-Host "  .\build.ps1 p myslides.md --pdf"
}

$Targets = $args
if (-not $Targets -or $Targets.Count -eq 0) {
    Show-Help
    exit 0
}

$i = 0
while ($i -lt $Targets.Count) {
    $Target = $Targets[$i]
    $ContentFile = ""
    $Format = @()
    
    switch ($Target) {
        "a" { $Target = "article" }
        "ad" { $Target = "article-docx" }
        "ap" { $Target = "article-pdf" }
        "at" { $Target = "article-tex" }
        "p" { $Target = "presentation" }
        "pd" { $Target = "presentation"; $Format = @("pdf") }
        "ph" { $Target = "presentation"; $Format = @("html") }
        "pp" { $Target = "presentation"; $Format = @("pptx") }
        "pt" { $Target = "presentation" }
        "px" { $Target = "presentation"; $Format = @("tex") }
        "t" { $Target = "thesis" }
    }
    
    switch ($Target) {
        "help" { Show-Help; exit 0 }
        "setup" { Install-Tools; $i++ }
        "presentation" {
            $i++
            while ($i -lt $Targets.Count) {
                $nextArg = $Targets[$i]
                if ($nextArg -match '^--?(html|pdf|pptx|tex)$') {
                    $Format += $matches[1]; $i++
                } elseif (-not $nextArg.StartsWith("-")) {
                    $ContentFile = $nextArg; $i++
                } else {
                    break
                }
            }
            if ($Format.Count -eq 0) { $Format = "all" }
            Build-Document -Target "presentation" -ContentFile $ContentFile -Format ($Format -join ",")
        }
        "article" {
            $i++
            while ($i -lt $Targets.Count) {
                $nextArg = $Targets[$i]
                if ($nextArg -match '^--?(docx|pdf|tex)$') {
                    $Format += $matches[1]; $i++
                } else {
                    break
                }
            }
            if ($Format.Count -eq 0) { $Format = "all" }
            Build-Document -Target "article" -Format ($Format -join ",")
        }
        default {
            Build-Document -Target $Target
            $i++
        }
    }
}
