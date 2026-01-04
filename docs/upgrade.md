# 升级指南

> 你已经安装了 Spec Kit，并希望升级到最新版本以获取新功能、修复 bug 或更新 slash commands。本指南同时覆盖 CLI 工具升级与项目文件更新。

---

## 快速参考

| 升级内容 | 命令 | 适用场景 |
|----------------|---------|-------------|
| **仅 CLI 工具** | `uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git` | 获取最新 CLI 功能，但不改动项目文件 |
| **项目文件** | `specify init --here --force --ai <your-agent>` | 更新项目中的 slash commands、模板与脚本 |
| **两者都升级** | 先升级 CLI，再更新项目文件 | 推荐用于主版本升级 |

---

## 第一部分：升级 CLI 工具

CLI 工具（`specify`）与项目文件是分开的。升级 CLI 可以获得最新功能与 bug 修复。

### 如果你使用 `uv tool install` 安装

```bash
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git
```

### 如果你使用一次性 `uvx` 命令

无需升级——`uvx` 总是拉取最新版本。照常运行命令即可：

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init --here --ai copilot
```

### 验证升级

```bash
specify check
```

该命令会显示已安装工具，并确认 CLI 可正常工作。

---

## 第二部分：更新项目文件

当 Spec Kit 发布新功能（例如新的 slash commands 或更新的模板）时，你需要刷新项目中的 Spec Kit 文件。

### 会更新哪些内容？

运行 `specify init --here --force` 会更新：

- ✅ **Slash command 文件**（`.claude/commands/`、`.github/prompts/` 等）
- ✅ **脚本文件**（`.specify/scripts/`）
- ✅ **模板文件**（`.specify/templates/`）
- ✅ **共享记忆文件**（`.specify/memory/`）- **⚠️ 请查看下方警告**

### 哪些内容是安全的（不会被改动）？

升级过程**绝不会触碰**以下内容——模板包里甚至不包含它们：

- ✅ **你的规格说明**（`specs/001-my-feature/spec.md` 等）- **已确认安全**
- ✅ **你的实现计划**（`specs/001-my-feature/plan.md`、`tasks.md` 等）- **已确认安全**
- ✅ **你的源代码** - **已确认安全**
- ✅ **你的 git 历史** - **已确认安全**

`specs/` 目录被模板包完全排除，因此在升级过程中永远不会被修改。

### 更新命令

在你的项目目录中运行：

```bash
specify init --here --force --ai <your-agent>
```

将 `<your-agent>` 替换为你的 AI assistant。可参考：[支持的 AI Agents](../README.md#-supported-ai-agents)。

**示例：**

```bash
specify init --here --force --ai copilot
```

### 理解 `--force` 标志

不使用 `--force` 时，CLI 会提示警告并请求确认：

```text
警告：当前目录非空（25 个条目）
模板文件将与现有内容合并，并可能覆盖已有文件
继续？[y/N]
```

使用 `--force` 时，会跳过确认并立即继续。

**重要：你的 `specs/` 目录始终安全。** `--force` 只影响模板文件（commands、scripts、templates、memory）。`specs/` 中的 feature 规格说明、计划与任务不会包含在升级包里，因此不可能被覆盖。

---

## ⚠️ 重要警告

### 1. Constitution 文件会被覆盖

**已知问题：**`specify init --here --force` 目前会用默认模板覆盖 `.specify/memory/constitution.md`，从而抹掉你做过的自定义修改。

**变通方案：**

```bash
# 1. 升级前先备份 constitution
cp .specify/memory/constitution.md .specify/memory/constitution-backup.md

# 2. 执行升级
specify init --here --force --ai copilot

# 3. 恢复你自定义的 constitution
mv .specify/memory/constitution-backup.md .specify/memory/constitution.md
```

或者用 git 恢复：

```bash
# 升级后，从 git 历史恢复
git restore .specify/memory/constitution.md
```

### 2. 自定义模板修改会被覆盖

如果你修改过 `.specify/templates/` 里的任何模板，升级会覆盖它们。请先备份：

```bash
# 备份自定义模板
cp -r .specify/templates .specify/templates-backup

