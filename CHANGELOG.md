# 更新日志

<!-- markdownlint-disable MD024 -->

Specify CLI 与模板的所有重要变更都会记录在此。

格式参考 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)，
本项目遵循 [语义化版本（Semantic Versioning）](https://semver.org/spec/v2.0.0.html)。

## [0.0.22] - 2025-11-07

- 支持 VS Code/Copilot agents，并从 prompts 迁移到具备 hand-off 能力的正式 agents。
- Copilot 工作流改为使用 `AGENTS.md`（因其开箱即用已支持）。
- 增加 `version` 命令支持。（[#486](https://github.com/github/spec-kit/issues/486)）
- 修复 `create-new-feature.ps1` 在计算下一个 feature 编号时可能忽略已有 feature 分支的潜在问题（[#975](https://github.com/github/spec-kit/issues/975)）
- 在拉取模板时遇到 GitHub API 限流，增加更友好的降级处理与日志记录（[#970](https://github.com/github/spec-kit/issues/970)）

## [0.0.21] - 2025-10-21

- 修复 [#975](https://github.com/github/spec-kit/issues/975)（感谢 [@fgalarraga](https://github.com/fgalarraga)）。
- 增加 Amp CLI 支持。
- 增加 VS Code hand-off 支持，并将 prompts 改为完整的 chat mode。
- 增加 `version` 命令支持（解决 [#811](https://github.com/github/spec-kit/issues/811) 与 [#486](https://github.com/github/spec-kit/issues/486)，感谢 [@mcasalaina](https://github.com/mcasalaina) 与 [@dentity007](https://github.com/dentity007)）。
- 增加在遇到限流时从 CLI 渲染 rate limit 错误信息（[#970](https://github.com/github/spec-kit/issues/970)，感谢 [@psmman](https://github.com/psmman)）。

## [0.0.20] - 2025-10-14

### 新增

- **智能分支命名**：`create-new-feature` 脚本新增 `--short-name` 参数，用于自定义分支名
  - 提供 `--short-name`：直接使用自定义名称（会清洗并格式化）
  - 不提供：通过停用词过滤与长度过滤自动生成有意义的名称
  - 过滤常见停用词（I、want、to、the、for 等）
  - 移除长度小于 3 的词（除非是全大写缩写）
  - 从描述中选取 3–4 个最有意义的词
  - **强制执行 GitHub 的 244 字节分支名限制**，并在需要时自动截断与提示告警
  - 示例：
    - "I want to create user authentication" → `001-create-user-authentication`
    - "Implement OAuth2 integration for API" → `001-implement-oauth2-integration-api`
    - "Fix payment processing bug" → `001-fix-payment-processing`
    - 超长描述会在词边界自动截断以保持在限制内
  - 面向 AI agents：既支持语义化短名称，又保持脚本独立可用

### 变更

- 增强 `create-new-feature.sh` 与 `create-new-feature.ps1` 的帮助文档，并补充示例
- 分支名现在会校验 GitHub 的 244 字节限制，必要时自动截断

## [0.0.19] - 2025-10-10

### 新增

- 增加 CodeBuddy 支持（感谢 [@lispking](https://github.com/lispking) 的贡献）。
- 现在可以在 Specify CLI 中看到来自 Git 的错误信息。

### 变更

- 修复 `plan.md` 中指向 constitution 的路径（感谢 [@lyzno1](https://github.com/lyzno1) 指出）。
- 修复为 Gemini 生成的 TOML 文件中的反斜杠转义问题（感谢 [@hsin19](https://github.com/hsin19) 的贡献）。
- `implement` 命令现在会确保添加正确的 ignore 文件（感谢 [@sigent-amazon](https://github.com/sigent-amazon) 的贡献）。

## [0.0.18] - 2025-10-06

### 新增

- 支持在 `specify init .` 中使用 `.` 作为当前目录的简写；效果等同 `--here`，但对用户更直观。
- 使用 `/speckit.` 命令前缀以便快速发现 Spec Kit 相关命令。
- 重构 prompts 与模板，简化能力边界与跟踪方式；不再在不需要时把测试塞进来“污染”产物。
- 确保按用户故事创建 tasks（简化测试与验证）。
- 增加 Visual Studio Code prompt 快捷方式与自动执行脚本支持。

### 变更

- 所有命令文件现在都带 `speckit.` 前缀（例如 `speckit.specify.md`、`speckit.plan.md`），以便在 IDE/CLI 的命令面板与文件浏览器中更易发现与区分

## [0.0.17] - 2025-09-22

### 新增

- 新增 `/clarify` 命令模板：针对既有 spec 提出最多 5 个聚焦澄清问题，并把答案持久化到 spec 的 Clarifications（澄清）章节。
- 新增 `/analyze` 命令模板：提供非破坏性的跨产物差异与对齐报告（spec、clarifications、plan、tasks、constitution），插入在 `/tasks` 之后、`/implement` 之前。
  - 注意：Constitution 规则被明确视为不可协商；任何冲突都会被标记为 CRITICAL，需要修复产物，而不是弱化原则。

## [0.0.16] - 2025-09-22

### 新增

- `init` 命令新增 `--force`：在使用 `--here` 且目录非空时跳过确认，直接合并/覆盖文件继续执行。

## [0.0.15] - 2025-09-21

### 新增

- 支持 Roo Code。

## [0.0.14] - 2025-09-21

### 变更

- 错误信息现在以一致方式展示。

## [0.0.13] - 2025-09-21

### 新增

- 支持 Kilo Code。感谢 [@shahrukhkhan489](https://github.com/shahrukhkhan489) 的贡献（[#394](https://github.com/github/spec-kit/pull/394)）。
- 支持 Auggie CLI。感谢 [@hungthai1401](https://github.com/hungthai1401) 的贡献（[#137](https://github.com/github/spec-kit/pull/137)）。
- 项目初始化完成后显示 agent 文件夹安全提示：提醒用户某些 agent 可能在其文件夹内存储凭据或 auth token，并建议将相关目录加入 `.gitignore` 以避免凭据意外泄露。

### 变更

- 增加告警提示，确保用户意识到可能需要把 agent 文件夹加入 `.gitignore`。
- 清理并优化 `check` 命令输出。

## [0.0.12] - 2025-09-21

### 变更

- 为 OpenAI Codex 用户补充更多上下文：他们需要设置一个额外的环境变量（见 [#417](https://github.com/github/spec-kit/issues/417)）。

## [0.0.11] - 2025-09-20

### 新增

- Codex CLI 支持（感谢 [@honjo-hiroaki-gtt](https://github.com/honjo-hiroaki-gtt) 的贡献：[ #14](https://github.com/github/spec-kit/pull/14)）
- 增加对 Codex 感知的上下文更新工具（Bash 与 PowerShell），使 feature plan 能与现有 assistants 一起刷新 `AGENTS.md`，无需手动编辑。

## [0.0.10] - 2025-09-20

### 修复

- 修复 [#378](https://github.com/github/spec-kit/issues/378)：当 GitHub token 为空时仍可能被附加到请求中的问题。

## [0.0.9] - 2025-09-19

### 变更

- 改进 agent 选择器 UI：agent key 使用青色高亮，全名使用灰色括号显示

## [0.0.8] - 2025-09-19

### 新增

- 支持 Windsurf IDE，作为额外的 AI assistant 选项（感谢 [@raedkit](https://github.com/raedkit) 的工作：[ #151](https://github.com/github/spec-kit/pull/151)）
- API 请求支持 GitHub token，以适配企业环境与限流（由 [@zryfish](https://github.com/@zryfish) 贡献：[ #243](https://github.com/github/spec-kit/pull/243)）

### 变更

- 更新 README：加入 Windsurf 示例与 GitHub token 使用方式
- 增强 release 工作流：包含 Windsurf 模板

## [0.0.7] - 2025-09-18

### 变更

- 更新 CLI 中的命令说明。
- 清理代码：当信息是通用的情况下，不再渲染 agent 专用信息。

## [0.0.6] - 2025-09-17

### 新增

- 支持 opencode，作为额外 AI assistant 选项

## [0.0.5] - 2025-09-17

### 新增

- 支持 Qwen Code，作为额外 AI assistant 选项

## [0.0.4] - 2025-09-14

### 新增

- 通过 `httpx[socks]` 依赖增加 SOCKS 代理支持，以适配企业环境

### 修复

N/A

### 变更

N/A
