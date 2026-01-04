# 为 Spec Kit 做贡献

你好！我们很高兴你愿意为 Spec Kit 做贡献。对本项目的贡献将依据[项目的开源许可证](LICENSE)对外公开发布（参见 GitHub 服务条款中关于贡献的说明：`https://help.github.com/articles/github-terms-of-service/#6-contributions-under-repository-license`）。

请注意：本项目采用一份[贡献者行为准则](CODE_OF_CONDUCT.md)。参与本项目即表示你同意遵守其中条款。

## 运行与测试代码的前置条件

以下为一次性安装项，用于在提交 Pull Request（PR）前在本地测试你的改动。

1. 安装 [Python 3.11+](https://www.python.org/downloads/)
1. 安装 [uv](https://docs.astral.sh/uv/) 作为包管理工具
1. 安装 [Git](https://git-scm.com/downloads)
1. 准备一个可用的 [AI coding agent](README.md#-supported-ai-agents)

<details>
<summary><b>💡 如果你使用 <code>VSCode</code> 或 <code>GitHub Codespaces</code> 作为 IDE 的提示</b></summary>

<br>

只要你的机器安装了 [Docker](https://docker.com)，你就可以通过这个 [VSCode 扩展](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) 来使用 [Dev Containers](https://containers.dev)，借助项目根目录的 `.devcontainer/devcontainer.json`，快速搭建开发环境（上述工具已预装并完成配置）。

操作步骤如下：

- 检出（checkout）仓库
- 用 VSCode 打开
- 打开 [命令面板](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette)，选择 “Dev Containers: Open Folder in Container...”

如果你使用 [GitHub Codespaces](https://github.com/features/codespaces)，则更简单：打开 codespace 时会自动使用 `.devcontainer/devcontainer.json`。

</details>

## 提交 Pull Request

> [!NOTE]
> 如果你的 PR 引入了会显著影响 CLI 或仓库其他部分的大改动（例如新增模板、参数或其他重大变更），请确保已经与项目维护者**提前沟通并达成一致**。未提前沟通且包含重大变更的 PR 可能会被关闭。

1. 派生（fork）并克隆（clone）仓库
1. 配置并安装依赖：`uv sync`
1. 确认 CLI 在你的机器上可用：`uv run specify --help`
1. 创建新分支：`git checkout -b my-branch-name`
1. 完成修改、补充测试，并确保一切仍然正常
1. 若相关，请用示例项目测试 CLI 功能
1. Push 到你的 fork 并提交 Pull Request
1. 等待 PR 被审阅与合并

以下做法会提高你的 PR 被接受的概率：

- 遵循项目的编码规范。
- 为新功能编写测试。
- 如果你的修改影响用户可见功能，请同步更新文档（`README.md`、`spec-driven.md`）。
- 尽量保持修改聚焦。如果你有多个互不依赖的改动，建议拆分成多个 PR 提交。
- 写一个[好的 commit message](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)。
- 用规格驱动开发（SDD）工作流验证你的改动，确保兼容性。

## 开发工作流

在开发 spec-kit 时：

1. 使用你选择的 coding agent，在 `specify` CLI 命令（`/speckit.specify`、`/speckit.plan`、`/speckit.tasks`）下测试改动
2. 验证 `templates/` 目录中的模板是否能正常工作
3. 测试 `scripts/` 目录下脚本功能
4. 若流程有重大变化，确保更新记忆文件（`memory/constitution.md`）

### 在本地测试模板与命令改动

运行 `uv run specify init` 会拉取已发布的包，其中不包含你的本地改动。  
要在本地测试模板、命令与其他改动，请按以下步骤操作：

1. **创建 release 包**

   运行以下命令生成本地包：

   ```bash
   ./.github/workflows/scripts/create-release-packages.sh v1.0.0
   ```

2. **将相关包复制到你的测试项目**

   ```bash
   cp -r .genreleases/sdd-copilot-package-sh/. <path-to-test-project>/
   ```

3. **打开并测试 agent**

   进入测试项目目录并打开 agent，验证你的实现。

## Spec Kit 中的 AI 辅助贡献

> [!IMPORTANT]
>
> 如果你在为 Spec Kit 做贡献时使用了**任何形式的 AI 辅助**，
> 必须在 PR 或 issue 中进行披露（说明）。

我们欢迎并鼓励使用 AI 工具来改进 Spec Kit！很多有价值的贡献都借助了 AI（例如用于代码生成、问题定位、功能定义等）。

不过，如果你在贡献过程中使用了任何 AI 辅助（例如 agents、ChatGPT），
**必须在 PR 或 issue 中披露**，并说明 AI 使用的范围与程度（例如仅用于文档注释 vs. 参与代码生成）。

如果你的 PR 回复或评论是由 AI 生成的，也请一并披露。

作为例外：仅涉及非常小的空格/拼写修复且改动范围仅限于少量代码或短语时，无需披露。

披露示例：

> 本 PR 主要由 GitHub Copilot 编写。

或更详细的披露：

> 我借助 ChatGPT 来理解代码库，但最终方案完全由我本人手工编写。

不披露首先是对 PR 另一端的人工审阅者不尊重；同时也会让维护者难以判断该贡献需要多大程度的审查。

在理想世界里，AI 辅助可以产出不低于任何人类的高质量成果。但现实并非如此：在多数缺少人类监督或专业能力兜底的情况下，AI 很可能生成难以维护或演进的代码。

### 我们希望看到什么

提交 AI 辅助的贡献时，请确保包含：

- **清晰披露 AI 使用情况**：明确说明是否使用 AI、以及使用程度
- **人类理解与测试**：你亲自测试过改动，并理解其行为
- **清楚的动机与理由**：你能解释为什么需要该改动，以及它如何符合 Spec Kit 的目标
- **具体证据**：提供测试用例、场景或示例来证明改进效果
- **你自己的分析**：分享你对端到端开发者体验的观察与想法

### 我们会关闭什么样的贡献

我们保留关闭以下类型贡献的权利：

- 未经测试/验证的改动
- 不能解决 Spec Kit 具体需求的泛泛建议
- 大批量提交但看不出有人类审阅与理解的改动

### 成功提交的建议

关键在于证明：你理解并验证了你提出的改动。如果维护者很容易看出贡献是纯 AI 生成且缺少人类输入或测试，那么它大概率需要在提交前做更多工作。

持续提交低投入、低质量的 AI 生成改动的贡献者，可能会被维护者酌情限制后续贡献权限。

请尊重维护者，并披露 AI 使用情况。

## 资源

- [规格驱动开发（SDD）方法论](./spec-driven.md)
- [如何为开源做贡献](https://opensource.guide/how-to-contribute/)
- [如何使用 Pull Request](https://help.github.com/articles/about-pull-requests/)
- [GitHub 帮助](https://help.github.com)
