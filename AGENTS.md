# AGENTS.md

## 关于 Spec Kit 与 Specify

**GitHub Spec Kit** 是一套用于落地规格驱动开发（Spec-Driven Development，SDD）的综合工具包。SDD 强调在实现之前先写清楚规格说明。该工具包包含模板、脚本与工作流，帮助团队以结构化方式构建软件。

**Specify CLI** 是用于用 Spec Kit 框架引导初始化项目的命令行工具。它会创建必要的目录结构、模板和 AI agent 集成，以支持 SDD 工作流。

该工具包支持多种 AI coding assistant，使团队可以使用自己偏好的工具，同时保持一致的项目结构与开发实践。

---

## 通用实践

- 只要修改了 Specify CLI 的 `__init__.py`，就必须在 `pyproject.toml` 里提升版本号，并在 `CHANGELOG.md` 中添加相应条目。

## 添加新的 Agent 支持

本节说明如何在 Specify CLI 中新增对 AI agent/assistant 的支持。在将新的 AI 工具集成进 SDD 工作流时，请参考此指南。

### 概览

Specify 通过在初始化项目时生成“agent 专用命令文件与目录结构”来支持多种 AI agent。每个 agent 都有自己的约定，例如：

- **命令文件格式**（Markdown、TOML 等）
- **目录结构**（`.claude/commands/`、`.windsurf/workflows/` 等）
- **命令调用方式**（slash command、CLI 工具等）
- **参数传递约定**（`$ARGUMENTS`、`{{args}}` 等）

### 当前支持的 Agents

| Agent                      | 目录                   | 格式     | CLI 工具        | 说明                          |
| -------------------------- | ---------------------- | -------- | --------------- | ----------------------------- |
| **Claude Code**            | `.claude/commands/`    | Markdown | `claude`        | Anthropic 的 Claude Code CLI  |
| **Gemini CLI**             | `.gemini/commands/`    | TOML     | `gemini`        | Google 的 Gemini CLI          |
| **GitHub Copilot**         | `.github/agents/`      | Markdown | 无（IDE 内置）  | VS Code 中的 GitHub Copilot    |
| **Cursor**                 | `.cursor/commands/`    | Markdown | `cursor-agent`  | Cursor CLI                    |
| **Qwen Code**              | `.qwen/commands/`      | TOML     | `qwen`          | 阿里巴巴的 Qwen Code CLI       |
| **opencode**               | `.opencode/command/`   | Markdown | `opencode`      | opencode CLI                  |
| **Codex CLI**              | `.codex/commands/`     | Markdown | `codex`         | Codex CLI                     |
| **Windsurf**               | `.windsurf/workflows/` | Markdown | 无（IDE 内置）  | Windsurf IDE 工作流            |
| **Kilo Code**              | `.kilocode/rules/`     | Markdown | 无（IDE 内置）  | Kilo Code IDE                  |
| **Auggie CLI**             | `.augment/rules/`      | Markdown | `auggie`        | Auggie CLI                    |
| **Roo Code**               | `.roo/rules/`          | Markdown | 无（IDE 内置）  | Roo Code IDE                   |
| **CodeBuddy CLI**          | `.codebuddy/commands/` | Markdown | `codebuddy`     | CodeBuddy CLI                 |
| **Qoder CLI**              | `.qoder/commands/`     | Markdown | `qoder`         | Qoder CLI                     |
| **Amazon Q Developer CLI** | `.amazonq/prompts/`    | Markdown | `q`             | Amazon Q Developer CLI        |
| **Amp**                    | `.agents/commands/`    | Markdown | `amp`           | Amp CLI                       |
| **SHAI**                   | `.shai/commands/`      | Markdown | `shai`          | SHAI CLI                      |
| **IBM Bob**                | `.bob/commands/`       | Markdown | 无（IDE 内置）  | IBM Bob IDE                   |

### 分步集成指南

按照以下步骤添加新 agent（以一个假设的 agent 为例）：

#### 1. 添加到 AGENT_CONFIG

