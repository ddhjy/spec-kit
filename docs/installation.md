# 安装指南

## 前置条件

- **Linux/macOS**（或 Windows；现已支持 PowerShell 脚本，无需 WSL）
- AI coding agent：[Claude Code](https://www.anthropic.com/claude-code)、[GitHub Copilot](https://code.visualstudio.com/)、[Codebuddy CLI](https://www.codebuddy.ai/cli) 或 [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- 用于包管理的 [uv](https://docs.astral.sh/uv/)
- [Python 3.11+](https://www.python.org/downloads/)
- [Git](https://git-scm.com/downloads)

## 安装

### 初始化一个新项目

最简单的开始方式是初始化一个新项目：

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init <PROJECT_NAME>
```

或者在当前目录初始化：

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init .
# or use the --here flag
uvx --from git+https://github.com/github/spec-kit.git specify init --here
```

### 指定 AI Agent

你可以在初始化时直接指定要使用的 AI agent：

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init <project_name> --ai claude
uvx --from git+https://github.com/github/spec-kit.git specify init <project_name> --ai gemini
uvx --from git+https://github.com/github/spec-kit.git specify init <project_name> --ai copilot
uvx --from git+https://github.com/github/spec-kit.git specify init <project_name> --ai codebuddy
```

### 指定脚本类型（Shell vs PowerShell）

所有自动化脚本现在都同时提供 Bash（`.sh`）与 PowerShell（`.ps1`）版本。

自动选择规则：

- Windows 默认：`ps`
- 其他系统默认：`sh`
- 交互模式：若未传 `--script` 会提示你选择

强制指定脚本类型：

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init <project_name> --script sh
uvx --from git+https://github.com/github/spec-kit.git specify init <project_name> --script ps
```

### 忽略 Agent 工具检查

如果你只想获取模板而不检查是否安装了对应工具：

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init <project_name> --ai claude --ignore-agent-tools
```

## 验证

初始化完成后，你应该能在 AI agent 中看到以下命令：

- `/speckit.specify`：创建规格说明
- `/speckit.plan`：生成实现计划
- `/speckit.tasks`：拆分为可执行任务

`.specify/scripts` 目录将同时包含 `.sh` 与 `.ps1` 脚本。

## 故障排查

### Linux 上的 Git Credential Manager

如果你在 Linux 上遇到 Git 认证问题，可以安装 Git Credential Manager：

```bash
#!/usr/bin/env bash
set -e
echo "正在下载 Git Credential Manager v2.6.1..."
wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.1/gcm-linux_amd64.2.6.1.deb
echo "正在安装 Git Credential Manager..."
sudo dpkg -i gcm-linux_amd64.2.6.1.deb
echo "正在配置 Git 使用 GCM..."
git config --global credential.helper manager
echo "正在清理..."
rm gcm-linux_amd64.2.6.1.deb
```
