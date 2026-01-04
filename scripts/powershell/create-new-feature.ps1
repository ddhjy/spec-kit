#!/usr/bin/env pwsh
# 创建新 feature
[CmdletBinding()]
param(
    [switch]$Json,
    [string]$ShortName,
    [int]$Number = 0,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FeatureDescription
)
$ErrorActionPreference = 'Stop'

# 若请求则显示帮助
if ($Help) {
    Write-Host "用法：./create-new-feature.ps1 [-Json] [-ShortName <name>] [-Number N] <feature description>"
    Write-Host ""
    Write-Host "选项："
    Write-Host "  -Json               以 JSON 格式输出"
    Write-Host "  -ShortName <name>   为分支提供自定义短名称（2-4 个词）"
    Write-Host "  -Number N           手动指定分支编号（覆盖自动检测）"
    Write-Host "  -Help               显示帮助信息"
    Write-Host ""
    Write-Host "示例："
    Write-Host "  ./create-new-feature.ps1 '新增用户认证系统' -ShortName 'user-auth'"
    Write-Host "  ./create-new-feature.ps1 '为 API 实现 OAuth2 集成'"
    exit 0
}

# 检查是否提供了 feature 描述
if (-not $FeatureDescription -or $FeatureDescription.Count -eq 0) {
    Write-Error "用法：./create-new-feature.ps1 [-Json] [-ShortName <name>] <feature description>"
    exit 1
}

$featureDesc = ($FeatureDescription -join ' ').Trim()

# 解析仓库根目录：优先使用 git 信息；若不可用，则回退到搜索仓库标记，
# 以便在使用 --no-git 初始化的仓库中也能工作。
function Find-RepositoryRoot {
    param(
        [string]$StartDir,
        [string[]]$Markers = @('.git', '.specify')
    )
    $current = Resolve-Path $StartDir
    while ($true) {
        foreach ($marker in $Markers) {
            if (Test-Path (Join-Path $current $marker)) {
                return $current
            }
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) {
            # Reached filesystem root without finding markers
            return $null
        }
        $current = $parent
    }
}

function Get-HighestNumberFromSpecs {
    param([string]$SpecsDir)
    
    $highest = 0
    if (Test-Path $SpecsDir) {
        Get-ChildItem -Path $SpecsDir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d+)') {
                $num = [int]$matches[1]
                if ($num -gt $highest) { $highest = $num }
            }
        }
    }
    return $highest
}

function Get-HighestNumberFromBranches {
    param()
    
    $highest = 0
    try {
        $branches = git branch -a 2>$null
        if ($LASTEXITCODE -eq 0) {
            foreach ($branch in $branches) {
                # Clean branch name: remove leading markers and remote prefixes
                $cleanBranch = $branch.Trim() -replace '^\*?\s+', '' -replace '^remotes/[^/]+/', ''
                
                # Extract feature number if branch matches pattern ###-*
                if ($cleanBranch -match '^(\d+)-') {
                    $num = [int]$matches[1]
                    if ($num -gt $highest) { $highest = $num }
                }
            }
        }
    } catch {
        # If git command fails, return 0
        Write-Verbose "Could not check Git branches: $_"
    }
    return $highest
}

function Get-NextBranchNumber {
    param(
        [string]$SpecsDir
    )

    # Fetch all remotes to get latest branch info (suppress errors if no remotes)
    try {
        git fetch --all --prune 2>$null | Out-Null
    } catch {
        # Ignore fetch errors
    }

    # Get highest number from ALL branches (not just matching short name)
    $highestBranch = Get-HighestNumberFromBranches

    # Get highest number from ALL specs (not just matching short name)
    $highestSpec = Get-HighestNumberFromSpecs -SpecsDir $SpecsDir

    # Take the maximum of both
    $maxNum = [Math]::Max($highestBranch, $highestSpec)

    # Return next number
    return $maxNum + 1
}

function ConvertTo-CleanBranchName {
    param([string]$Name)
    
    return $Name.ToLower() -replace '[^a-z0-9]', '-' -replace '-{2,}', '-' -replace '^-', '' -replace '-$', ''
}
$fallbackRoot = (Find-RepositoryRoot -StartDir $PSScriptRoot)
if (-not $fallbackRoot) {
    Write-Error "错误：无法确定仓库根目录。请在仓库内运行该脚本。"
    exit 1
}

try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0) {
        $hasGit = $true
    } else {
        throw "Git not available"
    }
} catch {
    $repoRoot = $fallbackRoot
    $hasGit = $false
}

Set-Location $repoRoot

$specsDir = Join-Path $repoRoot 'specs'
New-Item -ItemType Directory -Path $specsDir -Force | Out-Null