**重要**：请使用真实的 CLI 工具名称作为 key，不要使用缩写。

把新 agent 添加到 `src/specify_cli/__init__.py` 里的 `AGENT_CONFIG` 字典中。这里是所有 agent 元数据的**唯一事实来源**：

```python
AGENT_CONFIG = {
    # ... 现有 agents ...
    "new-agent-cli": {  # 使用真实的 CLI 工具名称（用户在终端实际输入的命令）
        "name": "新 Agent 的展示名称",
        "folder": ".newagent/",  # 保存该 agent 文件的目录
        "install_url": "https://example.com/install",  # 安装文档 URL（IDE-based agent 可为 None）
        "requires_cli": True,  # 需要 CLI 工具则为 True；IDE-based 则为 False
    },
}
```

**关键设计原则**：字典 key 必须与用户安装的真实可执行文件名一致。例如：

- ✅ 使用 `"cursor-agent"`，因为该 CLI 工具的名字就是 `cursor-agent`
- ❌ 不要用 `"cursor"` 作为缩写（如果真实工具是 `cursor-agent`）

这样可以避免在整个代码库中到处写特殊映射逻辑。

**字段说明**：

- `name`：展示给用户的人类可读名称
- `folder`：保存 agent 专用文件的目录（相对项目根目录）
- `install_url`：安装文档 URL（IDE-based agent 设为 `None`）
- `requires_cli`：初始化时是否需要检查 CLI 工具是否存在

#### 2. 更新 CLI 帮助文本

更新 `init()` 命令里 `--ai` 参数的帮助文本，把新 agent 加进去：

```python
ai_assistant: str = typer.Option(None, "--ai", help="AI assistant to use: claude, gemini, copilot, cursor-agent, qwen, opencode, codex, windsurf, kilocode, auggie, codebuddy, new-agent-cli, or q"),
```

同时更新所有列出可用 agent 的函数 docstring、示例与错误信息。

#### 3. 更新 README 文档

更新 `README.md` 的 **Supported AI Agents**（支持的 AI Agents）章节，加入新 agent：

- 把新 agent 加入表格并标注合适的支持级别（完整/部分）
- 添加 agent 的官方网站链接
- 补充与 agent 实现相关的备注信息
- 确保表格格式对齐且一致

#### 4. 更新 release 打包脚本

修改 `.github/workflows/scripts/create-release-packages.sh`：

##### 加入 ALL_AGENTS 数组

```bash
ALL_AGENTS=(claude gemini copilot cursor-agent qwen opencode windsurf q)
```

##### 为目录结构添加 case 分支

```bash
case $agent in
  # ... existing cases ...
  windsurf)
    mkdir -p "$base_dir/.windsurf/workflows"
    generate_commands windsurf md "\$ARGUMENTS" "$base_dir/.windsurf/workflows" "$script" ;;
esac
```

#### 4. 更新 GitHub Release 脚本

修改 `.github/workflows/scripts/create-github-release.sh`，把新 agent 的打包产物加入 release：

```bash
gh release create "$VERSION" \
  # ... existing packages ...
  .genreleases/spec-kit-template-windsurf-sh-"$VERSION".zip \
  .genreleases/spec-kit-template-windsurf-ps-"$VERSION".zip \
  # 在此处添加新 agent 的打包产物
```

#### 5. 更新 agent 上下文脚本

##### Bash script (`scripts/bash/update-agent-context.sh`)

添加文件变量：

```bash
WINDSURF_FILE="$REPO_ROOT/.windsurf/rules/specify-rules.md"
```

加入 case 分支：

```bash
case "$AGENT_TYPE" in
  # ... existing cases ...
  windsurf) update_agent_file "$WINDSURF_FILE" "Windsurf" ;;
  "")
    # ... existing checks ...
    [ -f "$WINDSURF_FILE" ] && update_agent_file "$WINDSURF_FILE" "Windsurf";
    # Update default creation condition
    ;;
esac
```

##### PowerShell script (`scripts/powershell/update-agent-context.ps1`)

