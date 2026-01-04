---
description: 在任务生成后，对 spec.md、plan.md、tasks.md 进行非破坏性的跨产物一致性与质量分析。
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前，你 **必须** 先考虑用户输入（如果不为空）。

## 目标

在开始实现之前，识别三大核心产物（`spec.md`、`plan.md`、`tasks.md`）之间的不一致、重复、歧义与欠定义项。本命令必须在 `/speckit.tasks` 成功生成完整的 `tasks.md` 之后才可运行。

## 运行约束

**严格只读**：不得修改任何文件。输出结构化分析报告。可提供可选的修复建议方案（用户必须明确同意后，才可在后续由人工触发编辑类命令）。

**Constitution 权威性**：在本分析范围内，项目 constitution（`/memory/constitution.md`）是**不可协商**的。任何与 constitution 冲突的内容都自动判定为 **CRITICAL**，并要求调整 spec/plan/tasks，而不是稀释、重新解释或悄悄忽略原则。如果确实需要修改原则本身，必须在 `/speckit.analyze` 之外，单独进行明确的 constitution 更新。

## 执行步骤

### 1. 初始化分析上下文

在仓库根目录运行 `{SCRIPT}` 一次，并解析 JSON 获取 FEATURE_DIR 与 AVAILABLE_DOCS。推导绝对路径：

- SPEC = FEATURE_DIR/spec.md
- PLAN = FEATURE_DIR/plan.md
- TASKS = FEATURE_DIR/tasks.md

若任何必需文件缺失则报错并中止（提示用户运行缺失的前置命令）。  
参数中若包含单引号（例如 "I'm Groot"），请使用转义：例如 'I'\''m Groot'（或尽量用双引号："I'm Groot"）。

### 2. 加载产物（渐进式披露）

每个产物只加载最小必要上下文：

**从 spec.md：**

- Overview/Context
- Functional Requirements
- Non-Functional Requirements
- User Stories
- Edge Cases（如存在）

**从 plan.md：**

- 架构/技术栈选择
- 数据模型引用
- 阶段划分
- 技术约束

**从 tasks.md：**

- Task IDs
- 任务描述
- 阶段分组
- 并行标记 [P]
- 引用到的文件路径

**从 constitution：**

- 读取 `/memory/constitution.md` 用于原则校验

### 3. 构建语义模型

创建内部表示（不要在输出中粘贴原始全文）：

- **需求清单（requirements inventory）**：每条功能/非功能需求生成稳定 key（从祈使句生成 slug；例如 "User can upload file" → `user-can-upload-file`）
- **用户故事/动作清单**：离散用户动作及其验收标准
- **任务覆盖映射（task coverage mapping）**：将每个任务映射到一个或多个需求/故事（基于关键词推断或显式引用，如 ID/关键短语）
- **原则集合（constitution rule set）**：提取原则名称与 MUST/SHOULD 等规范性表述

### 4. 检测扫描（Token 高效）

聚焦高信号发现。最多输出 50 条发现；其余汇总到 overflow 摘要。

#### A. 重复检测

- 识别近似重复的需求
- 标记表达质量较差者以便合并

#### B. 歧义检测

- 标记缺少可衡量标准的模糊形容词（fast、scalable、secure、intuitive、robust 等）
- 标记未解决占位符（TODO、TKTK、???、`<placeholder>` 等）

#### C. 欠定义

- 有动词但缺少宾语或可衡量结果的需求
- 用户故事缺少与验收标准的对齐
- tasks 引用的文件/组件在 spec/plan 中未定义

#### D. Constitution 对齐

- 任意与 MUST 原则冲突的需求或计划项
- constitution 强制的章节或质量门禁缺失

#### E. 覆盖缺口

- 没有任何关联任务的需求
- 无法映射到任何需求/故事的任务
- tasks 未体现的非功能需求（例如性能、安全）

#### F. 不一致

- 术语漂移（同一概念在不同文件中名称不同）
- plan 引用的数据实体在 spec 中缺失（或反之）
- 任务顺序矛盾（例如未注明依赖却把集成任务放在基础设施任务之前）
- 需求互相冲突（例如一个要求 Next.js，另一个写 Vue）

### 5. 严重度判定

按以下启发式规则确定优先级：

- **CRITICAL**：违反 constitution MUST；缺少核心产物；或存在“零覆盖且阻塞基础功能”的需求
- **HIGH**：需求重复/冲突；安全/性能等关键非功能属性含糊；验收标准不可测试
- **MEDIUM**：术语漂移；缺少非功能任务覆盖；边界情况欠定义
- **LOW**：措辞/风格改进；不影响执行顺序的小冗余

### 6. 输出精炼分析报告

输出一个 Markdown 报告（不写文件），结构如下：

## 规格说明分析报告

| ID | 类别 | 严重度 | 位置 | 摘要 | 建议 |
|----|------|--------|------|------|------|
| A1 | 重复 | HIGH | spec.md:L120-134 | 两条相似需求…… | 合并表述；保留更清晰的版本 |

（每条发现一行；ID 使用稳定前缀，按类别首字母编号。）

**覆盖度汇总表：**

| Requirement Key | 是否有任务 | Task IDs | 备注 |
|-----------------|-----------|----------|------|

**Constitution 对齐问题：**（如有）

**未映射任务：**（如有）

**指标（Metrics）：**

- 需求总数（Total Requirements）
- 任务总数（Total Tasks）
- 覆盖率（Coverage %：至少有 1 个任务的需求占比）
- 歧义数量（Ambiguity Count）
- 重复数量（Duplication Count）
- Critical 问题数量（Critical Issues Count）

### 7. 给出下一步动作

在报告末尾输出一个精炼的 Next Actions 区块：

- 若存在 CRITICAL：建议在 `/speckit.implement` 前先修复
- 若仅 LOW/MEDIUM：可继续，但给出改进建议
- 给出明确命令建议：例如“用精炼提示词再次运行 /speckit.specify”“运行 /speckit.plan 调整架构”“手动编辑 tasks.md 为 'performance-metrics' 增加覆盖任务”

### 8. 提供修复建议（不自动修改）

询问用户：“你希望我为 Top N 问题给出具体的修复改动建议吗？”（不要自动应用修改）

## 操作原则

### 上下文效率

- **最少高信号 token**：聚焦可执行的发现，不做穷举式文档
- **渐进式披露**：按需加载产物，不要把全文倒进分析结果
- **输出 token 高效**：发现表最多 50 行，其余汇总
- **确定性结果**：不改动的情况下重复运行应得到一致的 ID 与统计

### 分析准则

- **绝不修改文件**（只读分析）
- **绝不臆造缺失章节**（缺失就如实报告）
- **优先处理 constitution 违规**（永远是 CRITICAL）
- **用例子胜过穷举规则**（引用具体实例，不做泛泛而谈）
- **零问题也要优雅报告**（输出成功报告与覆盖统计）

## Context

{ARGS}
