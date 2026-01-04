# 快速开始指南

本指南将帮助你使用 Spec Kit 快速上手规格驱动开发（SDD）。

> [!NOTE]
> 所有自动化脚本现在都同时提供 Bash（`.sh`）与 PowerShell（`.ps1`）版本。`specify` CLI 会根据操作系统自动选择，除非你显式传入 `--script sh|ps`。

## 六步流程

> [!TIP]
> **上下文感知**：Spec Kit 命令会根据你当前的 Git 分支（例如 `001-feature-name`）自动识别正在工作的 feature。要切换到不同规格说明，只需要切换 Git 分支即可。

### 步骤 1：安装/初始化 Specify

**在终端中**运行 `specify` CLI 来初始化项目：

```bash
# 创建一个新项目目录
uvx --from git+https://github.com/github/spec-kit.git specify init <PROJECT_NAME>

# 或在当前目录初始化
uvx --from git+https://github.com/github/spec-kit.git specify init .
```

（可选）显式指定脚本类型：

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init <PROJECT_NAME> --script ps  # 强制使用 PowerShell
uvx --from git+https://github.com/github/spec-kit.git specify init <PROJECT_NAME> --script sh  # 强制使用 POSIX shell
```

### 步骤 2：定义你的 Constitution（项目原则）

**在 AI agent 的聊天界面中**，使用 `/speckit.constitution` slash command 建立项目的核心规则与原则。你应把项目的具体原则作为参数传入。

```markdown
/speckit.constitution 本项目采用“库优先（Library-First）”方式。所有功能必须先实现为独立库。严格遵循 TDD。优先采用函数式编程模式。
```

### 步骤 3：创建规格说明（Spec）

**在聊天中**，使用 `/speckit.specify` slash command 描述你想构建什么。请聚焦 **做什么（what）** 与 **为什么（why）**，先不要关注技术栈。

```markdown
/speckit.specify 构建一个应用，帮助我把照片整理到不同相册中。相册按日期分组，并且可以在主页面通过拖拽重新排序。相册不会嵌套在其他相册里。每个相册内用类似瓷砖的界面预览照片。
```

### 步骤 4：精炼规格说明

**在聊天中**，使用 `/speckit.clarify` slash command 识别并解决规格说明中的歧义。你可以把关注点作为参数传入。

```bash
/speckit.clarify 请重点关注安全与性能需求。
```

### 步骤 5：创建技术实现计划

**在聊天中**，使用 `/speckit.plan` slash command 提供你的技术栈与架构选择。

```markdown
/speckit.plan 应用使用 Vite，并尽量减少依赖库。尽可能使用原生 HTML、CSS、JavaScript。图片不上传到任何地方，元数据存储在本地 SQLite 数据库。
```

### 步骤 6：拆分任务并实现

**在聊天中**，使用 `/speckit.tasks` slash command 生成可执行的任务清单。

```markdown
/speckit.tasks
```

（可选）使用 `/speckit.analyze` 校验计划：

```markdown
/speckit.analyze
```

然后使用 `/speckit.implement` slash command 执行计划。

```markdown
/speckit.implement
```

## 详细示例：构建 Taskify

下面是一个构建团队效率平台的完整示例：

### 步骤 1：定义 Constitution

初始化项目 constitution，设定基础规则：

```markdown
/speckit.constitution Taskify 是“安全优先（Security-First）”应用。所有用户输入必须校验。采用微服务架构。代码必须有完整文档。
```

### 步骤 2：用 `/speckit.specify` 定义需求

```text
开发 Taskify，一个团队效率平台。它应允许用户创建项目、添加团队成员、分配任务、发表评论，并以看板（Kanban）风格在不同列之间移动任务。在本功能的初始阶段（暂称 “Create Taskify”），我们支持多用户，但用户将预先声明并固定（预置）。
我需要 5 个用户，分两类：1 个产品经理与 4 个工程师。创建 3 个不同的示例项目。看板列使用标准状态列，例如 “To Do”（待办）、“In Progress”（进行中）、“In Review”（评审中）、“Done”（完成）。该应用不需要登录功能，因为这只是最初的验证，用于确保基础功能搭建完成。
```

### 步骤 3：精炼规格说明

使用 `/speckit.clarify` 以交互方式解决规格中的歧义。你也可以提供你希望确保被覆盖的具体细节。

```bash
/speckit.clarify 我想澄清任务卡片细节：在 UI 中，对每个任务卡片，用户应能在看板的不同列之间切换任务当前状态。用户应能对单张卡片留下不限数量的评论。并且用户应能在任务卡片中将其指派给一个有效用户。
```

你可以继续使用 `/speckit.clarify` 补充更多细节来精炼规格：

```bash
/speckit.clarify 当你第一次启动 Taskify 时，会提供 5 个用户供选择，不需要密码。点击某个用户后进入主视图，显示项目列表；点击项目后打开该项目的看板并看到各列。你可以拖拽卡片在不同列之间移动。分配给当前登录用户的卡片应与其他卡片用不同颜色区分，便于快速识别。你可以编辑自己发表的评论，但不能编辑他人的评论；你可以删除自己发表的评论，但不能删除他人的评论。
```

### 步骤 4：校验规格说明

使用 `/speckit.checklist` 校验规格说明清单：

```bash
/speckit.checklist
```

### 步骤 5：用 `/speckit.plan` 生成技术计划

明确你的技术栈与技术要求：

```bash
/speckit.plan 我们将使用 .NET Aspire 生成该项目，数据库使用 Postgres。前端使用 Blazor Server，支持拖拽看板并实时更新。需要提供 REST API：projects API、tasks API 与 notifications API。
```

### 步骤 6：校验并实现

让你的 AI agent 使用 `/speckit.analyze` 审计实现计划：

```bash
/speckit.analyze
```

最后，实现方案：

```bash
/speckit.implement
```

## 关键原则

- **明确表达**你要构建什么以及为什么
- 在规格阶段**不要纠结技术栈**
- 在实现前**迭代并精炼**你的规格说明
- 在开始编码前先**校验**计划
- **让 AI agent 处理**实现细节

## 下一步

- 阅读[完整方法论](../spec-driven.md)获取深入指导
- 查看仓库中的[更多示例](../templates)
- 浏览 [GitHub 上的源码](https://github.com/github/spec-kit)
