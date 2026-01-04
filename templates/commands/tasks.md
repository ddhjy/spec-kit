---
description: 基于现有设计产物，为该功能生成可执行、按依赖排序的 tasks.md。
handoffs: 
  - label: 一致性分析
    agent: speckit.analyze
    prompt: 请运行跨产物一致性分析
    send: true
  - label: 开始实现
    agent: speckit.implement
    prompt: 请按阶段开始实现
    send: true
scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前，你 **必须** 先考虑用户输入（如果不为空）。

## 大纲

1. **准备**：在仓库根目录运行 `{SCRIPT}`，并解析 FEATURE_DIR 与 AVAILABLE_DOCS 列表。所有路径必须是绝对路径。参数中若包含单引号（例如 "I'm Groot"），请使用转义：例如 'I'\''m Groot'（或尽量用双引号："I'm Groot"）。

2. **加载设计文档**：从 FEATURE_DIR 读取：
   - **必需**：plan.md（技术栈、依赖、结构）、spec.md（带优先级的用户故事）
   - **可选**：data-model.md（实体）、contracts/（API 端点）、research.md（技术决策）、quickstart.md（测试场景）
   - 注意：并非所有项目都有全部文档；请基于现有内容生成 tasks。

3. **执行任务生成工作流**：
   - 读取 plan.md 并提取技术栈、依赖与项目结构
   - 读取 spec.md 并提取用户故事及其优先级（P1、P2、P3……）
   - 若存在 data-model.md：提取实体并映射到用户故事
   - 若存在 contracts/：将端点映射到用户故事
   - 若存在 research.md：提取决策以生成准备阶段任务
   - 按用户故事组织任务（见下方“任务生成规则”）
   - 生成依赖图，展示用户故事完成顺序
   - 为每个用户故事生成并行执行示例
   - 校验任务完整性（每个用户故事都有所需任务，且可独立测试）

4. **生成 tasks.md**：以 `templates/tasks-template.md` 为结构，填充：
   - Correct feature name from plan.md
   - Phase 1: Setup tasks (project initialization)
   - Phase 2: Foundational tasks (blocking prerequisites for all user stories)
   - Phase 3+: One phase per user story (in priority order from spec.md)
   - Each phase includes: story goal, independent test criteria, tests (if requested), implementation tasks
   - Final Phase: Polish & cross-cutting concerns
   - All tasks must follow the strict checklist format (see Task Generation Rules below)
   - Clear file paths for each task
   - Dependencies section showing story completion order
   - Parallel execution examples per story
   - Implementation strategy section (MVP first, incremental delivery)

5. **汇报**：输出生成的 tasks.md 路径与摘要：
   - Total task count
   - Task count per user story
   - Parallel opportunities identified
   - Independent test criteria for each story
   - Suggested MVP scope (typically just User Story 1)
   - Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)

任务生成的上下文：{ARGS}

生成的 tasks.md 应可立即执行——每个任务都必须足够具体，使 LLM 在无需额外上下文的情况下也能完成。

## 任务生成规则

**关键**：任务必须按用户故事组织，以支持独立实现与独立测试。

**测试是可选的**：仅当功能规格明确要求测试，或用户要求 TDD 时才生成测试任务。

### 清单格式（必需）

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [P?] [Story?] Description with file path
```

**格式组成**：

1. **复选框**：必须以 `- [ ]` 开头（Markdown checkbox）
2. **任务 ID**：按执行顺序编号（T001、T002、T003……）
3. **[P] 标记**：仅在任务可并行时使用（不同文件，且不依赖未完成任务）
4. **[Story] 标签**：仅用于用户故事阶段任务，并且是必需的
   - 格式：[US1]、[US2]、[US3]……（映射到 spec.md 的用户故事）
   - 准备阶段：不写 story 标签
   - 基础设施阶段：不写 story 标签
   - 用户故事阶段：必须写 story 标签
   - 打磨阶段：不写 story 标签
5. **描述**：清晰动作 + 精确文件路径

**Examples**:

- ✅ CORRECT: `- [ ] T001 Create project structure per implementation plan`
- ✅ CORRECT: `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
- ✅ CORRECT: `- [ ] T012 [P] [US1] Create User model in src/models/user.py`
- ✅ CORRECT: `- [ ] T014 [US1] Implement UserService in src/services/user_service.py`
- ❌ WRONG: `- [ ] Create User model` (missing ID and Story label)
- ❌ WRONG: `T001 [US1] Create model` (missing checkbox)
- ❌ WRONG: `- [ ] [US1] Create User model` (missing Task ID)
- ❌ WRONG: `- [ ] T001 [US1] Create model` (missing file path)

### Task Organization

1. **From User Stories (spec.md)** - PRIMARY ORGANIZATION:
   - Each user story (P1, P2, P3...) gets its own phase
   - Map all related components to their story:
     - Models needed for that story
     - Services needed for that story
     - Endpoints/UI needed for that story
     - If tests requested: Tests specific to that story
   - Mark story dependencies (most stories should be independent)

2. **From Contracts**:
   - Map each contract/endpoint → to the user story it serves
   - If tests requested: Each contract → contract test task [P] before implementation in that story's phase

3. **From Data Model**:
   - Map each entity to the user story(ies) that need it
   - If entity serves multiple stories: Put in earliest story or Setup phase
   - Relationships → service layer tasks in appropriate story phase

4. **From Setup/Infrastructure**:
   - Shared infrastructure → Setup phase (Phase 1)
   - Foundational/blocking tasks → Foundational phase (Phase 2)
   - Story-specific setup → within that story's phase

### Phase Structure

- **Phase 1**: Setup (project initialization)
- **Phase 2**: Foundational (blocking prerequisites - MUST complete before user stories)
- **Phase 3+**: User Stories in priority order (P1, P2, P3...)
  - Within each story: Tests (if requested) → Models → Services → Endpoints → Integration
  - Each phase should be a complete, independently testable increment
- **Final Phase**: Polish & Cross-Cutting Concerns
