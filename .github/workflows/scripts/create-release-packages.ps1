#!/usr/bin/env pwsh
#requires -Version 7.0

<#
.SYNOPSIS
    为每个已支持的 AI assistant 与脚本类型构建 Spec Kit 模板的 release 压缩包。

.DESCRIPTION
    create-release-packages.ps1（工作流内部脚本）
    为每个已支持的 AI assistant 与脚本类型构建 Spec Kit 模板的 release 压缩包。
    
.PARAMETER Version
    带前缀 'v' 的版本字符串（例如 v0.2.0）

.PARAMETER Agents
    以逗号或空格分隔的 agent 子集（默认：全部）
    合法 agent：claude、gemini、copilot、cursor-agent、qwen、opencode、windsurf、codex、kilocode、auggie、roo、codebuddy、amp、q、bob、qoder

.PARAMETER Scripts
    以逗号或空格分隔的脚本类型子集（默认：两者）
    合法脚本类型：sh、ps

.EXAMPLE
    .\create-release-packages.ps1 -Version v0.2.0

.EXAMPLE
    .\create-release-packages.ps1 -Version v0.2.0 -Agents claude,copilot -Scripts sh

.EXAMPLE
    .\create-release-packages.ps1 -Version v0.2.0 -Agents claude -Scripts ps
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Agents = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Scripts = ""
)

$ErrorActionPreference = "Stop"

# 校验版本号格式
if ($Version -notmatch '^v\d+\.\d+\.\d+$') {
    Write-Error "版本号格式必须类似 v0.0.0"
    exit 1
}

Write-Host "正在为 $Version 构建 release 包"

