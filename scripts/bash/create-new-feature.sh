#!/usr/bin/env bash

set -e

JSON_MODE=false
SHORT_NAME=""
BRANCH_NUMBER=""
ARGS=()
i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --json) 
            JSON_MODE=true 
            ;;
        --short-name)
            if [ $((i + 1)) -gt $# ]; then
                echo '错误：--short-name 需要一个值' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            # Check if the next argument is another option (starts with --)
            if [[ "$next_arg" == --* ]]; then
                echo '错误：--short-name 需要一个值' >&2
                exit 1
            fi
            SHORT_NAME="$next_arg"
            ;;
        --number)
            if [ $((i + 1)) -gt $# ]; then
                echo '错误：--number 需要一个值' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo '错误：--number 需要一个值' >&2
                exit 1
            fi
            BRANCH_NUMBER="$next_arg"
            ;;
        --help|-h) 
            echo "用法：$0 [--json] [--short-name <name>] [--number N] <feature_description>"
            echo ""
            echo "选项："
            echo "  --json              以 JSON 格式输出"
            echo "  --short-name <name> 为分支提供自定义短名称（2-4 个词）"
            echo "  --number N          手动指定分支编号（覆盖自动检测）"
            echo "  --help, -h          显示帮助信息"
            echo ""
            echo "示例："
            echo "  $0 '新增用户认证系统' --short-name 'user-auth'"
            echo "  $0 '为 API 实现 OAuth2 集成' --number 5"
            exit 0
            ;;
        *) 
            ARGS+=("$arg") 
            ;;
    esac
    i=$((i + 1))
done

FEATURE_DESCRIPTION="${ARGS[*]}"
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "用法：$0 [--json] [--short-name <name>] [--number N] <feature_description>" >&2
    exit 1
fi