# 生成分支名（过滤停用词并限制长度）
function Get-BranchName {
    param([string]$Description)
    
    # 常见停用词（会被过滤）
    $stopWords = @(
        'i', 'a', 'an', 'the', 'to', 'for', 'of', 'in', 'on', 'at', 'by', 'with', 'from',
        'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
        'do', 'does', 'did', 'will', 'would', 'should', 'could', 'can', 'may', 'might', 'must', 'shall',
        'this', 'that', 'these', 'those', 'my', 'your', 'our', 'their',
        'want', 'need', 'add', 'get', 'set'
    )
    
    # 转为小写并提取词（仅保留字母数字）
    $cleanName = $Description.ToLower() -replace '[^a-z0-9\s]', ' '
    $words = $cleanName -split '\s+' | Where-Object { $_ }
    
    # 过滤：移除停用词与长度 < 3 的词（除非它们在原文中以大写形式出现，可能是缩写）
    $meaningfulWords = @()
    foreach ($word in $words) {
        # 跳过停用词
        if ($stopWords -contains $word) { continue }
        
        # 保留：长度 >= 3 的词；或在原文中以大写出现（可能是缩写）
        if ($word.Length -ge 3) {
            $meaningfulWords += $word
        } elseif ($Description -match "\b$($word.ToUpper())\b") {
            # 若短词在原文中以大写出现，则保留（可能是缩写）
            $meaningfulWords += $word
        }
    }
    
    # 若存在有效词，则取前 3–4 个
    if ($meaningfulWords.Count -gt 0) {
        $maxWords = if ($meaningfulWords.Count -eq 4) { 4 } else { 3 }
        $result = ($meaningfulWords | Select-Object -First $maxWords) -join '-'
        return $result
    } else {
        # 若未找到有效词，则回退到原始逻辑
        $result = ConvertTo-CleanBranchName -Name $Description
        $fallbackWords = ($result -split '-') | Where-Object { $_ } | Select-Object -First 3
        return [string]::Join('-', $fallbackWords)
    }
}

# 生成分支名
if ($ShortName) {
    # 使用用户提供的短名称（仅清洗）
    $branchSuffix = ConvertTo-CleanBranchName -Name $ShortName
} else {
    # 基于描述智能生成
    $branchSuffix = Get-BranchName -Description $featureDesc
}

# 确定分支编号
if ($Number -eq 0) {
    if ($hasGit) {
        # 检查远端已有分支
        $Number = Get-NextBranchNumber -SpecsDir $specsDir
    } else {
        # 回退到本地目录检查
        $Number = (Get-HighestNumberFromSpecs -SpecsDir $specsDir) + 1
    }
}

$featureNum = ('{0:000}' -f $Number)
$branchName = "$featureNum-$branchSuffix"

# GitHub 对分支名有 244 字节限制
# 如有需要则校验并截断
$maxBranchLength = 244
if ($branchName.Length -gt $maxBranchLength) {
    # 计算需要从后缀裁剪的长度
    # 需要扣除：feature 编号（3）+ 连字符（1）= 4 个字符
    $maxSuffixLength = $maxBranchLength - 4
    
    # 截断后缀
    $truncatedSuffix = $branchSuffix.Substring(0, [Math]::Min($branchSuffix.Length, $maxSuffixLength))
    # 若截断产生尾部连字符，则移除
    $truncatedSuffix = $truncatedSuffix -replace '-$', ''
    
    $originalBranchName = $branchName
    $branchName = "$featureNum-$truncatedSuffix"
    
        Write-Warning "[specify] 警告：分支名超过 GitHub 的 244 字节限制"
        Write-Warning "[specify] 原始值：$originalBranchName（$($originalBranchName.Length) 字节）"
        Write-Warning "[specify] 已截断为：$branchName（$($branchName.Length) 字节）"
}

if ($hasGit) {
    try {
        git checkout -b $branchName | Out-Null
    } catch {
        Write-Warning "创建 git 分支失败：$branchName"
    }
} else {
    Write-Warning "[specify] 警告：未检测到 Git 仓库；已跳过为 $branchName 创建分支"
}

$featureDir = Join-Path $specsDir $branchName
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null

$template = Join-Path $repoRoot '.specify/templates/spec-template.md'
$specFile = Join-Path $featureDir 'spec.md'
if (Test-Path $template) { 
    Copy-Item $template $specFile -Force 
} else { 
    New-Item -ItemType File -Path $specFile | Out-Null 
}

# 为当前会话设置 SPECIFY_FEATURE 环境变量
$env:SPECIFY_FEATURE = $branchName

if ($Json) {
    $obj = [PSCustomObject]@{ 
        BRANCH_NAME = $branchName
        SPEC_FILE = $specFile
        FEATURE_NUM = $featureNum
        HAS_GIT = $hasGit
    }
    $obj | ConvertTo-Json -Compress
} else {
    Write-Output "BRANCH_NAME: $branchName"
    Write-Output "SPEC_FILE: $specFile"
    Write-Output "FEATURE_NUM: $featureNum"
    Write-Output "HAS_GIT: $hasGit"
    Write-Output "已设置 SPECIFY_FEATURE 环境变量为：$branchName"
}

