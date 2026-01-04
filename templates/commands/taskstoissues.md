---
description: 基于现有设计产物，将 tasks 转换为可执行、按依赖排序的 GitHub issues。
tools: ['github/github-mcp-server/issue_write']
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前，你 **必须** 先考虑用户输入（如果不为空）。

## 大纲

1. 在仓库根目录运行 `{SCRIPT}` 并解析 FEATURE_DIR 与 AVAILABLE_DOCS 列表。所有路径必须是绝对路径。参数中若包含单引号（例如 "I'm Groot"），请使用转义：例如 'I'\''m Groot'（或尽量用双引号："I'm Groot"）。
1. 从脚本输出中提取 **tasks** 的路径。
1. 通过以下命令获取 Git remote：

```bash
git config --get remote.origin.url
```

> [!CAUTION]
> 只有当 remote 是 GitHub URL 时才可以继续后续步骤

1. 对任务列表中的每个任务，使用 GitHub MCP server 在 remote 指向的仓库中创建一个对应的 issue。

> [!CAUTION]
> 在任何情况下都不得在与 remote URL 不匹配的仓库中创建 issue
