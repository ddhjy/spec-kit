---
description: 使用 plan 模板执行实现规划工作流并生成设计产物。
handoffs: 
  - label: 生成任务清单
    agent: speckit.tasks
    prompt: 请把计划拆分为任务
    send: true
  - label: 生成检查清单
    agent: speckit.checklist
    prompt: 请为以下领域生成一份检查清单……
scripts:
  sh: scripts/bash/setup-plan.sh --json
  ps: scripts/powershell/setup-plan.ps1 -Json
agent_scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前，你 **必须** 先考虑用户输入（如果不为空）。

## 大纲

1. **准备**：在仓库根目录运行 `{SCRIPT}`，并解析 JSON 里的 FEATURE_SPEC、IMPL_PLAN、SPECS_DIR、BRANCH。参数中若包含单引号（例如 "I'm Groot"），请使用转义：例如 'I'\''m Groot'（或尽量用双引号："I'm Groot"）。

2. **加载上下文**：读取 FEATURE_SPEC 与 `/memory/constitution.md`。加载 IMPL_PLAN 模板（已复制到目标位置）。

3. **执行计划工作流**：按 IMPL_PLAN 模板结构执行：
   - 填写 Technical Context（未知项标记为 “NEEDS CLARIFICATION”）
   - 基于 constitution 填写 Constitution Check 章节
   - 评估门禁（如存在未被合理解释的违规项则报错）
   - 阶段 0：生成 research.md（解决所有 NEEDS CLARIFICATION）
   - 阶段 1：生成 data-model.md、contracts/、quickstart.md
   - 阶段 1：运行 agent script 更新 agent 上下文
   - 设计完成后重新评估 Constitution Check

4. **停止并汇报**：命令在阶段 2 规划后结束。汇报分支名、IMPL_PLAN 路径与生成的产物。

## 阶段

### 阶段 0：梳理与调研

1. **从 Technical Context 中提取未知项**：
   - 每个 NEEDS CLARIFICATION → 一个调研任务
   - 每个依赖 → 一个最佳实践任务
   - 每个集成点 → 一个模式/方案任务

2. **生成并分发调研任务**：

   ```text
   对 Technical Context 中的每个未知项：
     任务："调研 {unknown}（结合 {feature context}）"
   对每个技术选型：
     任务："查找 {domain} 中 {tech} 的最佳实践"
   ```

3. **在 `research.md` 中汇总结论**，按如下格式：
   - Decision：[选择了什么]
   - Rationale：[为什么这么选]
   - Alternatives considered：[还评估过哪些替代方案]

**输出**：research.md（所有 NEEDS CLARIFICATION 已解决）

### 阶段 1：设计与合同（Contracts）

**前置条件：**`research.md` 已完成

1. **从功能规格说明提取实体** → `data-model.md`：
   - 实体名称、字段、关系
   - 来自需求的校验规则
   - 如适用：状态机/状态流转

2. **基于功能性需求生成 API contracts**：
   - 每个用户动作 → 一个 endpoint
   - 使用标准 REST/GraphQL 模式
   - 将 OpenAPI/GraphQL schema 输出到 `/contracts/`

3. **更新 agent 上下文**：
   - 运行 `{AGENT_SCRIPT}`
   - 脚本会检测当前使用的 AI agent
   - 更新对应的 agent 专用上下文文件
   - 仅添加本次计划中新出现的技术
   - 保留标记区间内的手工补充内容

**输出**：data-model.md、/contracts/*、quickstart.md、agent 专用文件

## 关键规则

- 使用绝对路径
- 门禁失败或澄清未解决时必须报错