# 升级后手动把你的改动合并回去
```

### 3. Slash commands 重复（IDE-based agents）

某些基于 IDE 的 agent（例如 Kilo Code、Windsurf）在升级后可能会出现 **slash commands 重复**——旧版本与新版本同时存在。

**解决方案：**手动从 agent 目录中删除旧的命令文件。

**以 Kilo Code 为例：**

```bash
# 进入 agent 的命令目录
cd .kilocode/rules/

# 列出文件并识别重复项
ls -la

# 删除旧版本（示例文件名——你的项目可能不同）
rm speckit.specify-old.md
rm speckit.plan-v1.md
```

重启 IDE 以刷新命令列表。

---

## 常见场景

### 场景 1：“我只想要最新的 slash commands”

```bash
# 升级 CLI（如果你使用持久安装）
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git

# 更新项目文件以获得新命令
specify init --here --force --ai copilot

# 如果你自定义过 constitution，则恢复它
git restore .specify/memory/constitution.md
```

### 场景 2：“我改过 templates 和 constitution”

```bash
# 1. 备份自定义内容
cp .specify/memory/constitution.md /tmp/constitution-backup.md
cp -r .specify/templates /tmp/templates-backup

# 2. 升级 CLI
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git

# 3. 更新项目
specify init --here --force --ai copilot

# 4. 恢复自定义内容
mv /tmp/constitution-backup.md .specify/memory/constitution.md
# 如有需要，手动合并 templates 的变更
```

### 场景 3：“我的 IDE 里出现重复的 slash commands”

这通常发生在基于 IDE 的 agents（Kilo Code、Windsurf、Roo Code 等）上。

```bash
# 找到 agent 目录（示例：.kilocode/rules/）
cd .kilocode/rules/

# 列出所有文件
ls -la

# 删除旧命令文件
rm speckit.old-command-name.md

# 重启 IDE
```

### 场景 4：“我在一个没有 Git 的项目里工作”

如果你在初始化项目时使用了 `--no-git`，仍然可以升级：

```bash
# 手动备份你自定义过的文件
cp .specify/memory/constitution.md /tmp/constitution-backup.md

# 执行升级
specify init --here --force --ai copilot --no-git

# 恢复自定义内容
mv /tmp/constitution-backup.md .specify/memory/constitution.md
```

`--no-git` 会跳过 git 初始化，但不会影响文件更新。

---

## 使用 `--no-git` 标志

`--no-git` 会告诉 Spec Kit **跳过 git 仓库初始化**。以下场景会很有用：

- 你用不同的版本控制方式（Mercurial、SVN 等）
- 你的项目属于一个已有 git 配置的大型 monorepo
- 你在做实验，还不想引入版本控制

**初次初始化时：**

```bash
specify init my-project --ai copilot --no-git
```

**升级时：**

```bash
specify init --here --force --ai copilot --no-git
```

### `--no-git` 不会做什么

❌ 不会阻止文件更新  
❌ 不会跳过 slash command 安装  
❌ 不会影响模板合并  

它**只会**跳过执行 `git init` 与创建初始提交。

### 在没有 Git 的情况下工作

如果你使用 `--no-git`，就需要手动管理 feature 目录：

在使用规划类命令之前，**设置 `SPECIFY_FEATURE` 环境变量**：

```bash
# Bash/Zsh
export SPECIFY_FEATURE="001-my-feature"

# PowerShell
$env:SPECIFY_FEATURE = "001-my-feature"
```

这会告诉 Spec Kit 在创建 specs、plans、tasks 时要使用哪个 feature 目录。

**为什么重要：**没有 git 时，Spec Kit 无法通过当前分支名判断正在工作的 feature；环境变量提供了手动上下文。

---

## 故障排查

### “升级后看不到 slash commands”

**原因：**agent 没有重新加载命令文件。

**解决方案：**

1. **完全重启 IDE/编辑器**（不要只 reload window）
2. **对于基于 CLI 的 agents**，确认文件存在：

   ```bash
   ls -la .claude/commands/      # Claude Code
   ls -la .gemini/commands/      # Gemini
   ls -la .cursor/commands/      # Cursor
   ```

3. **检查 agent 专用配置：**
   - Codex 需要 `CODEX_HOME` 环境变量
   - 某些 agent 需要重启 workspace 或清理缓存

### “我的 constitution 自定义丢了”

**解决方案：**从 git 或备份恢复：

```bash
# 如果你在升级前提交过
git restore .specify/memory/constitution.md

