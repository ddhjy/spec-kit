# 实现计划（Implementation Plan）：[FEATURE]

**分支**：`[###-feature-name]` | **日期**：[DATE] | **规格**：[link]
**输入**：来自 `/specs/[###-feature-name]/spec.md` 的功能规格说明

**说明**：该模板由 `/speckit.plan` 命令填充。执行工作流请参考 `.specify/templates/commands/plan.md`。

## 摘要

[从功能规格说明提取：主要需求 + 来自 research 的技术实现思路]

## 技术上下文

<!--
  需要你填写：把本节内容替换为项目的具体技术细节。
  这里的结构仅作为建议，用于引导迭代过程。
-->

**语言/版本**：[例如 Python 3.11、Swift 5.9、Rust 1.75，或 NEEDS CLARIFICATION]  
**主要依赖**：[例如 FastAPI、UIKit、LLVM，或 NEEDS CLARIFICATION]  
**存储**：[如适用，例如 PostgreSQL、CoreData、文件或 N/A]  
**测试**：[例如 pytest、XCTest、cargo test，或 NEEDS CLARIFICATION]  
**目标平台**：[例如 Linux server、iOS 15+、WASM，或 NEEDS CLARIFICATION]
**项目类型**：[single/web/mobile——决定源码结构]  
**性能目标**：[领域相关，例如 1000 req/s、10k 行/秒、60 fps，或 NEEDS CLARIFICATION]  
**约束**：[领域相关，例如 p95 <200ms、内存 <100MB、支持离线，或 NEEDS CLARIFICATION]  
**规模/范围**：[领域相关，例如 1 万用户、100 万 LOC、50 个页面，或 NEEDS CLARIFICATION]

## Constitution 检查

*门禁（GATE）：在第 0 阶段 research 前必须通过；第 1 阶段设计后需再次检查。*

[基于 constitution 文件确定的门禁条目]

## 项目结构

### 文档（本 feature）

```text
specs/[###-feature]/
├── plan.md              # 本文件（/speckit.plan 输出）
├── research.md          # 第 0 阶段输出（/speckit.plan）
├── data-model.md        # 第 1 阶段输出（/speckit.plan）
├── quickstart.md        # 第 1 阶段输出（/speckit.plan）
├── contracts/           # 第 1 阶段输出（/speckit.plan）
└── tasks.md             # 第 2 阶段输出（/speckit.tasks——不是由 /speckit.plan 创建）
```

### 源码（仓库根目录）
<!--
  需要你填写：把下面占位的目录树替换为本 feature 的真实结构。
  删除未使用的选项，并将选中的结构扩展为真实路径（例如 apps/admin、packages/something）。
  最终交付的计划中不得保留 “Option” 标签。
-->

```text
# [如未使用请删除] 选项 1：单项目（默认）
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [如未使用请删除] 选项 2：Web 应用（检测到 "frontend" + "backend" 时）
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [如未使用请删除] 选项 3：移动端 + API（检测到 "iOS/Android" 时）
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**结构决策**：[记录所选结构，并引用上方已写明的真实目录]

## 复杂度追踪

> **仅当 Constitution 检查存在必须解释的违规项时才填写**

| 违规项 | 为什么需要 | 为什么拒绝更简单的替代方案 |
|------|----------|--------------------------|
| [例如：第 4 个项目] | [当前需要] | [为何 3 个项目不够] |
| [例如：Repository pattern] | [具体问题] | [为何直接访问 DB 不足] |