添加文件变量：

```powershell
$windsurfFile = Join-Path $repoRoot '.windsurf/rules/specify-rules.md'
```

加入 switch 分支：

```powershell
switch ($AgentType) {
    # ... existing cases ...
    'windsurf' { Update-AgentFile $windsurfFile 'Windsurf' }
    '' {
        foreach ($pair in @(
            # ... existing pairs ...
            @{file=$windsurfFile; name='Windsurf'}
        )) {
            if (Test-Path $pair.file) { Update-AgentFile $pair.file $pair.name }
        }
        # Update default creation condition
    }
}
```

#### 6. 更新 CLI 工具检查（可选）

对于需要 CLI 工具的 agent，在 `check()` 命令与 agent 校验逻辑里添加检查：

```python
# In check() command
tracker.add("windsurf", "Windsurf IDE (optional)")
windsurf_ok = check_tool_for_tracker("windsurf", "https://windsurf.com/", tracker)

# In init validation (only if CLI tool required)
elif selected_ai == "windsurf":
    if not check_tool("windsurf", "Install from: https://windsurf.com/"):
        console.print("[red]Error:[/red] Windsurf CLI is required for Windsurf projects")
        agent_tool_missing = True
```

**说明**：CLI 工具检查现在会基于 AGENT_CONFIG 中的 `requires_cli` 字段自动处理。`check()` 与 `init()` 命令无需再额外修改代码——它们会自动遍历 AGENT_CONFIG 并按需检查工具。

## 重要设计决策

### 使用真实 CLI 工具名作为 key

**关键**：向 AGENT_CONFIG 添加新 agent 时，字典 key 必须使用**真实可执行文件名**，不要使用缩写或“更顺手的名字”。

**为什么这很重要：**

- The `check_tool()` function uses `shutil.which(tool)` to find executables in the system PATH
- If the key doesn't match the actual CLI tool name, you'll need special-case mappings throughout the codebase
- This creates unnecessary complexity and maintenance burden

**示例：Cursor 的教训**

❌ **错误做法**（需要到处写特殊映射）：

```python
AGENT_CONFIG = {
    "cursor": {  # 缩写不匹配真实工具名
        "name": "Cursor",
        # ...
    }
}

# 然后你就不得不在各处加特殊判断：
cli_tool = agent_key
if agent_key == "cursor":
    cli_tool = "cursor-agent"  # 映射到真实工具名
```

✅ **正确做法**（无需映射）：

```python
AGENT_CONFIG = {
    "cursor-agent": {  # 匹配真实可执行文件名
        "name": "Cursor",
        # ...
    }
}

# 不需要特殊判断——直接使用 agent_key 即可！
```

**这样做的好处：**

- Eliminates special-case logic scattered throughout the codebase
- Makes the code more maintainable and easier to understand
- Reduces the chance of bugs when adding new agents
- Tool checking "just works" without additional mappings

#### 7. 更新 Devcontainer 文件（可选）

对于需要 VS Code 扩展或需要安装 CLI 的 agent，更新 devcontainer 配置文件：

##### VS Code Extension-based Agents

对于以 VS Code 扩展形式提供的 agent，将其加入 `.devcontainer/devcontainer.json`：

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        // ... existing extensions ...
        // [New Agent Name]
        "[New Agent Extension ID]"
      ]
    }
  }
}
```

##### CLI-based Agents

对于需要 CLI 工具的 agent，在 `.devcontainer/post-create.sh` 中添加安装命令：

```bash
#!/bin/bash

# Existing installations...

echo -e "\n🤖 正在安装 [新 Agent 名称] CLI..."
# run_command "npm install -g [agent-cli-package]@latest" # Node 生态 CLI 示例
# 或其他安装指令（必须是非交互式，并兼容 Linux Debian “Trixie” 或更高版本）...
echo "✅ 完成"

