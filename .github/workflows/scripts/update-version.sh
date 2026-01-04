#!/usr/bin/env bash
set -euo pipefail

# 脚本：update-version.sh
# 更新 pyproject.toml 中的版本（仅用于 release 产物）
# 用法：update-version.sh <version>

if [[ $# -ne 1 ]]; then
  echo "用法：$0 <version>" >&2
  exit 1
fi

VERSION="$1"

# 为 Python 版本号移除 'v' 前缀
PYTHON_VERSION=${VERSION#v}

if [ -f "pyproject.toml" ]; then
  sed -i "s/version = \".*\"/version = \"$PYTHON_VERSION\"/" pyproject.toml
  echo "已将 pyproject.toml 版本更新为 $PYTHON_VERSION（仅用于 release 产物）"
else
  echo "警告：未找到 pyproject.toml，跳过版本更新"
fi
