#!/usr/bin/env bash
set -euo pipefail

# 脚本：check-release-exists.sh
# 检查指定版本的 GitHub release 是否已存在
# 用法：check-release-exists.sh <version>

if [[ $# -ne 1 ]]; then
  echo "用法：$0 <version>" >&2
  exit 1
fi

VERSION="$1"

if gh release view "$VERSION" >/dev/null 2>&1; then
  echo "exists=true" >> $GITHUB_OUTPUT
  echo "发布 $VERSION 已存在，跳过..."
else
  echo "exists=false" >> $GITHUB_OUTPUT
  echo "发布 $VERSION 不存在，继续执行..."
fi
