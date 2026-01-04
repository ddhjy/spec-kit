#!/usr/bin/env bash

# 统一的前置条件检查脚本
#
# 本脚本为规格驱动开发（SDD）工作流提供统一的前置条件检查。
# 它替代了此前分散在多个脚本中的同类功能。
#
# 用法：./check-prerequisites.sh [OPTIONS]
#
# OPTIONS：
#   --json              以 JSON 格式输出
#   --require-tasks     要求 tasks.md 存在（实现阶段使用）
#   --include-tasks     在 AVAILABLE_DOCS 列表中包含 tasks.md
#   --paths-only        仅输出路径变量（不做校验）
#   --help, -h          显示帮助信息
#
# 输出（OUTPUTS）：
#   JSON 模式：{"FEATURE_DIR":"...", "AVAILABLE_DOCS":["..."]}
#   文本模式：FEATURE_DIR:... \n AVAILABLE_DOCS: \n ✓/✗ file.md
#   仅路径模式：REPO_ROOT: ... \n BRANCH: ... \n FEATURE_DIR: ... 等

set -e

# 解析命令行参数
JSON_MODE=false
REQUIRE_TASKS=false
INCLUDE_TASKS=false
PATHS_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --require-tasks)
            REQUIRE_TASKS=true
            ;;
        --include-tasks)
            INCLUDE_TASKS=true
            ;;
        --paths-only)
            PATHS_ONLY=true
            ;;
        --help|-h)
            cat << 'EOF'
用法：check-prerequisites.sh [OPTIONS]

用于规格驱动开发（SDD）工作流的统一前置条件检查。

OPTIONS：
  --json              以 JSON 格式输出
  --require-tasks     要求 tasks.md 存在（实现阶段使用）
  --include-tasks     在 AVAILABLE_DOCS 列表中包含 tasks.md
  --paths-only        仅输出路径变量（不做前置条件校验）
  --help, -h          显示帮助信息

示例（EXAMPLES）：
  # 检查任务生成前置条件（需要 plan.md）
  ./check-prerequisites.sh --json
  
  # 检查实现阶段前置条件（需要 plan.md + tasks.md）
  ./check-prerequisites.sh --json --require-tasks --include-tasks
  
  # 仅获取 feature 路径（不做校验）
  ./check-prerequisites.sh --paths-only
  
EOF
            exit 0
            ;;
        *)
            echo "错误：未知选项 '$arg'。使用 --help 查看用法说明。" >&2
            exit 1
            ;;
    esac
done

# 引入共用函数
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 获取 feature 路径并校验分支
eval $(get_feature_paths)
check_feature_branch "$CURRENT_BRANCH" "$HAS_GIT" || exit 1

# 若为仅路径模式：输出路径并退出（支持与 JSON 模式同时启用）
if $PATHS_ONLY; then
    if $JSON_MODE; then
        # 最小 JSON 路径载荷（不做校验）
        printf '{"REPO_ROOT":"%s","BRANCH":"%s","FEATURE_DIR":"%s","FEATURE_SPEC":"%s","IMPL_PLAN":"%s","TASKS":"%s"}\n' \
            "$REPO_ROOT" "$CURRENT_BRANCH" "$FEATURE_DIR" "$FEATURE_SPEC" "$IMPL_PLAN" "$TASKS"
    else
        echo "REPO_ROOT: $REPO_ROOT"
        echo "BRANCH: $CURRENT_BRANCH"
        echo "FEATURE_DIR: $FEATURE_DIR"
        echo "FEATURE_SPEC: $FEATURE_SPEC"
        echo "IMPL_PLAN: $IMPL_PLAN"
        echo "TASKS: $TASKS"
    fi
    exit 0
fi

# 校验必需目录与文件
if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "错误：未找到 feature 目录：$FEATURE_DIR" >&2
    echo "请先运行 /speckit.specify 创建 feature 结构。" >&2
    exit 1
fi

if [[ ! -f "$IMPL_PLAN" ]]; then
    echo "错误：在 $FEATURE_DIR 中未找到 plan.md" >&2
    echo "请先运行 /speckit.plan 创建实现计划。" >&2
    exit 1
fi

# 若需要则检查 tasks.md
if $REQUIRE_TASKS && [[ ! -f "$TASKS" ]]; then
    echo "错误：在 $FEATURE_DIR 中未找到 tasks.md" >&2
    echo "请先运行 /speckit.tasks 创建任务清单。" >&2
    exit 1
fi

# 构建可用文档列表
docs=()

# 始终检查这些可选文档
[[ -f "$RESEARCH" ]] && docs+=("research.md")
[[ -f "$DATA_MODEL" ]] && docs+=("data-model.md")

# 检查 contracts 目录（仅当存在且非空时）
if [[ -d "$CONTRACTS_DIR" ]] && [[ -n "$(ls -A "$CONTRACTS_DIR" 2>/dev/null)" ]]; then
    docs+=("contracts/")
fi

[[ -f "$QUICKSTART" ]] && docs+=("quickstart.md")

# 若请求包含且文件存在，则加入 tasks.md
if $INCLUDE_TASKS && [[ -f "$TASKS" ]]; then
    docs+=("tasks.md")
fi

# 输出结果
if $JSON_MODE; then
    # 构建文档 JSON 数组
    if [[ ${#docs[@]} -eq 0 ]]; then
        json_docs="[]"
    else
        json_docs=$(printf '"%s",' "${docs[@]}")
        json_docs="[${json_docs%,}]"
    fi
    
    printf '{"FEATURE_DIR":"%s","AVAILABLE_DOCS":%s}\n' "$FEATURE_DIR" "$json_docs"
else
    # 文本输出
    echo "FEATURE_DIR:$FEATURE_DIR"
    echo "AVAILABLE_DOCS:"
    
    # 显示各潜在文档的状态
    check_file "$RESEARCH" "research.md"
    check_file "$DATA_MODEL" "data-model.md"
    check_dir "$CONTRACTS_DIR" "contracts/"
    check_file "$QUICKSTART" "quickstart.md"
    
    if $INCLUDE_TASKS; then
        check_file "$TASKS" "tasks.md"
    fi
fi
