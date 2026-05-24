#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"
$ProjectDir = $PSScriptRoot
$ToolsDir = Join-Path $ProjectDir ".local\bin"
$PandocDefaults = "$PandocDefaults"

$env:TECTONIC_CACHE_DIR = "$env:TEMP\TectonicCache"
if (-not (Test-Path $env:TECTONIC_CACHE_DIR)) {
    New-Item -Path $env:TECTONIC_CACHE_DIR -ItemType Directory -Force | Out-Null
}

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

function Sync-Macros-TexToLua {
    Write-Host "[Syncing macros from TeX to Lua...]" -ForegroundColor Yellow
    
    $texFile = Join-Path $ProjectDir "article\macros.tex"
    $luaFile = Join-Path $ProjectDir "article\expand-macros.lua"
    
    if (-not (Test-Path $texFile)) {
        Write-Host "  Error: $texFile not found" -ForegroundColor Red
        return
    }
    
    if (-not (Test-Path $luaFile)) {
        Write-Host "  Error: $luaFile not found" -ForegroundColor Red
        return
    }
    
    $texContent = Get-Content $texFile -Raw
    
    $luaContent = "-- Macro expansion filter`n-- Uses built-in macro definitions, does not load external files`n`nlocal macros = {`n"
    
    function Find-Matching-Brace {
        param(
            [string]$str,
            [int]$start_pos
        )
        $depth = 1
        $pos = $start_pos + 1
        while ($pos -le $str.Length -and $depth -gt 0) {
            $char = $str[$pos]
            if ($char -eq '{') { $depth++ }
            elseif ($char -eq '}') { $depth-- }
            $pos++
        }
        return $pos - 1
    }
    
    $pattern = [regex]'\\newcommand\s*{\s*\\(\w+)\s*}'
    $matches = $pattern.Matches($texContent)
    
    foreach ($m in $matches) {
        $name = $m.Groups[1].Value
        $pos = $m.Index + $m.Length
        
        while ($pos -lt $texContent.Length -and $texContent[$pos] -match '\s') { $pos++ }
        
        $numParams = 0
        if ($pos -lt $texContent.Length -and $texContent[$pos] -eq '[') {
            $endBracket = $texContent.IndexOf(']', $pos)
            if ($endBracket -gt 0) {
                $numParams = [int]($texContent.Substring($pos + 1, $endBracket - $pos - 1))
                $pos = $endBracket + 1
            }
        }
        
        while ($pos -lt $texContent.Length -and $texContent[$pos] -match '\s') { $pos++ }
        
        if ($pos -lt $texContent.Length -and $texContent[$pos] -eq '{') {
            $endPos = Find-Matching-Brace -str $texContent -start_pos $pos
            $body = $texContent.Substring($pos + 1, $endPos - $pos - 1)
            $body = $body -replace '#(\d)', '%$1'
            
            $luaName = "\\" + $name
            $body = $body.Replace('\', '\\')
            $body = $body.Replace('"', '\"')
            
            if ($numParams -eq 0) {
                $line = "  [`"$luaName`"] = `"$body`","
            } else {
                $line = "  [`"$luaName`"] = {`"$body`", $numParams},"
            }
            $luaContent = $luaContent + $line + "`n"
        }
    }
    
    $luaContent += @'
}

function find_matching_brace(str, start_pos)
  local depth = 1
  local pos = start_pos + 1
  while pos <= #str and depth > 0 do
    local char = str:sub(pos, pos)
    if char == '{' then depth = depth + 1
    elseif char == '}' then depth = depth - 1 end
    pos = pos + 1
  end
  return pos - 1
end

function parse_macro_args(text, pos, num_params)
  local params = {}
  local current_pos = pos
  
  while true do
    while current_pos <= #text and text:sub(current_pos, current_pos) ~= '{' do
      current_pos = current_pos + 1
    end
    
    if current_pos > #text then break end
    
    local end_pos = find_matching_brace(text, current_pos)
    if end_pos then
      table.insert(params, text:sub(current_pos + 1, end_pos - 1))
      current_pos = end_pos + 1
      
      if num_params > 0 and #params >= num_params then break end
    else
      break
    end
  end
  
  return params, current_pos
end