# 创建并使用 .genreleases 目录存放所有构建产物
$GenReleasesDir = ".genreleases"
if (Test-Path $GenReleasesDir) {
    Remove-Item -Path $GenReleasesDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $GenReleasesDir -Force | Out-Null

function Rewrite-Paths {
    param([string]$Content)
    
    $Content = $Content -replace '(/?)\bmemory/', '.specify/memory/'
    $Content = $Content -replace '(/?)\bscripts/', '.specify/scripts/'
    $Content = $Content -replace '(/?)\btemplates/', '.specify/templates/'
    return $Content
}

function Generate-Commands {
    param(
        [string]$Agent,
        [string]$Extension,
        [string]$ArgFormat,
        [string]$OutputDir,
        [string]$ScriptVariant
    )
    
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    
    $templates = Get-ChildItem -Path "templates/commands/*.md" -File -ErrorAction SilentlyContinue
    
    foreach ($template in $templates) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($template.Name)
        
        # 读取文件内容并规范化换行符
        $fileContent = (Get-Content -Path $template.FullName -Raw) -replace "`r`n", "`n"
        
        # 从 YAML frontmatter 提取 description
        $description = ""
        if ($fileContent -match '(?m)^description:\s*(.+)$') {
            $description = $matches[1]
        }
        
        # 从 YAML frontmatter 提取脚本命令
        $scriptCommand = ""
        if ($fileContent -match "(?m)^\s*${ScriptVariant}:\s*(.+)$") {
            $scriptCommand = $matches[1]
        }
        
        if ([string]::IsNullOrEmpty($scriptCommand)) {
            Write-Warning "在 $($template.Name) 中未找到 $ScriptVariant 对应的脚本命令"
            $scriptCommand = "（缺失 $ScriptVariant 对应的脚本命令）"
        }
        
        # 若存在则从 YAML frontmatter 提取 agent_script 命令
        $agentScriptCommand = ""
        if ($fileContent -match "(?ms)agent_scripts:.*?^\s*${ScriptVariant}:\s*(.+?)$") {
            $agentScriptCommand = $matches[1].Trim()
        }
        
        # 用脚本命令替换 {SCRIPT} 占位符
        $body = $fileContent -replace '\{SCRIPT\}', $scriptCommand
        
        # 若存在 agent_script 命令，则替换 {AGENT_SCRIPT} 占位符
        if (-not [string]::IsNullOrEmpty($agentScriptCommand)) {
            $body = $body -replace '\{AGENT_SCRIPT\}', $agentScriptCommand
        }
        
        # 从 frontmatter 中移除 scripts: 与 agent_scripts: 章节
        $lines = $body -split "`n"
        $outputLines = @()
        $inFrontmatter = $false
        $skipScripts = $false
        $dashCount = 0
        
        foreach ($line in $lines) {
            if ($line -match '^---$') {
                $outputLines += $line
                $dashCount++
                if ($dashCount -eq 1) {
                    $inFrontmatter = $true
                } else {
                    $inFrontmatter = $false
                }
                continue
            }
            
            if ($inFrontmatter) {
                if ($line -match '^(scripts|agent_scripts):$') {
                    $skipScripts = $true
                    continue
                }
                if ($line -match '^[a-zA-Z].*:' -and $skipScripts) {
                    $skipScripts = $false
                }
                if ($skipScripts -and $line -match '^\s+') {
                    continue
                }
            }
            
            $outputLines += $line
        }
        
        $body = $outputLines -join "`n"
        
        # 应用其他替换
        $body = $body -replace '\{ARGS\}', $ArgFormat
        $body = $body -replace '__AGENT__', $Agent
        $body = Rewrite-Paths -Content $body
        
        # 根据扩展名生成输出文件
        $outputFile = Join-Path $OutputDir "speckit.$name.$Extension"
        
        switch ($Extension) {
            'toml' {
                $body = $body -replace '\\', '\\'
                $output = "description = `"$description`"`n`nprompt = `"`"`"`n$body`n`"`"`""
                Set-Content -Path $outputFile -Value $output -NoNewline
            }
            'md' {
                Set-Content -Path $outputFile -Value $body -NoNewline
            }
            'agent.md' {
                Set-Content -Path $outputFile -Value $body -NoNewline
            }
        }
    }
}

function Generate-CopilotPrompts {
    param(
        [string]$AgentsDir,
        [string]$PromptsDir
    )
    
    New-Item -ItemType Directory -Path $PromptsDir -Force | Out-Null
    
    $agentFiles = Get-ChildItem -Path "$AgentsDir/speckit.*.agent.md" -File -ErrorAction SilentlyContinue
    
    foreach ($agentFile in $agentFiles) {
        $basename = $agentFile.Name -replace '\.agent\.md$', ''
        $promptFile = Join-Path $PromptsDir "$basename.prompt.md"
        
        $content = @"
---
agent: $basename
---
"@
        Set-Content -Path $promptFile -Value $content
    }
}

function Build-Variant {
    param(
        [string]$Agent,
        [string]$Script
    )
    
    $baseDir = Join-Path $GenReleasesDir "sdd-${Agent}-package-${Script}"
    Write-Host "Building $Agent ($Script) package..."
    New-Item -ItemType Directory -Path $baseDir -Force | Out-Null
    
    # 复制基础结构，但按变体过滤 scripts
    $specDir = Join-Path $baseDir ".specify"
    New-Item -ItemType Directory -Path $specDir -Force | Out-Null
    
    # 复制 memory 目录
    if (Test-Path "memory") {
        Copy-Item -Path "memory" -Destination $specDir -Recurse -Force
        Write-Host "已复制 memory -> .specify"
    }
    
    # 只复制对应的脚本变体目录
    if (Test-Path "scripts") {
        $scriptsDestDir = Join-Path $specDir "scripts"
        New-Item -ItemType Directory -Path $scriptsDestDir -Force | Out-Null
        
        switch ($Script) {
            'sh' {
                if (Test-Path "scripts/bash") {
                    Copy-Item -Path "scripts/bash" -Destination $scriptsDestDir -Recurse -Force
                    Write-Host "已复制 scripts/bash -> .specify/scripts"
                }
            }
            'ps' {
                if (Test-Path "scripts/powershell") {
                    Copy-Item -Path "scripts/powershell" -Destination $scriptsDestDir -Recurse -Force
                    Write-Host "已复制 scripts/powershell -> .specify/scripts"
                }
            }
        }
        
        # 复制不在变体专用目录中的脚本文件
        Get-ChildItem -Path "scripts" -File -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $scriptsDestDir -Force
        }
    }
    
    # 复制 templates（排除 commands 目录与 vscode-settings.json）
    if (Test-Path "templates") {
        $templatesDestDir = Join-Path $specDir "templates"
        New-Item -ItemType Directory -Path $templatesDestDir -Force | Out-Null
        
        Get-ChildItem -Path "templates" -Recurse -File | Where-Object {
            $_.FullName -notmatch 'templates[/\\]commands[/\\]' -and $_.Name -ne 'vscode-settings.json'
        } | ForEach-Object {
            $relativePath = $_.FullName.Substring((Resolve-Path "templates").Path.Length + 1)
            $destFile = Join-Path $templatesDestDir $relativePath
            $destFileDir = Split-Path $destFile -Parent
            New-Item -ItemType Directory -Path $destFileDir -Force | Out-Null
            Copy-Item -Path $_.FullName -Destination $destFile -Force
        }
        Write-Host "已复制 templates -> .specify/templates"
    }
    
    # 生成 agent 专用命令文件
    switch ($Agent) {
        'claude' {
            $cmdDir = Join-Path $baseDir ".claude/commands"
            Generate-Commands -Agent 'claude' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'gemini' {
            $cmdDir = Join-Path $baseDir ".gemini/commands"
            Generate-Commands -Agent 'gemini' -Extension 'toml' -ArgFormat '{{args}}' -OutputDir $cmdDir -ScriptVariant $Script
            if (Test-Path "agent_templates/gemini/GEMINI.md") {
                Copy-Item -Path "agent_templates/gemini/GEMINI.md" -Destination (Join-Path $baseDir "GEMINI.md")
            }
        }
        'copilot' {
            $agentsDir = Join-Path $baseDir ".github/agents"
            Generate-Commands -Agent 'copilot' -Extension 'agent.md' -ArgFormat '$ARGUMENTS' -OutputDir $agentsDir -ScriptVariant $Script
            
            # 生成配套的 prompt 文件
            $promptsDir = Join-Path $baseDir ".github/prompts"
            Generate-CopilotPrompts -AgentsDir $agentsDir -PromptsDir $promptsDir
            
            # 创建 VS Code 工作区设置
            $vscodeDir = Join-Path $baseDir ".vscode"
            New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
            if (Test-Path "templates/vscode-settings.json") {
                Copy-Item -Path "templates/vscode-settings.json" -Destination (Join-Path $vscodeDir "settings.json")
            }
        }
        'cursor-agent' {
            $cmdDir = Join-Path $baseDir ".cursor/commands"
            Generate-Commands -Agent 'cursor-agent' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'qwen' {
            $cmdDir = Join-Path $baseDir ".qwen/commands"
            Generate-Commands -Agent 'qwen' -Extension 'toml' -ArgFormat '{{args}}' -OutputDir $cmdDir -ScriptVariant $Script
            if (Test-Path "agent_templates/qwen/QWEN.md") {
                Copy-Item -Path "agent_templates/qwen/QWEN.md" -Destination (Join-Path $baseDir "QWEN.md")
            }
        }
        'opencode' {
            $cmdDir = Join-Path $baseDir ".opencode/command"
            Generate-Commands -Agent 'opencode' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'windsurf' {
            $cmdDir = Join-Path $baseDir ".windsurf/workflows"
            Generate-Commands -Agent 'windsurf' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'codex' {
            $cmdDir = Join-Path $baseDir ".codex/prompts"
            Generate-Commands -Agent 'codex' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'kilocode' {
            $cmdDir = Join-Path $baseDir ".kilocode/workflows"
            Generate-Commands -Agent 'kilocode' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'auggie' {
            $cmdDir = Join-Path $baseDir ".augment/commands"
            Generate-Commands -Agent 'auggie' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'roo' {
            $cmdDir = Join-Path $baseDir ".roo/commands"
            Generate-Commands -Agent 'roo' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'codebuddy' {
            $cmdDir = Join-Path $baseDir ".codebuddy/commands"
            Generate-Commands -Agent 'codebuddy' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'amp' {
            $cmdDir = Join-Path $baseDir ".agents/commands"
            Generate-Commands -Agent 'amp' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'q' {
            $cmdDir = Join-Path $baseDir ".amazonq/prompts"
            Generate-Commands -Agent 'q' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'bob' {
            $cmdDir = Join-Path $baseDir ".bob/commands"
            Generate-Commands -Agent 'bob' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'qoder' {
            $cmdDir = Join-Path $baseDir ".qoder/commands"
            Generate-Commands -Agent 'qoder' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
    }
    
    # 创建 zip 压缩包
    $zipFile = Join-Path $GenReleasesDir "spec-kit-template-${Agent}-${Script}-${Version}.zip"
    Compress-Archive -Path "$baseDir/*" -DestinationPath $zipFile -Force
    Write-Host "Created $zipFile"
}

# 定义所有 agents 与 scripts
$AllAgents = @('claude', 'gemini', 'copilot', 'cursor-agent', 'qwen', 'opencode', 'windsurf', 'codex', 'kilocode', 'auggie', 'roo', 'codebuddy', 'amp', 'q', 'bob', 'qoder')
$AllScripts = @('sh', 'ps')

function Normalize-List {
    param([string]$Input)
    
    if ([string]::IsNullOrEmpty($Input)) {
        return @()
    }
    
    # 以逗号或空格分割，并在保持顺序的同时去重
    $items = $Input -split '[,\s]+' | Where-Object { $_ } | Select-Object -Unique
    return $items
}

function Validate-Subset {
    param(
        [string]$Type,
        [string[]]$Allowed,
        [string[]]$Items
    )
    
    $ok = $true
    foreach ($item in $Items) {
        if ($item -notin $Allowed) {
            Write-Error "Unknown $Type '$item' (allowed: $($Allowed -join ', '))"
            $ok = $false
        }
    }
    return $ok
}

# 确定 agent 列表
if (-not [string]::IsNullOrEmpty($Agents)) {
    $AgentList = Normalize-List -Input $Agents
    if (-not (Validate-Subset -Type 'agent' -Allowed $AllAgents -Items $AgentList)) {
        exit 1
    }
} else {
    $AgentList = $AllAgents
}

# 确定脚本列表
if (-not [string]::IsNullOrEmpty($Scripts)) {
    $ScriptList = Normalize-List -Input $Scripts
    if (-not (Validate-Subset -Type 'script' -Allowed $AllScripts -Items $ScriptList)) {
        exit 1
    }
} else {
    $ScriptList = $AllScripts
}

Write-Host "Agents: $($AgentList -join ', ')"
Write-Host "Scripts: $($ScriptList -join ', ')"

# 构建所有变体
foreach ($agent in $AgentList) {
    foreach ($script in $ScriptList) {
        Build-Variant -Agent $agent -Script $script
    }
}

Write-Host "`nArchives in ${GenReleasesDir}:"
Get-ChildItem -Path $GenReleasesDir -Filter "spec-kit-template-*-${Version}.zip" | ForEach-Object {
    Write-Host "  $($_.Name)"
}