```

**快速提示：**

- **基于扩展的 agent**：添加到 `devcontainer.json` 的 `extensions` 数组
- **基于 CLI 的 agent**：把安装脚本加入 `post-create.sh`
- **混合型 agent**：可能两者都需要
- **充分测试**：确保安装过程在 devcontainer 环境中可用

## Agent Categories

### 基于 CLI 的 Agents

需要安装命令行工具：

- **Claude Code**: `claude` CLI
- **Gemini CLI**: `gemini` CLI
- **Cursor**: `cursor-agent` CLI
- **Qwen Code**: `qwen` CLI
- **opencode**: `opencode` CLI
- **Amazon Q Developer CLI**: `q` CLI
- **CodeBuddy CLI**: `codebuddy` CLI
- **Qoder CLI**: `qoder` CLI
- **Amp**: `amp` CLI
- **SHAI**: `shai` CLI

### 基于 IDE 的 Agents

在集成开发环境（IDE）中工作：

- **GitHub Copilot**: Built into VS Code/compatible editors
- **Windsurf**: Built into Windsurf IDE
- **IBM Bob**: Built into IBM Bob IDE

## Command File Formats

### Markdown 格式

适用：Claude、Cursor、opencode、Windsurf、Amazon Q Developer、Amp、SHAI、IBM Bob

**标准格式：**

```markdown
---
description: "命令描述"
---

命令内容，包含 {SCRIPT} 与 $ARGUMENTS 占位符。
```

**GitHub Copilot Chat Mode 格式：**

```markdown
---
description: "命令描述"
mode: speckit.command-name
---

命令内容，包含 {SCRIPT} 与 $ARGUMENTS 占位符。
```

### TOML 格式

适用：Gemini、Qwen

```toml
description = "命令描述"

prompt = """
命令内容，包含 {SCRIPT} 与 {{args}} 占位符。
"""
```

## 目录约定

- **CLI agents**：通常为 `.<agent-name>/commands/`
- **IDE agents**：遵循 IDE 专用约定：
  - Copilot: `.github/agents/`
  - Cursor: `.cursor/commands/`
  - Windsurf: `.windsurf/workflows/`

## 参数占位符约定

不同 agent 使用不同的参数占位符：

- **基于 Markdown/prompt**：`$ARGUMENTS`
- **基于 TOML**：`{{args}}`
- **脚本占位符**：`{SCRIPT}`（会被替换为实际脚本路径）
- **Agent 占位符**：`__AGENT__`（会被替换为 agent 名称）

## Testing New Agent Integration

1. **构建测试**：在本地运行打包脚本
2. **CLI 测试**：测试 `specify init --ai <agent>` 命令
3. **文件生成**：验证目录结构与文件是否正确
4. **命令验证**：确保生成的命令在该 agent 下可用
5. **上下文更新**：测试 agent 上下文更新脚本

## Common Pitfalls

1. **用缩写 key 代替真实 CLI 工具名**：AGENT_CONFIG 的 key 必须使用真实可执行文件名（例如用 `"cursor-agent"` 而不是 `"cursor"`），避免到处写特殊映射逻辑。
2. **忘记更新脚本**：新增 agent 时，bash 与 PowerShell 脚本都需要更新。
3. **`requires_cli` 值不正确**：只有确实需要检查 CLI 工具的 agent 才设为 `True`；IDE-based agent 设为 `False`。
4. **参数格式错误**：不同 agent 需使用正确占位符（Markdown 用 `$ARGUMENTS`，TOML 用 `{{args}}`）。
5. **目录命名错误**：严格遵循 agent 的目录约定（参考现有 agent 的实现）。
6. **帮助文本不一致**：保持所有用户可见文本一致更新（help 字符串、docstring、README、错误信息）。

## Future Considerations

新增 agent 时建议：

- 考虑该 agent 原生的命令/工作流模式
- 确保与 SDD（规格驱动开发）流程兼容
- 记录任何特殊要求或限制
- 将经验教训补充到本指南中
- 在添加到 AGENT_CONFIG 之前，核实真实 CLI 工具名

---

*当新增 agent 时，应同步更新本文件，以保持准确性与完整性。*
