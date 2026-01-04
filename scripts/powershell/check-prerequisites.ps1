#!/usr/bin/env pwsh

# 统一的前置条件检查脚本（PowerShell）
#
# 本脚本为规格驱动开发（SDD）工作流提供统一的前置条件检查。
# 它替代了此前分散在多个脚本中的同类功能。
#
# 用法：./check-prerequisites.ps1 [OPTIONS]
#
# OPTIONS：
#   -Json               以 JSON 格式输出
#   -RequireTasks       要求 tasks.md 存在（实现阶段使用）
#   -IncludeTasks       在 AVAILABLE_DOCS 列表中包含 tasks.md
#   -PathsOnly          仅输出路径变量（不做校验）
#   -Help, -h           显示帮助信息

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$RequireTasks,
    [switch]$IncludeTasks,
    [switch]$PathsOnly,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# 若请求则显示帮助
if ($Help) {
    Write-Output @"
用法：check-prerequisites.ps1 [OPTIONS]

用于规格驱动开发（SDD）工作流的统一前置条件检查。

OPTIONS：
  -Json               以 JSON 格式输出
  -RequireTasks       要求 tasks.md 存在（实现阶段使用）
  -IncludeTasks       在 AVAILABLE_DOCS 列表中包含 tasks.md
  -PathsOnly          仅输出路径变量（不做前置条件校验）
  -Help, -h           显示帮助信息

示例（EXAMPLES）：
  # 检查任务生成前置条件（需要 plan.md）
  .\check-prerequisites.ps1 -Json
  
  # 检查实现阶段前置条件（需要 plan.md + tasks.md）
  .\check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
  
  # 仅获取 feature 路径（不做校验）
  .\check-prerequisites.ps1 -PathsOnly

"@
    exit 0
}

# 引入共用函数
. "$PSScriptRoot/common.ps1"

# 获取 feature 路径并校验分支
$paths = Get-FeaturePathsEnv

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit:$paths.HAS_GIT)) { 
    exit 1 
}

# 若为仅路径模式：输出路径并退出（支持 -Json 与 -PathsOnly 同时启用）
if ($PathsOnly) {
    if ($Json) {
        [PSCustomObject]@{
            REPO_ROOT    = $paths.REPO_ROOT
            BRANCH       = $paths.CURRENT_BRANCH
            FEATURE_DIR  = $paths.FEATURE_DIR
            FEATURE_SPEC = $paths.FEATURE_SPEC
            IMPL_PLAN    = $paths.IMPL_PLAN
            TASKS        = $paths.TASKS
        } | ConvertTo-Json -Compress
    } else {
        Write-Output "REPO_ROOT: $($paths.REPO_ROOT)"
        Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
        Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
        Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
        Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
        Write-Output "TASKS: $($paths.TASKS)"
    }
    exit 0
}

# 校验必需目录与文件
if (-not (Test-Path $paths.FEATURE_DIR -PathType Container)) {
    Write-Output "错误：未找到 feature 目录：$($paths.FEATURE_DIR)"
    Write-Output "请先运行 /speckit.specify 创建 feature 结构。"
    exit 1
}

if (-not (Test-Path $paths.IMPL_PLAN -PathType Leaf)) {
    Write-Output "错误：在 $($paths.FEATURE_DIR) 中未找到 plan.md"
    Write-Output "请先运行 /speckit.plan 创建实现计划。"
    exit 1
}

# 若需要则检查 tasks.md
if ($RequireTasks -and -not (Test-Path $paths.TASKS -PathType Leaf)) {
    Write-Output "错误：在 $($paths.FEATURE_DIR) 中未找到 tasks.md"
    Write-Output "请先运行 /speckit.tasks 创建任务清单。"
    exit 1
}

# 构建可用文档列表
$docs = @()

# 始终检查这些可选文档
if (Test-Path $paths.RESEARCH) { $docs += 'research.md' }
if (Test-Path $paths.DATA_MODEL) { $docs += 'data-model.md' }

# 检查 contracts 目录（仅当存在且非空时）
if ((Test-Path $paths.CONTRACTS_DIR) -and (Get-ChildItem -Path $paths.CONTRACTS_DIR -ErrorAction SilentlyContinue | Select-Object -First 1)) { 
    $docs += 'contracts/' 
}

if (Test-Path $paths.QUICKSTART) { $docs += 'quickstart.md' }

# 若请求包含且文件存在，则加入 tasks.md
if ($IncludeTasks -and (Test-Path $paths.TASKS)) { 
    $docs += 'tasks.md' 
}

# 输出结果
if ($Json) {
    # JSON 输出
    [PSCustomObject]@{ 
        FEATURE_DIR = $paths.FEATURE_DIR
        AVAILABLE_DOCS = $docs 
    } | ConvertTo-Json -Compress
} else {
    # 文本输出
    Write-Output "FEATURE_DIR:$($paths.FEATURE_DIR)"
    Write-Output "AVAILABLE_DOCS:"
    
    # 显示各潜在文档的状态
    Test-FileExists -Path $paths.RESEARCH -Description 'research.md' | Out-Null
    Test-FileExists -Path $paths.DATA_MODEL -Description 'data-model.md' | Out-Null
    Test-DirHasFiles -Path $paths.CONTRACTS_DIR -Description 'contracts/' | Out-Null
    Test-FileExists -Path $paths.QUICKSTART -Description 'quickstart.md' | Out-Null
    
    if ($IncludeTasks) {
        Test-FileExists -Path $paths.TASKS -Description 'tasks.md' | Out-Null
    }
}
