#!/usr/bin/env pwsh
# 为 feature 生成实现计划（plan.md）

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# 若请求则显示帮助
if ($Help) {
    Write-Output "用法：./setup-plan.ps1 [-Json] [-Help]"
    Write-Output "  -Json     以 JSON 格式输出结果"
    Write-Output "  -Help     显示帮助信息"
    exit 0
}

# 加载共用函数
. "$PSScriptRoot/common.ps1"

# 从共用函数获取所有路径与变量
$paths = Get-FeaturePathsEnv

# 检查是否处于正确的 feature 分支（仅对 git 仓库执行）
if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit $paths.HAS_GIT)) { 
    exit 1 
}

# 确保 feature 目录存在
New-Item -ItemType Directory -Path $paths.FEATURE_DIR -Force | Out-Null

# 若存在 plan 模板则复制，否则提示并创建空文件
$template = Join-Path $paths.REPO_ROOT '.specify/templates/plan-template.md'
if (Test-Path $template) { 
    Copy-Item $template $paths.IMPL_PLAN -Force
    Write-Output "已将 plan 模板复制到 $($paths.IMPL_PLAN)"
} else {
    Write-Warning "未找到 plan 模板：$template"
    # 若模板不存在则创建一个空的 plan 文件
    New-Item -ItemType File -Path $paths.IMPL_PLAN -Force | Out-Null
}

# 输出结果
if ($Json) {
    $result = [PSCustomObject]@{ 
        FEATURE_SPEC = $paths.FEATURE_SPEC
        IMPL_PLAN = $paths.IMPL_PLAN
        SPECS_DIR = $paths.FEATURE_DIR
        BRANCH = $paths.CURRENT_BRANCH
        HAS_GIT = $paths.HAS_GIT
    }
    $result | ConvertTo-Json -Compress
} else {
    Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
    Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
    Write-Output "SPECS_DIR: $($paths.FEATURE_DIR)"
    Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
    Write-Output "HAS_GIT: $($paths.HAS_GIT)"
}
