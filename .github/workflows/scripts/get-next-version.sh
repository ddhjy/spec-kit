#!/usr/bin/env bash
set -euo pipefail

# 脚本：get-next-version.sh
# 基于最新 git tag 计算下一个版本，并输出 GitHub Actions 变量
# 用法：get-next-version.sh

# 获取最新 tag；如果没有 tag，则使用 v0.0.0
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo "latest_tag=$LATEST_TAG" >> $GITHUB_OUTPUT

# 解析版本号并递增
VERSION=$(echo $LATEST_TAG | sed 's/v//')
IFS='.' read -ra VERSION_PARTS <<< "$VERSION"
MAJOR=${VERSION_PARTS[0]:-0}
MINOR=${VERSION_PARTS[1]:-0}
PATCH=${VERSION_PARTS[2]:-0}

# 递增 patch 版本
PATCH=$((PATCH + 1))
NEW_VERSION="v$MAJOR.$MINOR.$PATCH"

echo "new_version=$NEW_VERSION" >> $GITHUB_OUTPUT
echo "新版本将为：$NEW_VERSION"