# 通过搜索现有项目标记定位仓库根目录
find_repo_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ] || [ -d "$dir/.specify" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# 从 specs 目录获取最大编号
get_highest_from_specs() {
    local specs_dir="$1"
    local highest=0
    
    if [ -d "$specs_dir" ]; then
        for dir in "$specs_dir"/*; do
            [ -d "$dir" ] || continue
            dirname=$(basename "$dir")
            number=$(echo "$dirname" | grep -o '^[0-9]\+' || echo "0")
            number=$((10#$number))
            if [ "$number" -gt "$highest" ]; then
                highest=$number
            fi
        done
    fi
    
    echo "$highest"
}

# 从 git 分支获取最大编号
get_highest_from_branches() {
    local highest=0
    
    # 获取所有分支（本地与远端）
    branches=$(git branch -a 2>/dev/null || echo "")
    
    if [ -n "$branches" ]; then
        while IFS= read -r branch; do
            # 清洗分支名：移除前缀标记与远端前缀
            clean_branch=$(echo "$branch" | sed 's/^[* ]*//; s|^remotes/[^/]*/||')
            
            # 若分支匹配 ###-* 模式，则提取 feature 编号
            if echo "$clean_branch" | grep -q '^[0-9]\{3\}-'; then
                number=$(echo "$clean_branch" | grep -o '^[0-9]\{3\}' || echo "0")
                number=$((10#$number))
                if [ "$number" -gt "$highest" ]; then
                    highest=$number
                fi
            fi
        done <<< "$branches"
    fi
    
    echo "$highest"
}

# 检查已有分支（本地与远端）并返回下一个可用编号
check_existing_branches() {
    local specs_dir="$1"

    # 拉取所有远端以获取最新分支信息（若无远端则忽略错误）
    git fetch --all --prune 2>/dev/null || true

    # 从所有分支中取最大编号（不只匹配 short name）
    local highest_branch=$(get_highest_from_branches)

    # 从所有 specs 中取最大编号（不只匹配 short name）
    local highest_spec=$(get_highest_from_specs "$specs_dir")

    # 取两者的最大值
    local max_num=$highest_branch
    if [ "$highest_spec" -gt "$max_num" ]; then
        max_num=$highest_spec
    fi

    # 返回下一个编号
    echo $((max_num + 1))
}

# 清洗并格式化分支名
clean_branch_name() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//'
}

# 解析仓库根目录：优先使用 git 信息；若不可用，则回退到搜索仓库标记，
# 以便在使用 --no-git 初始化的仓库中也能工作。
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
    HAS_GIT=true
else
    REPO_ROOT="$(find_repo_root "$SCRIPT_DIR")"
    if [ -z "$REPO_ROOT" ]; then
        echo "错误：无法确定仓库根目录。请在仓库内运行该脚本。" >&2
        exit 1
    fi
    HAS_GIT=false
fi

cd "$REPO_ROOT"

SPECS_DIR="$REPO_ROOT/specs"
mkdir -p "$SPECS_DIR"

# 生成分支名（过滤停用词并限制长度）
generate_branch_name() {
    local description="$1"
    
    # 常见停用词（会被过滤）
    local stop_words="^(i|a|an|the|to|for|of|in|on|at|by|with|from|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|should|could|can|may|might|must|shall|this|that|these|those|my|your|our|their|want|need|add|get|set)$"
    
    # 转为小写并按词拆分
    local clean_name=$(echo "$description" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g')
    
    # 过滤：移除停用词与长度 < 3 的词（除非它们在原文中以大写形式出现，可能是缩写）
    local meaningful_words=()
    for word in $clean_name; do
        # 跳过空词
        [ -z "$word" ] && continue
        
        # 保留：非停用词，且（长度 >= 3 或可能是缩写）
        if ! echo "$word" | grep -qiE "$stop_words"; then
            if [ ${#word} -ge 3 ]; then
                meaningful_words+=("$word")
            elif echo "$description" | grep -q "\b${word^^}\b"; then
                # 若短词在原文中以大写出现，则保留（可能是缩写）
                meaningful_words+=("$word")
            fi
        fi
    done
    
    # 若存在有效词，则取前 3–4 个
    if [ ${#meaningful_words[@]} -gt 0 ]; then
        local max_words=3
        if [ ${#meaningful_words[@]} -eq 4 ]; then max_words=4; fi
        
        local result=""
        local count=0
        for word in "${meaningful_words[@]}"; do
            if [ $count -ge $max_words ]; then break; fi
            if [ -n "$result" ]; then result="$result-"; fi
            result="$result$word"
            count=$((count + 1))
        done
        echo "$result"
    else
        # 若未找到有效词，则回退到原始逻辑
        local cleaned=$(clean_branch_name "$description")
        echo "$cleaned" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//'
    fi
}

# 生成分支名
if [ -n "$SHORT_NAME" ]; then
    # 使用用户提供的短名称（仅清洗）
    BRANCH_SUFFIX=$(clean_branch_name "$SHORT_NAME")
else
    # 基于描述智能生成
    BRANCH_SUFFIX=$(generate_branch_name "$FEATURE_DESCRIPTION")
fi

# 确定分支编号
if [ -z "$BRANCH_NUMBER" ]; then
    if [ "$HAS_GIT" = true ]; then
        # 检查远端已有分支
        BRANCH_NUMBER=$(check_existing_branches "$SPECS_DIR")
    else
        # 回退到本地目录检查
        HIGHEST=$(get_highest_from_specs "$SPECS_DIR")
        BRANCH_NUMBER=$((HIGHEST + 1))
    fi
fi

# 强制按十进制解释，避免八进制转换（例如 010 在八进制是 8，但十进制应为 10）
FEATURE_NUM=$(printf "%03d" "$((10#$BRANCH_NUMBER))")
BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"

# GitHub 对分支名有 244 字节限制
# 如有需要则校验并截断
MAX_BRANCH_LENGTH=244
if [ ${#BRANCH_NAME} -gt $MAX_BRANCH_LENGTH ]; then
    # 计算需要从后缀裁剪的长度
    # 需要扣除：feature 编号（3）+ 连字符（1）= 4 个字符
    MAX_SUFFIX_LENGTH=$((MAX_BRANCH_LENGTH - 4))
    
    # 尽可能在词边界截断后缀
    TRUNCATED_SUFFIX=$(echo "$BRANCH_SUFFIX" | cut -c1-$MAX_SUFFIX_LENGTH)
    # 若截断产生尾部连字符，则移除
    TRUNCATED_SUFFIX=$(echo "$TRUNCATED_SUFFIX" | sed 's/-$//')
    
    ORIGINAL_BRANCH_NAME="$BRANCH_NAME"
    BRANCH_NAME="${FEATURE_NUM}-${TRUNCATED_SUFFIX}"
    
    >&2 echo "[specify] 警告：分支名超过 GitHub 的 244 字节限制"
    >&2 echo "[specify] 原始值：$ORIGINAL_BRANCH_NAME（${#ORIGINAL_BRANCH_NAME} 字节）"
    >&2 echo "[specify] 已截断为：$BRANCH_NAME（${#BRANCH_NAME} 字节）"
fi

if [ "$HAS_GIT" = true ]; then
    git checkout -b "$BRANCH_NAME"
else
    >&2 echo "[specify] 警告：未检测到 Git 仓库；已跳过为 $BRANCH_NAME 创建分支"
fi

FEATURE_DIR="$SPECS_DIR/$BRANCH_NAME"
mkdir -p "$FEATURE_DIR"

TEMPLATE="$REPO_ROOT/.specify/templates/spec-template.md"
SPEC_FILE="$FEATURE_DIR/spec.md"
if [ -f "$TEMPLATE" ]; then cp "$TEMPLATE" "$SPEC_FILE"; else touch "$SPEC_FILE"; fi

# 为当前会话设置 SPECIFY_FEATURE 环境变量
export SPECIFY_FEATURE="$BRANCH_NAME"

if $JSON_MODE; then
    printf '{"BRANCH_NAME":"%s","SPEC_FILE":"%s","FEATURE_NUM":"%s"}\n' "$BRANCH_NAME" "$SPEC_FILE" "$FEATURE_NUM"
else
    echo "BRANCH_NAME: $BRANCH_NAME"
    echo "SPEC_FILE: $SPEC_FILE"
    echo "FEATURE_NUM: $FEATURE_NUM"
    echo "已设置 SPECIFY_FEATURE 环境变量为：$BRANCH_NAME"
fi
