#!/usr/bin/env bash
set -euo pipefail

# 脚本：generate-release-notes.sh
# 基于 git 历史生成 release notes
# 用法：generate-release-notes.sh <new_version> <last_tag>

if [[ $# -ne 2 ]]; then
  echo "用法：$0 <new_version> <last_tag>" >&2
  exit 1
fi

NEW_VERSION="$1"
LAST_TAG="$2"

# 获取自上一个 tag 以来的提交
if [ "$LAST_TAG" = "v0.0.0" ]; then
  # 统计提交数量并作为上限
  COMMIT_COUNT=$(git rev-list --count HEAD)
  if [ "$COMMIT_COUNT" -gt 10 ]; then
    COMMITS=$(git log --oneline --pretty=format:"- %s" HEAD~10..HEAD)
  else
    COMMITS=$(git log --oneline --pretty=format:"- %s" HEAD~$COMMIT_COUNT..HEAD 2>/dev/null || git log --oneline --pretty=format:"- %s")
  fi
else
  COMMITS=$(git log --oneline --pretty=format:"- %s" $LAST_TAG..HEAD)
fi

# 生成 release notes
cat > release_notes.md << EOF
这是你可以与所选 agent 搭配使用的最新 release 集合。我们推荐使用 Specify CLI 来初始化项目；当然，你也可以单独下载这些模板并自行管理。

## 变更日志

$COMMITS

EOF

echo "已生成 release notes："
cat release_notes.md