# 如果你做过手动备份
cp /tmp/constitution-backup.md .specify/memory/constitution.md
```

**预防：**升级前请务必提交或备份 `constitution.md`。

### “Warning: Current directory is not empty”

**完整警告信息：**

```text
警告：当前目录非空（25 项）
模板文件会与现有内容合并，并可能覆盖已有文件
是否继续？[y/N]
```

**这是什么意思：**

当你在已有文件的目录中运行 `specify init --here`（或 `specify init .`）时会出现该警告。它在告诉你：

1. **目录已有内容**：示例中是 25 个文件/目录
2. **文件将被合并**：新模板文件会与现有文件并存/合并
3. **部分文件可能被覆盖**：如果你已经有 Spec Kit 文件（`.claude/`、`.specify/` 等），它们会被新版本替换

**会覆盖哪些内容：**

只会覆盖 Spec Kit 的基础设施文件：

- Agent 命令文件（`.claude/commands/`、`.github/prompts/` 等）
- `.specify/scripts/` 中的脚本
- `.specify/templates/` 中的模板
- `.specify/memory/` 中的记忆文件（包括 constitution）

**哪些内容不会被触碰：**

- 你的 `specs/` 目录（specifications、plans、tasks）
- 你的源代码文件
- 你的 `.git/` 目录与 git 历史
- 任何不属于 Spec Kit 模板的其他文件

**如何选择：**

- **输入 `y` 并回车**：继续合并（升级时推荐）
- **输入 `n` 并回车**：取消操作
- **使用 `--force`**：完全跳过该确认：

  ```bash
  specify init --here --force --ai copilot
  ```

**什么时候会看到该警告：**

- ✅ **正常**：升级既有 Spec Kit 项目时
- ✅ **正常**：把 Spec Kit 加到既有代码库时
- ⚠️ **不符合预期**：如果你以为自己是在空目录创建新项目

**预防建议：**升级前如果你自定义过 `.specify/memory/constitution.md`，请先提交或备份。

### “CLI 升级看起来没有生效”

验证安装情况：

```bash
# 查看已安装工具
uv tool list

# 应该能看到 specify-cli

# 验证路径
which specify

# 应该指向 uv tool 的安装目录
```

如果找不到，则重新安装：

```bash
uv tool uninstall specify-cli
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
```

### “我每次打开项目都需要运行 specify 吗？”

**简短回答：**不需要。每个项目只需运行一次 `specify init`（或在升级时再运行）。

**解释：**

`specify` CLI 工具用于：

- **初始搭建**：`specify init` 将 Spec Kit 引导进你的项目
- **升级**：`specify init --here --force` 更新模板与命令
- **诊断**：`specify check` 验证工具安装情况

一旦运行过 `specify init`，slash commands（例如 `/speckit.specify`、`/speckit.plan` 等）就会**永久安装**在项目的 agent 目录（`.claude/`、`.github/prompts/` 等）中。你的 AI assistant 会直接读取这些命令文件——无需再次运行 `specify`。

**如果你的 agent 没有识别 slash commands：**

1. **确认命令文件存在：**

   ```bash
   # GitHub Copilot
   ls -la .github/prompts/

   # Claude
   ls -la .claude/commands/
   ```

2. **完全重启 IDE/编辑器**（不要只 reload window）

3. **确认你位于正确目录**（即你运行过 `specify init` 的目录）

4. **对某些 agents**，你可能需要 reload workspace 或清理缓存

**相关问题：**如果 Copilot 无法打开本地文件，或意外使用 PowerShell 命令，这通常是 IDE 上下文问题，而不是 `specify` 的问题。你可以尝试：

- 重启 VS Code
- 检查文件权限
- 确认工作区文件夹被正确打开

---

## 版本兼容性

Spec Kit 的主版本遵循语义化版本规范。CLI 与项目文件被设计为在同一主版本内兼容。

**最佳实践：**主版本变更时同时升级 CLI 与项目文件，保持二者版本同步。

---

## 下一步

升级后：

- **测试新 slash commands：**运行 `/speckit.constitution` 或其他命令，确认一切正常
- **查看 release notes：**在 [GitHub Releases](https://github.com/github/spec-kit/releases) 了解新功能与破坏性变更
- **更新工作流：**如果新增了命令，请同步更新团队开发流程
- **查看文档：**访问 [github.io/spec-kit](https://github.github.io/spec-kit/) 获取最新指南