function expand_macros_once(text)
  local result = ""
  local pos = 1
  
  while pos <= #text do
    local matched = false
    
    for macro_name, macro_def in pairs(macros) do
      local macro_len = #macro_name
      local macro_start = text:find(macro_name, pos, true)
      
      if macro_start and macro_start == pos then
        matched = true
        
        if macro_start > pos then
          result = result .. text:sub(pos, macro_start - 1)
        end
        
        if type(macro_def) == "string" then
          result = result .. macro_def
          pos = macro_start + macro_len
          
        else
          local pattern = macro_def[1]
          local num_params = macro_def[2]
          
          local params, next_pos = parse_macro_args(text, macro_start + macro_len, num_params)
          
          local valid = true
          if num_params > 0 and #params ~= num_params then
            valid = false
          elseif num_params == -1 and #params == 0 then
            valid = false
          end
          
          if valid then
            for i, param in ipairs(params) do
              params[i] = expand_macros(param)
            end
            
            local expanded = pattern
            
            if num_params == -1 then
              local args_str = table.concat(params, ",")
              expanded = expanded:gsub("%%args%%", args_str)
            else
              for i, param in ipairs(params) do
                expanded = expanded:gsub("%%" .. i, param)
              end
            end
            
            result = result .. expanded
            pos = next_pos
          else
            result = result .. text:sub(macro_start, next_pos - 1)
            pos = next_pos
          end
        end
        
        break
      end
    end
    
    if not matched then
      result = result .. text:sub(pos, pos)
      pos = pos + 1
    end
  end
  
  return result
end

function expand_macros(text)
  local result = text
  local prev_result = ""
  local iterations = 0
  local max_iterations = 10
  
  while result ~= prev_result and iterations < max_iterations do
    prev_result = result
    result = expand_macros_once(result)
    iterations = iterations + 1
  end
  
  return result
end

function Math(elem)
  if elem.text then
    elem.text = expand_macros(elem.text)
  end
  return elem
end
'@
    
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($luaFile, $luaContent, $utf8NoBom)
    Write-Host "  Macros synced to $luaFile" -ForegroundColor Green
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
                Sync-Macros-TexToLua
                Write-Host "[Building article DOCX...]" -ForegroundColor Yellow
                Set-Location "article"
                & pandoc $PandocDefaults --defaults=docx.yaml --lua-filter=../assets/cite-links.lua --lua-filter=expand-macros.lua
                Write-Host "[Fixing equation table layout...]" -ForegroundColor Yellow
                python fix_table_eqns.py article.docx article.docx
                Set-Location ..
            }
            "article-pdf" {
                Sync-Macros-TexToLua
                Write-Host "[Building article PDF...]" -ForegroundColor Yellow
                Set-Location "article"
                $articleDir = (Get-Location).Path
                $outputFile = Join-Path $articleDir "article.pdf"
                Remove-Item $outputFile -Force -ErrorAction SilentlyContinue
                $headerFile = "$env:TEMP\header.tex"
                $macrosContent = Get-Content (Join-Path $ProjectDir "article\macros.tex") -Raw
                $macrosContent = $macrosContent -replace '%.*$', ''
                $macrosContent = $macrosContent -replace '(?m)^$', ''
                $macrosContent = $macrosContent.Trim()
                @"
\usepackage{fontspec}
\setmainfont{SimSun}
$macrosContent
"@ | Set-Content -Path $headerFile -Encoding UTF8
                $oldErrorAction = $ErrorActionPreference
                $ErrorActionPreference = "Continue"
                & pandoc $PandocDefaults --defaults=pdf.yaml --output=$outputFile --include-in-header="$headerFile" 2>&1 | Out-Null
                $ErrorActionPreference = $oldErrorAction
                Start-Sleep -Seconds 3
                if (-not (Test-Path $outputFile)) {
                    Write-Host "  PDF not in current dir, checking temp..." -ForegroundColor Cyan
                    $tempDirs = Get-ChildItem -Path "$env:TEMP" -Filter "media-*" -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
                    $pdfCopied = $false
                    foreach ($dir in $tempDirs) {
                        $tempPdf = Get-ChildItem -Path $dir.FullName -Filter "*.pdf" -ErrorAction SilentlyContinue | Select-Object -First 1
                        if ($tempPdf) {
                            Write-Host "  Found temp PDF: $($tempPdf.FullName)" -ForegroundColor Cyan
                            Copy-Item -Path $tempPdf.FullName -Destination $outputFile -Force
                            Write-Host "  Copied to $outputFile" -ForegroundColor Green
                            $pdfCopied = $true
                            break
                        }
                    }
                    if (-not $pdfCopied) {
                        Write-Host "  Error: PDF not found in temp directories" -ForegroundColor Red
                    }
                }
                Set-Location ..
            }
            "article-tex" {
                Write-Host "[Building article TeX...]" -ForegroundColor Yellow
                Set-Location "article"
                & pandoc $PandocDefaults --defaults=tex.yaml
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
                    & pandoc $PandocDefaults --defaults=$f.yaml -f markdown -o "${outputBaseName}.$f" metadata.yaml $ContentFile
                }
                Set-Location ..
            }
            "thesis" {
                Write-Host "[Building thesis...]" -ForegroundColor Yellow
                Set-Location "thesis"
                & pandoc $PandocDefaults --defaults=docx.yaml
                & pandoc $PandocDefaults --defaults=epub.yaml
                & pandoc $PandocDefaults --defaults=pdf.yaml
                & pandoc $PandocDefaults --defaults=tex.yaml
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
